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

#import <Foundation/Foundation.h>

// Defines the completion handler with a UIBackgroundFetchResult, and decides whether the UI should be be refreshed or not
typedef void (^SLNTaskCompletion_t)(UIBackgroundFetchResult result);

// Defines the priority of a scheduled background task.  Note that these enum is in positive integers
// to facilate the score calculation
typedef NS_ENUM(NSInteger, SLNTaskPriority) {
  SLNTaskPriorityVeryLow = 1,
  SLNTaskPriorityLow,
  SLNTaskPriorityNormal,
  SLNTaskPriorityHigh,
  SLNTaskPriorityVeryHigh
};

@protocol SLNTaskProtocol <NSObject>

@required

+ (NSString *)identifier;

/*!
 @abstract
 Defines an instance of an NSOperation

 @discussion
 The completion block should be executed so that scheduler knows whether there's new data, no data, or an error,
 thus forwarding the result to the UIApplication.  If the block isn't executed, the scheduler will assume
 that there's no new data.  The SLNTaskCompletion_t block exists distinct from the [NSOperation completionBlock],
 since one may choose to have a custom NSOperation (or a subclass thereof) with a custom block which passes in
 the result of the operation.

 A simple implementation could be:

 @code
 + (NSOperation *)operationWithCompletion:(SLNTaskCompletion_t)completion {
  MyCustomNSOperation *op = [MyCustomNSOperation new];
  [op setCustomCompletionBlock:^(id data, NSError *error){
    if (data) {
      completion(UIBackgroundFetchResultNewData);
    } else if (error) {
      completion(UIBackgroundFetchResultFailed);
    }
  }];
  return op
 }
 @endcode

 @param completion Completion block for the operation.

 @return
 The NSOperation which should execute as part of the scheduled background task.
 */
+ (NSOperation *)operationWithCompletion:(SLNTaskCompletion_t)completion;

/*!
 @abstract
 The average response time, in seconds, of the operation, should be in the range of 0..30

 @discussion
 The response time should be relative to how expensive the NSOperation is.
 For example, if the operation makes an HTTP request which is known to take a considerable time,
 then the response time is high. Therefore, response time is a function of time, memory consumption, etc...
 typically approximated as a constant.
 */
+ (CGFloat)averageResponseTime;

/*!
 @abstract
 Defines the priority of the scheduled background operation

 @discussion
 This priority (SLNTaskPriority) is distinct from the priority of the NSOperation
 (NSOperationQueuePriority). The priority, along with the cost, facilitates the calculation of the cost, necessary
 to determine whether the scheduled background operation is inserted in the queue, for execution.

 The NSOperation's priority merely dictates whether the operation, after it is inserted in the queue,
 is executed.  Therefore, due to several factors (battery life, connectivity, etc..) the NSOperation
 might not necessarily execute, even if in the queue.
 */
+ (SLNTaskPriority)priority;

@optional

/*!
 @abstract
 Number of previous data point to include when calculating the moving average for the response time

 @discussion
 These data points are used to calculate the moving average of the response time. Note that the higher the number, the more accurate the average will be.
 See http://en.wikipedia.org/wiki/Moving_average#Simple_moving_average

 Default: 3
 Min: 0
 Max: 30
 */
+ (NSUInteger)numberOfPeriodsForResponseTime;

@end

