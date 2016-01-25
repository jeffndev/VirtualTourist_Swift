//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/22/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController {

    //var images = [String]()
    var pin: Pin!
    
    @IBOutlet weak var noImagesLabel: UILabel!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //images.append("HI")
        guard let pin = pin else {
            setNoPhotosUIState(true)
            return
        }
        guard let photos = pin.photos else {
            setNoPhotosUIState(true)
            return
        }
        if photos.count < 1 {
            setNoPhotosUIState(true)
        } else {
            setNoPhotosUIState(false)
        }
        // Do any additional setup after loading the view.
        
    }
    func setNoPhotosUIState(noPhotos: Bool) {
        noImagesLabel.hidden = !noPhotos
        photoCollectionView.hidden = noPhotos
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
