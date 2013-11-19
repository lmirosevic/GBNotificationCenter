GBNotificationCenter
============

A clean & elegant block based API for user notifications that uses Lion's native NSUserNotificationCenter on OS X 10.8+ and falls back to Growl for older versions.

Simple usage
------------

First create a notification:

```objective-c
GBSimpleNotification *myNotification = [GBSimpleNotification new];
myNotification.title = @"New Notification";
myNotification.body = @"This is the hello world of Goonbee's notification center";
```

Then post it:

```objective-c
[[GBNotificationCenter defaultCenter] postNotification:myNotification];
```

You can also specify a handler for when the notification is clicked, for example:

```objective-c
GBSimpleNotification *upgradeNotification = [GBSimpleNotification new];
upgradeNotification.title = @"Pro Version";
upgradeNotification.body = @"Upgrade and unlock lots of awesome extra features. Click for more info!";
[[GBNotificationCenter defaultCenter] postNotification:upgradeNotification withHandler:^(id<GBNotification> notification) {
	//opens the Mac App Store onto our Pro version
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", @"1234567"]]];
}];
```

Don't forget to import header:

```objective-c
#import <GBNotificationCenter/GBNotificationCenter.h>
```

Advanced Usage
------------

You can choose whether a notification should be removed from the Lion sidebar once it has been clicked on, e.g.:
```objective-c
// This will prevent removing of notifications from the Lion notification center sidebar even after they've been clicked on. Defaults to YES.
[GBNotificationCenter defaultCenter].shouldRemoveDeliveredNotificationsFromNotificationCenter = NO;
```

You can set a show policy for notifications, e.g. to always show notifications, even when the app is active:
```objective-c
// Will show notification even if app is active. Defaults to GBNotificationCenterShowPolicyDefault, which only shows the notification if the app is not active.
[GBNotificationCenter defaultCenter].showPolicy = GBNotificationCenterShowPolicyAlwaysShow;
```

If you don't set a handler for your notifications, you can register a delegate and implement a handler for all unhandled notifications. Unhandled notifications are created when you post without a handler block, or if someone clicks on a notification when your app is not running. For example:

```objective-c
-(void)notificationController:(GBNotificationCenter *)notificationController didActivateWithUnhandledNotification:(id<GBNotification>)notification andNativeNotification:(id)nativeNotification {
    // Do something when our notification is clicked, in this case, show the app's window and make the app active
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:NO];
}
```

A notification can be any object which conforms to the `GBNotification` protocol. To create your own implementation you simply implement the methods `titleForNotification` and `bodyForNotification`. This enables you to use any object with whatever appropriate storage and internal logic that you may already have for display as a notification. `GBSimpleNotification` is a basic implementation:

```objective-c
#import "GBNotificationProtocol.h"

@interface GBSimpleNotification : NSObject <GBNotification>

@property (copy, nonatomic) NSString    *title;
@property (copy, nonatomic) NSString    *body;

@end

@implementation GBSimpleNotification

-(NSString *)titleForNotification {
    return self.title;
}

-(NSString *)bodyForNotification {
    return self.body;
}

@end
```

The reason behind this design choice is that it decouples the library's underlying display and handling logic from the formatting logic, thus allowing GBNotificationCenter to present an extremely generic interface, while granting your application full control over how notifications are displayed. It lets you "bolt on" notifications onto your existing objects, and provides a clean way for you to handle localisations, formatting, locales, etc.

You can create multiple GBNotificationCenter instances using `[[GBNotificationCenter alloc] init]`, each with it's own delegate, showPolicy and shouldRemoveDeliveredNotificationsFromNotificationCenter.

Dependencies
------------

* [GBToolbox](https://github.com/lmirosevic/GBToolbox)

Add to your project's workspace, add dependency for GBToolbox-OSX, link with your binary, add "copy file" step to copy framework into bundle.

* Growl.framework

It's included with GBNotificationCenter, but you must copy the framework to your app's bundle by dragging the framework out of the GBNotificationCenter subproject into your super project (making sure to **deselect** the "Copy items into destination group's folder" checkbox), and adding it to the "copy file" step.

Copyright & License
------------

Copyright 2013 Luka Mirosevic

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/lmirosevic/gbnotificationcenter/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
