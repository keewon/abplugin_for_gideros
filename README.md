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
