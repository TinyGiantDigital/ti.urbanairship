/**
 * Ti.Urbanairship Module
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUrbanairshipModule.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiBlob.h"
#import "TiUIButtonBarProxy.h"

@implementation TiUrbanairshipModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"d00fbe22-e01d-4ca5-b11b-133155320625";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.urbanairship";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
    
    // Default is automatically reset badge
    _autoResetBadge = YES;
	
	NSLog(@"[INFO] %@ loaded",self);
}

// This is called when the application receives the applicationWillResignActive message
-(void)suspend:(id)sender
{	
	UAInbox *inbox = [UAirship inbox];
	if (inbox != nil && inbox.messageList != nil && inbox.messageList.unreadCount >= 0) {
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:inbox.messageList.unreadCount];
	}
}

// This is called when the application receives the applicationDidBecomeActive message
-(void)resumed:(id)sender
{
    // See MOD-165
    if (![self isInitialized]) {
        NSLog(@"[DEBUG] Ignoring notification -- not initialized yet");
        return;
    }
    
	// [MOD-238] Automatically reset badge count on resume
    [self handleAutoBadgeReset];
}

-(void)shutdown:(id)sender
{
	// you *must* call the superclass
	[super shutdown:sender];
}

- (void)checkIfSimulator {
    if ([[[UIDevice currentDevice] model] rangeOfString:@"Simulator"].location != NSNotFound) {
		NSLog(@"[ERROR] [Ti.UrbanAirship] You will not be able to receive push notifications on the Simulator. Please use a device instead.");
    }
}

+ (void)load
{
    // Register to receive a notification for the application launching
    // This mechanism allows the module to perform actions during application startup
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppCreate:)
                                                 name:@"UIApplicationDidFinishLaunchingNotification" object:nil];
    [super load];
}

+(void)onAppCreate:(NSNotification *)notification
{
    ENSURE_CONSISTENCY([NSThread isMainThread]);
    
    // Set log level for debugging config loading (optional)
    // It will be set to the value in the loaded config upon takeOff
    [UAirship setLogLevel:UALogLevelTrace];
    
    // Populate AirshipConfig.plist with your app's info from https://go.urbanairship.com
    // or set runtime properties here.
    UAConfig *config = [UAConfig defaultConfig];
    
    // Call takeOff (which creates the UAirship singleton)
    [UAirship takeOff:config];
}

-(void)initialize
{
    if ([self isInitialized] == YES) {
        return;
    }
    
    [self checkIfSimulator];
    
    [[UAirship inbox] setDelegate:self];
    [[UAirship push] setPushNotificationDelegate:self];
    [[UAirship push] setUserPushNotificationsEnabled:YES];

    [self setInitialized:YES];
}

#pragma mark Public API's

-(void)registerDevice:(id)arg
{
    if (![self isInitialized]) {
        [self initialize];
    }
    
	ENSURE_SINGLE_ARG(arg, NSString);
	ENSURE_UI_THREAD(registerDevice, arg);
	
    // NOTE: We are not using the UA registerForRemoteNotificationTypes method since we rely on the developer
    // calling the Ti.Network.registerForRemoteNotifications method. The following call will generate an
    // error message in the log from UA about missing notification types.    
    //    [[UAPush shared] registerDeviceToken:token];
    // For now we can use the following call to register the device token. I have made a request to Urban Airship
    // to continue support for registering a device token without using their UAPush registration mechanism.
    // We could consider switching over to the UAPush mechanism but that would mean a change to existing user
    // applications. Perhaps we could switch over with a new API and start deprecating the current method.
    
    // The token received in the success callback to 'Ti.Network.registerForPushNotifications' is a hex-encode
    // string. We need to convert it back to it's byte format as an NSData object.
    NSMutableData *token = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = { '\0', '\0', '\0' };
    int i;
    for (i=0; i<[arg length]/2; i++) {
        byte_chars[0] = [arg characterAtIndex:i*2];
        byte_chars[1] = [arg characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [token appendBytes:&whole_byte length:1];
    }
    
    [[UAirship push] appRegisteredForRemoteNotificationsWithDeviceToken:token];
    [self updateUAServer];
}
	
-(void)unregisterDevice:(id)unused
{
    if (![self isInitialized]) {
        [self initialize];
    }

    NSLog(@"[WARN] [Ti.UrbanAirship] The method 'unregisterDevice' is deprecated. Please advice users to disable push notifications in the settings.");

    [[UAirship push] setUserPushNotificationsEnabled:NO];
    [self updateUAServer];
}

-(void)handleNotification:(id)args
{
	ENSURE_UI_THREAD(handleNotification, args);

	id userInfo = [args objectAtIndex:0];
	ENSURE_DICT(userInfo);
	
	NSLog(@"[DEBUG] [Ti.UrbanAirship] Handle push notification.");

    if (![self isInitialized]) {
        [self initialize];
    }

	// [MOD-238] Reset badge after push received
    [self handleAutoBadgeReset];
}

-(BOOL)notificationsEnabled
{
    return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
}

-(BOOL)isFlying
{
    NSLog(@"[WARN] [Ti.UrbanAirship] The method 'isFlying' is deprecated. Please use 'notificationsEnabled' instead.");
    return [self notificationsEnabled];
}

-(void)updateUAServer
{
    if (![self isInitialized]) {
        [self initialize];
    }

    [[UAirship push] updateRegistration];
}

-(void)handleAutoBadgeReset
{
    if ([self autoResetBadge] == YES) {
        [[UAirship push] resetBadge];
        [self updateUAServer];
    }
}

-(void)setAutoBadgeEnabled:(id)value
{
	BOOL autoBadge = [TiUtils boolValue:value def:NO];
	
    [[UAirship push] setAutobadgeEnabled:autoBadge];
    [self updateUAServer];
}

-(BOOL)autoBadgeEnabled
{
    return [[UAirship push] isAutobadgeEnabled];
}

-(void)setBadgeNumber:(id)value
{
	NSInteger badgeNumber = [TiUtils intValue:value def:0];
	
	[[UAirship push] setBadgeNumber:badgeNumber];
    [self updateUAServer];
}

-(void)resetBadge:(id)args
{
	[[UAirship push] resetBadge];
    [self updateUAServer];
}

-(void)setDevelopmentLogLevel:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    
    [[UAConfig defaultConfig] setDevelopmentLogLevel:value];
}

-(NSNumber*)developmentLogLevel
{
    return NUMINT([[UAConfig defaultConfig] developmentLogLevel]);
}

-(void)setProductionLogLevel:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    
    [[UAConfig defaultConfig] setProductionLogLevel:value];
}

-(NSNumber*)productionLogLevel
{
    return NUMINT([[UAConfig defaultConfig] productionLogLevel]);
}

-(void)setTags:(id)value
{
    ENSURE_ARRAY(value);

    [[UAirship push] setTags:value];
}

-(NSArray*)getTags
{
    return [[UAirship push] tags];
}

-(void)setAlias:(id)value
{
    NSString* alias = [TiUtils stringValue:value];
           
    [[UAirship push] setAlias:alias];
}

-(NSString*)alias
{
    return [[UAirship push] alias];
}

-(NSString*)deviceToken
{
    return [[UAirship push] deviceToken];
}

-(NSString*)username
{
    return [[UAirship inboxUser] username];
}

-(BOOL)quietTimeEnabled
{
    return [[UAirship push] isQuietTimeEnabled];
}

#pragma mark Deprecated and removed API's

-(void)displayInbox:(id)args
{
    NSLog(@"[ERROR] [Ti.UrbanAirship] The API 'displayInbox' has been removed in Ti.UrbanAirship 4.0.0. Please create an own view to display incoming messages.");
}

-(void)hideInbox:(id)arg
{
    NSLog(@"[ERROR] [Ti.UrbanAirship] The API 'hideInbox' has been removed in Ti.UrbanAirship 4.0.0. Please create an own view to display incoming messages.");
}


#pragma mark Delegates


-(void)showInbox
{
    
}
-(void)displayNotificationAlert:(NSString *)alertMessage
{
    
}

-(void)displayLocalizedNotificationAlert:(NSDictionary *)alertDict
{
    
}

- (void)launchedFromNotification:(NSDictionary *)notification
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    UA_LDEBUG(@"The application was launched or resumed from a notification");
    
    // Do something when launched via a notification
    
    // Be sure to call the completion handler with a UIBackgroundFetchResult
    completionHandler(UIBackgroundFetchResultNoData);
}

-(void)registrationFailed
{
    NSLog(@"[ERROR] [Ti.UrbanAirship] Registration failed.");
}

-(void)registrationSucceededForChannelID:(NSString *)channelID deviceToken:(NSString *)deviceToken
{
    NSLog(@"[INFO] [Ti.UrbanAirship] Registration for channel ID = %@ and deviceToken = %@ succeeded.", channelID, deviceToken);
}


#pragma mark Constants

MAKE_SYSTEM_PROP(LOG_LEVEL_UNDEFINED, UALogLevelUndefined);
MAKE_SYSTEM_PROP(LOG_LEVEL_NONE, UALogLevelNone);
MAKE_SYSTEM_PROP(LOG_LEVEL_ERROR, UALogLevelError);
MAKE_SYSTEM_PROP(LOG_LEVEL_WARN, UALogLevelWarn);
MAKE_SYSTEM_PROP(LOG_LEVEL_INFO, UALogLevelInfo);
MAKE_SYSTEM_PROP(LOG_LEVEL_DEBUG, UALogLevelDebug);
MAKE_SYSTEM_PROP(LOG_LEVEL_TRACE, UALogLevelTrace);

@end

