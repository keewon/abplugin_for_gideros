#include "gabplugin.h"
#include "gideros.h"
#include <map>
#include <string>
#include <vector>

#if defined(ANDROID)
#include <android/log.h>
#endif

// some Lua helper functions
#ifndef abs_index
#define abs_index(L, i) ((i) > 0 || (i) <= LUA_REGISTRYINDEX ? (i) : lua_gettop(L) + (i) + 1)
#endif

static void luaL_newweaktable(lua_State *L, const char *mode)
{
    lua_newtable(L);            // create table for instance list
    lua_pushstring(L, mode);
    lua_setfield(L, -2, "__mode");      // set as weak-value table
    lua_pushvalue(L, -1);             // duplicate table
    lua_setmetatable(L, -2);          // set itself as metatable
}

static void luaL_rawgetptr(lua_State *L, int idx, void *ptr)
{
    idx = abs_index(L, idx);
    lua_pushlightuserdata(L, ptr);
    lua_rawget(L, idx);
}

static void luaL_rawsetptr(lua_State *L, int idx, void *ptr)
{
    idx = abs_index(L, idx);
    lua_pushlightuserdata(L, ptr);
    lua_insert(L, -2);
    lua_rawset(L, idx);
}

static const char *AB_AD_DISPLAYED   = "AB_AD_DISPLAYED";
static const char *AB_AD_DISMISSED   = "AB_AD_DISMISSED";
static const char *AB_AD_ERROR       = "AB_AD_ERROR";
static const char *AB_AD_REWARDED    = "AB_AD_REWARDED";
static const char *AB_AD_VIDEO_READY = "AB_AD_VIDEO_READY";

static const char *AB_AD_ENUMS[] = {
    AB_AD_DISPLAYED,
    AB_AD_DISMISSED,
    AB_AD_ERROR,
    AB_AD_REWARDED,
    AB_AD_VIDEO_READY,
    NULL
};

static const char *AB_COHORT_CONST_ENUMS[] = {
    AB_COHORT_LEVEL,
    NULL
};

static char keyWeak = ' ';

static lua_State *L = NULL;

class GABPlugin : public GEventDispatcherProxy
{
public:
    GABPlugin()
    {
        gabplugin_init();
        gabplugin_addCallback(callback_s, this);
    }

    ~GABPlugin()
    {
        gabplugin_removeCallback(callback_s, this);
        gabplugin_cleanup();
    }

private:
    static void callback_s(int type, void *event, void *udata)
    {
        static_cast<GABPlugin*>(udata)->callback(type, event);
    }

    void callback(int type, void *event)
    {
        dispatchEvent(type, event);
    }

    void dispatchEvent(int type, void *event)
    {
        if (L == NULL)
            return;

        luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
        luaL_rawgetptr(L, -1, this);

        if (lua_isnil(L, -1))
        {
            lua_pop(L, 2);
            return;
        }

        lua_getfield(L, -1, "dispatchEvent");

        lua_pushvalue(L, -2);

        lua_getglobal(L, "Event");
        lua_getfield(L, -1, "new");
        lua_remove(L, -2);

        lua_pushstring(L, AB_AD_ENUMS[type]);
        lua_call(L, 1, 1);

        if (type == GABPLUGIN_AD_REWARDED)
        {
            gabplugin_SimpleEvent *event2 = (gabplugin_SimpleEvent*)event;

            lua_pushinteger(L, event2->value);
            lua_setfield(L, -2, "point");
        }

        lua_call(L, 2, 0);

        lua_pop(L, 2);
    }
};

static int destruct(lua_State* L)
{
    void *ptr = *(void**)lua_touserdata(L, 1);
    GReferenced* object = static_cast<GReferenced*>(ptr);
    GABPlugin *abplugin = static_cast<GABPlugin*>(object->proxy());

    abplugin->unref();

    return 0;
}

static GABPlugin *getInstance(lua_State* L, int index)
{
    GReferenced *object = static_cast<GReferenced*>(g_getInstance(L, "ABPlugin", index));
    GABPlugin *abplugin = static_cast<GABPlugin*>(object->proxy());

    return abplugin;
}

static int sendEvent(lua_State *L)
{
    const char* eventName = luaL_checkstring(L, 2);
    const char* arg1 = luaL_optstring(L, 3, 0);
    const int value = luaL_checkint(L, 4);

    gabplugin_sendEvent(eventName, arg1, value);

    return 0;
}

static int setUserProperty(lua_State *L)
{
    const char* k = luaL_checkstring(L, 2);
    const char* v = luaL_checkstring(L, 3);
    gabplugin_setUserProperty(k, v);
    return 0;
}

static int showVideo(lua_State *L)
{
    gabplugin_showVideo();
    return 0;
}

static int showOffers(lua_State *L)
{
    gabplugin_showOffers();
    return 0;
}

static int isVideoAvailable(lua_State *L){
    lua_pushnumber(L, gabplugin_isVideoAvailable());
    return 1;
}

static int setRemoteNotifications(lua_State *L){
    const int value = luaL_checkint(L, 2);
    gabplugin_setRemoteNotifications(value);
    return 0;
}

static int isRemoteNotificationsEnabled(lua_State *L){
    lua_pushnumber(L, gabplugin_isRemoteNotificationsEnabled());
    return 1;
}

static int log(lua_State *L) {
    const char* text = luaL_checkstring(L, 2);
    gabplugin_log(text);
    return 0;
}

static int loader(lua_State *L)
{
    const luaL_Reg functionlist[] = {
        {"sendEvent", sendEvent},
        {"setUserProperty", setUserProperty},
        {"showVideo", showVideo},
        {"showOffers", showOffers},
        {"isVideoAvailable", isVideoAvailable},
        {"setRemoteNotifications", setRemoteNotifications},
        {"isRemoteNotificationsEnabled", isRemoteNotificationsEnabled},
        {"log", log},
        {NULL, NULL},
    };

    g_createClass(L, "ABPlugin", "EventDispatcher", NULL, destruct, functionlist);

    // create a weak table in LUA_REGISTRYINDEX that can be accessed with the address of keyWeak
    luaL_newweaktable(L, "v");
    luaL_rawsetptr(L, LUA_REGISTRYINDEX, &keyWeak);

    lua_getglobal(L, "Event");
    for (int i=0; AB_AD_ENUMS[i] != NULL; ++i) {
        lua_pushstring(L, AB_AD_ENUMS[i]);
        lua_setfield(L, -2, AB_AD_ENUMS[i]);
    }
    lua_pop(L, 1);

    lua_getglobal(L, "ABPlugin");
    for (int i=0; AB_COHORT_CONST_ENUMS[i] != NULL; ++i) {
        lua_pushstring(L, AB_COHORT_CONST_ENUMS[i]);
        lua_setfield(L, -2, AB_COHORT_CONST_ENUMS[i]);
    }

    GABPlugin *abplugin = new GABPlugin;
    g_pushInstance(L, "ABPlugin", abplugin->object());

    luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
    lua_pushvalue(L, -2);
    luaL_rawsetptr(L, -2, abplugin);
    lua_pop(L, 1);

    lua_pushvalue(L, -1);
    lua_setglobal(L, "abplugin");

    return 1;
}

static void g_initializePlugin(lua_State *L)
{
    ::L = L;

    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");

    lua_pushcfunction(L, loader);
    lua_setfield(L, -2, "abplugin_native");

    lua_pop(L, 2);
}

static void g_deinitializePlugin(lua_State *L)
{
    ::L = NULL;
}

REGISTER_PLUGIN("ABPlugin", "1.0")