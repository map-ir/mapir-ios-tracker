<p align="center">
<img width="200" src="https://corp.map.ir/wp-content/uploads/2019/06/map-site-logo-1.png" alt="Map.ir Logo">
</p>

<p align="center">
   <a href="https://developer.apple.com/swift/">
      <img src="https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat" alt="Swift 5.1">
   </a>
   <!-- 
   <a href="http://cocoapods.org/pods/MapirLiveTracker">
      <img src="https://img.shields.io/cocoapods/v/MapirLiveTracker.svg?style=flat" alt="Version">
   </a>
   -->
   <!--
   <a href="http://cocoapods.org/pods/MapirLiveTracker">
      <img src="https://img.shields.io/cocoapods/p/MapirLiveTracker.svg?style=flat" alt="Platform">
   </a>
   -->
   <a href="https://github.com/Carthage/Carthage">
      <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage Compatible">
   </a>
</p>


# MapirLiveTracker

<p align="center">

</p>

## Features

- Map.ir Live Tracker uses MQTT protocol which has low data usage.
- Easy configuration.
- Complete and expressive documentation.
- You can use both Swift and Objective-C languages. 

## Example

The example applications are the best way to see `MapirLiveTracker` in action. Simply open the `MapirLiveTracker.xcodeproj` and run the `Swift Example` scheme.
There is also an Objective-C Example that is still being developed. 

## Installation

### CocoaPods
This SDK will be available on CocoaPods soon.
<!--
MapirLiveTracker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```bash
pod 'MapirLiveTracker'
```
-->
### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

To integrate MapirLiveTracker into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "map-ir/mapir-ios-tracker"
```

Run `carthage update` to build the framework and drag the built `MapirLiveTracker.framework` into your Xcode project. 

On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase” and add the Framework path as mentioned in [Carthage Getting started Step 4, 5 and 6](https://github.com/Carthage/Carthage/blob/master/README.md#if-youre-building-for-ios-tvos-or-watchos)

## Usage

1. Add your API Key to Info.plist with `MAPIRAccessToken` key or simply use Publisher/Subscriber initializers with accessToken argument.
2. use `start(withTrackingIdentifier:)` and pass in your tracking identifier.

## Contributing
Contributions are very welcome 🙌

## License
License is available in LICENSE file.
