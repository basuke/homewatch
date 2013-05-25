//
//  MosquittoClient.m
//
//  Copyright 2012 Nicholas Humfrey. All rights reserved.
//  Modified by Basuke Suzuki 2013.
//

#import "MosquittoClient.h"

// C Callbacks
static void on_connect(struct mosquitto *mosq, void *obj, int rc);
static void on_disconnect(struct mosquitto *mosq, void *obj, int rc);
static void on_publish(struct mosquitto *mosq, void *obj, int message_id);
static void on_message(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message);
static void on_subscribe(struct mosquitto *mosq, void *obj, int message_id, int qos_count, const int *granted_qos);
static void on_unsubscribe(struct mosquitto *mosq, void *obj, int message_id);
static void on_log(struct mosquitto *mosq, void *obj, int level, const char *str);


@implementation MosquittoClient {
    struct mosquitto *_mosq;
	BOOL _connected;
	NSTimer *_idleTimer;
}

// Initialize is called just before the first object is allocated
+ (void)initialize {
    mosquitto_lib_init();
}

+ (NSString*)version {
    int major, minor, revision;
    mosquitto_lib_version(&major, &minor, &revision);
    return [NSString stringWithFormat:@"%d.%d.%d", major, minor, revision];
}

- (MosquittoClient*)initWithClientId:(NSString*)clientId cleanSession:(BOOL)isCleanSession {
    if ((self = [super init])) {
        const char* cstrClientId = [clientId UTF8String];
        [self setHost: @"localhost"];
        [self setPort: 1883];
        [self setKeepAlive: 60];
        
        _mosq = mosquitto_new(cstrClientId, isCleanSession, (__bridge void *)(self));
        mosquitto_connect_callback_set(_mosq, on_connect);
        mosquitto_disconnect_callback_set(_mosq, on_disconnect);
        mosquitto_publish_callback_set(_mosq, on_publish);
        mosquitto_message_callback_set(_mosq, on_message);
        mosquitto_subscribe_callback_set(_mosq, on_subscribe);
        mosquitto_unsubscribe_callback_set(_mosq, on_unsubscribe);
    }
    return self;
}

- (void)dealloc {
    if (_mosq) {
		[self disconnect];
		
        mosquitto_destroy(_mosq);
        _mosq = NULL;
    }
}

- (BOOL)connect {
	if (_connected) return YES;
	
    const char *cstrHost = [_host cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cstrUsername = NULL, *cstrPassword = NULL;
    
    if (_username)
        cstrUsername = [_username UTF8String];
    
    if (_password)
        cstrPassword = [_password UTF8String];
    
    mosquitto_username_pw_set(_mosq, cstrUsername, cstrPassword);
    
    int rc = mosquitto_connect(_mosq, cstrHost, _port, _keepAlive);
    if (rc == MOSQ_ERR_ERRNO) {
		NSError *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithUTF8String:strerror(errno)]}];
		[self.delegate mosquitto:self didFailToConnectWithError:err];
		return NO;
	}
	
	_connected = YES;
	_idleTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onIdle:) userInfo:nil repeats:YES];
	
	return YES;
}

- (void)disconnect {
	if (_connected) {
		mosquitto_disconnect(_mosq);
	}
}

- (BOOL)isConnected
{
	return _connected;
}

- (void)setWill:(NSString *)payload toTopic:(NSString *)topic withQos:(NSUInteger)qos retained:(BOOL)retained;
{
    const char* cstrTopic = [topic UTF8String];
    const uint8_t* cstrPayload = (const uint8_t*)[payload UTF8String];
    size_t cstrlen = [payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    mosquitto_will_set(_mosq, cstrTopic, cstrlen, cstrPayload, qos, retained);
}


- (void)clearWill
{
    mosquitto_will_clear(_mosq);
}

- (void)publish:(NSString *)payload toTopic:(NSString *)topic withQos:(NSUInteger)qos retained:(BOOL)retained {
    const char* cstrTopic = [topic UTF8String];
    const uint8_t* cstrPayload = (const uint8_t*)[payload UTF8String];
    size_t cstrlen = [payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    mosquitto_publish(_mosq, NULL, cstrTopic, cstrlen, cstrPayload, qos, retained);
    
}

- (void)subscribe: (NSString *)topic {
    [self subscribe:topic withQos:0];
}

- (void)subscribe: (NSString *)topic withQos:(NSUInteger)qos {
    const char* cstrTopic = [topic UTF8String];
    mosquitto_subscribe(_mosq, NULL, cstrTopic, qos);
}

- (void)unsubscribe: (NSString *)topic {
    const char* cstrTopic = [topic UTF8String];
    mosquitto_unsubscribe(_mosq, NULL, cstrTopic);
}

- (void)setMessageRetry: (NSUInteger)seconds
{
    mosquitto_message_retry_set(_mosq, (unsigned int)seconds);
}

- (void)onMessage:(const struct mosquitto_message *)message
{
    MosquittoMessage *mosq_msg = [[MosquittoMessage alloc] init];
	
	mosq_msg.mid = message->mid;
	mosq_msg.qos = message->qos;
	mosq_msg.retained = message->retain;
	
    mosq_msg.topic = [NSString stringWithUTF8String: message->topic];
    mosq_msg.payload = [[NSString alloc] initWithBytes:message->payload
												length:message->payloadlen
											  encoding:NSUTF8StringEncoding];
    
    [self.delegate mosquitto:self didReceiveMessage:mosq_msg];
}

- (void)onDisconnected
{
	[_idleTimer invalidate];
	_idleTimer = nil;
	_connected = NO;
	
	[self.delegate mosquittoDidDisconnect:self];
}

- (void)onIdle:(NSTimer *)timer
{
	mosquitto_loop(_mosq, 1, 1);
}

@end

static void on_connect(struct mosquitto *mosq, void *obj, int rc)
{
    MosquittoClient* client = (__bridge MosquittoClient*)obj;
	[[client delegate] mosquitto:client didConnect:(NSUInteger)rc];
}

static void on_disconnect(struct mosquitto *mosq, void *obj, int rc)
{
    MosquittoClient* client = (__bridge MosquittoClient*)obj;
	[client onDisconnected];
}

static void on_publish(struct mosquitto *mosq, void *obj, int message_id)
{
    MosquittoClient* client = (__bridge MosquittoClient*)obj;
	[[client delegate] mosquitto:client didPublish:(NSUInteger)message_id];
}

static void on_message(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message)
{
    MosquittoClient* client = (__bridge MosquittoClient*)obj;
	[client onMessage:message];
}

static void on_subscribe(struct mosquitto *mosq, void *obj, int message_id, int qos_count, const int *granted_qos)
{
    MosquittoClient* client = (__bridge MosquittoClient*)obj;
	// FIXME: implement this
	[[client delegate] mosquitto:client didSubscribe:message_id grantedQos:nil];
}

static void on_unsubscribe(struct mosquitto *mosq, void *obj, int message_id)
{
    MosquittoClient* client = (__bridge MosquittoClient*)obj;
	[[client delegate] mosquitto:client didUnsubscribe:message_id];
}

static void on_log(struct mosquitto *mosq, void *obj, int level, const char *str)
{
    MosquittoClient* client = (__bridge MosquittoClient*)obj;
	NSString *message = [NSString stringWithUTF8String:str];
	[[client delegate] mosquitto:client log:message level:level];
}

