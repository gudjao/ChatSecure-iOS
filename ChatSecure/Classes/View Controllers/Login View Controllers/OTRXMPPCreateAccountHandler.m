//
//  OTRXMPPCreateAccountHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPCreateAccountHandler.h"
#import "OTRXMPPManager.h"
#import "XLForm.h"
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "XMPPServerInfoCell.h"
#import "XMPPJID.h"
#import "OTRXMPPManager.h"
#import "OTRXMPPServerInfo.h"
#import "OTRPasswordGenerator.h"
#import "OTRTorManager.h"
#import "OTRAPIClient.h"

@implementation OTRXMPPCreateAccountHandler

- (OTRXMPPAccount *)moveValues:(XLFormDescriptor *)form intoAccount:(OTRXMPPAccount *)account
{
    account = (OTRXMPPAccount *)[super moveValues:form intoAccount:account];
    OTRXMPPServerInfo *serverInfo = [[form formRowWithTag:kOTRXLFormXMPPServerTag] value];
    
    NSString *username = nil;
    if ([account.username containsString:@"@"]) {
        NSArray *components = [account.username componentsSeparatedByString:@"@"];
        username = components[0];
    } else {
        username = account.username;
    }
    
    NSString *domain = serverInfo.domain;
    
    //Create valid 'username' which is a bare jid (user@domain.com)
    XMPPJID *jid = [XMPPJID jidWithUser:username domain:domain resource:nil];
    
    if (jid) {
        account.username = [jid bare];
    }
    
    return account;
}

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account progress:(void (^)(NSInteger, NSString *))progress completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    if (form) {
        [[OTRAPIClient sharedClient]
         POST:@"/users"
         parameters:form.formValues
         progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             NSLog(@"POST - REGISTRATION SUCCESS: %@", [self getJSONObject:responseObject]);
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"POST - REGISTRATION FAILED: %@", error.localizedDescription);
         }];
        //account = (OTRXMPPAccount *)[super moveValues:form intoAccount:(OTRXMPPAccount*)account];
    }
    self.completion = completion;
    
//    if (account.accountType == OTRAccountTypeXMPPTor) {
//        //check tor is running
//        if ([OTRTorManager sharedInstance].torManager.status == CPAStatusOpen) {
//            [self finishRegisteringWithForm:form account:account];
//        } else if ([OTRTorManager sharedInstance].torManager.status == CPAStatusClosed) {
//            [[OTRTorManager sharedInstance].torManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
//                
//                if (error) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        completion(account,error);
//                    });
//                } else {
//                    [self finishRegisteringWithForm:form account:account];
//                }
//            } progress:progress];
//        }
//    } else {
//        [self finishRegisteringWithForm:form account:account];
//    }
}

- (void) finishRegisteringWithForm:(XLFormDescriptor *)form account:(OTRAccount *)account {
    [self prepareForXMPPConnectionFrom:form account:(OTRXMPPAccount *)account];
    XLFormRowDescriptor *passwordRow = [form formRowWithTag:kOTRXLFormPasswordTextFieldTag];
    NSString *passwordFromForm = [passwordRow value];
    if (passwordRow.sectionDescriptor.isHidden == NO &&
        passwordRow.isHidden == NO &&
        passwordFromForm.length > 0) {
        _password = passwordFromForm;
    } else {
        // if no password provided, generate a strong one
        _password = [OTRPasswordGenerator passwordWithLength:11];
    }
    [self.xmppManager registerNewAccountWithPassword:self.password];
}

#pragma mark - Helpers

- (id<NSObject>)getJSONObject:(id)responseObject {
    if([responseObject isKindOfClass:[NSData class]]) {
        id serializedObject = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject
                                                              options:kNilOptions error:nil];
        if([serializedObject isKindOfClass:[NSDictionary class]] ||
           [serializedObject isKindOfClass:[NSMutableDictionary class]])
        {
            return [[NSMutableDictionary alloc] initWithDictionary:serializedObject];
        }
        else if([serializedObject isKindOfClass:[NSArray class]] ||
                [serializedObject isKindOfClass:[NSMutableArray class]])
        {
            return [[NSMutableArray alloc] initWithArray:serializedObject];
        }
        else
        {
            NSLog(@"Response is not a valid object");
            return nil;
        }
    } else {
        NSLog(@"Reponse is not a NSData class");
        return nil;
    }
}

@end
