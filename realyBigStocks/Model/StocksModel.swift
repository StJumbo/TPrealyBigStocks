//
//  StocksModel.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 22/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import Foundation

class Stocks: Codable {
    let latestTime: String?
    let latestPrice: Double?
    let latestSource: String?
    let change: Double?
    let iexBidPrice: Double?
    let iexBidSize: Int?
    let iexAskPrice: Double?
    let iexAskSize: Int?
    let ytdChange: Double?
    
    enum CodingKeys: CodingKey{
        case latestTime
        case latestPrice
        case latestSource
        case change
        case iexBidPrice
        case iexBidSize
        case iexAskPrice
        case iexAskSize
        case ytdChange
    }
    
    static func getStocksInfo(for name: String, completion:@escaping (Stocks) -> ()) {
        let url = URL(string: "https://api.iextrading.com/1.0/stock/\(name)/quote?filter=latestTime,latestPrice,latestSource,change,iexBidPrice,iexBidSize,iexAskPrice,iexAskSize,ytdChange")!
        
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let data = data else { return }
            do {
                let tmp = try! JSONDecoder().decode(Stocks.self, from: data)
                completion(tmp)
            }
            
            }.resume()
    }
    init(latestTime: String, latestPrice: Double, latestSource: String, change: Double, iexBidPrice: Double, iexBidSize: Int, iexAskPrice: Double, iexAskSize: Int, ytdChange: Double) {
        self.latestTime = latestTime
        self.latestPrice = latestPrice
        self.latestSource = latestSource
        self.change = change
        self.iexBidPrice = iexBidPrice
        self.iexBidSize = iexBidSize
        self.iexAskPrice = iexAskPrice
        self.iexAskSize = iexAskSize
        self.ytdChange = ytdChange
    }
    
}
