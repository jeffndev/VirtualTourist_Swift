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
    
    @IBAction func newCollectionAction(sender: AnyObject) {
        //Clear the data from Core Data, while removing the local file artifacts
        
        //re-fetch photos
        FlickrProvider.sharedInstance.getPhotos(pin, dataContext: sharedContext)
    }
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
    }
    func setNoPhotosUIState(noPhotos: Bool) {
        noImagesLabel.hidden = !noPhotos
        photoCollectionView.hidden = noPhotos
    }
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "photoTitle", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "locationPin == %@", self.pin )
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let pin = pin else {
            setNoPhotosUIState(true)
            return
        }
        if pin.photos.count < 1 {
            setNoPhotosUIState(true)
        } else {
            setNoPhotosUIState(false)
        }
        //
        if pin.photos.isEmpty {
            //go get em...
            print("fetching photos in album view")
            FlickrProvider.sharedInstance.getPhotos(pin, dataContext: sharedContext)
//            let parameters = [FlickrProvider.Keys.LatitudeSearchParameter: pin.latitude,
//                FlickrProvider.Keys.LongitudeSearchParameter: pin.longitude]
//            let task = FlickrProvider.sharedInstance.taskForResource(FlickrProvider.Resources.SearchPhotos, parameters: parameters) { result, error in
//                //TODO: parse the result through a map, attach the pin to each photo
//                if let result = result {
//                    print(result)
//                }
//            }
//            pin.photosTask = task
        } else {
            print("album view, pin HAD photos already")
        }
    }
}

extension PhotoAlbumViewController:  UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        configureCell(cell, photo: photo)
        cell.backgroundColor = UIColor.blackColor()
        return cell
    }
    func configureCell(cell: PhotoAlbumCell, photo: Photo) {
        var photoImage: UIImage!
        cell.imageView!.image = nil
        if photo.remoteImagePath == "" {
            //no image Image
        } else if photo.photoImage != nil {
            photoImage = photo.photoImage
        } else {
            //go git it...
            let _ = FlickrProvider.sharedInstance.taskForImage(photo.remoteImagePath) { data, error in
                if let error = error {
                    print("Poster download error: \(error.localizedDescription)")
                }
                guard let data = data else {
                    print("Empty image data returned from: \(photo.remoteImagePath)")
                    return
                }
                let image = UIImage(data: data)
                photo.photoImage = image
                dispatch_async(dispatch_get_main_queue()) {
                    cell.imageView!.image = image
                }
            }
            //TODO: hook up a task cancelling thing for the cell...
        }
        cell.imageView.image = photoImage
    }
    
}
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
}
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        //TODO: beginUpdates() equivalent for CollectionViews?
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        //TODO: endUpdates() equivalent for CollectionViews
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type){
        case .Insert:
            break
        case .Delete:
            break
        case .Update:
            break
        default:
            break
        }
    }
}