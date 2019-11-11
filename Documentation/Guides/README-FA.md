<p align="center">
<img width="200" src="https://corp.map.ir/wp-content/uploads/2019/06/map-site-logo-1.png" alt="Map.ir Logo">
</p>

<p align="center">
   <a href="https://developer.apple.com/swift/">
      <img src="https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat" alt="Swift 5.1">
   </a>
   
   <!-- <a href="http://cocoapods.org/pods/MapirLiveTracker">
      <img src="https://img.shields.io/cocoapods/v/MapirLiveTracker.svg?style=flat" alt="Version">
   </a>
  
   
   <a href="http://cocoapods.org/pods/MapirLiveTracker">
      <img src="https://img.shields.io/cocoapods/p/MapirLiveTracker.svg?style=flat" alt="Platform">
   </a> -->
  
   <a href="https://github.com/Carthage/Carthage">
      <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage Compatible">
   </a>
</p>

# MapirLiveTracker

## امکانات

- Map.ir Live Tracker با استفاده از پروتوکل  MQTT کار میکند که باعث مصرف کم باتری و دیتا میشود.
- راه اندازی و تنظیمات ساده.
- رفرنس و توضیحات کامل.
- قابلیت برنامه نویسی با هردو زبان  Swift و Objective-C. 

## نمونه
بهترین راه آشنایی با شیوه کار Live Tracker استفاده از اپلیکیشن های نمونه است. ابتدا `MapirLiveTracker.xcodeproj` را بازکنید، سپس اسکیم `Swift Example` را باز انتخاب کرده و اجرا نمایید.
در حال حاضر نسخه ی Objective-C اپلیکیشن نمونه، در حال توسعه است.

## نصب

### CocoaPods
این SDK بزودی بر روی CocoaPods در دسترس قرار خواهد گرفت.
<!--
MapirLiveTracker در [CocoaPods](http://cocoapods.org) در دسترس است. برای نصب خط زیر را به فایل Podfile پروژه خود اضافه کنید.

```bash
pod 'MapirLiveTracker'
```
-->
### Carthage

برای استفاده از MapirLiveTracker در پروژه خود با استفاده از Carthage، در فایل `Cartfile` خود، خط زیر را اضافه کنید: 
```ogdl
github "map-ir/mapir-ios-tracker"
```

دستور `carthage update` را در ترمینال در محل پروژه خود احرا کنید. سپس فایل `MapirLiveTracker.framework` را به پروژه خود اضافه کنید. 

در تارگت اپلیکیشن خود در تب “Build Phases” در تنظیمات تارگت، دکمه “+” را زده و گزینه “New Run Script Phase” را انتخاب کنید، سپس آدرس فرمورک ساحته شده را مانند آنچه که در آموزش زیر گفته شده، به پروژه خود اضافه کنید.
[Carthage Getting started Step 4, 5 and 6](https://github.com/Carthage/Carthage/blob/master/README.md#if-youre-building-for-ios-tvos-or-watchos)

## استفاده

1. کلید دسترسی خود را به فایل Info.plist خود اضافه کنید. به عنوان کلید `MAPIRAccessToken` را وارد کرده کلید دسترسی را به به عنوان مقدار مقابل آن وارد کنید. یا از `initializers` های `Publisher/Subscriber` که آرگومان `APIKey` دارند استفاده کنید.
2. از متد `start(withTrackingIdentifier:)` استفاده کنید و شناسه سفر را به عنوان ورودی وارد کنید.

 برای استفاده از سرویس Live Tracker مپ شما به یک کلید دسترسی احتیاج دارید. اگر تا به حال ثبت نام نکرده اید و کلید دسترسی ندارید، میتوانید [(رایگان شروع کنید)](https://corp.map.ir/registration).
 ابتدا کلید دسترسی خود را به یکی از روش های زیر به پروژه اضافه کنید.
 - __با استفاده از Info.plist:__ یک key-value جدید بسازید. کلید را برابر با `MAPIRAccessToken` قرار دهید. مقدار آنرا نیز برابر با کلید دسترسی خود قرار دهید.
 - __با استفاده از initializer های کلاس:__ از  `Publisher(APIKey:distanceFilter:)` یا `Subscriber(APIKey:)` استفاده کنید و مقدار کلید دسترسی خود را به عنوان ورودی ارسال کنید.

یک پابلیشر برای ارسال اطلاعات محل دستگاه فعلی با یک شناسه سفر بر بستر مپ استفاده میشود. باید دقت کنید که برای هر سفر باید از یک شناسه یکتا استفاده کنید که توسط خود شما قابل شناسایی باشد. هر Publisher میتواند با شناسه خود توسط یک Subscriber با همان شناسه تعقیب شود. شناسه های هر کاربر فقط برای همان کاربر در دسترس است. شناسه های سفر شما با شناسه های سفر سایر کاربران تعارض نخواهت داشت. 

برای استفاده از سرویس تنها نیاز است که یک Publishern یا Subscriber بسازید. برای استفاده های حرفه ای تر میتوانید تنظیمات شبکه خود را وارد کنید.

### Publisher
یک پابلیشر نیاز به دسترسی به سرویس مکان یابی دارد. شما باید دسترسی مورد نیاز SDK را از کار بر بگیرید. "[Requesting Authorization for Location Services](https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services)" را ببینید.

همانطور که گفته شد شما فقط به یک کلید دسترسی و یک شناسه یکتای سفر نیاز خواهید داشت.
```swift

import UIKit
import MapirLiveTracker

let mapirAPIKey: String = <#"your API Key here"#>

class ViewController: UIViewController {

    var publisher: Publisher!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First initialize the Publisher class. you also have to provide a distance filter. 
        // Distance filter is the value that publisher publishes location information whenever
        // the user location changes that amount.
        publisher = Publisher(APIKey: mapirAPIKey, distanceFilter: 30.0)
        
        // Set `self` as delegate for the publisher. In order to do so, `ViewController` must 
        // conform to `PublisherDelegate` protocol. In this case conformance is provided using
        // an extenstion for `ViewController` class.
        publisher.delegate = self
        
        // Create a unique tracking identifier for the commute.
        let trackingIdentifier = "Some unique ID"
        
        // Use the `start` method and provide the tracking identifier.
        publisher.start(withTrackingIdentifier: trackingIdentifier)
    }
}

extension ViewController: PublisherDelegate {

    // This method send the information whenever publisher stops.
    func publisher(_ publisher: Publisher, stoppedWithError error: Error?) {
        print("Publisher Stopped with error: \(error.description ?? "nil")")
    } 
    
    // This method gets called whenever publisher sends the a location info successfully. 
    // You will receive the same `CLLocation` object here.
    func publisher(_ publisher: Publisher, publishedLocation location: CLLocation) {
        let timestampString = "\(location.timestamp.description)"
        let coordinatesString = "(\(location.coordinates.latitude), \(location.coordinate.longitude))"
        print("Last published location is \(coordinatesString) on \(timestampString)")
    }
}
```

### Subscriber
برعکس Publisher، برای یک Subscriber نیازی به دسترسی به سرویس مکانیابی نیست. پس تنهای باید یک کلید دسترسی و یک شناسه یکتای معتبر که یک نفر دیگر در حال ارسال اطلاعات روی آنست، داشته باشید. (طرف مقابل باید از کلید دسترسی یکسان با شما استفاده کند.)

```swift

import UIKit
import MapirLiveTracker

let mapirAPIKey: String = <#"your API Key here"#>

class ViewController: UIViewController {

    var subscriber: Subscriber!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First initialize the Subscriber class.
        subscriber = Publisher(APIKey: mapirAPIKey)
        
        // Set `self` as delegate for the subscriber. In order to do so, `ViewController` must 
        // conform to `SubscriberDelegate` protocol. In this case conformance is provided using
        // an extenstion for `ViewController` class.
        subscriber.delegate = self
        
        // Create a unique tracking identifier for the commute.
        let trackingIdentifier = "Some unique ID"
        
        // Use the `start` method and provide the tracking identifier.
        subscriber.start(withTrackingIdentifier: trackingIdentifier)
    }
}

extension ViewController: SubscriberDelegate {

    // This method send the information whenever publisher stops.
    func subscriber(_ subscriber: Subscriber, stoppedWithError error: Error?) {
        print("Subscriber Stopped with error: \(error.description ?? "nil")")
    } 
    
    // This method gets called whenever subscriber receives a location info of the other user. 
    // You will receive their location info in a `CLLocation` object.
    func publisher(_ subscriber: Subscriber, receivedLocation location: CLLocation) {
        let timestampString = "\(location.timestamp.description)"
        let coordinatesString = "(\(location.coordinates.latitude), \(location.coordinate.longitude))"
        let speedString = "\(Int(location.speed.rounded(.up))) Km/h"
        print("Other user was passing \(coordinatesString) on \(timestampString) with \(speedString) speed.")
    }
}
```

## مشارکت در توسعه
مشتاق هرگونه مشارکت در توسعه پروژه هستیم. 🙌

## مجوز
مجوز این پروژه در فایل LICENSE در دسترس است.

