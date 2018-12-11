//
//  DetailViewController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/13/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import Cosmos
import MessageUI

class DetailViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    var detail: JSON?

    @IBOutlet weak var addr: UILabel!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var priceLevel: UILabel!
    @IBOutlet weak var ratingCosmosView: CosmosView!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var website: UILabel!
    @IBOutlet weak var googlePage: UILabel!
    @IBOutlet weak var phone: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
            
            let detail = placeDetail.detail
            
            addr.text = ("" != detail.addr ? detail.addr : "No address")
            
            if "" != detail.phoneNumber {
                phoneNumber.text = detail.phoneNumber
                
                let phoneNumberTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DetailViewController.onPhoneNumberTapEvent))
                phoneNumber.isUserInteractionEnabled = true
                phoneNumber.textColor = self.view.tintColor
                phoneNumber.addGestureRecognizer(phoneNumberTapGestureRecognizer)
                phone.text = phoneNumber.text
            } else {
                phoneNumber.text = "No phone number"
                phone.text = "No phone number"
            }
            
            if "" != detail.priceLevel {
                if let priceLevel = Int(detail.priceLevel) {
                    self.priceLevel.text = { (level) -> String in
                        var priceLevel = ""
                        if 0 < level {
                            for _ in 0..<level {
                                priceLevel += "$"
                            }
                        } else {
                            priceLevel = "Free"
                        }
                        
                        return priceLevel
                    }(priceLevel)
                }
            } else {
                priceLevel.text = "Free"
            }
            
            if let rating = Double(detail.rating) {
                ratingCosmosView.rating = rating
                ratingCosmosView.isHidden = false
                self.rating.isHidden = true
            } else {
                ratingCosmosView.isHidden = true
                self.rating.isHidden = false
                self.rating.text = "No rating"
            }
            
            if "" != detail.website {
                website.text = detail.website
                
                let websiteTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DetailViewController.onUrlTapEvent))
                website.isUserInteractionEnabled = true
                website.textColor = self.view.tintColor
                website.addGestureRecognizer(websiteTapGestureRecognizer)
            } else {
                website.text = "No website"
            }
            
            if "" != detail.googlePage {
                googlePage.text = detail.googlePage
                
                let googlePageTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DetailViewController.onUrlTapEvent))
                googlePage.isUserInteractionEnabled = true
                googlePage.textColor = self.view.tintColor
                googlePage.addGestureRecognizer(googlePageTapGestureRecognizer)
            } else {
                googlePage.text = "No google page"
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func onPhoneNumberTapEvent(sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel, let phoneNumber = label.text {
            if 0 < phoneNumber.lengthOfBytes(using: .utf16) {
                do {
                    let regex = try NSRegularExpression(pattern: "[ -]", options: .caseInsensitive)
                    let urlStr = "tel://\(regex.stringByReplacingMatches(in: phoneNumber, options: [], range: NSRange(0..<phoneNumber.utf16.count), withTemplate: ""))"
                    
                    if let url = URL(string: urlStr) {
                        UIApplication.shared.canOpenURL(url)
                    }
                } catch {
                    print(error)
                    
                }
            }
        }
    }
    
    @objc func onUrlTapEvent(sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel {
            if let urlString = label.text, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
}
