#import "ABPlugin.h"
#import "gabplugin.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <Crashlytics/Crashlytics.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

static const NSInteger AD_TAPJOY = 0;
static const NSInteger AD_ADMOB  = 1;
static const NSInteger AD_MAX    = 2;

static NSString * ADMOB_AD_ID = @"ca-app-pub-3940256099942544/1712485313"; // test

@interface ABPlugin (Private) <
    TJPlacementDelegate, TJPlacementVideoDelegate, GADRewardBasedVideoAdDelegate
>
// properties here cause crash
//@property (assign) NSInteger manualMediationIndex;
//@property (assign) NSInteger tryVideoCount;
@end

@implementation ABPlugin

+ (ABPlugin *)sharedInstance {
    static dispatch_once_t onceToken;
    static ABPlugin *instance;
    dispatch_once(&onceToken, ^{
        instance = [[ABPlugin alloc] init];
    });
    return instance;
}

- (void)showOffers {
    dispatch_async(dispatch_get_main_queue(), ^{
        TJPlacement *placement = self.tjOffers;
        if (placement == nil) {
            gabplugin_enqueueEvent0(GABPLUGIN_AD_ERROR);
            return;
        }
        else if ([placement isContentReady]) {
            [placement showContentWithViewController:self.viewController];
            [FIRAnalytics logEventWithName:@"show_tapjoy_offers" parameters:nil];
        }
        else {
            gabplugin_enqueueEvent0(GABPLUGIN_AD_ERROR);
            [placement requestContent];
        }
    });
}

- (void)showVideo {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tryVideoCount = AD_MAX;
        [self tryNextVideo];
    });
}

- (void)tryNextVideo {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.tryVideoCount > 0) {
            self.tryVideoCount--;
        }
        else {
            gabplugin_enqueueEvent0(GABPLUGIN_AD_ERROR);
            return;
        }
        
        int ad = (self.manualMediationIndex) % AD_MAX;
        self.manualMediationIndex++;
        self.manualMediationIndex = (self.manualMediationIndex % AD_MAX);
        
        if (ad == AD_TAPJOY) {
            if ([Tapjoy isConnected]) {
                if (self.tjVideo == nil) {
                    self.tjVideo = [TJPlacement placementWithName:@"video_unit" delegate:self];
                }
                
                if ([self.tjVideo isContentReady]) {
                    [self.tjVideo showContentWithViewController:self.viewController];
                    [FIRAnalytics logEventWithName:@"show_tapjoy_video" parameters:nil];
                }
                else {
                    [self.tjVideo requestContent];
                }
            }
            else {
                [self tryNextVideo];
            }
        }
        else if (ad == AD_ADMOB) {
            GADRequest *request = [GADRequest request];
            request.testDevices = @[ kGADSimulatorID ];
            [[GADRewardBasedVideoAd sharedInstance] loadRequest:request
                                                   withAdUnitID:ADMOB_AD_ID];
        }
    });
}

- (BOOL)isVideoAvailable {
    return YES;
}

- (void)setRemoteNotifications:(BOOL)enable {
    if (enable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication *application = [UIApplication sharedApplication];
            
            // iOS 8 Notifications
            [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            
            [application registerForRemoteNotifications];
        });
    }
}

- (BOOL)isRemoteNotificationsEnabled {
    UIApplication *application = [UIApplication sharedApplication];
    return [application isRegisteredForRemoteNotifications];
}

- (instancetype) init {
    self = [super init];
    
    [GADRewardBasedVideoAd sharedInstance].delegate = self;
    
    return self;
}

- (void)initTapjoy {
    if ([Tapjoy isConnected]) {
        _tjOffers = [TJPlacement placementWithName:@"offerwall_unit" delegate:self];
        //_tjVideo = [TJPlacement placementWithName:@"video_unit" delegate:self];
        //[_tjVideo requestContent];
        [_tjOffers requestContent];
        
        [self checkCurrency];
    }
}

#pragma mark TJPlacementDelegate

- (void)requestDidSucceed:(TJPlacement*)placement {
    if (placement == self.tjVideo) {
        if (![placement isContentAvailable]) {
            [self tryNextVideo];
        }
    }
}


- (void)requestDidFail:(TJPlacement*)placement error:(NSError*)error {
    if (placement == self.tjVideo) {
        [self tryNextVideo];
    }
    else {
        gabplugin_enqueueEvent0(GABPLUGIN_AD_ERROR);
    }
}

/**
 * Called when content for an placement is successfully cached
 * @param placement The TJPlacement that was sent
 */
- (void)contentIsReady:(TJPlacement*)placement {
    if (placement == self.tjOffers) {
        //[placement showContentWithViewController:self.viewController];
    }
    else if (placement == self.tjVideo) {
        [placement showContentWithViewController:self.viewController];
        [FIRAnalytics logEventWithName:@"show_tapjoy_video" parameters:nil];
    }
}

/**
 * Called when placement content did appear
 * @param placement The TJPlacement that was sent
 * @return n/a
 */
- (void)contentDidAppear:(TJPlacement*)placement {
    gabplugin_enqueueEvent0(GABPLUGIN_AD_DISPLAYED);
}

/**
 * Called when placement content did disappear
 * @param placement The TJPlacement that was sent
 * @return n/a
 */
- (void)contentDidDisappear:(TJPlacement*)placement {
    gabplugin_enqueueEvent0(GABPLUGIN_AD_DISMISSED);
    [self checkCurrency];
    
    if (placement == self.tjOffers) {
        [self.tjOffers requestContent];
    }
}

- (void)checkCurrency {
    [Tapjoy getCurrencyBalanceWithCompletion:^(NSDictionary *parameters, NSError *error) {
        NSLog(@"getCurrencyBalanceWithCompletion: %@", parameters);
        int balance = [parameters[@"amount"] intValue];
        
        [Tapjoy spendCurrency:balance completion:^(NSDictionary *parameters, NSError *error){
            gabplugin_enqueueEvent1(GABPLUGIN_AD_REWARDED, balance);
            [FIRAnalytics logEventWithName:kFIREventEarnVirtualCurrency parameters:@{ kFIRParameterValue: @(balance) }];
        }];
        
        
    }];
}

#pragma mark ADMOB
/// Tells the delegate that the reward based video ad has rewarded the user.
- (void)rewardBasedVideoAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd
   didRewardUserWithReward:(GADAdReward *)reward {
    int balance = [reward.amount intValue];
    gabplugin_enqueueEvent1(GABPLUGIN_AD_REWARDED, balance);
    [FIRAnalytics logEventWithName:kFIREventEarnVirtualCurrency parameters:@{ kFIRParameterValue: @(balance) }];
}


/// Tells the delegate that the reward based video ad failed to load.
- (void)rewardBasedVideoAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd
    didFailToLoadWithError:(NSError *)error {
    NSLog(@"AdMob error: %@", error);
    [self tryNextVideo];
}

/// Tells the delegate that a reward based video ad was received.
- (void)rewardBasedVideoAdDidReceiveAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    if ([[GADRewardBasedVideoAd sharedInstance] isReady]) {
        [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:self.viewController];
        [FIRAnalytics logEventWithName:@"show_admob_video" parameters:nil];
    }
    else {
        [self tryNextVideo];
    }
}

/// Tells the delegate that the reward based video ad opened.
- (void)rewardBasedVideoAdDidOpen:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    gabplugin_enqueueEvent0(GABPLUGIN_AD_DISPLAYED);
}

/// Tells the delegate that the reward based video ad started playing.
- (void)rewardBasedVideoAdDidStartPlaying:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    
}

/// Tells the delegate that the reward based video ad closed.
- (void)rewardBasedVideoAdDidClose:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    gabplugin_enqueueEvent0(GABPLUGIN_AD_DISMISSED);
}

/// Tells the delegate that the reward based video ad will leave the application.
- (void)rewardBasedVideoAdWillLeaveApplication:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    
}

@end
