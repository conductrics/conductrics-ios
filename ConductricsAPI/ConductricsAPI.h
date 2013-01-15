//
//  ConductricsAPI.h
//  ConductricsAPI
//
//  Created by Nate Weiss on 1/11/13.
//  Copyright (c) 2013 Conductrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ConductricsAPI : NSObject

@property (nonatomic, strong) NSString *apiKey; // provided via initializer
@property (nonatomic, strong) NSString *ownerCode; // provided via initializer
@property (nonatomic, strong) NSString *baseUrl; // defaults to http://api.conductrics.com
@property (nonatomic, strong) NSString *sessionId; // defaults to vendorIdentifier (see README)
@property (nonatomic) NSTimeInterval timeoutInterval; // defaults to 5 (in seconds)

// Main constructor
- (id)initWithOwner:(NSString *)aOwnerCode apiKey:(NSString *)aApiKey;

// API for Decisions
// most typical case - you know the agent code and the choices you expect
- (void)decisionFromAgent:(NSString *)agentCode withChoices:(NSString *)choices
        completionHandler:(void (^)(NSString *decision, NSString *errn))callbackBlock;
// simplest case - provide just the agent code (agent will use prior set of choices)
- (void)decisionFromAgent:(NSString *)agentCode
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock;
// multi-decision-point case
- (void)decisionFromAgent:(NSString *)agentCode withChoices:(NSString *)choices atPoint:(NSString *)pointCode
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock;
// multi-decisions case
- (void)decisionsFromAgent:(NSString *)agentCode withChoices:(NSString *)choices
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock;
// multi-decisions with point
- (void)decisionsFromAgent:(NSString *)agentCode withChoices:(NSString *)choices atPoint:(NSString *)pointCode
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock;

// API for Rewards
// simplest case - all you know is agent code
- (void)goalToAgent:(NSString *)agentCode
  completionHandler:(void (^)(NSString *err))callbackBlock;
// if you want to provide a specific "reward value" (for example, purchase amount for commerce-related event)
- (void)goalToAgent:(NSString *)agentCode rewardValue:(NSDecimalNumber *)reward
  completionHandler:(void (^)(NSString *err))callbackBlock;
// if you want to provide a goal code
- (void)goalToAgent:(NSString *)agentCode goalCode:(NSString *)goalCode rewardValue:(NSDecimalNumber *)reward
  completionHandler:(void (^)(NSString *err))callbackBlock;

// API for Sessions - expiration
- (void)expireSessionForAgent:(NSString *)agentCode
  completionHandler:(void (^)(NSString *err))callbackBlock;

@end