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
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!

    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    //MARK: Core Data computed properties
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

    
    // MARK: Lifecycle overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let pin = pin else {
            setNoPhotosUIState(true)
            return
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "screenRotated", name: UIDeviceOrientationDidChangeNotification, object: nil)
        setNoPhotosUIState(fetchedResultsController.fetchedObjects!.isEmpty)
        setImagesLoadingUIState(false)
        centerOnPin(pin)
        if fetchedResultsController.fetchedObjects!.isEmpty {
            //Check if there is already a fetch in progress...
            if pin.photoFetchTask != nil && pin.photoFetchTask!.state == .Running {
                print("Photos fetch in-progress, do not re-fetch, waiting...")
            } else {
                //go get em...
                print("Photos Empty, fetching photos in album view")
                setImagesLoadingUIState(true)
                FlickrProvider.sharedInstance.getPhotos(pin, dataContext: sharedContext) { photosJson, error in
                    self.processPhotosJson(self.pin, photosJson: photosJson, error: error)
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    //MARK: Actions handlers
    
    @IBAction func newCollectionAction(sender: AnyObject) {
        //Clear the data from Core Data, while removing the local file artifacts
        let photos = fetchedResultsController.fetchedObjects as! [Photo]
        for photo in photos {
            //remove the locale file and cache through Photo prepareForDeletion
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance.saveContext()
        //re-fetch photos
        setImagesLoadingUIState(true)
        FlickrProvider.sharedInstance.getPhotos(pin, dataContext: sharedContext) { photosJson, error in
            self.processPhotosJson(self.pin, photosJson: photosJson, error: error)
        }
    }
    
    //MARK: Data helpers
    func processPhotosJson(pin: Pin, photosJson: [[String: AnyObject]]?, error: NSError?) {
        var emptyFetch = false
        if let photosJson = photosJson {
            dispatch_async(dispatch_get_main_queue()) {
                let photos: [Photo] = photosJson.map() {
                    let photo = Photo(dictionary: $0, context: self.sharedContext)
                    photo.locationPin = pin
                    return photo
                }
                if photos.isEmpty {
                    print("Photos json came up EMPTY in FINAL COMPLETION")
                    emptyFetch = true
                }
                CoreDataStackManager.sharedInstance.saveContext()
            }
        } else {
            emptyFetch = true
            print("EMPTY JSON RETURNED")
            if let error = error {
                print("Error fetching photos from PhotoBooth Scene: \(error.localizedDescription)")
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.setImagesLoadingUIState(false)
            if emptyFetch {
                self.emptyFetchAlert()
            }
        }
    }
    func emptyFetchAlert() {
        let alert = UIAlertController(title: "Empty Fetch", message: "No photos retrieved", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    // MARK: UI Helpers
    
    func setNoPhotosUIState(noPhotos: Bool) {
        print("setNoPhotosState: \(noPhotos)")
        noImagesLabel.hidden = !noPhotos
        photoCollectionView.hidden = noPhotos
    }
    func setImagesLoadingUIState(activelyLoading: Bool) {
        print("setImagesLoading: \(activelyLoading)")
        newCollectionButton.enabled = !activelyLoading
        photoCollectionView.alpha = activelyLoading ? 0.5 : 1.0
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

//MARK: CollectionView delegates
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
        cell.backgroundColor = UIColor.whiteColor()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    func configureCell(cell: PhotoAlbumCell, photo: Photo) {
        
        var photoImage = UIImage(named: "photoDownloading")
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
                dispatch_async(dispatch_get_main_queue()) {
                    photo.photoImage = image
                    cell.imageView!.image = image
                }
            }
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

// MARK:  Core Data
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        photoCollectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)

        setNoPhotosUIState(controller.fetchedObjects!.isEmpty)
        setImagesLoadingUIState(false)
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch(type){
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }
}