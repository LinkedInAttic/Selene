//
//  Selene
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import <XCTest/XCTest.h>
#import "Selene.h"
#import <objc/runtime.h>

// Set the flag for a block completion handler
#define StartBlock() __block BOOL waitingForBlock = YES
// Set the flag to stop the loop
#define EndBlock() waitingForBlock = NO
// Wait and loop until flag is set
#define WaitUntilBlockCompletes() WaitWhile(waitingForBlock)
// Macro - Wait for condition to be NO/false in blocks and asynchronous calls
#define WaitWhile(condition) \
do { \
  while(condition) { \
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; \
  } \
} while(0)

// Dummy task class which conforms to SLNTaskProtocol, simple here so
// we can easily get its methods' parameters and return types when dynamically
// creating task classes
@interface DummyTask : NSObject<SLNTaskProtocol>
@end
@implementation DummyTask
+ (NSString *)identifier {
  return @"";
}
+ (NSOperation *)operationWithCompletion:(SLNTaskCompletion_t)completion {
  return nil;
}
+ (CGFloat)averageResponseTime {
  return 0;
}
+ (SLNTaskPriority)priority {
  return 0;
}
+ (NSInteger)numberOfPeriodsForResponseTime {
  return 5;
}
@end


@interface SeleneTests : XCTestCase

@end

@implementation SeleneTests

static const char * GetEncoding(SEL name) {
  return method_getTypeEncoding(class_getClassMethod([DummyTask class], name));
};

- (Class<SLNTaskProtocol>)createTaskClassWithPriority:(SLNTaskPriority)priority
                                  averageResponseTime:(CGFloat)averageResponseTime
                                        executionTime:(CGFloat)executionTime
                       numberOfPeriodsForResponseTime:(CGFloat)numberOfPeriodsForResponseTime
                                          fetchResult:(UIBackgroundFetchResult)fetchResult {
  Class taskClass = [self createTaskClassWithPriority:priority averageResponseTime:averageResponseTime executionTime:executionTime fetchResult:fetchResult];
  
  class_addMethod(object_getClass(taskClass), @selector(numberOfPeriodsForResponseTime), imp_implementationWithBlock(^NSInteger(id self){
    return numberOfPeriodsForResponseTime;
  }), GetEncoding(@selector(numberOfPeriodsForResponseTime)));
  
  return taskClass;
}

- (Class<SLNTaskProtocol>)createTaskClassWithPriority:(SLNTaskPriority)priority
                                  averageResponseTime:(CGFloat)averageResponseTime
                                        executionTime:(CGFloat)executionTime
                                          fetchResult:(UIBackgroundFetchResult)fetchResult {
  static int count = 0;
  
  NSString* taskClassName = [NSString stringWithFormat: @"Task%i", ++count];
  const char *cString = [taskClassName cStringUsingEncoding:NSASCIIStringEncoding];
  
  Class taskClass = objc_allocateClassPair([NSObject class], cString, 0);
  class_conformsToProtocol(taskClass, @protocol(SLNTaskProtocol));
  
  //Add class methods
  class_addMethod(object_getClass(taskClass), @selector(identifier), imp_implementationWithBlock(^NSString*(id self) {
    return NSStringFromClass([self class]);
  }), GetEncoding(@selector(identifier)));
  
  class_addMethod(object_getClass(taskClass), @selector(operationWithCompletion:), imp_implementationWithBlock(^NSOperation*(id self, SLNTaskCompletion_t completion) {
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
      dispatch_semaphore_t sema = dispatch_semaphore_create(0);
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                   (int64_t)(executionTime * NSEC_PER_SEC)),
                     dispatch_queue_create([[NSString stringWithFormat:@"selene.test.scheduler.queue.%@", taskClassName] UTF8String],
                                           DISPATCH_QUEUE_SERIAL), ^{
        completion(fetchResult);
        dispatch_semaphore_signal(sema);
      });
      dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }];
    return operation;
  }), GetEncoding(@selector(operationWithCompletion:)));
  
  class_addMethod(object_getClass(taskClass), @selector(averageResponseTime), imp_implementationWithBlock(^CGFloat(id self){
    return averageResponseTime;
  }), GetEncoding(@selector(averageResponseTime)));
  
  class_addMethod(object_getClass(taskClass), @selector(priority), imp_implementationWithBlock(^SLNTaskPriority(id self){
    return priority;
  }), GetEncoding(@selector(priority)));
  
  return taskClass;
}

- (void)reset {
  StartBlock();
  [SLNScheduler reset];
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    EndBlock();
  });
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults removeObjectForKey:@"kSLNExecutionSchedule"];
  [userDefaults synchronize];
  
  WaitUntilBlockCompletes();
}

- (void)setUp {
  [super setUp];
  [SLNScheduler setMinimumBackgroundFetchInterval:60 * 10];
}

- (void)tearDown {  
  [super tearDown];
  [self reset];
}

- (void)testExample {
  Class taskA = [self createTaskClassWithPriority:SLNTaskPriorityVeryLow averageResponseTime:25.0 executionTime:0 fetchResult:UIBackgroundFetchResultNewData];
  Class taskB = [self createTaskClassWithPriority:SLNTaskPriorityVeryHigh averageResponseTime:5.0 executionTime:0 fetchResult:UIBackgroundFetchResultNewData];
  Class taskC = [self createTaskClassWithPriority:SLNTaskPriorityLow averageResponseTime:5.0 executionTime:0 fetchResult:UIBackgroundFetchResultNewData];
  
  NSArray *tasks = @[taskA, taskB, taskC];
  [SLNScheduler scheduleTasks:tasks];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Scheduled tasks"];

  void (^completion)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result) {
    [expectation fulfill];
    XCTAssertTrue(YES, @"Tasks all successfully executed");
  };
  [SLNScheduler startWithCompletion:completion];
  
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertFalse(NO, @"Tasks did not finish in time");
  }];
}

- (void)testThreadSafeyAndMultipleExecutions {
  Class taskA = [self createTaskClassWithPriority:SLNTaskPriorityVeryLow averageResponseTime:2.0 executionTime:1 fetchResult:UIBackgroundFetchResultNewData];
  Class taskB = [self createTaskClassWithPriority:SLNTaskPriorityVeryHigh averageResponseTime:3.0 executionTime:2 fetchResult:UIBackgroundFetchResultNewData];
  Class taskC = [self createTaskClassWithPriority:SLNTaskPriorityLow averageResponseTime:4.0 executionTime:2 fetchResult:UIBackgroundFetchResultNewData];
  Class taskD = [self createTaskClassWithPriority:SLNTaskPriorityLow averageResponseTime:5.0 executionTime:3 fetchResult:UIBackgroundFetchResultNewData];
  
  NSArray *tasks = @[taskA, taskB, taskC, taskD];
  
  const NSInteger cycles = 5;
  
  NSOperationQueue *queue = [NSOperationQueue new];
  NSMutableArray *operations = [NSMutableArray new];
  for (NSInteger i = 0; i < cycles; i++) {
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
      StartBlock();
      [SLNScheduler scheduleTasks:tasks];
      [SLNScheduler startWithCompletion:^(UIBackgroundFetchResult result) {
        EndBlock();
        NSLog(@"Tasks completed");
      }];
      [SLNScheduler startWithCompletion:^(UIBackgroundFetchResult result) { NSLog(@"Tasks completed"); }];
      WaitUntilBlockCompletes();
    }];
    [operations addObject:op];
  }
  
  

  [SLNScheduler startWithCompletion:^(UIBackgroundFetchResult result) {
    NSLog(@"Inner completed");
  }];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"All tasks have been scheduled"];
  NSBlockOperation *finalOp = [NSBlockOperation blockOperationWithBlock:^{
    [expectation fulfill];
    XCTAssertTrue(YES, @"Tasks should complete execution");
  }];
  [operations addObject:finalOp];
  
  NSInteger i = [operations count] - 1;
  while (i > 0) {
    NSOperation *op = [operations objectAtIndex:i];
    NSOperation *previousOp = [operations objectAtIndex:(i-1)];
    if (previousOp) {
      [op addDependency:previousOp];
    }
    i--;
  }
  
  [queue addOperations:operations waitUntilFinished:NO];
  
  [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
    XCTAssertFalse(NO, @"Tasks did not finish in time");
  }];
}

@end
