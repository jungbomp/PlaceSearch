//
//  ResultTableViewCell.swift
//  hw9
//
//  Created by Jungbom Pak on 4/13/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import EasyToast

class ResultTableViewCell: UITableViewCell {
    
    var placeid: String!
    var iconUrl: String!
    var isFavorite: Bool!

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var vicinity: UILabel!
    @IBOutlet weak var favoriteBtn: UIButton!
    @IBOutlet weak var favorite: UIImageView!
    
    var indexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func favoriteBtnTouchUpInside(_ sender: UIButton) {
        
        let defaults = UserDefaults.standard
        var favorites = defaults.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
        
        if self.isFavorite {
            if let index = favorites.index(where: { placeid == $0["placeid"] as? String }) {
                favorites.remove(at: index)
            }
            self.isFavorite = false
            favoriteBtn.setBackgroundImage(#imageLiteral(resourceName: "favorite-empty"), for: .normal)
            self.cellView.showToast("\(name.text ?? "") was deleted from favorites", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
        } else {
            self.isFavorite = true
            let nearbyItem: [String: Any] = ["placeid": placeid,
                                             "icon": iconUrl,
                                             "name": name.text!,
                                             "vicinity": vicinity.text!]
                              
            favorites.append(nearbyItem)
            favoriteBtn.setBackgroundImage(#imageLiteral(resourceName: "favorite-filled"), for: .normal)
            
            self.cellView.showToast("\(name.text ?? "") was added to favorites", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
        }
        
        UserDefaults.standard.set(favorites, forKey: "favorites")
    }
}
