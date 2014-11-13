![Selene: Background Task Scheduler](https://raw.githubusercontent.com/linkedin/Selene/master/selene-banner.png)

Selene is an iOS library which schedules the execution of tasks on a [background fetch](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW56).

[![Build Status](https://travis-ci.org/linkedin/Selene.svg?branch=master)](http://travis-ci.org/linkedin/Selene)

# Installation

## CocoaPods

Add to your Podfile:
`pod Selene`

## Submodule

You can also add this repo as a submodule and copy everything in the Selene folder into your project.

# Use

**1) Add the `fetch` background mode in your app’s `Info.plist` file.**

**2) Create a task**

A task must conform to `SLNTaskProtocol`.  For example:

```objective-c
@interface SampleTask: NSObject<SLNTaskProtocol>
@end

@implementation SampleTask

+ (NSString *)identifier {
  return NSStringFromClass(self);
}

+ (NSOperation *)operationWithCompletion:(SLNTaskCompletion_t)completion {
  NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    // Do some work ....
    completion(UIBackgroundFetchResultNoData);
  }];
  return operation;
}

+ (CGFloat)averageResponseTime {
  return 5.0;
}

+ (SLNTaskPriority)priority {
  return SLNTaskPriorityLow;
}

@end
```

**3) Add the task class to the scheduler**

```objective-c
NSArray *tasks = @[[SomeTask class]];
// Run the scheduler every 5 minutes
[SLNScheduler setMinimumBackgroundFetchInterval:60 * 5];
// Add the tasks
[SLNScheduler scheduleTasks:tasks];
```

In the application delegate:

```objective-c
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  [SLNScheduler startWithCompletion:completionHandler];
}
```

---

Interested? Here's the [blog post](http://engineering.linkedin.com/ios/introducing-selene-open-source-library-scheduling-tasks-ios)