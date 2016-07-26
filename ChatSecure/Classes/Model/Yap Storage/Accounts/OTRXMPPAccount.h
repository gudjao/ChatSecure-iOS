//
//  OTRXMPPAccount.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"
#import "OTRvCard.h"

@class XMPPJID, XMPPStream, XMPPvCardTemp;

@interface OTRXMPPAccount : OTRAccount <OTRvCard>

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *resource;
@property (nonatomic) int port;

@property (nonatomic, strong) NSString *pushPubsubEndpoint;
@property (nonatomic, strong) NSString *pushPubsubNode;

+ (int)defaultPort;
+ (NSString *)newResource;
+ (NSString *)defaultHostname;
+ (NSString *)defaultLoginDomain;

+ (instancetype)accountForStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction;

@end
