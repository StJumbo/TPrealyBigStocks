//
//  NewsTableViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 21/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import SafariServices
import Firebase
import Alamofire

class NewsTableViewController: UITableViewController {
    
    var newsArray: [News] = [] {
        didSet {
            updateUI()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        getNews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 330
        tableView.tableFooterView = UIView(frame: .zero)
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
    }
    
    @IBAction func logOut(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            KeychainWrapper.standard.set("", forKey: "userEmail")
            KeychainWrapper.standard.set("", forKey: "userPswd")
            KeychainWrapper.standard.set(false, forKey: "userLogin")
            KeychainWrapper.standard.set("", forKey: "uid")
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc: UIViewController = storyboard.instantiateViewController(withIdentifier: "PasswordLoginViewController") as UIViewController
            self.present(vc, animated: true, completion: nil)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //MARK: - Service functions
    @objc func refresh(sender:AnyObject)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        getNews()
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func openInSafari(page: String) {
        let url  = URL(string: page)!
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let WebVC = SFSafariViewController.init(url: url, configuration: config)
        self.present(WebVC, animated: true, completion: nil)
    }
    
    private func getNews(){
        let page = "https://api.iextrading.com/1.0/stock/market/news?filter=datetime,headline,source,url,summary"
        News.getNews(from: page, completion: {(data) in
            self.newsArray.removeAll()
            for tmp in data {
                let temp = News.init(datetime: tmp.datetime, headline: tmp.headline, source: tmp.source, url: tmp.url, summary: tmp.summary)
                self.newsArray.append(temp)
            }
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
    }
    
    //MARK: - Tableview Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SomeNews", for: indexPath)
        let headline = cell.viewWithTag(2) as? UILabel
        let date = cell.viewWithTag(3) as? UILabel
        let summ = cell.viewWithTag(20) as? UILabel
        let index = indexPath.row
        
        headline!.text = newsArray[index].headline
        date!.text = "\(newsArray[index].datetime) source: \(newsArray[index].source)"
        summ!.text = newsArray[index].summary
        headline!.font = UIFont.boldSystemFont(ofSize: 21.0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openInSafari(page: newsArray[indexPath.row].url)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

