//
//  ResultViewController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/15/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import GooglePlaces
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import SwiftSpinner
import EasyToast

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var results: [NearbyResult]?
    var currentIndex = 0
    var placeDetail: PlaceDetail?
    var origin: [String: String]?
    
    var noListView: UIView?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var prevBarBtn: UIBarButtonItem! {
        didSet {
            prevBarBtn.isEnabled = false
        }
    }
    
    @IBOutlet weak var nextBarBtn: UIBarButtonItem! {
        didSet {
            if let nextPageToken = results?[currentIndex].next_page_token {
                if "" == nextPageToken {
                    nextBarBtn.isEnabled = false
                } else {
                    nextBarBtn.isEnabled = true
                }
            } else {
                nextBarBtn.isEnabled = false
            }
        }
    }
    
    @IBAction func prevBarBtnAction(_ sender: UIBarButtonItem) {
        if 0 < currentIndex {
            currentIndex -= 1
            prevBarBtn.isEnabled = (0 < currentIndex)
            nextBarBtn.isEnabled = true
            tableView.reloadData()
        }
    }
    
    @IBAction func nextBarBtnAction(_ sender: UIBarButtonItem) {
        
        if let nearByResults = results {
            if (currentIndex+1) < nearByResults.count {
                currentIndex += 1
                nextBarBtn.isEnabled = ("" != nearByResults[currentIndex].next_page_token)
                prevBarBtn.isEnabled = true
                tableView.reloadData()
            } else {
                guard let rootView = UIApplication.shared.keyWindow?.rootViewController as?  RootViewController else {
                    view.showToast("Can not retrieve server url", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                    return
                }
                
                SwiftSpinner.show("Loading next page...")
                
                let url = rootView.serverUrl+"/googlemap/nearbyNext?"
                if let pagetoken = results?[currentIndex].next_page_token {
                    Alamofire.request(url, method: .get, parameters: ["pagetoken": pagetoken]).responseJSON { [weak self] response in
                        switch response.result {
                        case .success(let value):
                            print(value)
                            let resultJson = JSON(value)
                            
                            if let delegator = self, let results = resultJson["results"].array {
                                if 0 < results.count {
                                    let nextPageToken = resultJson["next_page_token"].string ?? ""
                                    delegator.nextBarBtn.isEnabled = ("" != nextPageToken)
                                    delegator.prevBarBtn.isEnabled = true
                                    
                                    var nearbyItems = [NearbyItem]()
                                    for result in results {
                                        let nearbyItem = NearbyItem(placeid: result["place_id"].string ?? "",
                                                                    icon: result["icon"].string ?? "",
                                                                    name: result["name"].string ?? "",
                                                                    vicinity: result["vicinity"].string ?? "")
                                        nearbyItems.append(nearbyItem)
                                    }
                                    
                                    let nearbyResult = NearbyResult(results: nearbyItems, next_page_token: nextPageToken)
                                    delegator.results!.append(nearbyResult)
                                    delegator.currentIndex += 1
                                    
                                    delegator.tableView.reloadData()
                                }
                                SwiftSpinner.hide()
                            }
                        case .failure(let error):
                            print(error)
                            SwiftSpinner.hide()
                            if let delegator = self {
                                delegator.view.showToast(error.localizedDescription, tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        let label = UILabel(frame: tableView.bounds)
        label.text = "No Results"
        label.center = CGPoint(x: view.bounds.width/2.0, y: view.bounds.height/2.0)
        label.textAlignment = NSTextAlignment.center
        
        let noListView = UIView()
        noListView.addConstraints(tableView.constraints)
        noListView.addSubview(label)
        noListView.isHidden = (0 < results![currentIndex].results.count)
        tableView.isHidden = !(0 < results![currentIndex].results.count)
        
        self.noListView = noListView
        view.addSubview(noListView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = results?[currentIndex].results.count {
            return count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        
        if let resultCell = cell as? ResultTableViewCell {
            // Configure the cell...
            if let nearbyItem = results?[currentIndex].results[indexPath.row] {
                resultCell.iconUrl = nearbyItem.icon
                resultCell.icon.downloadedFrom(url: URL(string: nearbyItem.icon)!)
                resultCell.name.text = nearbyItem.name
                resultCell.vicinity.text = nearbyItem.vicinity
                resultCell.placeid = nearbyItem.placeid
                
                let favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
                if 0 < (favorites.filter { nearbyItem.placeid == $0["placeid"] as? String }).count {
                    resultCell.isFavorite = true
                    resultCell.favoriteBtn.setBackgroundImage(#imageLiteral(resourceName: "favorite-filled"), for: .normal)
                } else {
                    resultCell.isFavorite = false
                    resultCell.favoriteBtn.setBackgroundImage(#imageLiteral(resourceName: "favorite-empty"), for: .normal)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let placeid = results?[currentIndex].results[indexPath.row].placeid {
            guard let rootView = UIApplication.shared.keyWindow?.rootViewController as?  RootViewController else {
                view.showToast("Can not retrieve server url", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                return
            }
            
            SwiftSpinner.show("Fetching place details...")
            
            let url = rootView.serverUrl+"/googlemap/placedetail?"
            Alamofire.request(url, method: .get, parameters: ["placeid" : placeid]).responseJSON { [weak self] response in
                switch response.result {
                case .success(let value):
                    print(value)
                    if let delegator = self {
                        let placeDetailJson = JSON(value)
                        let detail = DetailItem(placeid: placeid,
                                                name: placeDetailJson["name"].stringValue,
                                                addr: placeDetailJson["formatted_address"].stringValue,
                                                phoneNumber: placeDetailJson["international_phone_number"].stringValue,
                                                priceLevel: placeDetailJson["price_level"].stringValue,
                                                rating: placeDetailJson["rating"].stringValue,
                                                website: placeDetailJson["website"].stringValue,
                                                googlePage: placeDetailJson["url"].stringValue,
                                                geometry: (lat: placeDetailJson["geometry"]["location"]["lat"].stringValue,
                                                           lng:placeDetailJson["geometry"]["location"]["lng"].stringValue))
                        
                        var convertedReviews = [ReviewItem]()
                        if let googleReviews = placeDetailJson["reviews"].array {
                            var orderNum = 0
                            for review in googleReviews {
                                orderNum += 1
                                let reviewItem = ReviewItem(orderNum: orderNum,
                                                            authorUrl: review["author_url"].stringValue,
                                                            authorName: review["author_name"].stringValue,
                                                            profilePhotoUrl: review["profile_photo_url"].stringValue,
                                                            rating: review["rating"].floatValue,
                                                            time: review["time"].stringValue,
                                                            comment: review["text"].stringValue)
                                
                                convertedReviews.append(reviewItem)
                            }
                        }
                        
                        var convertedPhotos = [PhotoItem]()
                        if let photos = placeDetailJson["photos"].array {
                            for photo in photos {
                                let photoItem = PhotoItem(photoReference: photo["photo_reference"].stringValue,
                                                          height: photo["height"].intValue,
                                                          width: photo["width"].intValue,
                                                          url: "",
                                                          image: nil)
                                convertedPhotos.append(photoItem)
                            }
                        }
                        
                        delegator.placeDetail = PlaceDetail(detailItem: detail,
                                                            reviews: ["Google Reviews": convertedReviews],
                                                            photos: convertedPhotos)
                        
                        SwiftSpinner.hide()
                        delegator.performSegue(withIdentifier: "showDetails", sender: delegator)
                    }
                    
                case .failure(let error):
                    print(error)
                    SwiftSpinner.hide()
                    if let delegator = self {
                        delegator.view.showToast(error.localizedDescription, tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let destination = segue.destination as? DetailTabBarController {
            if let placeDetail = placeDetail {
                destination.placeDetail = placeDetail
                destination.nearbyItem = results![currentIndex].results[tableView.indexPathForSelectedRow!.row]
                
                do {
                    guard let rootView = UIApplication.shared.keyWindow?.rootViewController as?  RootViewController else {
                        view.showToast("Can not retrieve server url", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                        return
                    }
                    
                    let url = rootView.serverUrl+"/yelpQuery?"
                    var params = ["location": placeDetail.detail.addr,
                                  "term": placeDetail.detail.name]
                    if 0 < placeDetail.detail.phoneNumber.lengthOfBytes(using: .utf16) {
                        let phoneNumber = placeDetail.detail.phoneNumber
                        let regex = try NSRegularExpression(pattern: "[ -]", options: .caseInsensitive)
                        params["phone"] = regex.stringByReplacingMatches(in: phoneNumber, options: [], range: NSRange(0..<phoneNumber.utf16.count), withTemplate: "")
                    }
                        
                    Alamofire.request(url, method: .get, parameters: params).responseJSON { [weak destination] response in
                        switch response.result {
                        case .success(let value):
                            print(value)
                            if let delegator = destination, let yelpReviews = JSON(value)["reviews"].array {
                                let dateFormatter = DateFormatter()
                                dateFormatter.timeZone = TimeZone.current
                                dateFormatter.locale = NSLocale.current
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                
                                var convertedReviews = [ReviewItem]()
                                var orderNum = 0
                                
                                for review in yelpReviews {
                                    orderNum += 1
                                    let reviewItem = ReviewItem(orderNum: orderNum,
                                                                authorUrl: review["url"].stringValue,
                                                                authorName: review["user"]["name"].stringValue,
                                                                profilePhotoUrl: review["user"]["image_url"].stringValue,
                                                                rating: review["rating"].floatValue,
                                                                time: String(dateFormatter.date(from: review["time_created"].stringValue)!.timeIntervalSince1970),
                                                                comment: review["text"].stringValue);
                                    convertedReviews.append(reviewItem)
                                }
                                
                                delegator.placeDetail!.reviews["Yelp Reviews"] = convertedReviews
                            }
                            
                        case .failure(let error):
                            print(error)
                            if let delegator = destination {
                                delegator.view.showToast(error.localizedDescription, tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                            }
                        }
                    }
                } catch {
                    
                }
                
                do {
                    GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeDetail.detail.placeid) { [weak destination] (photos, error) in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        } else {
                            if let photoMetadata = photos?.results {
                                for photoMetadatum in photoMetadata {
                                    GMSPlacesClient.shared().loadPlacePhoto(photoMetadatum) { [weak destination] (photo, error) in
                                        if let error = error {
                                            print("Error: \(error.localizedDescription)")
                                        } else {
                                            if let delegator = destination, let index = photoMetadata.index(of: photoMetadatum) {
                                                delegator.placeDetail!.photos[index].image = photo!
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
