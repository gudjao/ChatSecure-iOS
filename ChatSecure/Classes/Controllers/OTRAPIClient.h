//
//  OTRAPIClient.h
//  ChatSecure
//
//  Created by Juston Paul Alcantara on 20/07/2016.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface OTRAPIClient : AFHTTPSessionManager

+ (instancetype)sharedClient;

@end
