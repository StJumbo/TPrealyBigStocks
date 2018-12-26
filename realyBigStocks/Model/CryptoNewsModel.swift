//
//  CryptoNewsModel.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 28/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import Foundation
import Alamofire

struct CryptoNews: Codable {
    let title: String
    let url: String
    let source: String
    let body: String
    let date: Int
    
    enum CodingKeys: String, CodingKey {
        case title
        case url
        case source
        case body
        case date = "published_on"
    }
    
    static func getCryptoNews(completion:@escaping ([CryptoNews]) -> ()) {
        let url = "https://min-api.cryptocompare.com/data/v2/news/?lang=EN&api_key=113c2e990b4a2cd147b989e17a116bf63541d103d8596967af7c7c6ce781fd7e"
        request(url).responseJSON { responseJSON in
            
            switch responseJSON.result {
            case .success(let value):
                guard let jsonArray = value as? [String: Any]
                    else {
                        print("current point: can't parse JSON as dictionary")
                        return
                }
                guard let jsonData = jsonArray["Data"] as? [[String: Any]]
                    else {
                        print("current point: can't parse jsonArray as dictionary")
                        return
                }
                let coinInfoAsData = try? JSONSerialization.data(withJSONObject: jsonData, options: [])
                let coin = try? JSONDecoder().decode([CryptoNews].self, from: coinInfoAsData!)
                completion(coin!)
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
}
