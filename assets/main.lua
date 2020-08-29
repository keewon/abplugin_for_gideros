require "strict"
require 'scenemanager'
require 'scenemain'
require 'abplugin'

application:setBackgroundColor(0xffffff)
abPluginRegister()

SCENE_MAIN = 'SCENE_MAIN'

local sceneManager = SceneManager.new({
  [SCENE_MAIN] = SceneMain,
})

stage:addChild(sceneManager)

sceneManager:changeScene(SCENE_MAIN, 0, SceneManager.flipWithFade)