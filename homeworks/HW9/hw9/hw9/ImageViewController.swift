//
//  ImageViewController.swift
//  hw9
//
//  Created by Jungbom Pak on 4/14/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import UIKit
import GooglePlaces

class ImageViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var noListView: UIView?
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        
        let label = UILabel(frame: imageCollectionView.bounds)
        label.text = "No Photos"
        label.center = CGPoint(x: view.bounds.width/2.0, y: view.bounds.height/2.0)
        label.textAlignment = NSTextAlignment.center
        
        let noListView = UIView()
        noListView.addConstraints(imageCollectionView.constraints)
        noListView.addSubview(label)
        noListView.isHidden = true
        
        self.noListView = noListView
        view.addSubview(noListView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
            
            if 0 < placeDetail.photos.count {
                noListView?.isHidden = true
                imageCollectionView.isHidden = false
            } else {
                noListView?.isHidden = false
                imageCollectionView.isHidden = true
            }
            
            return placeDetail.photos.count
        }
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
            if let imageSize = placeDetail.photos[indexPath.row].image?.size {
                let viewSize = imageCollectionView.safeAreaLayoutGuide.layoutFrame.size // 414.0x623.0
//                let ratio = (((viewSize.width-(32)) / imageSize.width) > 1.0 ? 1.0 : (viewSize.width-(32)) / imageSize.width)
                let ratio = (viewSize.width-(32)) / imageSize.width
            
                print("view size is \(viewSize.width)x\(viewSize.height) and image size is \(imageSize.width)x\(imageSize.height)")
                print("horiental ration is \(ratio) and image size is \(imageSize.height*ratio)")
                
                return CGSize(width: imageSize.width*ratio, height: imageSize.height*ratio)
            }
        }
        
        return CGSize(width: 375.0, height: 375.0)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageViewCell", for: indexPath) as UICollectionViewCell
        if let imageViewCell = cell as? ImageCollectionViewCell {
            if let parentView = self.parent as? DetailTabBarController, let placeDetail = parentView.placeDetail {
                imageViewCell.imageCell.image = placeDetail.photos[indexPath.row].image

                if let size = imageCollectionView.layoutAttributesForItem(at: indexPath)?.bounds.size {
                    imageViewCell.frame.size = size
                }
            }
        }
        
        return cell
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
