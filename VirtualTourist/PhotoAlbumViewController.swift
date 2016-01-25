//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/22/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController {

    var images = [String]()
    @IBOutlet weak var noImagesLabel: UILabel!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //images.append("HI")
        if images.count < 1 {
            noImagesLabel.hidden = false
            photoCollectionView.hidden = true
        } else {
            noImagesLabel.hidden = true
            photoCollectionView.hidden = false
        }
        // Do any additional setup after loading the view.
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
