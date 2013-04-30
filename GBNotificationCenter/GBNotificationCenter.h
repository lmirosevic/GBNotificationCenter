//
//  GBNotificationCenter.h
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

#import <Foundation/Foundation.h>

#import "GBNotificationProtocol.h"
#import "GBSimpleNotification.h"

#import <Growl/Growl.h>

@protocol GBNotification;
@protocol GBNotificationCenterDelegate;

typedef enum {
    GBNotificationCenterShowPolicyDefault,
    GBNotificationCenterShowPolicyAlwaysShow,
    GBNotificationCenterShowPolicyNeverShow,
} GBNotificationCenterShowPolicy;

@interface GBNotificationCenter : NSObject <NSUserNotificationCenterDelegate, GrowlApplicationBridgeDelegate>

@property (unsafe_unretained, nonatomic) id<GBNotificationCenterDelegate>       delegate;
@property (assign, nonatomic) GBNotificationCenterShowPolicy                    showPolicy;
@property (assign, nonatomic, readonly) BOOL                                    isLionNotificationCenterAvailable;
@property (assign, nonatomic) BOOL                                              shouldRemoveDeliveredNotificationsFromNotificationCenter;

//use the default controller:
+(GBNotificationCenter *)defaultCenter;
//...or if you want to set different policies and/or delegates for different notifications, make a new controller with:
-(id)init;

//posting API
-(void)postNotification:(id<GBNotification>)notification;
-(void)postNotification:(id<GBNotification>)notification withHandler:(void(^)(id<GBNotification> notification))handler;

@end

@protocol GBNotificationCenterDelegate <NSObject>

-(void)notificationController:(GBNotificationCenter *)notificationController didActivateWithUnhandledNotification:(id<GBNotification>)notification andNativeNotification:(id)nativeNotification;

@end