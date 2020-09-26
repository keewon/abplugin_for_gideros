# ABPluginExample
This is a Gideros plugin example which calls Tapjoy, Firebase and AdMob functions.

## ios
This directory is exported using 'Export Project' > 'iOS'

### Change AppDelegate.m
 * Find `// ABPluginExample -->`

### Add following files to the project
 * gabplugin.h/mm
 * ABPlugin.h/mm - ABPlugin.mm requires compile option -fobjc-arc
 * abpluginbinder.cpp
 * Add remote-notification to UIBackgroundModes in Info.plist to get push notification.
 * GoogleService-Info.plist (If you use Firebase/AdMob)
 * For your AdMob integration, see https://developers.google.com/admob/ios/quick-start#update_your_infoplist

## android
This directory is exported using 'Export Project' > 'Android (Old)'

### Update some settings
To add Firebase and Tapjoy, you need to change project settings a lot.
Please diff with your fresh project.

### Change AndroidManifest.xml
 * Find `<!-- ABPlugin: Tapjoy and Google products -->`

### Change YourMainActivity.java
 * Find `// ABPlugin`

### Setup JNI build
 * In app level build.gradle, you need to add configurations for native build. Find `// ABPlugin -->`

### Add Some files
 * In app/src/main/java/com/giderosmobile/android
   - ABPlugin.java
 * In app/src/main/jni
   - abpluginbinder.cpp
   - gabplugin.h/cpp
   - and more

## APIs
See https://github.com/keewon/abplugin_for_gideros/blob/master/assets/abplugin.lua

### How to add more APIs which don't need return value
 1. Add them to abplugin.lua
 2. Add them to abpluginbinder.cpp
 3. Implement them in gabplugin.x or ABPlugin.x
