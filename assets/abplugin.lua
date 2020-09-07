require 'strict'

local useABPlugin = false
local localABPlugin = nil
if application:getDeviceInfo() == 'Android' or application:getDeviceInfo() == 'iOS' then
    require('abplugin_native')
  localABPlugin = abplugin
  useABPlugin = true
else
  localABPlugin = EventDispatcher.new()
  Event.AB_AD_DISPLAYED = 'AB_AD_DISPLAYED'
  Event.AB_AD_DISMISSED = 'AB_AD_DISMISSED'
  Event.AB_AD_REWARDED  = 'AB_AD_REWARDED'
  Event.AB_AD_ERROR     = 'AB_AD_ERROR'
end

local function abPluginOnAdDisplayed(event)
  print('AD displayed')
end

local function abPluginOnAdDismissed(event)
  print('AD dismissed')
end

local function abPluginOnAdError(event)
  print('AD error')
  local dialog = AlertDialog.new('Sorry', 'AD is not available.', 'OK')
	dialog:show()
end

local function abPluginOnAdRewarded(event)
  print(event.point)
end

function abPluginRegister()
  localABPlugin:addEventListener(Event.AB_AD_DISPLAYED, abPluginOnAdDisplayed)
  localABPlugin:addEventListener(Event.AB_AD_DISMISSED, abPluginOnAdDismissed)
  localABPlugin:addEventListener(Event.AB_AD_ERROR, abPluginOnAdError)
  localABPlugin:addEventListener(Event.AB_AD_REWARDED, abPluginOnAdRewarded)
end

function abPluginRegisterCallback(eventType, f, data)
  localABPlugin:addEventListener(eventType, f, data)
end

function abPluginUnregisterCallback(eventType, f, data)
  localABPlugin:removeEventListener(eventType, f, data)
end

function abPluginSendEvent(eventName, arg1, value)
  if not useABPlugin then return end
  localABPlugin:sendEvent(eventName, arg1, value)
end

function abPluginSetUserProperty(key, value)
  if not useABPlugin then return end
  localABPlugin:setUserProperty(key, value)
end

local simulateVideoError = 3
function abPluginShowVideo()
  if not useABPlugin then
    local timer = Timer.new(1000, 1)
    timer:addEventListener(Event.TIMER_COMPLETE, function()
      print('TIMER')
      localABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISPLAYED))
      localABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISMISSED))
      if simulateVideoError > 0 then
        local e = Event.new(Event.AB_AD_REWARDED)
        e.point = 1
        localABPlugin:dispatchEvent(e)
      else
        local e = Event.new(Event.AB_AD_ERROR)
        localABPlugin:dispatchEvent(e)
      end
      simulateVideoError = simulateVideoError - 1
      if simulateVideoError < 0 then
        simulateVideoError = 3
      end
    end)
    timer:start()
    return
  end
  localABPlugin:showVideo()
end

function abPluginShowOffers()
  if not useABPlugin then
    localABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISPLAYED))

    local e = Event.new(Event.AB_AD_REWARDED)
    e.point = 10
    localABPlugin:dispatchEvent(e)

    localABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISMISSED))
    return
  end
  localABPlugin:showOffers()
end

function abPluginIsVideoAvailable()
  if not useABPlugin then return true end
  return localABPlugin:isVideoAvailable() == 1
end

local simulateRemoteNotification = false

function abPluginIsRemoteNotificationsEnabled()
  if not useABPlugin then return simulateRemoteNotification end
  return localABPlugin:isRemoteNotificationsEnabled() == 1
end

function abPluginSetRemoteNotifications(enable)
  if not useABPlugin then
    simulateRemoteNotification = enable
    return
  end
  local nEnable = 0
  if enable then
    nEnable = 1
  end
  localABPlugin:setRemoteNotifications(nEnable)
end

function abPluginSetUserLevel(level)
  if useABPlugin then
    abPluginSetUserProperty(AB_COHORT_LEVEL, level)
  end
end

function abPluginLog(text)
  if useABPlugin then
    localABPlugin:log(text)
  else
    print(text)
  end
end
