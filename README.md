# Selene

Selene is an iOS library which schedules the execution of [background fetch](https://developer.apple.com/library/ios/documentation/iphone/conceptual/iphoneosprogrammingguide/ManagingYourApplicationsFlow/ManagingYourApplicationsFlow.html) operations on iOS.  It works similar to the [Linux Scheduler](http://oreilly.com/catalog/linuxkernel/chapter/ch10.html) (albeit in a simplified version).

# Installation

## CocoaPods

Add to your Podfile:
pod Selene

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
NSArray *tasks = @[[TaskA class]];
// Run the scheduler every 5 minutes
[SLNScheduler sharedInstance].minimumBackgroundFetchInterval = 60 * 5;
// Add the tasks
[[SLNScheduler sharedInstance] scheduleTasks:tasks];
```

In the application delegate:

```objective-c
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  [[SLNScheduler sharedInstance] startWithCompletion:completionHandler];
}
```

## Scheduling policy

The scheduling policy is the set of rules used to determine when and how selene selects a task to run.  Currently, Selene's scheduling policy ranks the tasks according to their **priority**, **average response time**, and **last executed time**.

#### Priority

Static value. This is dictated by the task's `NSObject<SLNTaskProtocol>::priority` function.

#### Average Response Time

Has an initial value set by the developer, but is then dynamically adjusted as a moving average of the last N executions, where N is defaulted to 3.  This is initially dictated by the task's `NSObject<SLNTaskProtocol>::averageResponseTime` function.

#### Last Executed Time

Dynamically determined, internally, by Selene.  The developer need not concern themselves with it.