//
//  CurrentStockTableViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 14/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire

class CurrentStockTableViewController: UITableViewController {
    
    
    @IBOutlet var CurrentCompany: UITableView!

    private var newsArray: [News] = []
    private let sections = ["", "Stocks", "News"]
    private var symbolForDownload = ""
    func setSymbolForDownload(sender: String?) {
        self.symbolForDownload = sender!
    }
    private var currCompany = Company(symbol: "", companyName: "", exchange: "", industry: "", website: "", description: "", CEO: "", issueType: "", sector: "", tags: [""])
    private var stock = Stocks(latestTime: "", latestPrice: 0.0, latestSource: "", change: 0.0, iexBidPrice: 0.0, iexBidSize: 0, iexAskPrice: 0.0, iexAskSize: 0, ytdChange: 0.0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
        tableView.tableFooterView = UIView(frame: .zero)
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = "Company info"
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        showInfo()
    }
    
    @IBAction func tapOnButton(sender: UIButton) {
        _ = sender.superview?.superview as! UITableViewCell
        showWebPage(at: currCompany.website, isNews: false)
    }
    
    //MARK: - Service functions
    @objc func refresh(sender:AnyObject)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        showInfo()
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    private func showInfo() {
        DispatchQueue.main.async {
            Company.getCompanyInfo(for: self.symbolForDownload, completion: { (json) in
                self.currCompany = json
                
                if self.currCompany.exchange.isEmpty {
                    self.currCompany.exchange = "no exchange info"
                }
                if self.currCompany.industry.isEmpty {
                    self.currCompany.industry = "no industry info"
                }
                if self.currCompany.sector.isEmpty {
                    self.currCompany.sector = "no sector info"
                }
                if self.currCompany.CEO.isEmpty {
                    self.currCompany.CEO = "no CEO info"
                }
                if self.currCompany.description.isEmpty {
                    self.currCompany.description = "no description"
                }
                if self.currCompany.tags.isEmpty {
                    self.currCompany.tags.append("no tags")
                }
                self.currCompany.issueType = self.issueTypeConvert(for: json.issueType)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            Stocks.getStocksInfo(for: self.symbolForDownload) { (data) in
                self.stock = data
            }
            
            let url = "https://api.iextrading.com/1.0/stock/\(self.symbolForDownload)/news?filter=datetime,headline,source,url,summary"
            News.getNews(from: url, completion: { (data) in
                self.newsArray.removeAll()
                for tmp in data {
                    let temp = News.init(datetime: tmp.datetime, headline: tmp.headline, source: tmp.source, url: tmp.url, summary: tmp.summary)
                    self.newsArray.append(temp)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            })
        }
        
    }
    private func issueTypeConvert(for type: String) -> String{
        switch type {
        case "ad":
            return "American Depository Receipt"
        case "re":
            return "Real Estate Investment Trust"
        case "ce":
            return "Closed end fund"
        case "si":
            return "Secondary Issue "
        case "lp":
            return "Limited Partnerships"
        case "cs":
            return "Common Stock "
        case "et":
            return "Exchange Traded Fund"
        default:
            return "Not Available"
        }
    }
    
    private func showWebPage(at page: String, isNews: Bool) {
        let url  = URL(string: page)!
        let config = SFSafariViewController.Configuration()
        if isNews {
            config.entersReaderIfAvailable = true
        }
        let WebVC = SFSafariViewController.init(url: url, configuration: config)
        self.present(WebVC, animated: true, completion: nil)
    }
    
    //MARK: - TableView data source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cellInfo = tableView.dequeueReusableCell(withIdentifier: "CompanyInfo")
            let image = cellInfo?.viewWithTag(111) as? UIImageView
            let name = cellInfo?.viewWithTag(1) as? UILabel
            let symbol = cellInfo?.viewWithTag(2) as? UILabel
            let exchange = cellInfo?.viewWithTag(3) as? UILabel
            let industry = cellInfo?.viewWithTag(4) as? UILabel
            let sector = cellInfo?.viewWithTag(5) as? UILabel
            let CEO = cellInfo?.viewWithTag(6) as? UILabel
            let website = cellInfo?.viewWithTag(10) as? UIButton
            let issueType = cellInfo?.viewWithTag(7) as? UILabel
            let description = cellInfo?.viewWithTag(8) as? UILabel
            let tags = cellInfo?.viewWithTag(9) as? UILabel
            
            let url = "https://storage.googleapis.com/iex/api/logos/\(self.symbolForDownload).png"
            image?.loadLogo(for: url)
            name!.text = currCompany.companyName
            symbol!.text = "Ticker: \(currCompany.symbol)"
            exchange!.text = "Exchange: \(currCompany.exchange)"
            industry!.text = "Indusrty: \(currCompany.industry)"
            sector!.text = "Sector: \(currCompany.sector)"
            CEO!.text = "CEO: \(currCompany.CEO)"
            
            if currCompany.website.isEmpty == true {
                website?.isEnabled = false
                website?.tintColor = .gray
                website!.setTitle("no website", for: .normal)
            } else {
                website?.isEnabled = true
                website?.tintColor = self.view.tintColor
                website!.setTitle(currCompany.website, for: .normal)
            }
            issueType!.text = "Issue type: \(currCompany.issueType)"
            description!.text = "\(currCompany.description)"
            var tmp = ""
            for i in currCompany.tags {
                if i != currCompany.tags.last {
                    tmp += "\(i)\n"
                } else {
                    tmp += "\(i)"
                }
            }
            tags!.text = tmp
            return cellInfo!
            
        case 1:
            let cellStocks = tableView.dequeueReusableCell(withIdentifier: "CompanyStocks")
            let latestTime = cellStocks?.viewWithTag(11) as? UILabel
            let latesstPrice = cellStocks?.viewWithTag(12) as? UILabel
            let latesstSource = cellStocks?.viewWithTag(13) as? UILabel
            let change = cellStocks?.viewWithTag(14) as? UILabel
            let bidPrice = cellStocks?.viewWithTag(15) as? UILabel
            let bidSize = cellStocks?.viewWithTag(16) as? UILabel
            let askPrice = cellStocks?.viewWithTag(17) as? UILabel
            let askSize = cellStocks?.viewWithTag(18) as? UILabel
            let yearChange = cellStocks?.viewWithTag(19) as? UILabel
            
            latestTime?.text = "Latest time: \(stock.latestTime ?? "no date")"
            latesstPrice?.text = "Latest price: \(stock.latestPrice ?? 0.0)"
            latesstSource?.text = "Latest source: \(stock.latestSource ?? "no source")"
            change?.text = "Change: \(stock.change ?? 0.0)%"
            bidPrice?.text = "IEX bid price: \(stock.iexBidPrice ?? 0.0)"
            bidSize?.text = "IEX bid size: \(stock.iexBidSize ?? 0)"
            askPrice?.text = "IEX ask price: \(stock.iexAskPrice ?? 0.0)"
            askSize?.text = "IEX ask size: \(stock.iexAskSize ?? 0)"
            let changeTmp = Double(round(100000 * (stock.ytdChange ?? 0.0)) / 100000)
            var difference = ""
            if (stock.ytdChange ?? 0.0) > 0.0 {
                difference = "+"
            }
            yearChange?.text = "Current year change: \(difference)\(changeTmp)%"
            return cellStocks!
            
        default:
            let index = indexPath.row
            let cellNews = tableView.dequeueReusableCell(withIdentifier: "CompanyNews")
            let title = cellNews?.viewWithTag(21) as? UILabel
            let date = cellNews?.viewWithTag(22) as? UILabel
            let descr = cellNews?.viewWithTag(23) as? UILabel
            
            title!.text = newsArray[index].headline
            date!.text = "\(newsArray[index].datetime) source: \(newsArray[index].source)"
            descr!.text = newsArray[index].summary
            title!.font = UIFont.boldSystemFont(ofSize: 21.0)
            return cellNews!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            showWebPage(at: newsArray[indexPath.row].url, isNews: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 1
        case 1:
            return 1
        default:
            return newsArray.count
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UITableView.automaticDimension
        case 1:
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BuySomeStocks" {
            let url = "https://storage.googleapis.com/iex/api/logos/\(self.symbolForDownload).png"
            let destinationController = segue.destination as? BuyViewController
            destinationController?.setStock(with: currCompany.companyName, price: stock.latestPrice!, type: "stock", symbol: currCompany.symbol, image: url)
        }
    }
    
}

//MARK: - Extentions

extension UIImageView {
    func loadLogo(for symbol: String) {
        let url = URL(string: symbol)!
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                        self?.layer.cornerRadius = (self?.frame.height ?? 0) / 32
                        self?.layer.masksToBounds = true
                    }
                } else {
                    DispatchQueue.main.async {
                        let imgName = "baseLogo@3x.png"
                        self?.image = UIImage.init(named: imgName)
//                        self?.layer.cornerRadius = (self?.frame.height ?? 0) / 32
                        self?.layer.masksToBounds = true
                    }
                }
            }
        }
    }
}
