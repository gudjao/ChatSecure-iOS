//
//  OTRXMPPMessageYapStroage.m
//  ChatSecure
//
//  Created by David Chiles on 8/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPMessageYapStroage.h"
#import "XMPPStream.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+XEP_0280.h"
#import "NSXMLElement+XEP_0203.h"
#import "OTRLog.h"
@import OTRKit;
#import "OTRXMPPBuddy.h"
#import "OTRMessage.h"
#import "OTRAccount.h"
#import "OTRConstants.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRThreadOwner.h"

@implementation OTRXMPPMessageYapStroage

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)connection
{
    if (self = [self init]) {
        self.databaseConnection = connection;
    }
    return self;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)xmppMessage
{
    [self storeMessage:xmppMessage stream:sender incoming:YES];
}

- (void)storeMessage:(XMPPMessage *)xmppMessage stream:(XMPPStream *)stream incoming:(BOOL)incoming
{
    if ([xmppMessage isMessageCarbon]) {
        [self handleCarbonMessage:xmppMessage stream:stream];
    } else {
        [self handleMessage:xmppMessage stream:stream incoming:incoming];
    }
}

- (OTRXMPPBuddy *)buddyForUsername:(NSString *)username stream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
}

- (OTRMessage *)messageFromXMPPMessage:(XMPPMessage *)xmppMessage buddyId:(NSString *)buddyId
{
    NSString *body = [xmppMessage body];
    
    NSDate * date = [xmppMessage delayedDeliveryDate];
    
    OTRMessage *message = [[OTRMessage alloc] init];
    message.incoming = YES;
    message.text = body;
    message.buddyUniqueId = buddyId;
    if (date) {
        message.date = date;
    }
    
    message.messageId = [xmppMessage elementID];
    return message;
}

- (void)handleMessage:(XMPPMessage *)xmppMessage stream:(XMPPStream *)stream incoming:(BOOL)incoming;
{
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        if ([stream.tag isKindOfClass:[NSString class]]) {
            NSString *username = [[xmppMessage from] bare];
            
            [self handleChatState:xmppMessage username:username stream:stream transaction:transaction];
            [self handleDeliverResponse:xmppMessage transaction:transaction];
            
            OTRXMPPBuddy *messageBuddy = [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
            if (!messageBuddy) {
                // message from server
                
               DDLogWarn(@"No buddy for message: %@", xmppMessage);
                return;
            }
            
            /*
            <message xmlns="jabber:client" from="jalcantara29@upsexpress.com" to="jalcantara29@upsexpress.com/bentanayan54871"><result xmlns="urn:xmpp:mam:1" id="1471843591626919" queryid="98A435D7-3414-4EB8-9296-F8F13F728B40"><forwarded xmlns="urn:xmpp:forward:0"><message xmlns="jabber:client" from="gsabulaan2@upsexpress.com/converse.js-93520316" to="jalcantara29@upsexpress.com" type="chat" id="46e44c3d-7511-436a-94fc-f6b2a918bb8d"><body>RAWR TO ME</body><active xmlns="http://jabber.org/protocol/chatstates"/></message><delay xmlns="urn:xmpp:delay" from="upsexpress.com" stamp="2016-08-22T05:26:31.627Z"/></forwarded></result></message>
            */
            
            __block OTRMessage *message = [self messageFromXMPPMessage:xmppMessage buddyId:messageBuddy.uniqueId];
            message.incoming = YES;
            id<OTRThreadOwner>activeThread = [[OTRAppDelegate appDelegate] activeThread];
            if([[activeThread threadIdentifier] isEqualToString:message.threadId]) {
                message.read = YES;
            }
            OTRAccount *account = [OTRAccount fetchObjectWithUniqueID:xmppStream.tag transaction:transaction];
            
            
            if ([xmppMessage isErrorMessage]) {
                NSError *error = [xmppMessage errorMessage];
                message.error = error;
                NSString *errorText = [[xmppMessage elementForName:@"error"] elementForName:@"text"].stringValue;
                if (!message.text) {
                    if (errorText) {
                        message.text = errorText;
                    } else {
                        message.text = error.localizedDescription;
                    }
                }
                if ([errorText containsString:@"OTR Error"]) {
                    // automatically renegotiate a new session when there's an error
                    [[OTRKit sharedInstance] initiateEncryptionWithUsername:username accountName:account.username protocol:account.protocolTypeString];
                }
                //[message saveWithTransaction:transaction];
                return;
            }
            
            if ([self duplicateMessage:xmppMessage buddyUniqueId:messageBuddy.uniqueId transaction:transaction]) {
                DDLogWarn(@"Duplicate message received: %@", xmppMessage);
                return;
            }
            
            if (message.text) {
                [[OTRKit sharedInstance] decodeMessage:message.text username:messageBuddy.username accountName:account.username protocol:kOTRProtocolTypeXMPP tag:message];
            }
        }
    }];
}

- (void)handleChatState:(XMPPMessage *)xmppMessage username:(NSString *)username stream:(XMPPStream *)stream transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OTRXMPPBuddy *messageBuddy = [OTRXMPPBuddy fetchBuddyWithUsername:username withAccountUniqueId:stream.tag transaction:transaction];
    if([xmppMessage hasChatState])
    {
        if([xmppMessage hasComposingChatState])
            messageBuddy.chatState = kOTRChatStateComposing;
        else if([xmppMessage hasPausedChatState])
            messageBuddy.chatState = kOTRChatStatePaused;
        else if([xmppMessage hasActiveChatState])
            messageBuddy.chatState = kOTRChatStateActive;
        else if([xmppMessage hasInactiveChatState])
            messageBuddy.chatState = kOTRChatStateInactive;
        else if([xmppMessage hasGoneChatState])
            messageBuddy.chatState = kOTRChatStateGone;
        [messageBuddy saveWithTransaction:transaction];
    }
}

- (void)handleDeliverResponse:(XMPPMessage *)xmppMessage transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    if ([xmppMessage hasReceiptResponse] && ![xmppMessage isErrorMessage]) {
        [OTRMessage receivedDeliveryReceiptForMessageId:[xmppMessage receiptResponseID] transaction:transaction];
    }
}

- (BOOL)duplicateMessage:(XMPPMessage *)message buddyUniqueId:(NSString *)buddyUniqueId transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    __block BOOL result = NO;
    if ([message.elementID length]) {
        [transaction enumerateMessagesWithId:message.elementID block:^(id<OTRMessageProtocol> _Nonnull databaseMessage, BOOL * _Null_unspecified stop) {
            if ([[databaseMessage threadId] isEqualToString:buddyUniqueId]) {
                *stop = YES;
                result = YES;
            }
        }];
    }
    return result;
}

- (void)handleCarbonMessage:(XMPPMessage *)xmppMessage stream:(XMPPStream *)stream
{
    //Sent Message Carbons are sent by our account to another
    //So from is our JID and to is buddy
    BOOL incoming = NO;
    XMPPMessage *forwardedMessage = [xmppMessage messageCarbonForwardedMessage];
    
    NSString *username = nil;
    if ([xmppMessage isReceivedMessageCarbon]) {
        username = [[forwardedMessage from] bare];
        incoming = YES;
    } else {
        username = [[forwardedMessage to] bare];
    }
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * __nonnull transaction) {
        
        OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyForUsername:username accountName:stream.tag transaction:transaction];
        
        if (buddy) {
            if (![self duplicateMessage:forwardedMessage buddyUniqueId:buddy.uniqueId transaction:transaction]) {
                if (incoming) {
                    [self handleChatState:forwardedMessage username:username stream:stream transaction:transaction];
                    [self handleDeliverResponse:forwardedMessage transaction:transaction];
                }
                
                
                
                if ([forwardedMessage isMessageWithBody] && ![forwardedMessage isErrorMessage] && ![OTRKit stringStartsWithOTRPrefix:forwardedMessage.body]) {
                    OTRMessage *message = [self messageFromXMPPMessage:forwardedMessage buddyId:buddy.uniqueId];
                    message.incoming = incoming;
                    id<OTRThreadOwner>activeThread = [[OTRAppDelegate appDelegate] activeThread];
                    if([[activeThread threadIdentifier] isEqualToString:message.threadId]) {
                        message.read = YES;
                    }
                    [message saveWithTransaction:transaction];
                }
            }
        }
    }];
}

@end
