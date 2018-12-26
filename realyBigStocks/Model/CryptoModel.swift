//
//  CryptoModel.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 28/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import Foundation
import Alamofire

struct Crypto: Codable {
    let fullName: String?
    let internalName: String?
    let imageUrl: String?
    let url: String?
    let algorithm: String?
    let proofType: String?
    let netHashesPerSecond: Double?
    let blockNumber: Int?
    let blockTime: Int?
    let blockReward: Double?
//    let priceUSD: Double?
    
    enum CodingKeys: String, CodingKey {
        case fullName = "FullName"
        case internalName = "Internal"
        case imageUrl = "ImageUrl"
        case url = "Url"
        case algorithm = "Algorithm"
        case proofType = "ProofType"
        case netHashesPerSecond = "NetHashesPerSecond"
        case blockNumber = "BlockNumber"
        case blockTime = "BlockTime"
        case blockReward = "BlockReward"
//        case priceUSD = "PriceUSD"
    }
    
    static func getCrypto(for symbol: String, completion:@escaping (Crypto) -> ()) {
        let url = "https://min-api.cryptocompare.com/data/coin/generalinfo?fsyms=\(symbol)&tsym=USD&api_key=113c2e990b4a2cd147b989e17a116bf63541d103d8596967af7c7c6ce781fd7e"
        request(url).responseJSON { responseJSON in
            
            switch responseJSON.result {
            case .success(let value):
                guard let jsonArray = value as? [String: Any]
                    else {
                        print("current point: can't parse JSON a sdictionary")
                        return
                }
                guard let jsonData = jsonArray["Data"] as? [[String: Any]]
                    else {
                        print("current point: can't parse jsonArray as dictionary")
                        return
                }
                guard let data = jsonData[0] as? [String: Any]
                    else {
                        print("current point: can't parse data as \"coin info\" dictionary")
                        return
                }
                guard let coinInfo = data["CoinInfo"] as? [String: Any]
                    else {
                        print("current point: can't parse coinInfo as coin info")
                        return
                }
                let coinInfoAsData = try? JSONSerialization.data(withJSONObject: coinInfo, options: [])
                let coin = try? JSONDecoder().decode(Crypto.self, from: coinInfoAsData!)
                completion(coin!)
    
            case .failure(let error):
                print(error)
            }
        }
    }
    
    init(fullName: String, internalName: String, imageUrl: String, url: String, algorithm: String, proofType: String, netHashesPerSecond: Double, blockNumber: Int, blockTime: Int, blockReward: Double) {
        self.fullName = fullName
        self.internalName = internalName
        self.imageUrl = imageUrl
        self.url = url
        self.algorithm = algorithm
        self.proofType = proofType
        self.netHashesPerSecond = netHashesPerSecond
        self.blockNumber = blockNumber
        self.blockTime = blockTime
        self.blockReward = blockReward
    }
}
