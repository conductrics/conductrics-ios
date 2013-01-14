//
//  ConductricsHelloWorldViewController.h
//  ConductricsAPI-HelloWorld
//
//  Created by Nate Weiss on 1/14/13.
//  Copyright (c) 2013 Conductrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConductricsHelloWorldViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *decisionLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

- (IBAction)sendRewardGesture:(id)sender;
- (IBAction)expireSessionGesture:(id)sender;

@end
