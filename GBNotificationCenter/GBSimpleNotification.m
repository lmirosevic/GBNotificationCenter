//
//  GBSimpleNotification.m
//  GBNotificationCenter
//
//  Created by Luka Mirosevic on 01/04/2013.
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

#import "GBSimpleNotification.h"

@implementation GBSimpleNotification

-(NSString *)titleForNotification {
    return self.title;
}

-(NSString *)bodyForNotification {
    return self.body;
}

@end