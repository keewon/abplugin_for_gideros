require 'strict'

local useNativeABPlugin = false
local currentABPlugin = nil

if application:getDeviceInfo() == 'Android' or application:getDeviceInfo() == 'iOS' then
  require('abplugin_native')
  currentABPlugin = abplugin
  useNativeABPlugin = true
else
  -- use ABPlugin mock for other platforms
  currentABPlugin = EventDispatcher.new()
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
  if event.point > 0 then
    local text = "Got " .. event.point .. " points"
    local dialog = AlertDialog.new('ABPlugin', text, 'OK')
    dialog:show()
  end
end

function abPluginRegister()
  currentABPlugin:addEventListener(Event.AB_AD_DISPLAYED, abPluginOnAdDisplayed)
  currentABPlugin:addEventListener(Event.AB_AD_DISMISSED, abPluginOnAdDismissed)
  currentABPlugin:addEventListener(Event.AB_AD_ERROR, abPluginOnAdError)
  currentABPlugin:addEventListener(Event.AB_AD_REWARDED, abPluginOnAdRewarded)
end

function abPluginRegisterCallback(eventType, f, data)
  currentABPlugin:addEventListener(eventType, f, data)
end

function abPluginUnregisterCallback(eventType, f, data)
  currentABPlugin:removeEventListener(eventType, f, data)
end

function abPluginSendEvent(eventName, arg1, value)
  if not useNativeABPlugin then return end
  currentABPlugin:sendEvent(eventName, arg1, value)
end

function abPluginSetUserProperty(key, value)
  if not useNativeABPlugin then return end
  currentABPlugin:setUserProperty(key, value)
end

local simulateVideoError = 3
function abPluginShowVideo()
  -- simulate callback of video AD
  if not useNativeABPlugin then
    local timer = Timer.new(1000, 1)
    timer:addEventListener(Event.TIMER_COMPLETE, function()
      print('TIMER')
      currentABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISPLAYED))
      currentABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISMISSED))
      if simulateVideoError > 0 then
        local e = Event.new(Event.AB_AD_REWARDED)
        e.point = 1
        currentABPlugin:dispatchEvent(e)
      else
        local e = Event.new(Event.AB_AD_ERROR)
        currentABPlugin:dispatchEvent(e)
      end
      simulateVideoError = simulateVideoError - 1
      if simulateVideoError < 0 then
        simulateVideoError = 3
      end
    end)
    timer:start()
    return
  end
  currentABPlugin:showVideo()
end

function abPluginShowOffers()
  -- simulate callback of Offerwall AD
  if not useNativeABPlugin then
    currentABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISPLAYED))

    local e = Event.new(Event.AB_AD_REWARDED)
    e.point = 10
    currentABPlugin:dispatchEvent(e)

    currentABPlugin:dispatchEvent(Event.new(Event.AB_AD_DISMISSED))
    return
  end
  currentABPlugin:showOffers()
end

function abPluginIsVideoAvailable()
  if not useNativeABPlugin then return true end
  return currentABPlugin:isVideoAvailable() == 1
end

local simulateRemoteNotification = false

function abPluginIsRemoteNotificationsEnabled()
  if not useNativeABPlugin then return simulateRemoteNotification end
  return currentABPlugin:isRemoteNotificationsEnabled() == 1
end

function abPluginSetRemoteNotifications(enable)
  if not useNativeABPlugin then
    simulateRemoteNotification = enable
    return
  end
  local nEnable = 0
  if enable then
    nEnable = 1
  end
  currentABPlugin:setRemoteNotifications(nEnable)
end

function abPluginSetUserLevel(level)
  if useNativeABPlugin then
    abPluginSetUserProperty(AB_COHORT_LEVEL, level)
  end
end

function abPluginLog(text)
  if useNativeABPlugin then
    currentABPlugin:log(text)
  else
    print(text)
  end
end
