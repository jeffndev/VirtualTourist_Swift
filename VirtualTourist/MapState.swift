//
//  MapState.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 2/3/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import CoreData
import MapKit

class MapState: NSManagedObject {
    
    struct Keys {
        static let CenterLatitude = "center latitude"
        static let CenterLongitude = "center longitude"
        static let SpanLatitudeDelta = "span latitude delta"
        static let SpanLongitudeDelta = "span longitude delta"
    }
    
    @NSManaged var centerLatitude: NSNumber
    @NSManaged var centerLongitude: NSNumber
    @NSManaged var spanLatitudeDelta: NSNumber
    @NSManaged var spanLongitudeDelta: NSNumber
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("MapState", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        centerLatitude = dictionary[Keys.CenterLatitude] as! CLLocationDegrees
        centerLongitude = dictionary[Keys.CenterLongitude] as! CLLocationDegrees
        spanLatitudeDelta = dictionary[Keys.SpanLatitudeDelta] as! CLLocationDegrees
        spanLongitudeDelta = dictionary[Keys.SpanLongitudeDelta] as! CLLocationDegrees
    }
    
}