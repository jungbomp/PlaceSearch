//
//  MapViewController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/15/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate, CLLocationManagerDelegate {
    
    
    private let locationManager = CLLocationManager()
    private var myLocation: CLLocationCoordinate2D?
    private var destination: CLLocationCoordinate2D?
    private var origin: CLLocationCoordinate2D?
    private var polyline: GMSPolyline?
    private var originMarker: GMSMarker?

    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var travelMode: UISegmentedControl!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBAction func travelModeValueChanged(_ sender: UISegmentedControl) {
        if let ori = origin, let dest = destination, let mode = sender.titleForSegment(at: sender.selectedSegmentIndex)?.lowercased() {
            retriveRoute(origin: ori, destination: dest, mode: mode)
        }
    }
    
    @IBAction func locationEditingDidBegin(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        // Do any additional setup after loading the view.
        if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
            if let lat = Double(placeDetail.detail.geometry.lat), let lng = Double(placeDetail.detail.geometry.lng) {
                let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lng, zoom: 15.0)
                mapView.camera = camera
                destination = camera.target
                showMarker(position: camera.target)
                
                let path = GMSMutablePath()
                path.add(camera.target)
                let polyline = GMSPolyline(path: path)
                polyline.strokeWidth = 5.0
                polyline.geodesic = true
                polyline.strokeColor = .blue
                polyline.map = mapView
                self.polyline = polyline
                
                let marker = GMSMarker(position: camera.target)
                marker.map = mapView
                self.originMarker = marker
            }
        }
        
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
            self.myLocation = location.coordinate
            self.origin = location.coordinate
            
            if let topVC = UIApplication.shared.keyWindow?.rootViewController {
                let children = topVC.childViewControllers
                for child in children {
                    if let view = child as? ResultViewController, let origin = view.origin {
                        if let latitude = origin["latitude"], let longitude = origin["longitude"], let placeName = origin["name"] {
                            self.origin = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!)
                            self.location.text = ("Your location" == placeName ? "" : placeName)
                        }
                    }
                }
            }
        }
    }
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        
        if place.name == "Your Location Lubrication" {
            location.text = "Your Locaton"
            origin = myLocation
        } else {
            if !place.name.isEmpty {
                location.text =  "\(place.name), "
            }
            
            if let formattedAddress = place.formattedAddress {
                location.text?.append(formattedAddress)
            }
            
            origin = place.coordinate
        }
        
        if let ori = origin, let dest = destination, let mode = travelMode.titleForSegment(at: travelMode.selectedSegmentIndex)?.lowercased() {
            retriveRoute(origin: ori, destination: dest, mode: mode)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func showMarker(position: CLLocationCoordinate2D){
        let marker = GMSMarker()
        marker.position = position
        marker.title = ""
        marker.snippet = ""
        marker.map = mapView
    }
    
    private func retriveRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, mode: String) {
        guard let rootView = UIApplication.shared.keyWindow?.rootViewController as?  RootViewController else {
            view.showToast("Can not retrieve server url", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
            return
        }
        
        let url = rootView.serverUrl+"/googlemap/directions?"
        let params = ["origin": "\(destination.latitude),\(destination.longitude)",
            "destination": "\(origin.latitude),\(origin.longitude)",
            "mode": mode]
            
        Alamofire.request(url, method: .get, parameters: params).responseJSON { [weak self] response in
            switch response.result {
            case .success(let value):
//                print(value)
                if let delegator = self {
                    let retJson = JSON(value)
                    
                    if let routes = retJson["routes"].array, let mapView = delegator.mapView, let polyline = delegator.polyline, let marker = delegator.originMarker, let origin = delegator.origin, let dest = delegator.destination {
//                        let bound = GMSCoordinateBounds(coordinate: dest, coordinate: dest)
                        let path = GMSMutablePath()
                        path.add(dest)
                        
                        if let steps = routes.first?["legs"].array?.first?["steps"].array {
                            for step in steps {
                                let lat = step["end_location"]["lat"].doubleValue
                                let lng = step["end_location"]["lng"].doubleValue
                                
                                path.add(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                            }
                            
                            marker.position = origin
                            polyline.path = path
                            mapView.animate(with: GMSCameraUpdate.fit(GMSCoordinateBounds(path: path)))
                        } else {
                            path.add(dest)
                            polyline.path = path
                            mapView.animate(toLocation: dest)
                            mapView.animate(toZoom: 15.0)
                            
                            if let originName = delegator.location.text {
                                delegator.view.showToast("Can not found routes from \(originName)", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                            } else {
                                delegator.view.showToast("Can not found routes", tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                            }
                        }
                        
                        
                    }
                }
                
            case .failure(let error):
                print(error)
                if let delegator = self {
                    delegator.view.showToast(error.localizedDescription, tag: "test", position: .bottom, popTime: 3, dismissOnTap: true)
                }
            }
        }
    }
}
