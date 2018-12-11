//
//  SearchViewController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/12/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

//

import UIKit
import GooglePlaces
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import EasyToast
import McPicker
import SwiftSpinner

class SearchViewController: UIViewController, GMSAutocompleteViewControllerDelegate, CLLocationManagerDelegate {
    
    let picker = UIPickerView()
    
    private let categories = [(key: "Default", value: "default"),
                              (key: "Airport", value: "airport"),
                              (key: "Amusement Park", value: "amusement_park"),
                              (key: "Aquarium", value: "aquarium"),
                              (key: "Art Gallery", value: "art_gallery"),
                              (key: "Bakery", value: "bakery"),
                              (key: "Bar", value: "bar"),
                              (key: "Beauty Salon", value: "beauty_salon"),
                              (key: "Bowling Alley", value: "bowling_alley"),
                              (key: "Bus Station", value: "bus_station"),
                              (key: "Cafe", value: "cafe"),
                              (key: "Campground", value: "campground"),
                              (key: "Car Rental", value: "car_rental"),
                              (key: "Casino", value: "casino"),
                              (key: "Lodging", value: "lodging"),
                              (key: "Movie Theater", value: "movie_theater"),
                              (key: "Museum", value: "museum"),
                              (key: "Night Club", value: "night_club"),
                              (key: "Park", value: "park"),
                              (key: "Parking", value: "parking"),
                              (key: "Restaurant", value: "restaurant"),
                              (key: "Shopping Mall", value: "shopping_mall"),
                              (key: "Stadium", value: "stadium"),
                              (key: "Subway Station", value: "subway_station"),
                              (key: "Taxi Stand", value: "taxi_stand"),
                              (key: "Train Station", value: "train_station"),
                              (key: "Travel Agency", value: "travel_agency"),
                              (key: "Zoo", value: "zoo")]
    
    let locationManager = CLLocationManager()
    var myLocation = CLLocationCoordinate2D(latitude: 34.0223519, longitude: -118.285117)
    var origin = CLLocationCoordinate2D(latitude: 34.0223519, longitude: -118.285117)
    
    
    @IBOutlet weak var keywordTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField! {
        didSet {
            categoryTextField.text = "Default"
        }
    }
    @IBOutlet weak var distanceTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField! {
        didSet {
            locationTextField.text = "Your location"
        }
    }
    
    @IBAction func categoryEditDidBegin(_ sender: UITextField) {
        let pickerData = categories.map { $0.key }
        McPicker.show(data: [pickerData]) {[weak self] (selections: [Int: String]) in
            if let category = selections[0] {
                self?.categoryTextField.text = category
            }
        }
    }
    
    @IBAction func locationEditDidBegin(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func searchClicked(_ sender: UIButton) {
        let keyword = keywordTextField.text ?? ""
        let category = categories.filter { $0.key == categoryTextField.text! }.last!.value
        let distance = distanceTextField.text ?? "10"
        let latitude = String(self.origin.latitude)
        let longitude = String(self.origin.longitude)
        let location = locationTextField.text ?? ""
        
        keywordTextField.resignFirstResponder()
        categoryTextField.resignFirstResponder()
        distanceTextField.resignFirstResponder()
        locationTextField.resignFirstResponder()
        
        if "" == keyword {
            self.view.showToast("Keyword cannot be empty", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
            return
        }

        guard let rootView = UIApplication.shared.keyWindow?.rootViewController as?  RootViewController else {
            view.showToast("Can not retrieve server url", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
            return
        }
        
        SwiftSpinner.show("Searching...")
        
        let url = rootView.serverUrl+"/googlemap/nearby?"
        let params = ["keyword": keyword,
                      "type": category,
                      "radius": distance,
                      "latitude": latitude,
                      "longitude": longitude/*,
                      "addr": location*/]
        
        if !(location.lowercased() == "your location" || location.lowercased() == "my location") {
//            params["from"] = "location"
        }
        
        Alamofire.request(url, method: .get, parameters: params).responseJSON { [weak self] response in
            switch response.result {
            case .success(let value):
                print(value)
                let resultJson = JSON(value)
                
                if let topVC = UIApplication.shared.keyWindow?.rootViewController {
                    let children = topVC.childViewControllers
                    for child in children {
                        if let view = child as? MasterViewController {
                            if let results = resultJson["results"].array {
                                var nearbyItems = [NearbyItem]()
                                for result in results {
                                    let nearbyItem = NearbyItem(placeid: result["place_id"].string ?? "",
                                                                icon: result["icon"].string ?? "",
                                                                name: result["name"].string ?? "",
                                                                vicinity: result["vicinity"].string ?? "")
                                    nearbyItems.append(nearbyItem)
                                }
                                
                                let nextPageToken = resultJson["next_page_token"].string ?? ""
                                let nearbyResult = NearbyResult(results: nearbyItems, next_page_token: nextPageToken)
                                view.results = nearbyResult
                                if let delegator = self {
                                    view.origin = ["latitude": String(delegator.origin.latitude), "longitude": String(delegator.origin.longitude), "name": location]
                                }
                            }
                            
                            SwiftSpinner.hide()
                            view.performSegue(withIdentifier: "searchResults", sender: child)
                            
                        }
                    }
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
    
    @IBAction func clearClicked(_ sender: UIButton) {
        keywordTextField.text = nil
        categoryTextField.text = "Default"
        distanceTextField.text = nil
        locationTextField.text = "Your location"
        origin = myLocation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
            
            self.myLocation = location.coordinate;
            self.origin = location.coordinate
        }
    }
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        
        if place.name == "Your Location Lubrication" {
            locationTextField.text = "Your Locaton"
            self.myLocation = place.coordinate
            self.origin = place.coordinate
        } else {
            if !place.name.isEmpty {
//                locationTextField.text =  "\(place.name), "
                locationTextField.text =  ""
            }
            
            if let formattedAddress = place.formattedAddress {
                locationTextField.text?.append(formattedAddress)
            }
            
            self.origin = place.coordinate
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
