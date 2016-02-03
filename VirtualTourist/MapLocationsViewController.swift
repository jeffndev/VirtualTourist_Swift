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
    
    @IBOutlet weak var mapView: MKMapView!
    
    var mapState: MapState!
    
    let photoAlbumViewControllerStoryboardID = "PhotoAlbum"
    
    //MARK: Lifecycle overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        
        do {
            try fetchedMapStateResultsController.performFetch()
        } catch {}
        fetchedMapStateResultsController.delegate = self
        loadMapState()
        
        do {
            try fetchedPinResultsController.performFetch()
        } catch {}
        fetchedPinResultsController.delegate = self
        loadPins()
    }

    //MARK: Core Data computed properties
    
    lazy var fetchedPinResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
    }()
    
    lazy var fetchedMapStateResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "MapState")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "centerLatitude", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
    }()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    func processPhotosJson(pin: Pin, photosJson: [[String: AnyObject]]?, error: NSError?) {
        if let photosJson = photosJson {
            dispatch_async(dispatch_get_main_queue()) {
                let _: [Photo] = photosJson.map() {
                    let photo = Photo(dictionary: $0, context: self.sharedContext)
                    photo.locationPin = pin
                    return photo
                }
                CoreDataStackManager.sharedInstance.saveContext()
            }
        } else {
            if let error = error {
                print("Error fetching photos from  MapLocations Scene: \(error.localizedDescription)")
            }
        }
    }

}

extension MapLocationsViewController: MKMapViewDelegate {
    func loadPins() {
        let pins = fetchedPinResultsController.fetchedObjects as! [Pin]
        for pin in pins {
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            mapView.addAnnotation(newAnnotation)
        }
    }
    //MARK: map view helpers
    func loadMapState() {
        let states = fetchedMapStateResultsController.fetchedObjects as! [MapState]
        if !states.isEmpty {
            mapState = states.first!
            let lat = mapState.centerLatitude as CLLocationDegrees
            let lon = mapState.centerLongitude as CLLocationDegrees
            let latDelta = mapState.spanLatitudeDelta as CLLocationDegrees
            let lonDelta = mapState.spanLongitudeDelta as CLLocationDegrees
            let centerCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            mapView.centerCoordinate = centerCoord
            let theSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            mapView.region = MKCoordinateRegionMake(centerCoord, theSpan)
        } else {
            let dictionary = [MapState.Keys.CenterLatitude: mapView.centerCoordinate.latitude,
                              MapState.Keys.CenterLongitude: mapView.centerCoordinate.longitude,
                              MapState.Keys.SpanLatitudeDelta: mapView.region.span.latitudeDelta,
                              MapState.Keys.SpanLongitudeDelta: mapView.region.span.longitudeDelta]
            mapState = MapState(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
        }
        
    }
    
    func saveMapState() {
        if let mapState = mapState {
            mapState.centerLatitude = mapView.centerCoordinate.latitude
            mapState.centerLongitude = mapView.centerCoordinate.longitude
            mapState.spanLatitudeDelta = mapView.region.span.latitudeDelta
            mapState.spanLongitudeDelta = mapView.region.span.longitudeDelta
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }
    
    func longPressAction(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            print("long press received")
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let coord: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = coord
            let dictionary = [Pin.Keys.Latitude: coord.latitude, Pin.Keys.Longitude: coord.longitude]
            let _ = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    //MARK: MKMapViewDelegate methods
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        //tap annotation, get Pin from Data, push to Photo Album
        let albumController = storyboard?.instantiateViewControllerWithIdentifier(photoAlbumViewControllerStoryboardID) as! PhotoAlbumViewController
        guard let clickedPin = view.annotation else {
            return
        }
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let epsilon: Double = 0.0000001
        fetchRequest.predicate = epsilonPredicateString(epsilon, coordinate: clickedPin.coordinate)
        var fetchedPins: [Pin]!
        do {
            fetchedPins = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("no pins returned from fetch after pin tap: \(error.localizedDescription)")
            return
        }
        guard fetchedPins.count > 0 else {
            print("Pins fetch should be 1, instead we got: \(fetchedPins.count). Note total pin count: \(mapView.annotations.count)")
            return
        }
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
        //defines the Annotation that gets created on the long tap
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        pinView!.draggable = true
        pinView!.annotation = annotation
        pinView!.canShowCallout = false
        return pinView
    }
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch (newState) {
        case .Starting:
            view.dragState = .Dragging
        case .Ending, .Canceling:
            view.dragState = .None
        default: break
        }
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
                    FlickrProvider.sharedInstance.getPhotos(pin, dataContext: sharedContext) { photosJson, error in
                        self.processPhotosJson(pin, photosJson: photosJson, error: error)                    }
                }
            }
        default:
            break
        }
    }
}