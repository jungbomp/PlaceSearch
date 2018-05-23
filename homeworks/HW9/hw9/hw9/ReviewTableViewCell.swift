//
//  ReviewTableViewCell.swift
//  hw9
//
//  Created by Jungbom Pak on 4/14/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import Cosmos

class ReviewTableViewCell: UITableViewCell {
    
    var authorUrl: String?
    
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var ratingCosmosView: CosmosView!
    
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var comment: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setReviewCell(reviewItem item: ReviewItem) {
        if let url = URL(string: item.profilePhotoUrl) {
            self.authorImage.downloadedFrom(url: url)
        }
        self.authorName.text = item.authorName
        self.ratingCosmosView.rating = Double(item.rating)
        self.time.text = item.time
        self.comment.text = item.comment
        self.authorUrl = item.authorUrl
        
        let date = Date(timeIntervalSince1970: Double(item.time)!)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.time.text = dateFormatter.string(from: date)
        
//        self.layer.cornerRadius = frame.height / 2
//        authorImage.layer.cornerRadius = authorImage.frame.height / 2
    }
}
