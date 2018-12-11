//
//  DetailTabBarController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/13/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import SwiftyJSON
import EasyToast

class DetailTabBarController: UITabBarController {
    
    private var info: JSON?
    var placeDetail: PlaceDetail?
    var nearbyItem: NearbyItem?
    
    private let favoriteBtn = UIButton.init(type: UIButtonType.custom)
    private let twitteBtn = UIButton.init(type: UIButtonType.custom)
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
        if let placeid = nearbyItem?.placeid {
            let favoriteItem = favorites.filter { placeid == ($0["placeid"] as? String) }
            let favoriteFilledImg = (0 < favoriteItem.count ? #imageLiteral(resourceName: "favorite-filled") : #imageLiteral(resourceName: "favorite-empty"))
            favoriteBtn.addTarget(self, action: #selector(onTapFavoriteBarBtn), for: UIControlEvents.touchUpInside)
            favoriteBtn.frame = CGRect(x: 0, y: 0, width: 42, height:22)
            favoriteBtn.setImage(favoriteFilledImg.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
            let favoriteBarBtn = UIBarButtonItem(customView: favoriteBtn)
            
            let forwardImg = #imageLiteral(resourceName: "forward-arrow")
            twitteBtn.addTarget(self, action: #selector(onTapTwitteBarBtn), for: UIControlEvents.touchUpInside)
            twitteBtn.frame = CGRect(x: 0, y: 0, width: 42, height:22)
            twitteBtn.setImage(forwardImg.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
            let twitteBarBtn = UIBarButtonItem(customView: twitteBtn)
            
            self.navigationItem.rightBarButtonItems = [favoriteBarBtn, twitteBarBtn]
        }
        
        if let name = placeDetail?.detail.name {
            self.navigationItem.title = name
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.s
    }
    
    @objc func onTapFavoriteBarBtn() {
        var favorites = UserDefaults.standard.object(forKey: "favorites") as? [[String: Any]] ?? [[String: Any]]()
        var favoriteImg: UIImage?
        var toastMessage = ""
        if let nearbyItem = self.nearbyItem {
            let favoriteItem = favorites.filter { nearbyItem.placeid == ($0["placeid"] as? String) }
            if 0 < favoriteItem.count {
                if let index = favorites.index(where: { nearbyItem.placeid == $0["placeid"] as? String }) {
                    favorites.remove(at: index)
                }
                
                favoriteImg = #imageLiteral(resourceName: "favorite-empty")
                toastMessage = "\(String(describing: nearbyItem.name)) was deleted from favorites"
            } else {
                let favoriteItem: [String: Any] = ["placeid": nearbyItem.placeid,
                                             "icon": nearbyItem.icon,
                                             "name": nearbyItem.name,
                                             "vicinity": nearbyItem.vicinity]
            
                favorites.append(favoriteItem)
                favoriteImg = #imageLiteral(resourceName: "favorite-filled")
                toastMessage = "\(String(describing: nearbyItem.name)) was added to favorites"
            }
            
            UserDefaults.standard.set(favorites, forKey: "favorites")
            favoriteBtn.setImage(favoriteImg!.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
            
            if let topVC = UIApplication.shared.keyWindow?.rootViewController {
                let children = topVC.childViewControllers
                for child in children {
                    if let view = child as? MasterViewController {
                        view.tableView.reloadData()
                    } else if let view = child as? ResultViewController {
                        if let cell = view.tableView.cellForRow(at: view.tableView.indexPathForSelectedRow!) as? ResultTableViewCell {
                            cell.favoriteBtn.setBackgroundImage(favoriteImg, for: .normal)
                            cell.isFavorite = (0 < favoriteItem.count)
                        }
                        
                    }
                }
            }
            
            self.view.showToast(toastMessage, tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
        }
    }
    
    @objc func onTapTwitteBarBtn() {
        if let detailItem = self.placeDetail?.detail {
            guard let website = detailItem.website.encodeURIComponent() else { return }
            guard let comment = String("Check out \(detailItem.name) located at \(detailItem.addr). Website:").encodeURIComponent() else {return }
            let urlString = "https://twitter.com/intent/tweet?text=\(comment)&hashtags=TravelAndEntertainmentSearch&url=\(website)"
            
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    
}

extension String {
    func encodeURIComponent() -> String? {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-_.!~*'()")
        return self.addingPercentEncoding(withAllowedCharacters: characterSet)
    }
}
