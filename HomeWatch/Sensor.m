//
//  Sensor.m
//  MonHome
//
//  Created by Yosuke Suzuki on 2013/05/04.
//  Copyright (c) 2013年 Basuke. All rights reserved.
//

#import "Sensor.h"
#import "MosquittoClient.h"

@interface Sensor()<MosquittoClientDelegate>

@property(readwrite, assign) BOOL monitor;

@property(readwrite, assign) BOOL gas1;
@property(readwrite, assign) BOOL gas2;
@property(readwrite, assign) BOOL gas3;
@property(readwrite, assign) BOOL gas4;

@end

@implementation Sensor {
	MosquittoClient *_mosquitto;
	NSInteger _logLevel;
	NSDateFormatter *_timestampFormatter;
	NSRegularExpression *_gasRangeTopicRE;
}

@synthesize host=_host, port=_port, clientId=_clientId;

- (id)initWithHost:(NSString *)host port:(NSInteger)port
{
	self = [super init];
	if (self) {
		_host = host;
		_port = port;
		
		// Create unique serial
		NSString *uuid = [[[NSUUID UUID] UUIDString] substringToIndex:16];
		_clientId = [NSString stringWithFormat:@"HomeWatch-%@", uuid];
		
		// Create Mosquitto instance
		_mosquitto = [[MosquittoClient alloc] initWithClientId:_clientId cleanSession:YES];
		_mosquitto.delegate = self;
		
		// Date Formatter for parsing timestamp
		NSDateFormatter *f = [[NSDateFormatter alloc] init];
		f.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		f.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		f.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		f.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		
		_timestampFormatter = f;
		
		// Regular Expression for Topic parsing
		NSError *error;
		_gasRangeTopicRE = [NSRegularExpression regularExpressionWithPattern:@"^home/kitchen/(gas/(\\d+)|monitor)$" options:0 error:&error];
	}
	return self;
}

- (void)connect
{
	_mosquitto.host = _host;
	if (_port) _mosquitto.port = _port;
	
	[_mosquitto connect];
}

- (void)disconnect
{
	[_mosquitto disconnect];
}

- (BOOL)isConnected
{
	return [_mosquitto isConnected];
}

- (void)log:(NSString *)message level:(LogLevel)level
{
	[self.delegate sensor:self log:message level:level timestamp:[NSDate date]];
}

- (void)log:(NSString *)message
{
	[self log:message level:LogMessage];
	
#if DEBUG
	NSLog(@"%@", message);
#endif
}

#pragma mark - Mosquitto Delegate

- (void)mosquitto:(MosquittoClient *)client didConnect:(NSUInteger)code
{
	[self log:[NSString stringWithFormat:@"connected to %@ port %d", _host, _port]];
	
	[client subscribe:@"home/kitchen/gas/+"];
	[client subscribe:@"home/kitchen/monitor"];
}

- (void)mosquitto:(MosquittoClient *)client didFailToConnectWithError:(NSError *)error
{
	
}

- (void)mosquittoDidDisconnect:(MosquittoClient *)client
{
	[self log:@"disconnected"];
}

- (void)mosquitto:(MosquittoClient *)client didReceiveMessage:(MosquittoMessage*)message
{
#if DEBUG
	[self log:[NSString stringWithFormat:@"%@ : %@ qos:%d%@", message.topic, message.payload, message.qos, (message.retained ? @" RETAIN" : @"")]];
#endif
	
	BOOL on;
	NSDate *timestamp;
	
	NSArray *values = [message.payload componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if ([values count] >= 1) {
		on = [values[0] isEqualToString:@"ON"];
	}
	
	if ([values count] >= 2) {
		timestamp = [_timestampFormatter dateFromString:values[1]];
	}
	
	NSTextCheckingResult *match = [_gasRangeTopicRE firstMatchInString:message.topic options:0 range:NSMakeRange(0, message.topic.length)];
	if (match) {
		NSString *what = [message.topic substringWithRange:[match rangeAtIndex:1]];
		
		if ([what isEqualToString:@"monitor"]) {
			[self.delegate sensor:self monitorDidChange:on timestamp:timestamp];
		} else {
			NSInteger range = [[message.topic substringWithRange:[match rangeAtIndex:2]] integerValue];
			
			[self.delegate sensor:self gasRange:range didChange:on timestamp:timestamp];
		}
	}
}

- (void)mosquitto:(MosquittoClient *)client didPublish:(NSUInteger)messageId
{
}

- (void)mosquitto:(MosquittoClient *)client didSubscribe:(NSUInteger)messageId grantedQos:(NSArray*)qos
{
	[self log:[NSString stringWithFormat:@"subscribed (mid=%d)", messageId]];
}

- (void)mosquitto:(MosquittoClient *)client didUnsubscribe:(NSUInteger)messageId
{
	[self log:[NSString stringWithFormat:@"unsubscribed (mid=%d)", messageId]];
}

- (void)mosquitto:(MosquittoClient *)client log:(NSString *)message level:(NSInteger)level
{
	LogLevel logLevel = LogNone;
	
	switch (level) {
		case MOSQ_LOG_INFO:
			logLevel = LogMessage;
			break;
			
		case MOSQ_LOG_NOTICE:
			logLevel = LogMessage;
			break;
			
		case MOSQ_LOG_WARNING:
			logLevel = LogWarning;
			break;
			
		case MOSQ_LOG_ERR:
			logLevel = LogError;
			break;
			
#if DEBUG
		case MOSQ_LOG_DEBUG:
			logLevel = LogMessage;
			break;
#endif
		default:
			break;
	}
	
	if (logLevel != LogNone) {
		[self log:message level:logLevel];
	}
}

@end
