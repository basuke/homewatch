//
//  AppDelegate.m
//  MonHome
//
//  Created by Yosuke Suzuki on 2013/05/03.
//  Copyright (c) 2013年 Basuke. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "Sensor.h"

@implementation AppDelegate {
	Sensor *_sensor;
	UIBackgroundTaskIdentifier _disconnectTask;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	
	_sensor = [[Sensor alloc] initWithHost:@"mqtt.example.com" port:1883];
	[_sensor connect];
	
	self.viewController.sensor = _sensor;
	_sensor.delegate = self.viewController;
	
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	_disconnectTask = [application beginBackgroundTaskWithExpirationHandler:^{
		[application endBackgroundTask:_disconnectTask];
		_disconnectTask = UIBackgroundTaskInvalid;
	}];
	
	[_sensor disconnect];
	[self waitSensorDisconnected:application];
}

- (void)waitSensorDisconnected:(UIApplication *)application
{
	if ([_sensor isConnected] == NO) {
		[application endBackgroundTask:_disconnectTask];
		_disconnectTask = UIBackgroundTaskInvalid;
		return;
	}
	
	NSLog(@"waiting disconnection");
	[self performSelector:@selector(waitSensorDisconnected:) withObject:application afterDelay:0.5];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[_sensor connect];
}

@end
