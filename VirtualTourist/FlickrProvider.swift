//
//  FlickrProvider.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/27/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import Foundation
import CoreData

class FlickrProvider {
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    static let sharedInstance = FlickrProvider()
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    private var session: NSURLSession {
        return NSURLSession.sharedSession()
    }
    
    
    func getPhotos(pin: Pin, dataContext: NSManagedObjectContext, completion: (message: String?, error: NSError?) -> Void) {
        let parameters = [FlickrProvider.Keys.LatitudeSearchParameter: pin.latitude,
            FlickrProvider.Keys.LongitudeSearchParameter: pin.longitude]
        getPagesTaskForSearch(searchParameters: parameters) { page, error in
            guard error == nil else {
                print("Error retrieving data page for images: \(error)")
                completion(message: "Error retrieving data page for images: \(error!.localizedDescription)", error: error)
                return
            }
            guard let page = page else {
                print("Calculated data page come up empty")
                completion(message: "Calculated data page come up empty", error: NSError(domain: "Calculated data page come up empty", code: 0, userInfo: nil))
                return
            }
            pin.photoFetchTask = FlickrProvider.sharedInstance.searchForPhotosWithPageTask(page, searchParameters: parameters) { result, error in
                guard error == nil else {
                    print("Error retrieving Photos for location: \(error)")
                    completion(message: "Error retrieving Photos for location: \(error)", error: error!)
                    return
                }
                guard let photosDictionary = result as? [[String: AnyObject]] else {
                    print("Photos data came up empty")
                    completion(message: "Photos data came up empty", error: NSError(domain: "Photos data came up empty", code: 0, userInfo: nil))
                    return
                }
                let photos: [Photo] = photosDictionary.map() {
                    let photo = Photo(dictionary: $0, context: dataContext)
                    photo.locationPin = pin
                    return photo
                }
                print("DATA HAS BEEN RETRIEVED")
                completion(message: "DATA HAS BEEN RETRIEVED: \(photos.count)", error: nil)
            }
        }
        print("fetching photos ...")
    }
    
    
    
    func getPagesTaskForSearch(searchParameters parameters: [String: AnyObject], completion: (page: Int?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        var mutableParameters = parameters
        
        //Flickr uses a get parameter to specify the resource, as the "method" parameter
        mutableParameters[FlickrProvider.Keys.MethodParameterForResource] = FlickrProvider.Resources.SearchPhotos
        
        let EXTRAS_MEDIUM_IMAGE_PATH = "url_m"
        let SAFE_SEARCH = "1"
        let DATA_FORMAT = "json"
        let NO_JSON_CALLBACK = "1"
        let PER_PAGE = 18
        
        mutableParameters[FlickrProvider.Keys.ExtrasParameter] = EXTRAS_MEDIUM_IMAGE_PATH
        mutableParameters[FlickrProvider.Keys.SafeSearchParameter] = SAFE_SEARCH
        mutableParameters[FlickrProvider.Keys.DataFormatParameter] = DATA_FORMAT
        mutableParameters[FlickrProvider.Keys.NoJSONCallbackParameter] = NO_JSON_CALLBACK
        mutableParameters[FlickrProvider.Keys.PerPageParemeter] = PER_PAGE
        
        let task = taskForResource(nil, parameters: mutableParameters) { result, error in
            guard error == nil else {
                completion(page: nil, error: error)
                return
            }
            /*Did Flickr return an error (stat != ok)? */
            guard let stat = result["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(result)")
                return
            }
            //Parse out the initial JSON, and implement retrieval algorithm on the data
            guard let photosInfo = result.valueForKey("photos") as? [String: AnyObject] else {
                let err = NSError(domain: "Cannot parse out photos information in:\n\(result)", code: 0, userInfo: nil)
                completion(page: nil, error: err)
                return
            }
            
            guard let pages = photosInfo["pages"] as? Int where pages > 0 else {
                let err = NSError(domain: "Cannot parse out pages from photos information in:\n\(result)", code: 0, userInfo: nil)
                completion(page: nil, error: err)
                return
            }
            let randomPage = Int(arc4random_uniform(UInt32(pages)) + 1)
            completion(page: randomPage, error: nil)
        }
        return task
    }
    
    func searchForPhotosWithPageTask(page: Int,searchParameters parameters: [String: AnyObject], completion: CompletionHander) -> NSURLSessionDataTask {
        var mutableParameters = parameters
        
        //Flickr uses a get parameter to specify the resource, as the "method" parameter
        mutableParameters[FlickrProvider.Keys.MethodParameterForResource] = FlickrProvider.Resources.SearchPhotos
        
        let EXTRAS_MEDIUM_IMAGE_PATH = "url_m"
        let SAFE_SEARCH = "1"
        let DATA_FORMAT = "json"
        let NO_JSON_CALLBACK = "1"
        let PER_PAGE = 18
        
        mutableParameters[FlickrProvider.Keys.ExtrasParameter] = EXTRAS_MEDIUM_IMAGE_PATH
        mutableParameters[FlickrProvider.Keys.SafeSearchParameter] = SAFE_SEARCH
        mutableParameters[FlickrProvider.Keys.DataFormatParameter] = DATA_FORMAT
        mutableParameters[FlickrProvider.Keys.NoJSONCallbackParameter] = NO_JSON_CALLBACK
        mutableParameters[FlickrProvider.Keys.PerPageParemeter] = PER_PAGE
        mutableParameters[FlickrProvider.Keys.PageNumberParameter] = page
        
        let task = taskForResource(nil, parameters: mutableParameters) { result, error in
            guard error == nil else {
                completion(result: nil, error: error)
                return
            }
            /*Did Flickr return an error (stat != ok)? */
            guard let stat = result["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(result)")
                return
            }
            //Parse out the initial JSON, and implement retrieval algorithm on the data
            guard let photosInfo = result.valueForKey("photos") as? [String: AnyObject] else {
                let err = NSError(domain: "Cannot parse out photos information in:\n\(result)", code: 0, userInfo: nil)
                completion(result: nil, error: err)
                return
            }
            guard let photos = photosInfo["photo"] as? [[String: AnyObject]] else {
                let err = NSError(domain: "Cannot parse out photos array in:\n\(result)", code: 0, userInfo: nil)
                completion(result: nil, error: err)
                return
            }
            completion(result: photos, error: nil)
        }
        
        return task
    }
    
    
    
    // MARK: - All purpose task method for data
    func taskForResource(resource: String?, parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
        var mutableParameters = parameters
        
        // Add in the API Key
        mutableParameters[FlickrProvider.Keys.ApiKeyParameter] = Constants.ApiKey
        
        
        
        let urlString = Constants.BaseUrlSSL + (resource ?? "") + FlickrProvider.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        print(url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                //TODO: need to fix this..
                let newError = FlickrProvider.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                print("Step 3 - taskForResource's completionHandler is invoked.")
                FlickrProvider.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImage(remotePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let baseURL = NSURL(string: remotePath)!
        
        let request = NSURLRequest(URL: baseURL)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = FlickrProvider.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        
        return task
    }
    

    
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        
        for (key, value) in parameters {
            // make sure that it is a string value
            let stringValue = "\(value)"
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            // Append it
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    // Try to make a better error, based on the status_message from Flickr. If we cant then return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            print(parsedResult)
            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult[FlickrProvider.Keys.ErrorStatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
            }
            
        } catch _ {}
        
        return error
    }
    
    // Parsing the JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            print("Step 4 - parseJSONWithCompletionHandler is invoked.")
            completionHandler(result: parsedResult, error: nil)
        }
    }

}