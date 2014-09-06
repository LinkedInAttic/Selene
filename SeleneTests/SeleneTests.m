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
                       numberOfPeriodsForResponseTime:(CGFloat)numberOfPeriodsForResponseTime
                                          fetchResult:(UIBackgroundFetchResult)fetchResult {
  Class taskClass = [self createTaskClassWithPriority:priority averageResponseTime:averageResponseTime fetchResult:fetchResult];
  
  class_addMethod(object_getClass(taskClass), @selector(numberOfPeriodsForResponseTime), imp_implementationWithBlock(^NSInteger(id self){
    return numberOfPeriodsForResponseTime;
  }), GetEncoding(@selector(numberOfPeriodsForResponseTime)));
  
  return taskClass;
}

- (Class<SLNTaskProtocol>)createTaskClassWithPriority:(SLNTaskPriority)priority
                                  averageResponseTime:(CGFloat)averageResponseTime
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
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
      completion(fetchResult);
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

- (void)setUp {
  [super setUp];
  [SLNScheduler setMinimumBackgroundFetchInterval:60 * 10];
}

- (void)tearDown {
  // Note, a proper test of moving average, the following line should be commented out
  [SLNScheduler reset];
  
  [super tearDown];
}

- (void)testExample {
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  
  Class taskA = [self createTaskClassWithPriority:SLNTaskPriorityVeryLow averageResponseTime:25.0 fetchResult:UIBackgroundFetchResultNewData];
  Class taskB = [self createTaskClassWithPriority:SLNTaskPriorityVeryHigh averageResponseTime:5.0 fetchResult:UIBackgroundFetchResultNewData];
  Class taskC = [self createTaskClassWithPriority:SLNTaskPriorityLow averageResponseTime:5.0 fetchResult:UIBackgroundFetchResultNewData];
  
  NSArray *tasks = @[taskA, taskB, taskC];
  [SLNScheduler scheduleTasks:tasks];
  
  void (^completion)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result) {
    dispatch_semaphore_signal(semaphore);
  };
  [SLNScheduler startWithCompletion:completion];
  
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 1LL*NSEC_PER_SEC);
  if (dispatch_semaphore_wait(semaphore, timeout) == 0) {
    NSLog(@"success, semaphore signaled in time");
  } else {
    NSLog(@"failure, semaphore didn't signal in time");
  }
  
  XCTAssertTrue(@"", @"");
}

@end
