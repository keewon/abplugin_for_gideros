package com.giderosmobile.android;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.widget.Toast;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.reward.RewardItem;
import com.google.android.gms.ads.reward.RewardedVideoAd;
import com.google.android.gms.ads.reward.RewardedVideoAdListener;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.tapjoy.TJActionRequest;
import com.tapjoy.TJConnectListener;
import com.tapjoy.TJError;
import com.tapjoy.TJGetCurrencyBalanceListener;
import com.tapjoy.TJPlacement;
import com.tapjoy.TJPlacementListener;
import com.tapjoy.TJPrivacyPolicy;
import com.tapjoy.TJSpendCurrencyListener;
import com.tapjoy.Tapjoy;

import java.lang.ref.WeakReference;

import static android.os.Looper.getMainLooper;

public class ABPlugin {

    static int GABPLUGIN_AD_DISPLAYED = 0;
    static int GABPLUGIN_AD_DISMISSED = 1;
    static int GABPLUGIN_AD_ERROR = 2;
    static int GABPLUGIN_AD_REWARDED = 3;
    static int GABPLUGIN_AD_VIDEO_READY = 4;

    static int AD_TAPJOY = 0;
    static int AD_ADMOB = 1;
    static int AD_MAX = 2;

    static TJPlacement tjOffers;
    static TJPlacement tjVideo;
    static FirebaseAnalytics firebaseAnalytics;
    static RewardedVideoAd adMobVideo;
    static int manualMediationIndex = 0;
    static int tryVideoCount = 0;
    static WeakReference<Activity> weakActivity;

    // This method is called when Tapjoy SDK is successfully connected
    public static void initTapjoy() {
        // Please set appropriate privacy flags
        TJPrivacyPolicy.getInstance().setSubjectToGDPR(false);
        TJPrivacyPolicy.getInstance().setUserConsent("1");

        // We're pre-caching Offerwall here to show it quickly.
        // You can also do this lazily if you want.
        // Use your own placement name
        tjOffers = Tapjoy.getPlacement("offerwall_unit", tjListener);
        if (Tapjoy.isConnected()) {
            // We may have remaining virtual currency at Tapjoy side. Let's check it.
            checkCurrency();
            tjOffers.requestContent();
        }
    }

    public static void initFirebase(FirebaseAnalytics arg) {
        ABPlugin.firebaseAnalytics = arg;
    }
    public static void initAdMob(Activity activity) {
        weakActivity = new WeakReference<Activity>(activity);
        adMobVideo = MobileAds.getRewardedVideoAdInstance(activity);
        adMobVideo.setRewardedVideoAdListener(adMobListener);
    }

    // We're sending event to both of Tapjoy and Firebase.
    // You can use only one, or compare them.
    // Example of usage)
    // eventName=complete, arg1=level1, value=(score)
    public static void sendEvent(String eventName, String arg1, int value) {
        Log.d("ABPlugin", "sendEvent " + eventName + " " + arg1 + " " + value);
        Tapjoy.trackEvent(null, eventName, arg1, null, (long)value);
        Bundle bundle = new Bundle();
        bundle.putString(eventName, arg1);
        bundle.putInt(FirebaseAnalytics.Param.VALUE, value);
        firebaseAnalytics.logEvent(eventName, bundle);
    }

    // Tapjoy supports setting five 'Cohorts' + 'Level'
    // while Firebase supports 'User property'
    // With this, you can view metrics by cohorts/level/user properties.

    static String AB_COHORT_LEVEL = "AB_COHORT_LEVEL";
    static String AB_COHORT_PUSH = "AB_COHORT_PUSH";

    private static int keyToCohortNumber(String key) {
        if (AB_COHORT_LEVEL.equals(key)) {
            return 6;
        }
        return -1;
    }

    public static void setUserProperty(String key, String value) {
        Log.d("ABPlugin", "setUserProperty " + key + " " + value);
        int cohort = keyToCohortNumber(key);

        if (cohort >= 0 && cohort < 5) {
            Tapjoy.setUserCohortVariable(cohort, value);
            firebaseAnalytics.setUserProperty(key, value);
        }
        else if (cohort == 6) {
            Tapjoy.setUserLevel(Integer.parseInt(value));
            firebaseAnalytics.setUserProperty(key, value);
        }
    }

    // Implemented simple round-robin video mediation here
    // You may be interested in using mediation service like https://www.tapdaq.com
    public static void showVideo() {
        Log.d("ABPlugin", "showVideo");
        tryVideoCount = AD_MAX;
        tryNextVideo();
    }

    static void tryNextVideo() {
        if (tryVideoCount > 0) {
            tryVideoCount--;
        }
        else {
            enqueueEvent0(GABPLUGIN_AD_ERROR);
            return;
        }

        int ad = manualMediationIndex % AD_MAX;
        manualMediationIndex++;
        manualMediationIndex = manualMediationIndex % AD_MAX;

        if (ad == AD_TAPJOY) {
            if (Tapjoy.isConnected()) {
                if (tjVideo == null) {
                    // Use your own placement name
                    tjVideo = Tapjoy.getPlacement("video_unit", tjListener);
                }

                if (tjVideo.isContentReady()) {
                    tjVideo.showContent();
                    firebaseAnalytics.logEvent("show_tapjoy_video", null);
                } else {
                    tjVideo.requestContent();
                }
            }
            else {
                tryNextVideo();
            }
        }
        else if (ad == AD_ADMOB) {
            Runnable runnable = new Runnable() {
                @Override
                public void run() {
                    // !!! Use your own AD id here
                    adMobVideo.loadAd("ca-app-pub-7650460971703784/5754091386",
                            new AdRequest.Builder().build());
                }
            };

            // Most third party SDK runs well only on the UI thread
            if (weakActivity != null) {
                Activity activity = weakActivity.get();
                if (activity != null) {
                    activity.runOnUiThread(runnable);
                    runnable = null;
                }
            }

            if (runnable != null) {
                Handler handler = new Handler(getMainLooper());
                handler.post(runnable);
            }
        }
    }

    public static void showOffers() {
        Log.d("ABPlugin", "showOffers");

        final Activity activity = weakActivity.get();

        if (activity != null) {
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (tjOffers == null) {
                        Log.i("ABPlugin", "offers == null");
                        Toast.makeText(activity, "AD is not available yet.", Toast.LENGTH_LONG).show();
                        return;
                    }
                    else if (tjOffers.isContentReady()) {
                        // Tapjoy dashboard shows how many times Offerwall is shown
                        // Since Firebase is not aware of it, let it know
                        tjOffers.showContent();
                        firebaseAnalytics.logEvent("show_tapjoy_offers", null);
                    }
                    else {
                        Log.i("ABPlugin", "offers are not ready");
                        Toast.makeText(activity, "Requesting for AD now. Try again.", Toast.LENGTH_LONG).show();
                        tjOffers.requestContent();
                    }
                }
            });
        }

    }

    public static boolean isVideoAvailable() {
        Log.d("ABPlugin", "isVideoAvailable");
        return true;
    }

    public static boolean isRemoteNotificationsEnabled() {
        Log.d("ABPlugin", "isRemoteNotificationsEnabled");
        return !Tapjoy.isPushNotificationDisabled();
    }

    public static void setRemoteNotifications(int val) {
        Log.d("ABPlugin", "setRemoteNotifications");
        Tapjoy.setPushNotificationDisabled(val == 0);
        // We want to group push enabled users and send them push notifications later.
        firebaseAnalytics.setUserProperty(AB_COHORT_PUSH, String.valueOf(val));
    }

    // Callbacks are here - defined in gabplugin.cpp
    public static native void enqueueEvent0(int type);
    public static native void enqueueEvent1(int type, int n);

    // So, why do we get currency balance and spend them all?
    // Tapjoy supports two types of virtual currency.
    // 1) Self managed currency
    //    You need to use this approach when you have a server which manages virtual currency of your game.
    //    When a user earns currency, Tapjoy will directly calls your server.
    //    In this case, you can remove `checkCurrency` below.
    // 2) Tapjoy managed currency
    //    If
    //      - your game doesn't have a server
    //      - your game can be played when it's offline
    //      - your game uses not only Tapjoy for rewarded AD,
    //    you may want to manage virtual currency locally. In this case following code is for you.
    //    Get current currency balance, spend them all, and manage it by yourself (at Lua layer)
    private static void checkCurrency() {
        Tapjoy.getCurrencyBalance(new TJGetCurrencyBalanceListener() {
            @Override
            public void onGetCurrencyBalanceResponse(String s, int i) {
                final int rewarded = i;
                Tapjoy.spendCurrency(rewarded, new TJSpendCurrencyListener() {
                    @Override
                    public void onSpendCurrencyResponse(String s, int i) {
                        enqueueEvent1(GABPLUGIN_AD_REWARDED, rewarded);
                        Bundle bundle = new Bundle();
                        bundle.putInt(FirebaseAnalytics.Param.VALUE, i);
                        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.EARN_VIRTUAL_CURRENCY, bundle);
                    }

                    @Override
                    public void onSpendCurrencyResponseFailure(String s) {

                    }
                });
            }

            @Override
            public void onGetCurrencyBalanceResponseFailure(String s) {

            }
        });
    }

    static TJConnectListener tjConnectListener = new TJConnectListener() {
        @Override
        public void onConnectSuccess() {
            ABPlugin.initTapjoy();
        }

        @Override
        public void onConnectFailure() {

        }
    };

    public static TJConnectListener getTapjoyConnectListener() {
        return tjConnectListener;
    }

    static TJPlacementListener tjListener = new TJPlacementListener() {
        @Override
        public void onRequestSuccess(TJPlacement tjPlacement) {
            if (tjPlacement == tjVideo && !tjPlacement.isContentAvailable()) {
                tryNextVideo();
            }
        }

        @Override
        public void onRequestFailure(TJPlacement tjPlacement, TJError tjError) {
            if (tjPlacement == tjVideo) {
                tryNextVideo();
            }
            else {
                final Activity activity = weakActivity.get();

                if (activity != null) {
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            Toast.makeText(activity, "Failed to get AD.", Toast.LENGTH_LONG).show();
                        }
                    });
                }
                enqueueEvent0(GABPLUGIN_AD_ERROR);
            }
        }

        @Override
        public void onContentReady(TJPlacement tjPlacement) {
            /*
            if (tjPlacement == tjOffers) {
                tjOffers.showContent();
                firebaseAnalytics.logEvent("showTapjoyOffers", null);
            }
            */
            if (tjPlacement == tjVideo) {
                tjVideo.showContent();
                firebaseAnalytics.logEvent("show_tapjoy_video", null);
            }
        }

        @Override
        public void onContentShow(TJPlacement tjPlacement) {
            enqueueEvent0(GABPLUGIN_AD_DISPLAYED);
        }

        @Override
        public void onContentDismiss(TJPlacement tjPlacement) {
            enqueueEvent0(GABPLUGIN_AD_DISMISSED);
            checkCurrency();
            if (tjPlacement == tjOffers) {
                tjOffers.requestContent();
            }
        }

        @Override
        public void onPurchaseRequest(TJPlacement tjPlacement, TJActionRequest tjActionRequest, String s) {

        }

        @Override
        public void onRewardRequest(TJPlacement tjPlacement, TJActionRequest tjActionRequest, String s, int i) {

        }

        @Override
        public void onClick(TJPlacement tjPlacement) {

        }

    };

    static RewardedVideoAdListener adMobListener = new RewardedVideoAdListener() {

        @Override
        public void onRewardedVideoAdLoaded() {
            if (adMobVideo.isLoaded()) {
                adMobVideo.show();
                firebaseAnalytics.logEvent("show_admob_video", null);
            }
        }

        @Override
        public void onRewardedVideoAdOpened() {
            enqueueEvent0(GABPLUGIN_AD_DISPLAYED);
        }

        @Override
        public void onRewardedVideoStarted() {

        }

        @Override
        public void onRewardedVideoAdClosed() {
            enqueueEvent0(GABPLUGIN_AD_DISMISSED);
        }

        @Override
        public void onRewarded(RewardItem rewardItem) {
            int balance = rewardItem.getAmount();
            enqueueEvent1(GABPLUGIN_AD_REWARDED, balance);
            Bundle bundle = new Bundle();
            bundle.putInt(FirebaseAnalytics.Param.VALUE, balance);
            firebaseAnalytics.logEvent(FirebaseAnalytics.Event.EARN_VIRTUAL_CURRENCY, bundle);
        }

        @Override
        public void onRewardedVideoAdLeftApplication() {

        }

        @Override
        public void onRewardedVideoAdFailedToLoad(int i) {
            Log.e("ABPlugin", "AdMob error: " + i);
            tryNextVideo();
        }

        @Override
        public void onRewardedVideoCompleted() {

        }
    };
}
