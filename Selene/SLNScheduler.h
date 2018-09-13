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

@protocol SLNTaskProtocol;

/*!
 @abstract
 LCNBackgroundOperationManager holds the entire scheduling logic for all background tasks.
 
 @discussion
 The app delegate should setup the scheduler by doing the following:
 
 @code
 // Set the fetch interval
 [SLNScheduler setMinimumBackgroundFetchInterval:...];
 
 // Add the task classes
 [SLNScheduler scheduleTasks:@[...]];
 
 // Then, to start the execution, in the app delegate's application:performFetchWithCompletionHandler:
 [SLNScheduler startWithCompletion:completionHandler];
 
 // When scheduling needs to stop, perhaps due to authentication issues, do the following:
 [SLNScheduler stop]
 @endcode
 */
@interface SLNScheduler : NSObject

/*!
 @abstract
 Sets the user defaults
 
 @discussion
 This is used for storing all scheduling data. The scheduling mechanism uses the stored values for calculating
 and determining the rank and score. If no userDefaults is provided, the standardUserDefaults is used.
 
 @param userDefaults User defaults object to store scheduling data.
 */
+ (void)setUserDefaults:(NSUserDefaults *)userDefaults;

/*!
 @abstract
 Sets the maximum number of concurrent operations the the interval queue can execute.
 
 @discussion
 If you specify the value NSOperationQueueDefaultMaxConcurrentOperationCount (which is recommended),
 the maximum number of operations can change dynamically based on system conditions.
 
 @param maxConcurrentOperationCount Maximum number of concurrent operations
 The maximum number of concurrent operations. Specify the value NSOperationQueueDefaultMaxConcurrentOperationCount
 if you want the receiver to choose an appropriate value based on the number of available processors and other relevant factors.
 */
+ (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount;

/*!
 @abstract
 Sets the background fetch interval of [UIApplication sharedApplication]
 
 @discussion
 From Apple: "The minimum number of seconds that must elapse before another background fetch can be initiated.
 This value is advisory only and does not indicate the exact amount of time expected between fetch operations."
 */
+ (void)setMinimumBackgroundFetchInterval:(NSTimeInterval)minimumBackgroundFetchInterval;

/*!
 @abstract
 Sets the desired tasks to be scheduled.
 
 @param tasks
 An array of tasks, where each task is class which must conform to SLNTaskProtocol
 */
+ (void)scheduleTasks:(NSArray *)tasks;

/*!
 @abstract
 Stops the scheduler.  
 
 @discussion
 This utilizes the [UIApplication sharedApplication], which will set the fetch interval to UIApplicationBackgroundFetchIntervalNever
 */
+ (void)stop;


/*!
 @abstract
 Executes the set of tasks.
 
 @discussion
 Should be called from the App Delegate's application:performFetchWithCompletionHandler: method. 
 Must call this method from a single thread.
 
 @param completion
 Block which triggers when all operations are completed.  It is executed on the main queue.
 */
+ (void)startWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

/*!
 @abstract
 Schedules an background task to execute immediately, regardless of its priority and/or cost
 
 @param task Background task to be scheduled immediately.
 A class comforming to LCNScheduledBackgroundTaskProtocol
 */
+ (void)scheduleNow:(id<SLNTaskProtocol>)task;

/*!
 @abstract
 Resets all data stored in the scheduler.  
 
 @discussion
 This will wait for all tasks that are currently executing to complete.
 */
+ (void)reset;

@end

