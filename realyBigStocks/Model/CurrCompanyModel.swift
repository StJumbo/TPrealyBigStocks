//
//  CurrCompanyModel.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 14/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import Foundation

struct Company: Codable {
    var symbol: String
    var companyName: String
    var exchange: String
    var industry: String
    var website: String
    var description: String
    var CEO: String
    var issueType: String
    var sector: String
    var tags: [String]
    
    enum CodingKeys: String, CodingKey{
        case symbol
        case companyName
        case exchange
        case industry
        case website
        case description
        case CEO
        case issueType
        case sector
        case tags
    }
    
    static func getCompanyInfo(for name: String, completion:@escaping (Company) -> ()) {
        let url = URL(string: "https://api.iextrading.com/1.0/stock/\(name)/company?filter=symbol,companyName,exchange,industry,website,description,CEO,issueType,sector,tags")!
        
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let data = data else { return }
            do {
                let tmp = try! JSONDecoder().decode(Company.self, from: data)
                completion(tmp)
            }
            
        }.resume()
    }
    
    init(symbol: String, companyName: String, exchange: String, industry: String, website: String, description: String, CEO: String, issueType: String, sector: String, tags: [String]) {
        self.symbol = symbol
        self.companyName = companyName
        self.exchange = exchange
        self.industry = industry
        self.website = website
        self.description = description
        self.CEO = CEO
        self.issueType = issueType
        self.sector = sector
        self.tags = tags
    }
}
