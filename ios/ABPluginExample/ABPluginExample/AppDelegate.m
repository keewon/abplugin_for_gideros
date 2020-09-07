//
//  AppDelegate.m
//
//  Copyright 2012 Gideros Mobile. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

#include "giderosapi.h"

//GIDEROS-TAG-IOS:APP-DELEGATE-DECL//

// ABPluginExample -->
#import <Tapjoy/Tapjoy.h>
@import FirebaseCore;
@import FirebaseAnalytics;
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "ABPlugin.h"
// <-- ABPluginExample

#ifndef NSFoundationVersionNumber_iOS_7_1
# define NSFoundationVersionNumber_iOS_7_1 1047.25
#endif

@implementation AppDelegate

@synthesize window;
@synthesize viewController;

- (BOOL)isNotRotatedBySystem{
    BOOL OSIsBelowIOS8 = [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0;
    BOOL SDKIsBelowIOS8 = floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1;
    return OSIsBelowIOS8 || SDKIsBelowIOS8;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
    self.window = [[[UIWindow alloc] initWithFrame:bounds] autorelease];
	
    self.viewController = [[[ViewController alloc] init] autorelease];	
    self.viewController.wantsFullScreenLayout = YES;

	[self.viewController view];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

    int width = bounds.size.width;
    int height = bounds.size.height;
    
    if(![self isNotRotatedBySystem] && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
        height = bounds.size.width;
        width = bounds.size.height;
    }
    
    NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"assets"] stringByAppendingPathComponent:@"properties.bin"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    BOOL isPlayer = false;
    BOOL exists = [fileManager fileExistsAtPath:path];
    if (!exists) {
        isPlayer = true;
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* dir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"gideros"];
        
        NSArray *files = [fileManager contentsOfDirectoryAtPath:dir error:nil];
        if (files != nil) {
            for (NSString *file in files) {
                [self.viewController addProject:file];
            }
        }
        [self.viewController initTable];
    }
    
    gdr_initialize(self.viewController.glView, width, height, isPlayer);

    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        [self.window setRootViewController:self.viewController];
    }
    else
    {
        [self.window addSubview:self.viewController.view];
    }

    [self.window makeKeyAndVisible];

    gdr_drawFirstFrame();

    //GIDEROS-TAG-IOS:APP-LAUNCHED//
    
    // ABPluginExample -->
    [[ABPlugin sharedInstance] setViewController:self.viewController];

    // Firebase
    [FIRApp configure];
    
    // Tapjoy
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tjcConnectSuccess:)
                                                 name:TJC_CONNECT_SUCCESS
                                               object:nil];
    
    [Tapjoy setDebugEnabled:YES];
    [Tapjoy connect:@"znJ5NZWFRqGuiG-WN6DI-QEBALbbyE6EYqANHdWsjVOTdGY8e71YjZUu3E9y"]; // Use your SDK Key here
    
    // AdMob
    [GADMobileAds.sharedInstance startWithCompletionHandler:nil];
    // <-- ABPluginExample

    return YES;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_2
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    gdr_handleOpenUrl(url);
    return YES;
}
#else
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    gdr_handleOpenUrl(url);
    return YES;
}
#endif

- (void)applicationWillResignActive:(UIApplication *)application
{
	gdr_suspend();
    [self.viewController stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	gdr_resume();
    [self.viewController startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	gdr_exitGameLoop();
    [self.viewController stopAnimation];
	gdr_deinitialize();
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    gdr_background();
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    gdr_foreground();
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //GIDEROS-TAG-IOS:NOTIFICATION-RX//
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    UIBackgroundFetchResult result=UIBackgroundFetchResultNewData;
    //GIDEROS-TAG-IOS:NOTIFICATION-RX-CH//
    // ABPluginExample -->
    [Tapjoy setReceiveRemoteNotification:userInfo];
    // <-- ABPluginExample
    completionHandler(result);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken {
    //GIDEROS-TAG-IOS:NOTIFICATION-TOKEN//
    // ABPluginExample -->
    [Tapjoy setDeviceToken:deviceToken];
    // <-- ABPluginExample
}

- (void)dealloc
{
    [viewController release];
    [window release];
    
    [super dealloc];
}

// ABPluginExample -->
-(void)tjcConnectSuccess:(NSNotification*)notifyObj {
    [[ABPlugin sharedInstance] initTapjoy];
}
// <-- ABPluginExample

@end
