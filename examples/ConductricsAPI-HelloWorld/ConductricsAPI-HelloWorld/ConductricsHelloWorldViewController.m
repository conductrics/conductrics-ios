//
//  ConductricsHelloWorldViewController.m
//  ConductricsAPI-HelloWorld
//
//  Created by Nate Weiss on 1/14/13.
//  Copyright (c) 2013 Conductrics. All rights reserved.
//

#import "ConductricsHelloWorldViewController.h"
#import "ConductricsHelloWorldAppDelegate.h"

#define Conductrics [(ConductricsHelloWorldAppDelegate*)[[UIApplication sharedApplication]delegate]conductrics]

@interface ConductricsHelloWorldViewController ()

@end

@implementation ConductricsHelloWorldViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [Conductrics decisionFromAgent:@"ios-example-agent" withChoices:@"a,b"
         completionHandler: ^(NSString *decision, NSString *err) {
             self.decisionLabel.text = decision;
             self.errorLabel.text = err;
         }];
 
    /*
     [Conductrics decisionsFromAgent:@"ios-example-agent-multi" withChoices:@"a,b/c,d"
         completionHandler: ^(NSDictionary *decisions, NSString *err) {
             NSLog(@"Decisions are '%@' - error: %@ (null is good)", decisions, err);
             self.decisionLabel.text = [decisions valueForKeyPath:@"decision-2.code"];
             self.errorLabel.text = err;
         }];
     */
}

- (IBAction)sendRewardGesture:(id)sender {
    [Conductrics goalToAgent:@"ios-example-agent" completionHandler:^(NSString *err) {
        NSLog(@"Goal sent - error: %@ (null is good)", err);
    }];
    
}

- (IBAction)expireSessionGesture:(id)sender {
    [Conductrics expireSessionForAgent:@"ios-example-agent" completionHandler:^(NSString *err) {
        NSLog(@"Expire sent - error: %@ (null is good)", err);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
