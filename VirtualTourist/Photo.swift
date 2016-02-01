//
//  Photo.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/25/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//
import UIKit
import CoreData

class Photo: NSManagedObject {
    struct Keys {
        static let PhotoID = "id"
        static let MediumImageRemotePath = "url_m"
        static let Title = "title"
    }

    @NSManaged var photoId: String
    @NSManaged var remoteImagePath: String
    @NSManaged var photoTitle: String
    @NSManaged var locationPin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        photoId = dictionary[Photo.Keys.PhotoID] as! String
        remoteImagePath = (dictionary[Photo.Keys.MediumImageRemotePath] ?? "") as! String
        photoTitle = dictionary[Photo.Keys.Title] as! String
    }
    
    var photoImage: UIImage? {
        get { return FlickrProvider.Caches.imageCache.imageWithIdentifier(photoId) }
        set { FlickrProvider.Caches.imageCache.storeImage(newValue, withIdentifier: photoId) }
    }
}
