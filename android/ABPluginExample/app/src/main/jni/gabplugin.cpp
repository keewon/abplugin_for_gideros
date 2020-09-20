#include "gabplugin.h"
#include "gideros.h"
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

static g_id gid;
gevent_CallbackList callbackList;

const char *AB_COHORT_LEVEL = "AB_COHORT_LEVEL";

static void callback_s(int type, void *event, void *udata)
{
    callbackList.dispatchEvent(type, event);
}

/*
 
 */
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

void gabplugin_sendEvent(const char *eventName, const char * arg1, int value) {
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    jstring jEventName = 0, jArg1 = 0;
    if (eventName != 0) {
        jEventName = env->NewStringUTF(eventName);
    }
    if (arg1 != 0) {
        jArg1 = env->NewStringUTF(arg1);
    }
    env->CallStaticVoidMethod(cls_, env->GetStaticMethodID(cls_, "sendEvent", "(Ljava/lang/String;Ljava/lang/String;I)V"), jEventName, jArg1, value);

    env->DeleteLocalRef(jEventName);
    env->DeleteLocalRef(jArg1);
#endif
}

static int keyToCohortNumber(const char* key) {
    if (0 == strcmp(key, AB_COHORT_LEVEL)) {
        return 6;
    }
    return -1;
}

void gabplugin_setUserProperty(const char *key, const char *value)
{
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    jstring jKey = 0, jValue = 0;
    if (key != 0) {
        jKey = env->NewStringUTF(key);
    }
    if (value != 0) {
        jValue = env->NewStringUTF(value);
    }
    env->CallStaticVoidMethod(cls_, env->GetStaticMethodID(cls_, "setUserProperty", "(Ljava/lang/String;Ljava/lang/String;)V"), jKey, jValue);

    env->DeleteLocalRef(jKey);
    env->DeleteLocalRef(jValue);
#endif
}

void gabplugin_showVideo()
{
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    env->CallStaticVoidMethod(cls_, env->GetStaticMethodID(cls_, "showVideo", "()V")); // TODO
#endif
}

void gabplugin_showOffers()
{
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    env->CallStaticVoidMethod(cls_, env->GetStaticMethodID(cls_, "showOffers", "()V")); // TODO
#endif
}

int gabplugin_isVideoAvailable()
{
    int result = 0;
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    jboolean jResult = env->CallStaticBooleanMethod(cls_, env->GetStaticMethodID(cls_, "isVideoAvailable", "()Z"));
    if (jResult) {
        result = 1;
    }
#endif
    return result;
}

void gabplugin_setRemoteNotifications(int value)
{
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    env->CallStaticVoidMethod(cls_, env->GetStaticMethodID(cls_, "setRemoteNotifications", "(I)V"), value);
#endif
}

int gabplugin_isRemoteNotificationsEnabled()
{
    int result = 0;
#if defined(ANDROID)
    JNIEnv *env = g_getJNIEnv();
    jboolean jResult = env->CallStaticBooleanMethod(cls_, env->GetStaticMethodID(cls_, "isRemoteNotificationsEnabled", "()Z"));
    if (jResult) {
        result = 1;
    }
#endif
    return result;
}

void gabplugin_log(const char* text)
{
#if defined(ANDROID)
    __android_log_write(ANDROID_LOG_INFO, "OrganicPop", text);
#endif
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

extern "C" {
    void Java_com_giderosmobile_android_ABPlugin_enqueueEvent0(JNIEnv *env, jclass clz, jint type) {
        gabplugin_enqueueEvent0(type);
    }

    void Java_com_giderosmobile_android_ABPlugin_enqueueEvent1(JNIEnv *env, jclass clz, jint type, jint n) {
        gabplugin_enqueueEvent1(type, n);
    }
}
