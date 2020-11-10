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


NSString *const STATUS_OK = @"ok";
NSString *const STATUS_PROVISIONAL = @"p";

@synthesize baseUrl;
@synthesize apiKey;
@synthesize ownerCode;
@synthesize sessionId;
@synthesize timeoutInterval;

// This is the initializer folks should be encouraged to use
- (id)initWithOwner:(NSString *)aOwnerCode apiKey:(NSString *)aApiKey {
    self = [super init];
    if (self) {
        // passed in
        self.apiKey = aApiKey;
        self.ownerCode = aOwnerCode;
        // defaults
        self.baseUrl = defaultBaseUrl;
        self.timeoutInterval = defaultTimeoutInterval;
        // default sessionId to stable identifier in iOS 6 and later
        if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            self.sessionId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        } else {
            self.sessionId = nil;
        }
    }
    return self;
}
// Special setter for sessionId - if set to an explicit nil, create a UUID
- (void)setSessionId:(NSString *)newId {
    if (newId == nil) {
        sessionId = [[[NSUUID alloc] init] UUIDString];
    } else {
        sessionId = newId;
    }
}

- (void)decisionFromAgent:(NSString *)agentCode
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    [self decisionFromAgent:agentCode
                withChoices:nil
                    atPoint:nil
                     status:STATUS_OK
          completionHandler:callbackBlock];
}
- (void)decisionFromAgent:(NSString *)agentCode
                   status:(NSString *)status
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    [self decisionFromAgent:agentCode
                withChoices:nil
                    atPoint:nil
                     status:status
          completionHandler:callbackBlock];
}

// typical case - you know the agent code and the choices you expect
- (void)decisionFromAgent:(NSString *)agentCode
              withChoices:(NSString *)choices
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    [self decisionFromAgent:agentCode
                withChoices:choices
                    atPoint:nil
                     status:STATUS_OK
          completionHandler:callbackBlock];
}
// typical case - with provisional
- (void)decisionFromAgent:(NSString *)agentCode
              withChoices:(NSString *)choices
                   status:(NSString *)status
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    [self decisionFromAgent:agentCode
                withChoices:choices
                    atPoint:nil
                     status:status
          completionHandler:callbackBlock];
}
// - verbose case - choices, and point
- (void)decisionFromAgent:(NSString *)agentCode
              withChoices:(NSString *)choices
                  atPoint:(NSString *)pointCode
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    [self decisionFromAgent:agentCode
                withChoices:choices
                    atPoint:pointCode
                     status:STATUS_OK
          completionHandler:callbackBlock];
}
// - "full monty" version, used internally by the shortcut versions
- (void)decisionFromAgent:(NSString *)agentCode
              withChoices:(NSString *)choices
                  atPoint:(NSString *)pointCode
                   status:(NSString *)status
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock {
    
    // Compose url to talk to conductrics server
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@/%@/decision", baseUrl, ownerCode, agentCode];
    if (choices != nil) [urlString appendFormat:@"/%@", choices];

    // Set up url request with conductrics-specific headers
    NSMutableURLRequest *request = [self urlRequestForURL:urlString];
    if (pointCode != nil)
        [request setValue:pointCode forHTTPHeaderField: @"x-mpath-point"];
    
    // Set the "status" option, to support provisional selections
    if (status != nil)
        [request setValue:status forHTTPHeaderField:@"x-mpath-status"];
    
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

- (void)decisionsFromAgent:(NSString *)agentCode
               withChoices:(NSString *)choices
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock {
    return [self decisionsFromAgent:agentCode
                        withChoices:choices
                            atPoint:nil
                             status:STATUS_OK
                  completionHandler:callbackBlock];
}
- (void)decisionsFromAgent:(NSString *)agentCode
               withChoices:(NSString *)choices
                    status:(NSString *)status
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock {
    return [self decisionsFromAgent:agentCode
                        withChoices:choices
                            atPoint:nil
                             status:status
                  completionHandler:callbackBlock];
}
- (void)decisionsFromAgent:(NSString *)agentCode
               withChoices:(NSString *)choices
                   atPoint:(NSString *)point
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock {
    return [self decisionsFromAgent:agentCode
                        withChoices:choices
                            atPoint:point
                             status:STATUS_OK
                  completionHandler:callbackBlock];
}
- (void)decisionsFromAgent:(NSString *)agentCode
               withChoices:(NSString *)choices
                   atPoint:(NSString *)pointCode
                    status:(NSString *)status
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock {

    // Compose url to talk to conductrics server
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@/%@/decisions", baseUrl, ownerCode, agentCode];
    if (choices != nil)
        [urlString appendFormat:@"/%@", choices];
    
    // Set up url request with conductrics-specific headers
    NSMutableURLRequest *request = [self urlRequestForURL:urlString];
    if (pointCode != nil)
        [request setValue:pointCode forHTTPHeaderField: @"x-mpath-point"];

    // Set the "status" option, to support provisional selections
    if (status != nil)
        [request setValue:status forHTTPHeaderField:@"x-mpath-status"];
    
    [self fireUrlRequest:request
          requestHandler: ^(NSDictionary *returned, NSString *err) {
              // Bail now if there were any errors
              if (err != nil) {
                  NSMutableDictionary *fallbackDecisions = [[NSMutableDictionary alloc] init];
                  NSArray *parts = [choices componentsSeparatedByString:@"/"];
                  for (id object in parts) {
                      NSArray *decisionParts = [object componentsSeparatedByString:@":"];
                      if ([decisionParts count] >= 2) {
                           NSString *fallbackDecision = [decisionParts[1] componentsSeparatedByString:@","][0];
                          [fallbackDecisions setValue:[NSDictionary dictionaryWithObject:fallbackDecision forKey:@"code"] forKey:decisionParts[0]];
                      } else {
                          NSString *fallbackDecision = [decisionParts[0] componentsSeparatedByString:@","][0];
                          NSString *decisionCode = [NSString stringWithFormat:@"decision-%lu", [[fallbackDecisions allKeys] count] + 1];
                          [fallbackDecisions setValue:[NSDictionary dictionaryWithObject:fallbackDecision forKey:@"code"] forKey:decisionCode];
                      }
                  }
                  return callbackBlock(fallbackDecisions, err);
              }
              
              // Get the stuff we want from the returned object from the server
              NSDictionary *returnedDecisions = [[NSDictionary alloc]initWithDictionary:[returned valueForKey:@"decisions"] copyItems:YES];
              
              // Yay, success!
              return callbackBlock(returnedDecisions, nil);
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

    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
     completionHandler:^(NSData *data, NSURLResponse *response, NSError *err) {
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
    [task resume];

}


@end
