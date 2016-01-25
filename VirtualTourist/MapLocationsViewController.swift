//
//  MapLocationsViewController.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/22/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import UIKit
import MapKit

class MapLocationsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
    }
    
    func longPressAction(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let coord: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = coord
        mapView.addAnnotation(newAnnotation)
        
//        let alert = UIAlertController(title: "Long Press Action", message: "You pressed on map", preferredStyle: .Alert)
//        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
//        alert.addAction(okAction)
//        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tempToAlbum(sender: AnyObject) {
        
        let albumController = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
        let newBackNavBtn = UIBarButtonItem()
        newBackNavBtn.title = "OK"
        navigationItem.backBarButtonItem = newBackNavBtn
        navigationController?.pushViewController(albumController, animated: true)
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

extension MapLocationsViewController: MKMapViewDelegate {
    
    
    
    
    
    
}