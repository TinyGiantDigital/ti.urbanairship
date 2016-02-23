/**
 * Ti.Urbanairship Module
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiModule.h"

#import "AirshipLib.h"
#import "UAConfig.h"
#import "UAPush.h"

#import "UAInboxPushHandler.h"
#import "UAInbox.h"
#import "UAInboxMessageList.h"
#import "UAPushNotificationHandler.h"

@interface TiUrbanairshipModule : TiModule<UAInboxDelegate,UAPushNotificationDelegate, UARegistrationDelegate>

@property (readwrite, nonatomic) BOOL autoResetBadge;
@property(nonatomic,readwrite,getter=isInitialized) BOOL initialized;

@end
