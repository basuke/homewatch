//
//  ViewController.h
//  MonHome
//
//  Created by Yosuke Suzuki on 2013/05/03.
//  Copyright (c) 2013年 Basuke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sensor.h"

@class MosquittoMessage;

@interface ViewController : UIViewController<SensorDelegate>

@property(nonatomic) Sensor *sensor;

@end
