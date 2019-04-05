# AWAREFramework

[![CI Status](https://travis-ci.com/tetujin/AWAREFramework-iOS.svg?branch=master)](https://travis-ci.com/tetujin/AWAREFramework-iOS)
[![Version](https://img.shields.io/cocoapods/v/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)
[![License](https://img.shields.io/cocoapods/l/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)
[![Platform](https://img.shields.io/cocoapods/p/AWAREFramework.svg?style=flat)](http://cocoapods.org/pods/AWAREFramework)

[AWARE](http://www.awareframework.com/) is iOS and Android framework dedicated to instrument, infer, log and share mobile context information, for application developers, researchers and smartphone users. AWARE captures hardware-, software-, and human-based data (ESM). They transform data into information you can understand.

## Supported Sensors
* Accelerometer
* Gyroscope
* Magnetometer
* Gravity
* Rotation
* Motion Activity
* Pedometer
* Location
* Barometer
* Battery
* Network
* Call
* Bluetooth
* Processor
* Proximity
* Timezone
* Wifi
* Screen Events
* Microphone (Ambient Noise)
* Heartrate (BLE)
* Calendar
* Contact
* [Fitbit](https://dev.fitbit.com/)
* [Google Login](https://developers.google.com/identity/sign-in/ios/)
* Memory
* [NTPTime](https://github.com/jbenet/ios-ntp)
* [OpenWeatherMap](https://openweathermap.org/api)

## Example Apps
* [SensingApp](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-SensingApp)
* [SimpleClient](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-SimpleClient)
* [RichClient (aware-client-ios-v2)](https://github.com/tetujin/aware-client-ios-v2)
* [DynamicESM](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-DynamicESM)
* [ScheduleESM](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-ScheduleESM)
* [CustomESM](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-CustomESM)
* [CustomSensor](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-CustomSensor)
* [Visualizer](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Example/AWARE-Visualizer)

## How To Use

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Example 1: Initialize sensors and save sensor data to the local database
Just the following code, your application can collect sensor data in the background. The data is saved in a local-storage.

```swift
/// Example1  (Swift): Accelerometer ///
let accelerometer = Accelerometer()
accelerometer.setSensorEventHandler { (sensor, data) in
    print(data)
}
accelerometer.startSensor()
```
### Example 2: Sync local-database and AWARE Server

AWARECore, AWAREStudy, and AWARESensorManager are singleton instances for managing sensing/synchronization schedule in the library. You can access the instances via AWAREDelegate. The AWAREDelegate is described in the Installation section.  

```swift
let core    = AWARECore.shared()
let study   = AWAREStudy.shared()
let manager = AWARESensorManager.shared()
```

AWAREFramework-iOS allows us to synchronize your application and AWARE server by adding a server URL to AWAREStudy. About AWARE server, please check our [website](http://www.awareframework.com/).

```swift
/// Example2 (Swift): Accelerometer + AWARE Server ///
study.setStudyURL("https://api.awareframework.com/index.php/webservice/index/STUDY_ID/PASS")
let accelerometer = Accelerometer(awareStudy: study)
accelerometer.startSensor()
accelerometer.startSyncDB()
// or
manager.add(accelerometer)
```

### Example 3: Apply settings on AWARE Dashboard

Moreover, this library allows us to apply the settings on AWARE Dashboard by using -joinStuyWithURL:completion method.

```swift
/// Example3 (Swift): AWARE Dashboard ////
let url = "https://api.awareframework.com/index.php/webservice/index/STUDY_ID/PASS"
study.join(withURL: url, completion: { (settings, studyState, error) in
    manager.addSensors(with: study)
    manager.startAllSensors()
})
```

## Installation

AWAREFramework is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'AWAREFramework', :git=>'https://github.com/tetujin/AWAREFramework-iOS.git'
```

First, add permissions on Xcode for the background sensing (NOTE: the following permissions are minimum requirements)

* Info.plist
    * Privacy - Location Always and When In Use Usage Description
    * Privacy - Location Always Usage Description
![Image](./Screenshots/info_plist_location.png)

* Capabilities/Background Modes
    * Location updates
![Image](./Screenshots/background_modes.png)

Second, (1) import `AWAREFramework` into your class and (2) request permission for accessing the iOS location sensor always. 
After the permission is approved, you can (3) activate `AWARECore` and (4) use any sensors by the way which is described in How To Use session.

```swift
/// AppDelegate.swift ///
import UIKit
import AWAREFramework /// (1) import `AWAREFramework` into your source code.

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        ////////////////////////
        let core = AWARECore.shared()
        /// (2) request permission
        core.requestPermissionForBackgroundSensing{
            /// (3) activate AWARECore
            core.activate()
            core.requestPermissionForPushNotification()
            
            /// (4) use sensors 
            /// EDIT HERE ///
        
        }
        ////////////////////////
        
        return true
    }
}
```

## Experience Sampling Method (ESM)

This library supports ESM. The method allows us to make questions in your app at certain times.   The following code shows to a radio type question at 9:00, 12:00, 18:00, and 21:00 every day as an example. Please access our website for learning more information about the ESM.

```swift
/// Swift ///
let schdule = ESMSchedule()
schdule.notificationTitle   = "notification title"
schdule.notificationBody    = "notification body"
schdule.scheduleId          = "schedule_id"
schdule.expirationThreshold = 60
schdule.startDate           = Date.init()
schdule.endDate             = Date.init(timeIntervalSinceNow: 60*60*24*10)
schdule.fireHours           = [9,12,18,21]

let radio = ESMItem(asRadioESMWithTrigger: "1_radio", radioItems: ["A","B","C","D","E"])
radio.setTitle("ESM title")
radio.setInstructions("some instructions")
schdule.addESM(radio)

let esmManager = ESMScheduleManager.shared()
// esmManager.removeAllNotifications()
// esmManager.removeAllESMHitoryFromDB()
// esmManager.removeAllSchedulesFromDB()
esmManager.add(schdule)
```

Please call the following chunk of code for appearing ESMScrollViewController (e.g., at -viewDidAppear: ).

```swift
/// Swift ///
let schedules = ESMScheduleManager.shared().getValidSchedules() {
if(schedules.count > 0){
    let esmViewController = ESMScrollViewController()
    self.present(esmViewController, animated: true){}
}

```

### Supported ESM Types
This library supports 16 typs of ESMs.  You can see the screenshots from the [link](https://github.com/tetujin/AWAREFramework-iOS/tree/master/Screenshots/esms)

*  Text
*  Radio
*  Checkbox
*  Likert Scale
*  Quick Answer
*  Scale
*  DateTime
*  PAM
*  Numeric
*  Web
*  Date
*  Time
*  Clock
*  Picture
*  Audio
*  Video

## Author

Yuuki Nishiyama <yuuki.nishiyama@oulu.fi>

## License

AWAREFramework is available under the Apache2 license. See the LICENSE file for more info.
