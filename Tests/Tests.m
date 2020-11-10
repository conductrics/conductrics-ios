//
//  Tests.m
//  Tests
//
//  Created by Jesse Granger on 11/9/20.
//  Copyright © 2020 Conductrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ConductricsAPI.h"

@interface Tests : XCTestCase

@end

#define LOCK_CREATE() dispatch_semaphore_create(0)
#define LOCK_RELEASE(lock) dispatch_semaphore_signal(lock);
#define LOCK_WAIT(lock, sec) dispatch_semaphore_wait(lock, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sec * NSEC_PER_SEC)));

@implementation Tests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDecisionForAgentAllDefault {
    
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    ConductricsAPI *conductrics = [[ConductricsAPI alloc]
                                   initWithOwner: @"owner_jesse"
                                   apiKey: @"api-gwLapWUaXxCGeOLdhrtm"];
    [conductrics setSessionId:nil];
    [conductrics setBaseUrl:@"http://localhost:7001"];
    
    dispatch_semaphore_t lock = LOCK_CREATE();

    [conductrics decisionFromAgent:@"a-example"
        completionHandler: ^(NSString *selected, NSString *err) {
        @try {
            XCTAssertNil(err);
            XCTAssertNotNil(selected);
            XCTAssert([selected isEqual:@"A"] || [selected isEqual:@"B"]);
        } @finally {
            LOCK_RELEASE(lock);
        }
    }];
    LOCK_WAIT(lock, 5);
}

- (void)testDecisionForAgentProvisional {
    
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    ConductricsAPI *conductrics = [[ConductricsAPI alloc]
                                   initWithOwner: @"owner_jesse"
                                   apiKey: @"api-gwLapWUaXxCGeOLdhrtm"];
    [conductrics setSessionId:nil];
    [conductrics setBaseUrl:@"http://localhost:7001"];
    
    dispatch_semaphore_t lock = LOCK_CREATE();

    // first request one with status: "p", then again with status "ok"
    // because this way of using the API doesn't return the whole response
    // (only selected) we can only verify we got the same selection, with no errors
    [conductrics decisionFromAgent:@"a-example"
                            status:@"p"
        completionHandler: ^(NSString *selected, NSString *err) {
            XCTAssertNil(err);
            XCTAssertNotNil(selected);
            XCTAssert([selected isEqual:@"A"] || [selected isEqual:@"B"]);
            [conductrics decisionFromAgent:@"a-example"
                                    status:@"ok"
                         completionHandler: ^(NSString *selected2, NSString *err) {
                         @try {
                             XCTAssertNil(err);
                             XCTAssertNotNil(selected2);
                             XCTAssert([selected isEqualToString:selected2]);
                         } @finally {
                             LOCK_RELEASE(lock);
                         }
            }];
    }];
    LOCK_WAIT(lock, 10);
}

@end
