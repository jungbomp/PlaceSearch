//
//  ReviewViewController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/14/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON

class ReviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var noListView: UIView?
    
    @IBOutlet weak var reviewSource: UISegmentedControl!
    @IBOutlet weak var sortCriteria: UISegmentedControl!
    @IBOutlet weak var sortOrder: UISegmentedControl! {
        didSet {
            sortOrder.isEnabled = false
        }
    }
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func reviewSourceSegmentValueChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    @IBAction func onSortCriteriaSegmentedValueChanged(_ sender: UISegmentedControl) {
        sortOrder.isEnabled = (0 != sender.selectedSegmentIndex)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        let label = UILabel(frame: tableView.bounds)
        label.text = "No Reviews"
        label.center = CGPoint(x: view.bounds.width/2.0, y: view.bounds.height/2.0)
        label.textAlignment = NSTextAlignment.center
        
        let noListView = UIView()
        noListView.addConstraints(tableView.constraints)
        noListView.addSubview(label)
        noListView.isHidden = true
        
        self.noListView = noListView
        view.addSubview(noListView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentReview = reviewSource.titleForSegment(at: reviewSource.selectedSegmentIndex) {
            if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
                if let selectedReviews = placeDetail.reviews[currentReview] {
                    if 0 < selectedReviews.count {
                        noListView?.isHidden = true
                        tableView.isHidden = false
                    } else {
                        noListView?.isHidden = false
                        tableView.isHidden = true
                    }
                    
                    return selectedReviews.count
                }
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reviewCell", for: indexPath)
        
        if let reviewCell = cell as? ReviewTableViewCell {
            guard let currentReview = reviewSource.titleForSegment(at: reviewSource.selectedSegmentIndex) else { return cell }
            guard let currentSortCriterion = sortCriteria.titleForSegment(at: sortCriteria.selectedSegmentIndex) else { return cell }
            guard let currentSortOrder = sortOrder.titleForSegment(at: sortOrder.selectedSegmentIndex) else { return cell }
            if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
                if let selectedReviews = placeDetail.reviews[currentReview] {
                    let sortFunc = ["Default": { (lhs: ReviewItem, rhs: ReviewItem) -> Bool in return lhs.orderNum < rhs.orderNum },
                                    "Rating": { (lhs: ReviewItem, rhs: ReviewItem) -> Bool in return lhs.rating < rhs.rating },
                                    "Date": { (lhs: ReviewItem, rhs: ReviewItem) -> Bool in return lhs.time < rhs.time }]
                    
                    let sortedList = selectedReviews.sorted(by: sortFunc[currentSortCriterion]!)
                    if ("Ascending" == currentSortOrder) {
                        reviewCell.setReviewCell(reviewItem: sortedList[indexPath.row])
                    } else {
                        reviewCell.setReviewCell(reviewItem: (sortedList.reversed())[indexPath.row])
                    }
                }
            }
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let currentReview = reviewSource.titleForSegment(at: reviewSource.selectedSegmentIndex) else { return }
        guard let currentSortCriterion = sortCriteria.titleForSegment(at: sortCriteria.selectedSegmentIndex) else { return }
        guard let currentSortOrder = sortOrder.titleForSegment(at: sortOrder.selectedSegmentIndex) else { return }
        if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
            if let selectedReviews = placeDetail.reviews[currentReview] {
                let sortFunc = ["Default": { (lhs: ReviewItem, rhs: ReviewItem) -> Bool in return lhs.orderNum < rhs.orderNum },
                                "Rating": { (lhs: ReviewItem, rhs: ReviewItem) -> Bool in return lhs.rating < rhs.rating },
                                "Date": { (lhs: ReviewItem, rhs: ReviewItem) -> Bool in return lhs.time < rhs.time }]
                
                let sortedList = selectedReviews.sorted(by: sortFunc[currentSortCriterion]!)
                let urlString = ("Ascending" == currentSortOrder ? sortedList : (sortedList.reversed()))[indexPath.row].authorUrl
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
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

}
