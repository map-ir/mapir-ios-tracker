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
In order to use live tracking services you need to have a Map.ir API Key. If you dont have the key, get one for free on "[App Registration](https://corp.map.ir/registration)".
First add API key to your project, using these options:
- __Using Info.plist:__ Add a pair to the Info.plist. use `MAPIRAccessToken` as key and your API key as value of the pair.
- __Using class initializers:__ Use `Publisher(APIKey:distanceFilter:)` or `Subscriber(APIKey:)` and pass your API key in the first arguement.

A Publisher is used to send location of the current phone using a tracking identifier over the Map.ir Live Tracking service. You have to consider that a tracking idenftier for every commute must be a unique identifier which is identifiable by yourself. Every publishing session with a tracking identifier is trackable using a Subscriber with the same tacking identifer. Every user's tracking identifiers are available to themselves. Your identifiers will not conflict with another user's identifiers.

You only have to initialize a Publisher or a Subscriber to use services. In advanced uses you may provide your own network configuration.

### Publisher
A Publisher needs access to location service. You have to ask users to provide proper permission. See "[Requesting Authorization for Location Services](https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services)".

As said before you need to have an API key and a tracking identifier for a session.
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
Unlike Publisher subscriber doesn't need access to loaction services. So you should only have a API key and a valid tracking identifier which somebody else is publishing to it. (Other person must have the same API key with you.)

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

## Contributing
Contributions are very welcome 🙌

## License
License is available in LICENSE file.
