//
//  SeleneTests.m
//  SeleneTests
//
//  Created by Kirollos Risk on 7/16/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SLNScheduler.h"
#import "SLNTaskProtocol.h"
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
+ (SLNTaskPriority)priority{
  return 0;
}
@end

static const char * GetEncoding(SEL name) {
  return method_getTypeEncoding(class_getClassMethod([DummyTask class], name));
};

// Builder
Class<SLNTaskProtocol> CreateTaskClass(SLNTaskPriority priority, CGFloat averageResponseTime, UIBackgroundFetchResult fetchResult) {
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
};

@interface SeleneTests : XCTestCase

@end

@implementation SeleneTests

- (void)setUp {
  [super setUp];
  [SLNScheduler setMinimumBackgroundFetchInterval:60 * 10];
}

- (void)tearDown {
  [SLNScheduler reset];
  [super tearDown];
}

- (void)testExample {
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  Class taskA = CreateTaskClass(SLNTaskPriorityVeryHigh, 1.0, UIBackgroundFetchResultNewData);
  Class taskB = CreateTaskClass(SLNTaskPriorityVeryHigh, 5.0, UIBackgroundFetchResultNewData);
  NSArray *tasks = @[taskA, taskB];
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
