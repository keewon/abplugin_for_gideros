require "strict"
require 'scenemanager'
require 'scenemain'
require 'abplugin'

application:setBackgroundColor(0xffffff)
-- call this function to register ABPlugin
abPluginRegister()

SCENE_MAIN = 'SCENE_MAIN'

local sceneManager = SceneManager.new({
  [SCENE_MAIN] = SceneMain,
})

stage:addChild(sceneManager)

sceneManager:changeScene(SCENE_MAIN, 0, SceneManager.flipWithFade)