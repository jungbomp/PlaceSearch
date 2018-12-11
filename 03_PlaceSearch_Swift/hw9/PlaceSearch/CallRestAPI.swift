//
//  CallRestAPI.swift
//  hw9
//
//  Created by Jungbom Pak on 4/13/18.
//  Copyright © 2018 Jungbom Pak. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON


class CallRestAPI {
    
    init(url: String, actionType: String, params: [String: String], async: Bool) {
        self.url = url
        self.actionType = HTTPMethod.init(rawValue: actionType) ?? .get
        self.params = params
        self.async = async
    }
    
    private var url: String
    private var actionType: HTTPMethod
    private var params: [String: String]
    private var async: Bool
    
    func request() -> JSON {
        var retJSON = JSON(parseJSON: "{RET: \"NONE\"}")
        
        Alamofire.request(self.url, method: .get, parameters: self.params).responseJSON { response in
            switch response.result {
            case .success(let value):
                print(value)
                retJSON = JSON(value)
            case .failure(let error):
                print(error)
            }
        }
        
        return retJSON
    }
}
