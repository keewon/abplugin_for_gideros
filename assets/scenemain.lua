require 'strict'
require 'abplugin'
require 'button'

SceneMain = Core.class(Sprite)

function SceneMain:init(userData)
  self:addEventListener(Event.APPLICATION_RESUME, self.onApplicationResume, self)
  self:addEventListener(Event.APPLICATION_SUSPEND, self.onApplicationSuspend, self)
  self:addEventListener(Event.APPLICATION_EXIT, self.onApplicationSuspend, self)
  self:addEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
  self:addEventListener('enterBegin', self.onEnterBegin, self)
  self:addEventListener('exitBegin', self.onExitBegin, self)
  abPluginRegisterCallback(Event.AB_AD_REWARDED, self.updateReward, self)

  self:initUI()
end

function SceneMain:onApplicationResume()
  print('onApplicationResume')
  self:checkAndShowDailyReward()
end

function SceneMain:onApplicationSuspend()
  print('onApplicationSuspend')
  self:saveState()
end

function SceneMain:onEnterBegin()
end

function SceneMain:onExitBegin()
  self:removeEventListener(Event.APPLICATION_RESUME, self.onApplicationResume, self)
  self:removeEventListener(Event.APPLICATION_SUSPEND, self.onApplicationSuspend, self)
  self:removeEventListener(Event.APPLICATION_EXIT, self.onApplicationSuspend, self)
  self:removeEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
  self:removeEventListener(Event.MY_AD_REWARDED, self.updateReward, self)
end

function SceneMain:updateReward(event)
  local text = "updateReward: " .. event.point
  print(text)
  local dialog = AlertDialog.new('ABPlugin', text, 'OK')
	dialog:show()
end

function SceneMain:checkAndShowDailyReward()
end

function SceneMain:saveState()
end

function SceneMain:onEnterFrame(e)
  local now = os.timer()
end

local function createButton(text)
  local text1 = TextField.new(nil, text)
  local text2 = TextField.new(nil, text)

  text1:setScale(4)
  text2:setScale(4)
  text1:setTextColor(0x000000)
  text2:setTextColor(0xff0000)

  local button = Button.new(text1, text2)
  return button
end

MARGIN_X = 0
MARGIN_Y = 0
BUTTON_GAP = 60

function SceneMain:initUI()
  local labelTitle = TextField.new(nil, "ABPluginExample")
  labelTitle:setScale(5)
  local buttonShowOffers = createButton('Show Offers')
  local buttonShowVideo = createButton('Show Video')
  local buttonSendEvent = createButton('Send Event')

  labelTitle:setPosition(MARGIN_X, MARGIN_Y + labelTitle:getHeight())

  buttonShowOffers:setPosition(MARGIN_X, MARGIN_Y + buttonShowOffers:getHeight() / 2 + BUTTON_GAP * 2)
  buttonShowVideo:setPosition(MARGIN_X, MARGIN_Y + buttonShowVideo:getHeight() / 2 + BUTTON_GAP * 3)
  buttonSendEvent:setPosition(MARGIN_X, MARGIN_Y + buttonSendEvent:getHeight() / 2 + BUTTON_GAP * 4)

  buttonShowOffers:addEventListener('click', function()
    abPluginShowOffers()
  end)
  buttonShowVideo:addEventListener('click', function()
    abPluginShowVideo()
  end)
  buttonSendEvent:addEventListener('click', function()
    local level = math.random(1, 10)
    local score = math.random(0, 100)
    level = 'level_' .. level
    print('level_complete', level, score)
    abPluginSendEvent('level_complete', level, score)
  end)


  self:addChild(labelTitle)
  self:addChild(buttonShowOffers)
  self:addChild(buttonShowVideo)
  self:addChild(buttonSendEvent)
end