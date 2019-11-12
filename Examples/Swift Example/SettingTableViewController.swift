//
//  SettingTableViewController.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 21/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let settingUpdatedNofitication = Notification.Name(rawValue: "SettingUpdatedNotification")
}

class SettingTableViewController: UITableViewController {

    var trackingIdentifier: String? = nil
    var distanceFilter: Double? = nil

    @IBOutlet weak var trackingIdentifierTextField: UITextField!
    @IBOutlet weak var distanceFilterTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let trackingIdentifier = trackingIdentifier {
            trackingIdentifierTextField.text = trackingIdentifier
        }

        if let distanceFilter = distanceFilter {
            distanceFilterTextField.text = "\(distanceFilter)"
        }
    }

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let distanceFilterTextFieldValue = Double(distanceFilterTextField.text!) else {
            showError(message: "Distance filter must be a decimal number.")
            return
        }

        var changedSettigns: [String: Any] = [:]

        if trackingIdentifierTextField.text?.lowercased() != trackingIdentifier?.lowercased() {
            changedSettigns["trackingIdentifier"] = trackingIdentifierTextField.text!
        }

        if distanceFilterTextFieldValue != distanceFilter {
            changedSettigns["distanceFilter"] = distanceFilterTextFieldValue
        }

        if !changedSettigns.isEmpty {
            let notification = Notification(name: Notification.Name.settingUpdatedNofitication, object: changedSettigns)
            NotificationCenter.default.post(notification)
        }

        self.dismiss(animated: true)
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Got it", style: .default)
        alert.addAction(okAction)

        self.present(alert, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 || section == 2 {
            return 1
        }

        return 0
    }
}
