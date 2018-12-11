//
//  FavoriteTableViewCell.swift
//  hw9
//
//  Created by Jungbom Pak on 4/16/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell {

    var placeid: String?
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var vicinity: UILabel!
    @IBOutlet weak var favoriteBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func favoriteBtnTouchUpInside(_ sender: UIButton) {
    }
}
