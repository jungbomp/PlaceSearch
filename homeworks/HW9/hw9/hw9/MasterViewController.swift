//
//  MasterViewController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/12/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import GooglePlaces
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import SwiftSpinner
import EasyToast

class MasterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var results: NearbyResult?
    var placeDetail: PlaceDetail?
    var origin: [String: String]?
    
    var noListView: UIView?
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var SearchView: UIView!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.isHidden = true
        }
    }
    
    @IBAction func vauleChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            SearchView.isHidden = false
            tableView.isHidden = true
            noListView?.isHidden = true
        case 1:
            SearchView.isHidden = true
            
            let favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
            if 0 < favorites.count {
                tableView.reloadData()
                tableView.isHidden = false
            } else {
                noListView?.isHidden = false
            }
            
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        let label = UILabel(frame: tableView.bounds)
        label.text = "No Favorites"
        label.center = CGPoint(x: view.bounds.width/2.0, y: view.bounds.height/2.0)
        label.textAlignment = NSTextAlignment.center
        
        let noListView = UIView()
        noListView.addConstraints(tableView.constraints)
        noListView.addSubview(label)
        noListView.isHidden = true
        self.noListView = noListView
        view.addSubview(noListView)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
        
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favoriteCell", for: indexPath)
        if let favoriteCell = cell as? FavoriteTableViewCell {
            let favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
            let favoriteItem = favorites[indexPath.row]
            let nearbyItem = NearbyItem(placeid: favoriteItem["placeid"] as! String, icon: favoriteItem["icon"] as! String, name: favoriteItem["name"] as! String, vicinity: favoriteItem["vicinity"] as! String)
            
            favoriteCell.icon.downloadedFrom(url: URL(string: nearbyItem.icon)!)
            favoriteCell.name.text = nearbyItem.name
            favoriteCell.vicinity.text = nearbyItem.vicinity
            favoriteCell.placeid = nearbyItem.placeid
            favoriteCell.favoriteBtn.setBackgroundImage(#imageLiteral(resourceName: "favorite-filled"), for: .normal)
            favoriteCell.favoriteBtn.isEnabled = false
            favoriteCell.favoriteBtn.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
        if let placeid = favorites[indexPath.row]["placeid"] as? String {
            
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
                        delegator.performSegue(withIdentifier: "favoriteDetail", sender: delegator)
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.delete {
            // tableView.reloadData()
            var favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
            favorites.remove(at: indexPath.row)
            UserDefaults.standard.set(favorites, forKey: "favorites")
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            
            if !(0 < favorites.count) {
                tableView.isHidden = true
                noListView?.isHidden = false
            }
        } else {
            
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let destination = segue.destination as? ResultViewController {
            var passData = [NearbyResult]()
            if let item = results {
                passData.append(item)
            }
            
            destination.results = passData
            destination.origin = self.origin
        } else if let destination = segue.destination as? DetailTabBarController {
            if let placeDetail = placeDetail {
                destination.placeDetail = placeDetail
                
                let favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
                let favoriteItem = favorites[tableView.indexPathForSelectedRow!.row]
                let nearbyItem = NearbyItem(placeid: favoriteItem["placeid"] as! String, icon: favoriteItem["icon"] as! String, name: favoriteItem["name"] as! String, vicinity: favoriteItem["vicinity"] as! String)
                
                destination.nearbyItem = nearbyItem
                
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
                                SwiftSpinner.hide()
                                if let delegator = destination {
                                    delegator.view.showToast(error.localizedDescription, tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                                }
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
                                                //                                            attributionText = photoMetadatum.attributions;
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
