//
//  Sensor.h
//  MonHome
//
//  Created by Yosuke Suzuki on 2013/05/04.
//  Copyright (c) 2013年 Basuke. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LogLevel) {
	LogNone = 0,
	LogMessage,
	LogWarning,
	LogError,
};

@class Sensor;


@protocol SensorDelegate <NSObject>

- (void)sensor:(Sensor *)sensor log:(NSString *)message level:(LogLevel)level timestamp:(NSDate *)timestamp;
- (void)sensor:(Sensor *)sensor monitorDidChange:(BOOL)state timestamp:(NSDate *)timestamp;
- (void)sensor:(Sensor *)sensor gasRange:(NSInteger)range didChange:(BOOL)state timestamp:(NSDate *)timestamp;

@end


@interface Sensor : NSObject

- (id)initWithHost:(NSString *)host port:(NSInteger)port;

@property(weak) id<SensorDelegate> delegate;

@property(readonly) NSString *clientId;
@property(readonly) NSString *host;
@property(readonly) NSInteger port;

- (void)connect;
- (void)disconnect;

- (BOOL)isConnected;

@property(readonly, assign) BOOL monitor;

@property(readonly, assign) BOOL gas1;
@property(readonly, assign) BOOL gas2;
@property(readonly, assign) BOOL gas3;
@property(readonly, assign) BOOL gas4;

@end
