//
//  ExpenseTableViewCell.swift
//  Snapet
//
//  Created by Duan Li on 3/28/17.
//  Copyright © 2017 Yang Ding. All rights reserved.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {

    @IBOutlet weak var merchantLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
//    merchantLabel.text = ""
//    categoryLabel.text = ""
//    dateLabel.text = ""
//    amountLabel.text = ""
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
