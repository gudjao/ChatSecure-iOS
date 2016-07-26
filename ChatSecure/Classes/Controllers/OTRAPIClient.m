//
//  OTRAPIClient.m
//  ChatSecure
//
//  Created by Juston Paul Alcantara on 20/07/2016.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRAPIClient.h"

@implementation OTRAPIClient

+ (instancetype)sharedClient {
    static OTRAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[OTRAPIClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://13.76.83.133"]];
        //_sharedClient = [[OTRAPIClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://chatbentanayan.globalpinoyremittance.com"]];
        //_sharedClient = [[OTRAPIClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.bentanayan.com"]];
        _sharedClient.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sharedClient.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"text/plain", @"application/json", nil];
        [_sharedClient.requestSerializer setValue:@"zcommerce"
                               forHTTPHeaderField:@"x-app"];
    });
    return _sharedClient;
}

@end
