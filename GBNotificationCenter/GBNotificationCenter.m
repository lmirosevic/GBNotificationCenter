//
//  GBNotificationCenter.m
//  GBNotificationCenter
//
//  Created by Luka Mirosevic on 21/02/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "GBNotificationCenter.h"

#import "GBNotificationProtocol.h"
#import <GBToolbox/GBToolbox.h>

static NSString * const kGrowlNotificationName = @"Standard Notification";
static NSString * const kHandlerKey = @"kHandlerKey";
static NSString * const kNotificationKey = @"kNotificationKey";

static NSString * const kNSUserNotificationIdentifierKey = @"kNSUserNotificationIdentifierKey";

@interface GBNotificationCenter ()

@property (strong, nonatomic) NSMutableDictionary                   *postedNotifications;
@property (strong, nonatomic) NSUserNotificationCenter              *associatedLionNotificationCenter;
@property (assign, nonatomic, readwrite) BOOL                       isLionNotificationCenterAvailable;

@end


@implementation GBNotificationCenter

#pragma mark - memory

_singleton(GBNotificationCenter, defaultCenter)
_lazy(NSMutableDictionary, postedNotifications, _postedNotifications)

#pragma mark - init

-(id)init {
    if (self = [super init]) {
        //set up native notifications if notification center is available
        if (IsClassAvailable(NSUserNotificationCenter)) {
            self.isLionNotificationCenterAvailable = YES;
            self.associatedLionNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];//can be replaced by another in the future if needed
            self.associatedLionNotificationCenter.delegate = self;
        }
        
        //growl
        [GrowlApplicationBridge setGrowlDelegate:self];
        
        //initialise
        self.shouldRemoveDeliveredNotificationsFromNotificationCenter = YES;
        self.showPolicy = GBNotificationCenterShowPolicyDefault;
    }
    
    return self;
}

#pragma mark - public API

-(void)postNotification:(id<GBNotification>)notification {
    [self _postNotification:notification shouldStick:NO withHandler:nil];
}

-(void)postNotification:(id<GBNotification>)notification withHandler:(void(^)(id<GBNotification> notification))handler {
    [self _postNotification:notification shouldStick:NO withHandler:handler];
}

#pragma mark - private API

//this is private because stickiness doesn't work properly with the current Lion API... might change in the future so will leave it here
-(void)_postNotification:(id<GBNotification>)notification shouldStick:(BOOL)shouldStick withHandler:(void(^)(id<GBNotification> notification))handler {
    if (!notification) {
        @throw [NSException exceptionWithName:@"GBNotificationCenter" reason:@"must pass in non-nil notification" userInfo:nil];
    }
    else {
        //post it
        NSString *postedNotificationIdentifier;
        [self _postNotification:notification shouldStick:shouldStick withPostedNotificationIdentifier:&postedNotificationIdentifier];
        
        //remember notification so we can call appropriate handler
        self.postedNotifications[postedNotificationIdentifier] = @{kHandlerKey: handler ? [handler copy] : [NSNull null], kNotificationKey: notification};
    }
}

//this is private because stickiness doesn't work properly with the current Lion API... might change in the future so will leave it here
-(void)_postNotification:(id<GBNotification>)notification shouldStick:(BOOL)shouldStick withPostedNotificationIdentifier:(id *)postedNotificationIdentifier {
    //dont even send it if the policy is to never show
    if (self.showPolicy != GBNotificationCenterShowPolicyNeverShow) {
        //format it with the message formatter
        NSString *title = [notification titleForNotification];
        NSString *body = [notification bodyForNotification];
        
        //Lion native notifications
        if (self.isLionNotificationCenterAvailable) {
            NSUserNotification *userNotification = [[NSUserNotification alloc] init];
            
            NSString *notificationIdentifier = userNotification.pointerAddress;
            
            userNotification.title = title;
            userNotification.informativeText = body;
            userNotification.soundName = NSUserNotificationDefaultSoundName;
            userNotification.userInfo = @{kNSUserNotificationIdentifierKey: notificationIdentifier};
            
            userNotification.hasActionButton = shouldStick;
            if (shouldStick) {
                userNotification.actionButtonTitle = _s(@"More info", @"upgrade nag notification action button title");
            }
            
            [self.associatedLionNotificationCenter deliverNotification:userNotification];
            
            //set output parameter
            *postedNotificationIdentifier = notificationIdentifier;
        }
        //growl
        else {
            NSString *growlNotificationIdentifier = ((NSObject *)notification).pointerAddress;
            
            [GrowlApplicationBridge notifyWithTitle:title description:body notificationName:kGrowlNotificationName iconData:nil priority:0 isSticky:shouldStick clickContext:growlNotificationIdentifier];
            
            //set output parameter
            *postedNotificationIdentifier = growlNotificationIdentifier;
        }
    }
}

-(void)_handleNotificationClickWithNotificationIdentifier:(id)notificationIdentifier {
    //look for the native notification and the handler
    id<GBNotification> notification;
    BOOL isHandlerDefined = NO;
    
    for (id aNativeNotificationIdentifier in self.postedNotifications) {
        if ([notificationIdentifier isEqualTo:aNativeNotificationIdentifier]) {
            //fetch the moving parts
            notification = self.postedNotifications[aNativeNotificationIdentifier][kNotificationKey];
            id storedHandler = self.postedNotifications[aNativeNotificationIdentifier][kHandlerKey];
            
            //call handler if its not nil or NSNull null
            if (storedHandler && storedHandler != [NSNull null]) {
                void(^handler)(id<GBNotification> notification) = storedHandler;
                handler(notification);
            }
            
            //sentinel
            isHandlerDefined = YES;
            
            //break out
            break;
        }
    }
    
    //if a handler was defined, remove it from the dict to clean up mem
    if (isHandlerDefined) {
        //remove it from the list if it exists
        [self.postedNotifications removeObjectForKey:notificationIdentifier];
    }
    //if not defined, post an unhandled notification to the delegate
    else {
        //call delegate method
        if ([self.delegate respondsToSelector:@selector(notificationController:didActivateWithUnhandledNotification:andNativeNotification:)]) {
            [self.delegate notificationController:self didActivateWithUnhandledNotification:notification andNativeNotification:notificationIdentifier];
        }
    }
}

#pragma mark - lion notification center delegate

-(void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)nativeNotification {
    NSString *notificationIdentifier;
    if ((notificationIdentifier = nativeNotification.userInfo[kNSUserNotificationIdentifierKey])) {
        [self _handleNotificationClickWithNotificationIdentifier:notificationIdentifier];
    }
    
    //remove notification from notification center
    if (self.shouldRemoveDeliveredNotificationsFromNotificationCenter) {
        [center removeDeliveredNotification:nativeNotification];
    }
}

-(BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    switch (self.showPolicy) {
        case GBNotificationCenterShowPolicyDefault:
        case GBNotificationCenterShowPolicyNeverShow:
            return NO;
        
        case GBNotificationCenterShowPolicyAlwaysShow:
            return YES;
    }
}

#pragma mark - growl delegate

-(NSDictionary *)registrationDictionaryForGrowl {
    return @{GROWL_NOTIFICATIONS_ALL: @[kGrowlNotificationName],
             GROWL_NOTIFICATIONS_DEFAULT: @[kGrowlNotificationName]};
}

-(void)growlNotificationWasClicked:(id)clickContext {
    [self _handleNotificationClickWithNotificationIdentifier:clickContext];
}

@end
