//
//  Symbols.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 08/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import Foundation

struct Symbol: Codable {
    let symbol: String
    let companyName: String
    let type: String
    let searchString: String?
    
    enum CodingKeys: String, CodingKey{
        case symbol
        case companyName = "name"
        case type
        case searchString
    }
    
    static func getSymbols(completion:@escaping ([Symbol]) -> ()) {
        let url = URL(string: "https://api.iextrading.com/1.0/ref-data/symbols?filter=symbol,name,type")!
        
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let data = data else { return }
            
            do {
                let tmp = try! JSONDecoder().decode([Symbol].self, from: data)
                print("downloaded companies: \(tmp.count)")
                completion(tmp)
            }
            
            }.resume()
    }
    
    init(symb: String, name: String, type: String) {
        self.symbol = symb
        self.companyName = name
        self.type = type
        self.searchString = "\(companyName.uppercased()) \(symbol)"
    }
    
}





