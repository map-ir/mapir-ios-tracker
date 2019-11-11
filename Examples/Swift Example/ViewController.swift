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

let mapirAPIKey = "<#Map.ir API Key#>"

class MainViewController: UIViewController {

    var publisher: Publisher!
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

        receiver = Subscriber(apiKey: mapirAPIKey)
        publisher = Publisher(apiKey: mapirAPIKey, distanceFilter: 30.0)
        receiver.delegate = self

        tableView.delegate = self
        tableView.dataSource = self

        switch CLLocationManager.authorizationStatus() {
        case .denied, .notDetermined, .restricted:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            fatalError()
        }
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
            publisher.start(withTrackingIdentifier: trackingIdentifier)
        } else {
            publisher.stop()
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
