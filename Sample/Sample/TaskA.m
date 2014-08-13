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

#import "TaskA.h"

@interface CustomOperation : NSOperation

@end

@implementation TaskA

+ (NSString *)identifier {
  return NSStringFromClass(self);
}

+ (NSOperation *)operationWithCompletion:(SLNTaskCompletion_t)completion {
  NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    completion(UIBackgroundFetchResultNoData);
  }];
  return operation;
}

+ (CGFloat)averageResponseTime {
  // This operation, is relatively low cost since the contacts fetch is requested with a diff state
  return 5.0;
}

+ (SLNTaskPriority)priority {
  return SLNTaskPriorityLow;
}

@end
