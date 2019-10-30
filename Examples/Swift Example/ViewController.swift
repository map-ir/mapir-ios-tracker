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

    var tracker: Publisher!
    var receiver: Subscriber!
    let locationManager = CLLocationManager()

    var sentLocations: [CLLocation] = []
    var receivedLocations: [CLLocation] = []

    var trackingIdentifier = "sample-unique-identifier-test"

    let dateFormatter: DateFormatter = {
        let dateForamtter = DateFormatter()
        dateForamtter.timeZone = TimeZone.current
        dateForamtter.dateFormat = "dd/MM HH:mm:ss.SSS"
        return dateForamtter
    }()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var clearBarButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        receiver = Subscriber(accessToken: token)
        tracker = Publisher(accessToken: token, distanceFilter: 30.0)
        receiver.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }

    @IBAction func clearButtonTapped(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            receivedLocations = []
        } else {
            sentLocations = []
        }
        tableView.reloadData()
    }

    @IBAction func receivingSwitched(_ sender: UISwitch) {
        if sender.isOn {
            receiver.start(withTrackingIdentifier: trackingIdentifier)
        } else {
            receiver.stop()
        }
    }

    @IBAction func publishingSwitched(_ sender: UISwitch) {
        if sender.isOn {
            switch CLLocationManager.authorizationStatus() {
            case .denied, .notDetermined, .restricted:
                locationManager.requestAlwaysAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                tracker = Publisher(accessToken: token, distanceFilter: 10.0)
                tracker.delegate = self
                tracker.start(withTrackingIdentifier: trackingIdentifier)
            @unknown default:
                fatalError()
            }
        } else {
            tracker.stop()
        }
    }
}

extension MainViewController: SubscriberDelegate {
    func subscriber(_ subscriber: Subscriber, locationReceived location: CLLocation) {
        receivedLocations.insert(location, at: 0)
        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        }
    }

    func subscriber(_ subscriber: Subscriber, failedWithError error: Error) {
        print("-- Receiver Error Occured: ", error.localizedDescription)
    }

    func subscriber(_ subscriber: Subscriber, stoppedWithError error: Error?) {
        if let error = error {
            print("-- Recevier Stopped: ", error)
        } else {
            print("-- Recevier Stopped")
        }
    }


}

extension MainViewController: PublisherDelegate {
    func publisher(_ liveTrackerPublisher: Publisher, publishedLocation location: CLLocation) {
        sentLocations.insert(location, at: 0)
        if segmentedControl.selectedSegmentIndex == 1 {
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        }
    }

    func publisher(_ liveTrackerPublisher: Publisher, failedWithError error: Error) {
        print("-- Publisher Error Occured: ", error)
    }

    func publisher(_ liveTrackerPublisher: Publisher, stoppedWithError error: Error?) {
        if let error = error {
            print("-- Publisher Stopped: ", error)
        } else {
            print("-- Publisher Stopped")
        }
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return receivedLocations.count
        } else {
            return sentLocations.count
        }
    }

    func loactionForCurrentSegment(at index: Int) -> CLLocation {
        if segmentedControl.selectedSegmentIndex == 0 {
            return receivedLocations[index]
        } else {
            return sentLocations[index]
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = loactionForCurrentSegment(at: indexPath.row)

        let cell = tableView.dequeueReusableCell(withIdentifier: DataTableViewCell.reuseIdentifier, for: indexPath) as! DataTableViewCell

        cell.coordinatesLabel.text = "\(data.coordinate.latitude), \(data.coordinate.longitude)"
        cell.directionLabel.text = "\(data.course)"
        cell.speedLabel.text = "\(data.speed)"
        cell.timeLabel.text = "\(dateFormatter.string(from: data.timestamp))"

        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func titleForCurrentSegment() -> String {
        if segmentedControl.selectedSegmentIndex == 0 {
            return "Received Locations"
        } else {
            return "Sent Locations"
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForCurrentSegment()
    }
}
