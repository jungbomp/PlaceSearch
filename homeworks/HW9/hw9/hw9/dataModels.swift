//
//  dataModels.swift
//  hw9
//
//  Created by Jungbom Pak on 4/13/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import Foundation
import UIKit

struct DetailItem {
    var placeid: String
    var name: String
    var addr: String
    var phoneNumber: String
    var priceLevel: String
    var rating: String
    var website: String
    var googlePage: String
    var geometry: (lat: String, lng: String)
}

struct PhotoItem {
    var photoReference: String
    var height: Int
    var width: Int
    var url: String
    var image: UIImage?
}

struct ReviewItem {
    var orderNum: Int
    var authorUrl: String
    var authorName: String
    var profilePhotoUrl: String
    var rating: Float
    var time: String
    var comment: String
}

struct PlaceDetail {
    var detail: DetailItem
    var reviews: [String: [ReviewItem]]
    var photos: [PhotoItem]
    
    init(detailItem item: DetailItem, reviews: [String: [ReviewItem]], photos: [PhotoItem]) {
        self.detail = item
        self.reviews = reviews
        self.photos = photos
    }
    
    init(detailItem item: DetailItem) {
        self.detail = item
        self.reviews = [String: [ReviewItem]]()
        self.photos = [PhotoItem]()
    }
}


struct NearbyItem {
    var placeid: String
    var icon: String
    var name: String
    var vicinity: String
//    var isFavorite: Bool    
}

struct NearbyResult {
    var results: [NearbyItem]
    var next_page_token: String
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200, let mimeType = response?.mimeType, mimeType.hasPrefix("image"), let data = data, error == nil, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
        }.resume()
    }
    
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
