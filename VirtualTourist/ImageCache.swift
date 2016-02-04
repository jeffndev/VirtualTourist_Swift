//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/27/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//
// ATTRIBUTED TO: Jason Schatz at Udacity (Thanks Jason!)
//

import Foundation
import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retreiving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(identifier!) as? UIImage {
            return image
        }
        
        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    //MARK: - deleting images
    func deleteImageFile(withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        inMemoryCache.removeObjectForKey(identifier)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        }catch let error as NSError {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                print("could not remove existing image file: \(path): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Saving images
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        // If the image is nil, remove images from the cache
        if image == nil {
            inMemoryCache.removeObjectForKey(identifier)
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {}
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: identifier)
        
        // And in documents directory
        let data = UIImagePNGRepresentation(image!)!
        data.writeToFile(path, atomically: true)
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {
        var mutableIdentifier = identifier
        if !identifier.hasSuffix(".jpg") {
            mutableIdentifier = "\(identifier).jpg"
        }
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(mutableIdentifier)
        
        return fullURL.path!
    }
}