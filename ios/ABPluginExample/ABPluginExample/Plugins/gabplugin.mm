#include "gabplugin.h"
#include <stdlib.h>
#include <glog.h>
#include <gevent.h>
#include <string>
#include <gapplication.h>
#if defined(ANDROID)
#include <android/log.h>
#endif

#if defined(ANDROID)
static jclass cls_;
static const char* javaClassName = "com/giderosmobile/android/ABPlugin";
#endif

#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <Tapjoy/Tapjoy.h>
#import "ABPlugin.h"

static g_id gid;
gevent_CallbackList callbackList;

const char *AB_COHORT_LEVEL = "AB_COHORT_LEVEL";

static void callback_s(int type, void *event, void *udata)
{
    callbackList.dispatchEvent(type, event);
}

void gabplugin_enqueueEvent0(int type) {
    gevent_EnqueueEvent(gid, callback_s, type, NULL, 1, NULL);
}

void gabplugin_enqueueEvent1(int type, int n) {
    gabplugin_SimpleEvent *event = (gabplugin_SimpleEvent*)malloc(sizeof(gabplugin_SimpleEvent));
    event->value = n;
    gevent_EnqueueEvent(gid, callback_s, type, event, 1, NULL);
}

void gabplugin_init()
{
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    jclass localClass = env->FindClass(javaClassName);
    cls_ = (jclass)env->NewGlobalRef(localClass);
    env->DeleteLocalRef(localClass);
#endif
    gid = g_NextId();
}

void gabplugin_cleanup()
{
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    env->DeleteGlobalRef(cls_);
    cls_ = 0;
#endif
    gevent_RemoveEventsWithGid(gid);
}

// We're sending event to both of Tapjoy and Firebase.
// You can use only one, or compare them.
// Example of usage)
// eventName=complete, arg1=level1, value=(score)

void gabplugin_sendEvent(const char *eventName, const char * arg1, int value)
{
    NSString *strEventName = [NSString stringWithUTF8String:eventName];
    NSString *strArg1 = nil;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (arg1 != 0) {
        strArg1 = [NSString stringWithUTF8String:arg1];
        parameters[@"arg1"] = strArg1;
    }
    parameters[@"value"] = [NSNumber numberWithInt:value];

    [Tapjoy trackEvent:strEventName
              category:nil
            parameter1:strArg1
            parameter2:nil
                 value:value];

    [FIRAnalytics logEventWithName:strEventName
                        parameters:parameters];
}

// Tapjoy supports setting five 'Cohorts' + 'Level'
// while Firebase supports 'User property'
// With this, you can view metrics by cohorts/level/user properties.

static int keyToCohortNumber(const char* key) {
    if (0 == strcmp(key, AB_COHORT_LEVEL)) {
        return 6;
    }
    return -1;
}

void gabplugin_setUserProperty(const char *key, const char *value)
{
    NSString *strKey = [NSString stringWithUTF8String:key];
    NSString *strValue = nil;
    int cohort = keyToCohortNumber(key);

    if (cohort >= 0 && cohort < 5) {
        strValue = [NSString stringWithUTF8String:value];
        [Tapjoy setUserCohortVariable:cohort value:strValue];
        [FIRAnalytics setUserPropertyString:strValue forName:strKey];
    }
    else if (cohort == 6) {
        [Tapjoy setUserLevel:atoi(value)];
        strValue = [NSString stringWithUTF8String:value];
        [FIRAnalytics setUserPropertyString:strValue forName:strKey];
    }
}

void gabplugin_showVideo()
{
    [[ABPlugin sharedInstance] showVideo];
}

void gabplugin_showOffers()
{
    [[ABPlugin sharedInstance] showOffers];
}

int gabplugin_isVideoAvailable()
{
    BOOL available = [[ABPlugin sharedInstance] isVideoAvailable];
    return available ? 1 : 0;
}

void gabplugin_setRemoteNotifications(int value)
{
    BOOL enable = (value == 0) ? NO : YES;
    [[ABPlugin sharedInstance] setRemoteNotifications:enable];
}

int gabplugin_isRemoteNotificationsEnabled()
{
    BOOL enable = [[ABPlugin sharedInstance] isRemoteNotificationsEnabled];
    return enable ? 1 : 0;
}

void gabplugin_log(const char* text)
{
    NSLog(@"[Lua] %s", text);
}

g_id gabplugin_addCallback(gevent_Callback callback, void *udata)
{
    return callbackList.addCallback(callback, udata);
}

void gabplugin_removeCallback(gevent_Callback callback, void *udata)
{
    callbackList.removeCallback(callback, udata);
}

void gabplugin_removeCallbackWithGid(g_id gid)
{
    callbackList.removeCallbackWithGid(gid);
}
