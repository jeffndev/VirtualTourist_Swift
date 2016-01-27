//
//  FlickrProvider-Constants.swift
//  VirtualTourist
//
//  Created by Jeff Newell on 1/27/16.
//  Copyright © 2016 Jeff Newell. All rights reserved.
//

import Foundation

extension FlickrProvider {
    
    struct Constants {
        // MARK: - URLs
        static let ApiKey = "1c4a20853c41e65187fe1ac23eb85538"
        static let BaseUrl = "http://api.flickr.com/services/rest/"
        static let BaseUrlSSL = "https://api.flickr.com/services/rest/"
    }
    
    struct Resources {
        static let SearchPhotos = "flickr.photos.search"
    }
    
    struct Keys {
        static let ErrorStatusMessage = "error" //TODO: find the real one, this is just a guess
        static let MethodParameterForResource = "method"
        static let ApiKeyParameter = "api_key"
        static let LatitudeSearchParameter = "lat"
        static let LongitudeSearchParameter = "lon"
        static let SafeSearchParameter = "safe_search"
        static let ExtrasParameter = "extras"
        static let DataFormatParameter = "format"
        static let NoJSONCallbackParameter = "nojsoncallback"
    }
}