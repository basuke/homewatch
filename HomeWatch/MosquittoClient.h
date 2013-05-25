//
//  MosquittoClient.h
//
//  Copyright 2012 Nicholas Humfrey. All rights reserved.
//  Modified by Basuke Suzuki 2013.
//

#import <Foundation/Foundation.h>
#import "MosquittoMessage.h"
#import "mosquitto.h"

@class MosquittoClient;

@protocol MosquittoClientDelegate

- (void)mosquitto:(MosquittoClient *)client didConnect:(NSUInteger)code;
- (void)mosquitto:(MosquittoClient *)client didFailToConnectWithError:(NSError *)error;
- (void)mosquittoDidDisconnect:(MosquittoClient *)client;
- (void)mosquitto:(MosquittoClient *)client didPublish:(NSUInteger)messageId;

- (void)mosquitto:(MosquittoClient *)client didReceiveMessage:(MosquittoMessage*)message;
- (void)mosquitto:(MosquittoClient *)client didSubscribe:(NSUInteger)messageId grantedQos:(NSArray*)qos;
- (void)mosquitto:(MosquittoClient *)client didUnsubscribe:(NSUInteger)messageId;

- (void)mosquitto:(MosquittoClient *)client log:(NSString *)message level:(NSInteger)level;

@end


@interface MosquittoClient : NSObject

@property (readwrite,retain) NSString *host;
@property (readwrite,assign) unsigned short port;
@property (readwrite,retain) NSString *username;
@property (readwrite,retain) NSString *password;
@property (readwrite,assign) unsigned short keepAlive;
@property (readwrite,assign) id<MosquittoClientDelegate> delegate;

+ (void) initialize;
+ (NSString*) version;

- (MosquittoClient*)initWithClientId:(NSString *)clientId cleanSession:(BOOL)isCleanSession;
- (void)setMessageRetry:(NSUInteger)seconds;
- (BOOL)connect;
- (void)disconnect;
- (BOOL)isConnected;

- (void)setWill:(NSString *)payload toTopic:(NSString *)topic withQos:(NSUInteger)qos retained:(BOOL)retain;
- (void)clearWill;

- (void)publish:(NSString *)payload toTopic:(NSString *)topic withQos:(NSUInteger)qos retained:(BOOL)retain;

- (void)subscribe:(NSString *)topic;
- (void)subscribe:(NSString *)topic withQos:(NSUInteger)qos;
- (void)unsubscribe:(NSString *)topic;

@end
