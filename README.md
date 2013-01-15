# Conductrics API Wrapper for Objective-C / iOS / iPhone / iPad

This is an Objective-C wrapper for the Conductrics service, which provides an API for bandit-style optimization, dynamic targeting, and A/B testing. 

We'll proceed here assuming that you are at familiar with the basic idea of the service. If not, please see http://conductrics.com for information about the service itself. Thanks!

## TL;DR version

Here's the basic gist in code:

```objective-c
// Get an instance of this wrapper with Conductrics account info
ConductricsAPI *conductrics = [[ConductricsAPI alloc] initWithOwner: @"my-owner-code" apiKey: @"my-api-key"];

// Get a 'decision' between 'a' or 'b'
[conductrics decisionFromAgent:@"ios-example-agent" withChoices:@"a,b"
    completionHandler: ^(NSString *decision, NSString *err) {
        // Value of decision is 'a' or 'b' - adapt your app however you want in response
 }];
 
// Later, if the user does what you want, reward the selection ('a' or 'b', etc)
[conductrics goalToAgent:@"ios-example-agent"
    completionHandler:^(NSString *err) {
        // Consider reward sent 
    }];
```
 
This will cause your app to try the 'a' versus 'b' behavior on different users. Eventually, more and more users will be exposed to the option that brings in the most rewards.

## Before you start

Sign up for a developer account at http://conductrics.com if you don't have one already.
    
## Getting set up in XCode

*(These instructions were correct as of XCode 4.5.2.)*

1. Grab the code from Github, and locate the **ConductricsAPI.h** and **ConductricsAPI.m** files in your Finder.
2. Open the XCode project that you'd like to use the wrapper in, and make sure the project is visible in the Project Navigator (Cmd-1).
3. Drag the files from the Finder and drop them on your project in the Project Navigator. You should see a dialog that says "Choose options for adding these files". You can accept the default settings (the "Copy items into destination" option unchecked, and the "Create groups for any added folders" option selected) and click Finish.

Now you can import the wrapper and start using it in your code:

```objective-c
#import "ConductricsAPI.h"
```

If you want, you can select the files you just added and then do File > New > Folder from Selection and put them in a folder called ConductricsAPI or something.

## Basic Usage

### Initialize with your account info

First, create an instance of ConductricsAPI and initialize it with your Conductrics Account ID (aka Owner Code) and API Key. You'll find these in the welcome email you get when signing up, or in the Conductrics admin console.

```objective-c
ConductricsAPI *conductrics = [[ConductricsAPI alloc] initWithOwner: @"my-owner-code" apiKey: @"my-api-key"];
```

These instances are cheap to create, so you can either create a new one each time you want to use the API (in, say, your ViewController logic), or you can create it once and store it in some central place (perhaps as a property of your App Delegate). You could also subclass ConductricsAPI with your account details "baked in".

### Get a decision from a Conductrics agent

Now it's time to get a "decision" from a Conductrics agent.

First, make up an **agent code** to talk to our API with. We're using "ios-example-agent" here, but you can use whatever you want.
- You'll use a different agent code for each little testing or optimization project. 
- You can use numbers, letters, underscores and dashes in the agent code (we like to use "dash case" as shown in these examples). 
- You can use an agent code that you created already in the web-based Conductrics admin console, but it's not necessary. The agent will be created on the fly the first time your code runs.

Now call **decisionFromAgent:withChoices:** to get a decision from Conductrics. 

The key thing you'll provide is a list of choices. Each time you ask for a decision, you'll get back one of the choices from the list. At first, it's just a random selection. But in the background, Conductrics will be keeping track of which choices are most effective for various users, and can begin favoring the "winning" choice more often as it gains more data. There's more info about all that stuff at http://conducrics.com.

For instance, let's say there's something new about your application you want to try out. Let's think of it as an "a/b" test, where "a" is to do things the old way, and "b" is to do things the new way. So, we provide the list choices as the commma-separated string "a,b" like so:

```objective-c
[conductrics decisionFromAgent:@"ios-example-agent" withChoices:@"a,b"
    completionHandler: ^(NSString *decision, NSString *err) {
        
        NSLog(@"Agent chose %@", decision); // "Agent chose b"
        
        if ( [decision isEqualToString:@"b"] ) {
          // now do something!
          // - switch focus to a different view
          // - make something visible
          // - adjust the UX a bit
          // - display a special offer
          // - whatever you want
        }
 }];
```

When the code runs, the Conductrics server is contacted and makes a selection (chooses between "a" or "b"). The selected choice is returned to the completionHandler as its first argument, as a string.

At this point, Conductrics gets out of the way. You can add whatever code you need to to transition the user into whatever the "new" experience is. The Conductrics framework doesn't need to know what "a" or "b" really mean--but there obviously should be *some* difference between what happens, otherwise there's really no point. :)

##### A few notes about those choice codes
Of course, you aren't restricted to just two choices. You could use "a,b,c" if you wanted to try out three different treatments, etc. And you can make up whatever codes you want (perhaps "old,new" or "normal,small,big") instead of the "a" and "b" we're using here.

Also, you can assign human-readable names for each of the choices later in the Conductrics admin console. These "friendly" names will show up in reports and so on, which may be more pleasant for anyone keeping track of the agent's progress. You can change the friendly names at any time without affecting the logic in your app.

##### Behind the scenes
FYI, at the end of the day the wrapper just makes a request like this to the Conductrics servers. If you don't like the way this wrapper is implemented for some reason, you could always make the request yourself (perhaps via AFNetworking or other helper library).
```
GET http://api.conductrics.com/my-owner-code/ios-example-agent/decision/a,b
```

There's more info about the underlying API at http://console.conductrics.com/docs/quick-guide.

##### Error Handling and Timeouts
If a decision can't be retrieved from the server for some reason (device in airplane mode, network timeout, Conductrics account closed, etc), the completion handler will be called with the "default" decision, which is the first choice in the list of choices. So, in the example above, the decision will be "a" whenever such an exception occurs. A string description of the error will also be provided if you want to log or display it for debugging purposes.

By default, the wrapper uses a timeout of 5 seconds (after which the error-handling logic kicks in). If you wish, you can set the timeout to a different value via the **timeoutInterval** property after you initialize your ConductricsAPI instance. The timeout is expressed in seconds, and is simply passed to the [NSURLRequest timeoutInterval] property internally.

##### Decision stickiness

By default, the Conductrics service assumes that decisions should be "sticky", so if your code happens to run more than once, the Conductrics API will continue to return the same choice (unless the current "session" expires or is closed explicitly -- the the notes on session identifiers at the end of this document for details). 

Usually this behavior is preferable to ensure an experience that doesn't keep "changing on" the user. If it is not desired, you can go to the web-based Conductrics admin console and change the "Sticky" option in the agent's settings. 

##### "Pausing" the agent so you can test a particular choice

You might want to "lock" the agent on the Conducrics side so that you can test out the "a" or "b" experience explicitly (or show it to a client, UAT, etc).  You can log into the Conductrics admin console and use the Stop/Pause Agent feature to temporarily "hard-code" the agent to always return "a" or "b" or whatever. 

Just keep in mind that this will affect all users that hit the agent (there's no facility right now to pause selectively for certain IP's or device IDs--would that be useful to you?).

### Multi-Faceted Agents

In some cases, you may want to make more than one "decision" within your app. The Conductrics service provides full support for "Multi-Faceted" agents. 

PLEASE read the "Multi-Faceted Agents" section of the Conductrics Docs online (available in the web-based admin console) for a conceptual overview.

###### Using Multiple Decision Points
You can define more than one decision point for an agent. Conceptually, each point represents a key "place" or "moment" in your app. In practice, the points would most likely correlate to views (eg, if your app has two different views that each have something for Conductrics to try out, that would be two decision points), though that is not a requirement.

To use multiple decision points, use **decisionFromAgent:withChoices:atPoint**, which gives you an opportunity to provide a point code. You may have specified this point code using the web-based Conductrics admin console, or you can just make up a new point code (in which case Conductrics will create the point "on the fly" the first time your code runs).

```objective-c
[conductrics decisionFromAgent:@"ios-example-agent" withChoices:@"a,b" atPoint:@"high-scores"
    completionHandler: ^(NSString *decision, NSString *err) {
      // Handle decision here (see earlier example)
    }];
```

###### Using Multiple Decisions
Sometimes you want to make more than one decision at the same moment. Perhaps you want to try out some different colors of something, and also some different sizes. People often call this a **Multivariate** or MVT type scenario.

To use multiple decisions in the same point, use **decisionsFromAgent:** (note the "decisions" rather than "decision" in the name). Rather than expressing your choices as a simple comma-separated list as we saw earlier, instead use the form "name:choice,choice/name:choice,choice" as shown below. (We realize that the notation looks a bit odd in this context, but we are using it here to retain parity with the underlying HTTP API -- feedback is welcome on this point.) 

The completionHandler will be passed a NSDictionary (rather than a single NSString). The dictionary will contain a sub-object for each decision, keyed by the decision code. Each sub-object will contain a **code**, which is an NSString you can use to adjust your app accordingly.

```objective-c
[conductrics decisionsFromAgent:@"ios-example-agent-multi" withChoices:@"color:red,blue/size:sm,md,lg"
     completionHandler: ^(NSDictionary *decisions, NSString *err) {
        // The selected choices are returned in the dictionary
        NSString *color = [decisions valueForKeyPath:@"color.code"];
        NSString *size = [decisions valueForKeyPath:@"size.code"];
        // Do whatever is appropriate...
    }];
```

If the wrapper can't reach the Conductrics server (see Error Handling and Timeouts above), it will parse withChoices string to construct an appropriate "fallback" object, which will be passed to your completionHandler as if it had been made normally over the wire.

## Sending "rewards" to the agent when goals are reached

We're almost done. But to make the project meaninfgul, we need to let the Conductrics agent know when the application's goals are reached.

When a user goes whatever it is that you want them to, you send a goal event to Conductrics. When to send the goal event is of course completely dependent on what your app is about. Most likely, you already know what constitutes "engagement" or "conversion". It might be when the user:
- makes a purchase 
- listens to a song
- completes a game level
- submits a form
- spends time playing with a new feature

In any case, you'll send the goal event to Conductrics like this:

```objective-c
[conductrics goalToAgent:@"ios-example-agent"
    completionHandler:^(NSString *err) {
        // Consider goal sent (unless err != nil)
    }];
```

As you can see, it's pretty easy to send goals to your agent. All you need to provide is the same agent code that you used when getting the decision earlier. Conductrics now has what it needs to try out the different variations ("a" vs "b" or whatever) and track which one sends back more goals. Over time, it will be able to favor the better-performing option (assuming there is actually some kind of significant difference). 

If an exception occurs, the *err* argument will be populated (nil means no error) with a string message about what went wrong. You might want to log or display the message for debugging purposes. Unless it happens often, it probably isn't worth attempting to retry or otherwise recover from the exception condition. In the aggregate, a lost goal here or there isn't the end of the world.

##### Sending more specific goal rewards

If the conceptual value of your goals is variable (for instance, in e-commerce, if often makes sense to use a purchase amount as the "value" of the goal), you can send a numeric value along with your goal using **rewardValue:** like so: 

```objective-c
[conductrics goalToAgent:@"ios-example-agent" rewardValue:3.99
    completionHandler:^(NSString *err) {
        // Consider goal sent (unless err != nil)
    }];
```

##### Behind the scenes
The goalToAgent function just sends a request to Conductrics, using a URL such as the following. You can check out the Conductrics documentation for more information about the underlying API.

```
POST http://api.conductrics.com/my-owner-code/ios-example-agent/goal?reward=3.99
```

##### Decision and goal sequencing
Conceptually, goals only have meaning if they happen after a decision. With some application flows, it's possible that a user could "encounter" a reward before encountering a decision. But you don't have to keep track of that in your code... Conductrics will just silently ignore the goal when it doesn't have a prior decision to "reward" with the goal you're sending.

## Session Identifiers

Here are some details that you may never care about, but some explanation is due anyway.

As you might expect, the Conductrics API needs an identifier to "track" which decisions successfully lead to goals. Conductrics calls this a session identifier. 

By default, this wrapper automatically uses the built-in identifierForVendor value as the session identifier it sends to Conductrics. This means that decisions should be correctly matched up to goals between app restarts, etc., without you having to do anything special. This default behavior should be suitable for most apps.

If you prefer to provide your own identifier for some reason, simply set the **sessionId** property of your ConductricsAPI after you initialize it. This might be helpful if your app uses its own "session" tracking mechanism for which you already have an identifier handy.

```objective-c
conductrics.sessionId = myMadeUpIdenfifier;
```

You can also explicitly set the sessionId to *nil*, which will cause the wrapper to create a new identifier for itself to use as long as the ConductricsAPI instance is in scope.

```objective-c
conductrics.sessionId = nil; // new UUID created internally
```

Note that the identifier generated for *nil* will not be persisted by the wrapper, which means that a different one will be used the next time the app launches, etc. You can store the identifier on the device if you like (we are trying to stay away from doing any device persistence in the wrapper code itself). 

If you are using your Conductrics agents for something related to displaying ads, you might want to consider setting **sessionId** to the value of advertisingIdentifier. This will cause the identifier used by Conductrics to respect the Reset Advertising Identifier button (in iOS 6.1 and later). Per Apple's guidelines, you should **only** use that identifier if you are indeed using your Conductrics agent(s) for showing ads.

## Explicit session expiration

Sometimes, depending on the nature of your app, it may make sense to explicitly "close out" a user's "session" when certain events occur, for instance if they use an explicit "log out" gesture in your app. In such a situation, you can use **expireSessionForAgent:** like so:

```objective-c
[Conductrics expireSessionForAgent:@"ios-example-agent" 
    completionHandler:^(NSString *err) {
       // Consider session expired (unless err != nil)
    }];
```

If, later, the user does something that causes a decision to be made again, they will be counted as a new "session" on the Conductrics side (even if the **sessionId** being sent by the wrapper hasn't changed), and be eligible to be assigned to a different decision ("a" vs "b" or whatever). 

## Other API operations

The Conductrics API provides additional functionality not yet "wrapped" by this wrapper:
- Access to reporting data
- Management of targeting rules
- Agent configuration changes

You can access these directly via NSURLConnection, or using a convenient library such as AFNetworking or similar. 

Let us know if you feel the scope of this wrapper should be expanded to include the additional functionality. We tried to keep it as simple and lightweight as possible for 80% of expected use cases. Pull requests welcome. :)

# ConductricsAPI Wrapper Reference

Copied and pasted from ConductricsAPI.h:

```objective-c
@property (nonatomic, strong) NSString *apiKey; // provided via initializer
@property (nonatomic, strong) NSString *ownerCode; // provided via initializer
@property (nonatomic, strong) NSString *baseUrl; // defaults to http://api.conductrics.com
@property (nonatomic, strong) NSString *sessionId; // defaults to vendorIdentifier (see README)
@property (nonatomic) NSTimeInterval timeoutInterval; // defaults to 5 (in seconds)

// Main constructor
- (id)initWithOwner:(NSString *)aOwnerCode apiKey:(NSString *)aApiKey;

// API for Decisions
// most typical case - you know the agent code and the choices you expect
- (void)decisionFromAgent:(NSString *)agentCode withChoices:(NSString *)choices
        completionHandler:(void (^)(NSString *decision, NSString *errn))callbackBlock;
// simplest case - provide just the agent code (agent will use prior set of choices)
- (void)decisionFromAgent:(NSString *)agentCode
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock;
// multi-decision-point case
- (void)decisionFromAgent:(NSString *)agentCode withChoices:(NSString *)choices atPoint:(NSString *)pointCode
        completionHandler:(void (^)(NSString *decision, NSString *err))callbackBlock;
// multi-decisions case
- (void)decisionsFromAgent:(NSString *)agentCode withChoices:(NSString *)choices
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock;
// multi-decisions with point
- (void)decisionsFromAgent:(NSString *)agentCode withChoices:(NSString *)choices atPoint:(NSString *)pointCode
         completionHandler:(void (^)(NSDictionary *decisions, NSString *err))callbackBlock;

// API for Rewards
// simplest case - all you know is agent code
- (void)goalToAgent:(NSString *)agentCode
  completionHandler:(void (^)(NSString *err))callbackBlock;
// if you want to provide a specific "reward value" (for example, purchase amount for commerce-related event)
- (void)goalToAgent:(NSString *)agentCode rewardValue:(NSDecimalNumber *)reward
  completionHandler:(void (^)(NSString *err))callbackBlock;
// if you want to provide a goal code
- (void)goalToAgent:(NSString *)agentCode goalCode:(NSString *)goalCode rewardValue:(NSDecimalNumber *)reward
  completionHandler:(void (^)(NSString *err))callbackBlock;

// API for Sessions - expiration
- (void)expireSessionForAgent:(NSString *)agentCode
  completionHandler:(void (^)(NSString *err))callbackBlock;
```

### Not Yet Implemented / TODO / Ideas for future versions

- Ability to optionally pass in targeting segment or targeting features
- Ability to enable passing along the device's lat/long for geo targeting
- Local storage of decision (either ephemeral or persisted) instead of going over the wire each time
- More examples and documentation

Please contact us at dev@conductrics.com if you have any questions.