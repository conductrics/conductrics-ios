//
//  ConductricsAPI.m
//  ConductricsAPI
//
//  Created by Nate Weiss on 1/11/13.
//  Copyright (c) 2013 Conductrics. All rights reserved.
//

#import "ConductricsAPI.h"

#define defaultBaseUrl @"http://api.conductrics.com"
#define defaultTimeoutInterval 5.0

// "Privates"
@interface ConductricsAPI()
-(NSMutableURLRequest *)urlRequestForURL:(NSString *)urlString;
-(void)fireUrlRequest:(NSURLRequest *)request requestHandler:(void (^)(NSDictionary *returned, NSString *err))callbackBlock;
@end

@implementation ConductricsAPI

@synthesize baseUrl;
@synthesize apiKey;
@synthesize ownerCode;
@synthesize sessionId;
@synthesize timeoutInterval;

// This is the initializer folks should be encouraged to use
- (id)initWithOwner:(NSString *)aOwnerCode apiKey:(NSString *)aApiKey {
    self = [super init];
    if (self) {
        // defaults
        self.baseUrl = defaultBaseUrl;
        self.timeoutInterval = defaultTimeoutInterval;
        self.sessionId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        // passed in
        self.apiKey = aApiKey;
        self.ownerCode = aOwnerCode;
    }
    return self;
}

// Special setter for sessionId - if set to an explicit nil, create a UUID
-(void)setSessionId:(NSString *)newId {
    if (newId == nil) {
        newId = (__bridge NSString*)CFUUIDCreateString(nil, CFUUIDCreate(nil));
    }
    sessionId = newId;
}

// API for Decisions
// simplest case - all you know is the agent code
- (void)decisionFromAgent:(NSString *)agentCode completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    [self decisionFromAgent:agentCode withChoices:nil atPoint:nil completionHandler:callbackBlock];
}
// most typical case - you know the agent code and the choices you expect
- (void)decisionFromAgent:(NSString *)agentCode withChoices:(NSString *)choices completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    [self decisionFromAgent:agentCode withChoices:choices atPoint:nil completionHandler:callbackBlock];
}
// "full monty" version, used internally by the shortcut versions
- (void)decisionFromAgent:(NSString *)agentCode withChoices:(NSString *)choices atPoint:(NSString *)pointCode completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    
    // Compose url to talk to conductrics server
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@/%@/decision", baseUrl, ownerCode, agentCode];
    if (choices != nil) [urlString appendFormat:@"/%@", choices];
    
    // Set up url request with conductrics-specific headers
    NSMutableURLRequest *request = [self urlRequestForURL:urlString];
    if (pointCode != nil) [request setValue:pointCode forHTTPHeaderField: @"x-mpath-point"];
    
    [self fireUrlRequest:request
          requestHandler: ^(NSDictionary *returned, NSString *err) {
              // Bail now if there were any errors
              if (err != nil) {
                  NSString *fallbackDecision = [choices componentsSeparatedByString:@","][0];
                  return callbackBlock(fallbackDecision, err);
              }
              
              // Get the stuff we want from the returned object from the server
              NSString *returnedDecisionCode = [returned valueForKey:@"decision"]; // TODO - what if it doesn't have a "decision" property for some reason?
              
              // Yay, success!
              return callbackBlock(returnedDecisionCode, nil); // TODO - should we return session id?
          }];
}

// API for Rewards
// simplest case - all you know is agent code
- (void)goalToAgent:(NSString *)agentCode completionHandler:(void (^)(NSString *err))callbackBlock {
    return [self goalToAgent:agentCode goalCode:nil rewardValue:nil completionHandler:callbackBlock];
}
// if you want to provide a specific "reward value" (for example, purchase amount if the goal is a commerce-related event)
- (void)goalToAgent:(NSString *)agentCode rewardValue:(NSDecimalNumber *)reward completionHandler:(void (^)(NSString *err))callbackBlock {
    return [self goalToAgent:agentCode goalCode:nil rewardValue:reward completionHandler:callbackBlock];
}
// if you want to provide a goal code
- (void)goalToAgent:(NSString *)agentCode goalCode:(NSString *)goalCode rewardValue:(NSDecimalNumber *)reward completionHandler:(void (^)(NSString *err))callbackBlock {
    
    // Compose url to talk to conductrics server
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@/%@/goal", baseUrl, ownerCode, agentCode];
    if (goalCode != nil) [urlString appendFormat:@"/%@", goalCode];
    
    // Set up url request with conductrics-specific headers
    NSMutableURLRequest *request = [self urlRequestForURL:urlString];
    if (reward != nil) [request setValue:[reward stringValue] forHTTPHeaderField: @"x-mpath-reward"];
    
    // Attempt to send url request to the server
    [self fireUrlRequest:request
          requestHandler: ^(NSDictionary *returned, NSString *err) {
              // Bail now if there were any errors
              if (err != nil) {
                  return callbackBlock(err);
              }
              // Yay, success!
              return callbackBlock(nil); // TODO - should we return session id?
          }];
}

// API for Sessions - expiration
- (void)expireSessionForAgent:(NSString *)agentCode completionHandler:(void (^)(NSString *err))callbackBlock {
    
    // Compose url to talk to conductrics server
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@/%@/expire", baseUrl, ownerCode, agentCode];
    
    // Set up url request with conductrics-specific headers
    NSMutableURLRequest *request = [self urlRequestForURL:urlString];
    
    // Attempt to send url request to the server
    [self fireUrlRequest:request
          requestHandler: ^(NSDictionary *returned, NSString *err) {
              // Bail now if there were any errors
              if (err != nil) {
                  return callbackBlock(err);
              }
              // Yay, success!
              return callbackBlock(nil); // TODO - should we return anything?
          }];
}


// PRIVATES / HELPERS
// Helper to return a set-up NSURLRequest
-(NSMutableURLRequest *)urlRequestForURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:self.timeoutInterval];
    [request setValue:apiKey forHTTPHeaderField: @"x-mpath-apikey"];
    [request setValue:sessionId forHTTPHeaderField: @"x-mpath-session"];
    return request;
}

// Helper to fire off an HTTP request, and return parsed JSON
-(void)fireUrlRequest:(NSURLRequest *)request requestHandler:(void (^)(NSDictionary *returned, NSString *err))callbackBlock {
    
    // Fire off the http call
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue]
     // When the http call returns
                           completionHandler:
     ^(NSURLResponse *res, NSData *data, NSError *err) {
         
         // Bail if weren't able to communicate with the server
         if (err != nil) {
             NSString *errorMsg = [NSString stringWithFormat:@"Network error: %@", [err localizedDescription]];
             return callbackBlock(nil, errorMsg);
         }
         
         // Attempt to parse the response from the server as JSON
         NSError *_jsonError = nil;
         NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error: &_jsonError];
         
         // Bail if we didn't get valid JSON
         if (_jsonError != nil) {
             NSString *errorMsg = [NSString stringWithFormat:@"JSON Parsing error: %@", [_jsonError localizedDescription]];
             return callbackBlock(nil, errorMsg);
         }
         
         // Bail if the server returned an error message in its JSON response
         if ([responseObject objectForKey:@"err"]) {
             NSString *errorMsg = [responseObject objectForKey:@"err"];
             return callbackBlock(nil, errorMsg);
         }
         
         // Yay, success!
         return callbackBlock(responseObject, nil); 
     }];
}


@end