//
//  MosquittoMessage.h
//  Marquette
//
//  Created by horace on 11/10/12.
//  Modified by Basuke Suzuki 2013.
//
//

#import <Foundation/Foundation.h>

@interface MosquittoMessage : NSObject

@property (readwrite) unsigned short mid;
@property (readwrite) NSString *topic;
@property (readwrite) NSString *payload;
@property (readwrite) unsigned short qos;
@property (readwrite) BOOL retained;

@end
