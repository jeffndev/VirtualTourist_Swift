//
//  Pin.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/25/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import CoreData

class Pin: NSManagedObject {
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
    
    @NSManaged var longitude: NSNumber //really a Double
    @NSManaged var latitude: NSNumber //really a Double
    @NSManaged var photos: [Photo]?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    init( dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        longitude = dictionary["longitude"] as! Double
        latitude = dictionary["latitude"] as! Double
    }
}
