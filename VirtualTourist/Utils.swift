//
//  Utils.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 2/4/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import Foundation

class Utils {
    
    func checkIfDocsDirIsEmpty() -> Bool {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let path = documentsDirectoryURL.path!
        do {
            let listOfFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
            listOfFiles.map( { print($0) })
            return listOfFiles.isEmpty
        } catch {
            print("Error listing Documents directory files")
            return false
        }
    }
}
