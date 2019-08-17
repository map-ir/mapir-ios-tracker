//
//  ViewController.swift
//  Example
//
//  Created by Alireza Asadi on 13 Mordad, 1398 AP.
//  Copyright © 1398 Map. All rights reserved.
//

import UIKit
import MapirLiveTracker
import CoreLocation

let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijc4MDMzN2YyYjFlOTZkZjExZjdhY2FhZGI1MzVhNDBjMjA4N2E2MmVkMDFjMmE5MzI4Y2M1ZDE2MDJjODlkMDIzOTEwZDdkY2YxNjQwNTA1In0.eyJhdWQiOiI3MTU3IiwianRpIjoiNzgwMzM3ZjJiMWU5NmRmMTFmN2FjYWFkYjUzNWE0MGMyMDg3YTYyZWQwMWMyYTkzMjhjYzVkMTYwMmM4OWQwMjM5MTBkN2RjZjE2NDA1MDUiLCJpYXQiOjE1NjQyOTI3MzksIm5iZiI6MTU2NDI5MjczOSwiZXhwIjoxNTY2OTcxMTM4LCJzdWIiOiIiLCJzY29wZXMiOlsiYmFzaWMiXX0.Ef9kZ-_jmy8Dcp_Pu1fGlu5RbMZLORUgFFpcSD_dRBfXb232TJldXRFu66pIoiQcLqtFTWFPwx31HXDfruWh0Nt3QsoG9zvxqAi0ILCdioW4aiJVM5jro1euPSQ3ezlDgqzcraAToVjVrvy-5C7CQ9aFVy8PNq-oB9-PIeHsBfqGOYo4xjfsaCEB1_eqst_jWICUs-1fTLzCUyrRv2RsKHfJdhaFbc-3Mim1oQjYah4C8Qa4BFcGDcfYLR_LMu68zUdQSQL1yBZZsfpINVcGpFggP1zbtNbXPEk0Ouf5wlVz0AA2nL8Heu9Owjoc9_gVuPOeMF7qXpBE0d5WXRJjHw"

class MainViewController: UIViewController {

    var tracker: MapirLiveTrackerPublisher!
    var receiver: MapirLiveTrackerReceiver!
    let locationManager = CLLocationManager()

    var sentLocations: [CLLocation] = []
    var receivedLocations: [CLLocation] = []

    var trackingIdentifier = "sample-unique-identifier"

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        receiver = MapirLiveTrackerReceiver(token: token)
        receiver.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func startReceiveButtonTapped(_ sender: UIButton) {
        switch receiver.status {
        case .initiated, .stopped:
            receiver.start(withTrackingIdentifier: trackingIdentifier)
        default:
            receiver.stop()
        }

    }

    @IBAction func startPublishButtonTapped(_ sender: UIButton) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .denied, .notDetermined, .restricted:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            tracker = MapirLiveTrackerPublisher(token: token, distanceFilter: 20.0)
            tracker.delegate = self
            tracker.start(withTrackingIdentifier: trackingIdentifier)
        @unknown default:
            fatalError()
        }
    }
}

extension MainViewController: ReceiverDelegate {
    func receiver(_ liveTrackerReceiver: MapirLiveTrackerReceiver, locationReceived location: CLLocation) {
        receivedLocations.insert(location, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }

    func receiver(_ liveTrackerReceiver: MapirLiveTrackerReceiver, failedWithError error: Error?) {
        print("-- Error Occured: ", error.localizedDescription)
    }


}

extension MainViewController: PublisherDelegate {
    func publisher(_ liveTrackerPublisher: MapirLiveTrackerPublisher, publishedLocation location: CLLocation) {
        
        sentLocations.insert(location, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
    }

    func publisher(_ liveTrackerPublisher: MapirLiveTrackerPublisher, failedWithError error: Error?) {
        print("-- Error Occured: ", error)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return sentLocations.count
        } else if section == 0 {
            return receivedLocations.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var data: CLLocation = CLLocation()
        if indexPath.section == 1 {
            data = sentLocations[indexPath.row]
        } else if indexPath.section == 0 {
            data = receivedLocations[indexPath.row]
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: DataTableViewCell.reuseIdentifier, for: indexPath) as! DataTableViewCell

        cell.coordinatesLabel.text = "\(data.coordinate.latitude), \(data.coordinate.longitude)"
        cell.directionLabel.text = "\(data.course)"
        cell.speedLabel.text = "\(data.speed)"
        cell.timeLabel.text = "\(data.timestamp.description(with: Locale.current))"

        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Sent Locations"
        } else if section == 0 {
            return "Received Locations"
        }
        return nil
    }


}
