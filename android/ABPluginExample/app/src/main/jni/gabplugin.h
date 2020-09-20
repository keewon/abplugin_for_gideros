#ifndef GABPLUGIN_H
#define GABPLUGIN_H

#include <gglobal.h>
#include <gevent.h>
#include <string.h>
#include <time.h>

enum
{
    GABPLUGIN_AD_DISPLAYED,
    GABPLUGIN_AD_DISMISSED,
    GABPLUGIN_AD_ERROR,
    GABPLUGIN_AD_REWARDED,
    GABPLUGIN_AD_VIDEO_READY,
};

extern const char *AB_COHORT_LEVEL;

typedef struct gabplugin_SimpleEvent
{
    int value;
} gabplugin_SimpleEvent;

#ifdef __cplusplus
extern "C" {
#endif

G_API void gabplugin_init();
G_API void gabplugin_cleanup();

G_API void gabplugin_sendEvent(const char *eventName, const char * arg1, int value);
G_API void gabplugin_setUserProperty(const char *key, const char *value);
G_API void gabplugin_showVideo();
G_API void gabplugin_showOffers();
G_API int gabplugin_isVideoAvailable();
G_API void gabplugin_setRemoteNotifications(int value);
G_API int gabplugin_isRemoteNotificationsEnabled();
G_API void gabplugin_log(const char* text);

G_API g_id gabplugin_addCallback(gevent_Callback callback, void *udata);
G_API void gabplugin_removeCallback(gevent_Callback callback, void *udata);
G_API void gabplugin_removeCallbackWithGid(g_id gid);

G_API void gabplugin_enqueueEvent0(int type);
G_API void gabplugin_enqueueEvent1(int type, int value);

#ifdef __cplusplus
}
#endif

#endif