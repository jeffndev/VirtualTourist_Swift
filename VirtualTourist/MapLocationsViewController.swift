//
//  MapLocationsViewController.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/22/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapLocationsViewController: UIViewController {
    
    struct MapStateKeys {
        static let CenterLatitude = "center latitude"
        static let CenterLongitude = "center longitude"
        static let SpanLatitudeDelta = "span latitude delta"
        static let SpanLongitudeDelta = "span longitude delta"
    }

    @IBOutlet weak var mapView: MKMapView!
    
    let photoAlbumViewControllerStoryboardID = "PhotoAlbum"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        
        loadMapState()
        
//        Span Code sample:
//        let theSpan:MKCoordinateSpan = MKCoordinateSpanMake(0.01 , 0.01)
//        let location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.612125, longitude: 22.948280)
//        let theRegion:MKCoordinateRegion = MKCoordinateRegionMake(location, theSpan)
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    func loadMapState() {
        guard let lon = NSUserDefaults.standardUserDefaults().valueForKey(MapStateKeys.CenterLongitude) as? Double,
            let lat = NSUserDefaults.standardUserDefaults().valueForKey(MapStateKeys.CenterLatitude) as? Double,
            let latDelta = NSUserDefaults.standardUserDefaults().valueForKey(MapStateKeys.SpanLatitudeDelta) as? Double,
            let lonDelta = NSUserDefaults.standardUserDefaults().valueForKey(MapStateKeys.SpanLongitudeDelta) as? Double else {
            return
        }
        let centerCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        mapView.centerCoordinate = centerCoord
        let theSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        mapView.region = MKCoordinateRegionMake(centerCoord, theSpan)
    }
    
    func saveMapState() {
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.longitude, forKey: MapStateKeys.CenterLongitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.latitude, forKey: MapStateKeys.CenterLatitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: MapStateKeys.SpanLongitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: MapStateKeys.SpanLatitudeDelta)
    }
    
    func longPressAction(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .Ended {
            print("long press received")
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let coord: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = coord
            let dictionary = [Pin.Keys.Latitude: coord.latitude, Pin.Keys.Longitude: coord.longitude]
            let _ = Pin(dictionary: dictionary, context: sharedContext)
            //CoreDataStackManager.sharedInstance.saveContext()
            mapView.addAnnotation(newAnnotation)
        }
    }
    
//    @IBAction func tempToAlbum(sender: AnyObject) {
//        //TODO: DELETE ME...just temporary code
//        let albumController = storyboard?.instantiateViewControllerWithIdentifier(photoAlbumViewControllerStoryboardID) as! PhotoAlbumViewController
//        let newBackNavBtn = UIBarButtonItem()
//        newBackNavBtn.title = "OK"
//        navigationItem.backBarButtonItem = newBackNavBtn
//        navigationController?.pushViewController(albumController, animated: true)
//    }

}

extension MapLocationsViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
//        let alert = UIAlertController(title: "Annotatation tapped", message: "You tapped the pin", preferredStyle: .Alert)
//        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
//        alert.addAction(okAction)
//        self.presentViewController(alert, animated: true, completion: nil)
        
        let albumController = storyboard?.instantiateViewControllerWithIdentifier(photoAlbumViewControllerStoryboardID) as! PhotoAlbumViewController
        guard let clickedPin = view.annotation else {
            return
        }
        //let dictionary = [Pin.Keys.Latitude: clickedPin.coordinate.latitude, Pin.Keys.Longitude: clickedPin.coordinate.longitude]
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let epsilon: Double = 0.0000001
        fetchRequest.predicate = epsilonPredicateString(epsilon, coordinate: clickedPin.coordinate)
        //TODO: this is a mess, so needs to be cleaned up after making it work
        var fetchedPins: [Pin]!
        do {
            fetchedPins = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("no pins returned from fetch after pin tap: \(error.localizedDescription)")
            return
        }
        assert(fetchedPins.count == 1, "Pins fetch should be 1, instead we got: \(fetchedPins.count). Note total pin count: \(mapView.annotations.count)")
        albumController.pin = fetchedPins.first
        
        let newBackNavBtn = UIBarButtonItem()
        newBackNavBtn.title = "OK"
        navigationItem.backBarButtonItem = newBackNavBtn
        navigationController?.pushViewController(albumController, animated: true)
    }
    
    func epsilonPredicateString(epsilon: Double, coordinate: CLLocationCoordinate2D) ->NSPredicate {
        return NSPredicate(format:"latitude > %lf AND latitude < %lf AND longitude > %lf AND longitude < %lf", coordinate.latitude - epsilon,  coordinate.latitude + epsilon, coordinate.longitude - epsilon, coordinate.longitude + epsilon)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapState()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            //pinView!.pinColor = .Red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

extension MapLocationsViewController: NSFetchedResultsControllerDelegate {
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch(type){
        case .Insert:
            if let pin = anObject as? Pin {
                print("Inserting additional pin: lat (\(pin.latitude) lon(\(pin.longitude)))")
                if pin.photos.isEmpty {
                    //go fetch photos...
                    FlickrProvider.sharedInstance.getPhotos(pin, dataContext: sharedContext)
//                    let parameters = [FlickrProvider.Keys.LatitudeSearchParameter: pin.latitude,
//                        FlickrProvider.Keys.LongitudeSearchParameter: pin.longitude]
//                    let task = FlickrProvider.sharedInstance.getPagesTaskForSearch(searchParameters: parameters) { page, error in
//                        guard error == nil else {
//                            print("Error retrieving data page for images: \(error)")
//                            return
//                        }
//                        guard let page = page else {
//                            print("Calculated data page come up empty")
//                            return
//                        }
//                        pin.photosTask = FlickrProvider.sharedInstance.searchForPhotosWithPageTask(page, searchParameters: parameters) { result, error in
//                            guard error == nil else {
//                                print("Error retrieving Photos for location: \(error)")
//                                return
//                            }
//                            guard let photosDictionary = result as? [[String: AnyObject]] else {
//                                print("Photos data came up empty")
//                                return
//                            }
//                            let photos: [Photo] = photosDictionary.map() {
//                                let photo = Photo(dictionary: $0, context: self.sharedContext)
//                                photo.locationPin = pin
//                                return photo
//                            }
//                        }
//                    }
//                    //pin.photosLoading = true
//                    print("fetching photos in map locations view")
//                    pin.photosTask = task
                }
            }
        default:
            break
        }
    }
}