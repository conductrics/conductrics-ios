//
//  ConductricsHelloWorldAppDelegate.h
//  ConductricsAPI-HelloWorld
//
//  Created by Nate Weiss on 1/14/13.
//  Copyright (c) 2013 Conductrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConductricsAPI.h"

@interface ConductricsHelloWorldAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ConductricsAPI *conductrics;

@end
