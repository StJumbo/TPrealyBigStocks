//
//  NewsModel.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 21/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import Foundation

struct News: Codable {
    let datetime: String
    let headline: String
    let source: String
    let url: String
    let summary: String
    
    enum CodingKeys: String, CodingKey {
        case datetime
        case headline
        case source
        case summary
        case url
    }
    
    static func getNews(from page: String, completion:@escaping ([News]) -> ()) {
        let url = URL(string: page)!
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            
            guard let data = data else { return }
            guard let articles = try? JSONDecoder().decode([News].self, from: data) else { return }
            
            completion(articles)
        }.resume()
    }
    
    init(datetime: String, headline: String, source: String, url: String, summary: String) {
        let i = datetime.firstIndex(of: "T")
        let str = datetime.substring(to: i!)
        self.datetime = str
        self.headline = headline
        self.url = url
        self.summary = summary
        self.source = source
    }
}
