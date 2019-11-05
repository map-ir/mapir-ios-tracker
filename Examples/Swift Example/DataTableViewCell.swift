//
//  DataTableViewCell.swift
//  Example
//
//  Created by Alireza Asadi on 22/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import UIKit

class DataTableViewCell: UITableViewCell {

    static let reuseIdentifier = "data-cell"

    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        coordinatesLabel.text = ""
        directionLabel.text = ""
        speedLabel.text = ""
        timeLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
