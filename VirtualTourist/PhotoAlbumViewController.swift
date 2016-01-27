//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/22/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    private let cellReuseIdentifier = "AlbumCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    var pin: Pin!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    func setNoPhotosUIState(noPhotos: Bool) {
        noImagesLabel.hidden = !noPhotos
        photoCollectionView.hidden = noPhotos
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
        //
        if pin.photos == nil || pin.photos!.isEmpty {
            //go get em...
            let parameters = [FlickrProvider.Keys.LatitudeSearchParameter: pin.latitude,
                FlickrProvider.Keys.LongitudeSearchParameter: pin.longitude]
            let task = FlickrProvider.sharedInstance.taskForResource(FlickrProvider.Resources.SearchPhotos, parameters: parameters) { result, error in
                //TODO: parse the result through a map, attach the pin to each photo
                print(result)
            }
        }
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
