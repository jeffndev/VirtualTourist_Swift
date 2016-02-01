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
    private let sectionInsets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
    private let cellPadding: CGFloat = 3.0
    var pin: Pin!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    @IBAction func newCollectionAction(sender: AnyObject) {
        //Clear the data from Core Data, while removing the local file artifacts
        let photos = fetchedResultsController.fetchedObjects as! [Photo]
        for photo in photos {
            //remove the locale file and cache
            FlickrProvider.Caches.imageCache.deleteImageFile(withIdentifier: photo.photoId)
            sharedContext.deleteObject(photo)
        }
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "screenRotated", name: UIDeviceOrientationDidChangeNotification, object: nil)
        setNoPhotosUIState(pin.photos.isEmpty)
        centerOnPin(pin)
        //
        if pin.photos.isEmpty {
            //go get em...
            print("fetching photos in album view")
            FlickrProvider.sharedInstance.getPhotos(pin, dataContext: sharedContext)
        } else {
            print("album view, pin HAD photos already")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func screenRotated() {
        photoCollectionView.reloadData()
    }
    
    func centerOnPin(pin: Pin) {
        let centerCoord = CLLocationCoordinate2D(latitude: Double(pin.latitude), longitude: Double(pin.longitude))
        mapView.centerCoordinate = centerCoord
        let LAT_DELTA = 0.3
        let LON_DELTA = 0.3
        let theSpan = MKCoordinateSpanMake(LAT_DELTA, LON_DELTA)
        mapView.region = MKCoordinateRegionMake(centerCoord, theSpan)
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = centerCoord
        mapView.addAnnotation(newAnnotation)
    }
}

extension PhotoAlbumViewController:  UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let numItems = fetchedResultsController.fetchedObjects?.count {
            return numItems
        } else {
            return 0
        }
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        configureCell(cell, photo: photo)
        cell.backgroundColor = UIColor.blackColor()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //TODO: remove the object
        print("tapped the cell")
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
        let perRow = CGFloat(UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ? 6.0 : 3.0)
        let sideSize = (collectionView.frame.size.width - 2.0*perRow*(cellPadding + sectionInsets.left))/perRow
        return CGSize(width: sideSize, height: sideSize)
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
        photoCollectionView.reloadData()
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type){
        case .Insert:
//            if let newIndexPath = newIndexPath {
//                photoCollectionView.insertItemsAtIndexPaths([newIndexPath])
//            }
            break
        case .Delete:
//            if let indexPath = indexPath {
//                photoCollectionView.deleteItemsAtIndexPaths([indexPath])
//            }
            break
        case .Update:
            break
        default:
            break
        }
    }
}