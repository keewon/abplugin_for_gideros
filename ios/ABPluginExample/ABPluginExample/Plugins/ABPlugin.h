#ifndef ABPlugin_h
#define ABPlugin_h

#import <Foundation/Foundation.h>
#import <Tapjoy/Tapjoy.h>
#import <Tapjoy/TJPlacement.h>

@interface ABPlugin : NSObject

@property (nonatomic, weak) UIViewController *viewController;

@property (nonatomic, strong) TJPlacement *tjOffers;
@property (nonatomic, strong) TJPlacement *tjVideo;

@property (assign) NSInteger manualMediationIndex;
@property (assign) NSInteger tryVideoCount;

+ (ABPlugin *)sharedInstance;

- (void)initTapjoy;

- (void)checkCurrency;
- (void)showOffers;
- (void)showVideo;
- (BOOL)isVideoAvailable;
- (void)setRemoteNotifications:(BOOL)enable;
- (BOOL)isRemoteNotificationsEnabled;

@end

#endif /* ABPlugin_h */
