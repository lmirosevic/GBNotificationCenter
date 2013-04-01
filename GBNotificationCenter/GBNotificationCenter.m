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
        //set up native notifications is if notification center is available
        if (IsClassAvailable(NSUserNotificationCenter)) {
            self.isLionNotificationCenterAvailable = YES;
            self.associatedLionNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];//can be replaced by another in the future if needed
            self.associatedLionNotificationCenter.delegate = self;
        }
        
        //initialise
        self.shouldRemoveDeliveredNotificationsFromNotificationCenter = YES;
        self.showPolicy = GBNotificationCenterShowPolicyDefault;
    }
    
    return self;
}

#pragma mark - public API

-(void)postNotification:(id<GBNotification>)notification withNativePostedNotification:(id *)postedNotification {
    //dont even send it if the policy is never show.
    if (self.showPolicy != GBNotificationCenterShowPolicyNeverShow) {
        //format it with the message formatter
        NSString *title = [notification titleForNotification];
        NSString *content = [notification bodyForNotification];
        
        //publish it via Lion native notifications
        if (self.isLionNotificationCenterAvailable) {
            NSUserNotification *userNotification = [[NSUserNotification alloc] init];
            userNotification.title = title;
            userNotification.informativeText = content;
            userNotification.soundName = NSUserNotificationDefaultSoundName;
            [self.associatedLionNotificationCenter deliverNotification:userNotification];
            
            //set output parameter
            *postedNotification = userNotification;
        }
        //maybe add growl here in other cases
    }
}

-(void)postNotification:(id<GBNotification>)notification withHandler:(void(^)(id<GBNotification> notification))handler {
    if (!notification) {
        @throw [NSException exceptionWithName:@"GBNotificationCenter" reason:@"must pass in non-nil notification" userInfo:nil];
    }
    else {
        //post it
        id nativePostedNotification;
        [self postNotification:notification withNativePostedNotification:&nativePostedNotification];
        
        //if its a lion notificaion
        if ([nativePostedNotification isKindOfClass:[NSUserNotification class]]) {
            //remember notification so we can call appropriate handler
            self.postedNotifications[nativePostedNotification] = @{@"handler": handler ? [handler copy] : [NSNull null], @"notification": notification};
        }
    }
}

-(void)postNotification:(id<GBNotification>)notification {
    [self postNotification:notification withHandler:nil];
}

#pragma mark - lion notification center delegate

-(void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)nativeNotification {
    //look for the native notification and the handler
    id<GBNotification> notification;
    BOOL isHandlerDefined = NO;
    
    for (id aNativeNotification in self.postedNotifications) {
        if ([nativeNotification isEqualTo:aNativeNotification]) {
            //fetch the moving parts
            notification = self.postedNotifications[aNativeNotification][@"notification"];
            id storedHandler = self.postedNotifications[aNativeNotification][@"handler"];
            
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
    
    //if a handler was defined, remove it from the dict to clean up mem, otherwise post an unhandled notification to the delegate
    if (isHandlerDefined) {
        //remove it from the list if it exists
        [self.postedNotifications removeObjectForKey:nativeNotification];
    }
    else {
        //call delegate method
        if ([self.delegate respondsToSelector:@selector(notificationController:didActivateWithUnhandledNotification:andNativeNotification:)]) {
            [self.delegate notificationController:self didActivateWithUnhandledNotification:notification andNativeNotification:nativeNotification];
        }
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

@end
