//
//  ViewController.m
//  MonHome
//
//  Created by Yosuke Suzuki on 2013/05/03.
//  Copyright (c) 2013年 Basuke. All rights reserved.
//

#import "ViewController.h"
#import "MosquittoMessage.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *status;

@property (weak, nonatomic) IBOutlet UISwitch *gas1;
@property (weak, nonatomic) IBOutlet UISwitch *gas2;
@property (weak, nonatomic) IBOutlet UISwitch *gas3;
@property (weak, nonatomic) IBOutlet UISwitch *gas4;

@property (weak, nonatomic) IBOutlet UITextView *logView;

@end

@implementation ViewController {
	NSString *_log;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self setStatusIcon:self.sensor.monitor];
	
	self.gas1.on = self.sensor.gas1;
	self.gas2.on = self.sensor.gas2;
	self.gas3.on = self.sensor.gas3;
	self.gas4.on = self.sensor.gas4;
	
	self.logView.text = _log;
}

- (void)setStatusIcon:(BOOL)status
{
	self.status.image = [UIImage imageNamed:(status ? @"lite-green" : @"lite-red")];
}

- (void)sensor:(Sensor *)sensor monitorDidChange:(BOOL)state timestamp:(NSDate *)timestamp
{
	[self setStatusIcon:state];
}

- (void)sensor:(Sensor *)sensor gasRange:(NSInteger)range didChange:(BOOL)state timestamp:(NSDate *)timestamp
{
	switch (range) {
		case 1:
			self.gas1.on = state;
			break;
			
		case 2:
			self.gas2.on = state;
			break;
			
		case 3:
			self.gas3.on = state;
			break;
			
		case 4:
			self.gas4.on = state;
			break;
	}
}

- (void)sensor:(Sensor *)sensor log:(NSString *)message level:(LogLevel)level timestamp:(NSDate *)timestamp
{
	NSRange selection;
	
	if (_log) {
		selection.location = [_log length] + 1;
		_log = [[_log stringByAppendingString:@"\n"] stringByAppendingString:message];
	} else {
		selection.location = 0;
		_log = message;
	}
	selection.length = [_log length] - selection.location;
	
	self.logView.text = _log;
	[self.logView scrollRangeToVisible:selection];
}

@end
