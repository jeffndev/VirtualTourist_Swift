//
//  Photo.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/25/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import CoreData

class Photo: NSManagedObject {

    @NSManaged var photoId: NSNumber
    @NSManaged var remoteImagePath: String
    @NSManaged var localImagePath: String?
    @NSManaged var locationPin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        photoId = dictionary["photoID"] as! Int
        remoteImagePath = dictionary["remoteImagePath"] as! String
        localImagePath = dictionary["localImagePath"] as? String
    }
    
}
