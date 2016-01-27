//
//  FlickrProvider.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/27/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import Foundation

class FlickrProvider {
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    static let sharedInstance = FlickrProvider()
    
    private var session: NSURLSession {
        return NSURLSession.sharedSession()
    }
    // MARK: - All purpose task method for data
    func taskForResource(resource: String, parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
        var mutableParameters = parameters
        //var mutableResource = resource
        
        //Flickr uses a get parameter to specify the resource, as the "method" parameter
        mutableParameters[FlickrProvider.Keys.MethodParameterForResource] = resource
        // Add in the API Key
        mutableParameters[FlickrProvider.Keys.ApiKeyParameter] = Constants.ApiKey
        
        let EXTRAS = "url_m"
        let SAFE_SEARCH = "1"
        let DATA_FORMAT = "json"
        let NO_JSON_CALLBACK = "1"
        mutableParameters[FlickrProvider.Keys.ExtrasParameter] = EXTRAS
        mutableParameters[FlickrProvider.Keys.SafeSearchParameter] = SAFE_SEARCH
        mutableParameters[FlickrProvider.Keys.DataFormatParameter] = DATA_FORMAT
        mutableParameters[FlickrProvider.Keys.NoJSONCallbackParameter] = NO_JSON_CALLBACK
        
        let urlString = Constants.BaseUrlSSL + resource + FlickrProvider.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        print(url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
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
    
    func taskForImageWithSize(size: String, filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let baseURL = NSURL(string: Constants.BaseUrlSSL)!
        let url = baseURL.URLByAppendingPathComponent(size).URLByAppendingPathComponent(filePath)
        
        print(url)
        
        let request = NSURLRequest(URL: url)
        
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
            
            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult[FlickrProvider.Keys.ErrorStatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "TMDB Error", code: 1, userInfo: userInfo)
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