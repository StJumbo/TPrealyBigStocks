//
//  CryptoTableViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 19/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire

class CryptoTableViewController: UITableViewController {

    private var symbolCrypto = ""
    private let sections = ["","Crypto news"]
    private var cryptoNews: [CryptoNews] = []
    private var coinPrice = 0.0
    func setSymbolCrypto(for symbol: String) {
        self.symbolCrypto = symbol.uppercased()
    }
    
    private var coin = Crypto.init(fullName: "", internalName: "", imageUrl: "", url: "", algorithm: "", proofType: "", netHashesPerSecond: 0.0, blockNumber: 0, blockTime: 0, blockReward: 0.0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 420
        tableView.tableFooterView = UIView(frame: .zero)
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        getCryptoInfo()
    }
    
    @IBAction func tapOnButton(sender: UIButton) {
        _ = sender.superview?.superview as! UITableViewCell
        let overview = "https://www.cryptocompare.com\(coin.url!)"
        showWebPage(at: overview, isNews: false)
    }
    
    //MARK: - Service functions
    @objc func refresh(sender:AnyObject)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        getCryptoInfo()
        self.refreshControl?.endRefreshing()
    }
    
    private func getCryptoInfo() {
        Crypto.getCrypto(for: symbolCrypto, completion: {(data) in
            self.coin = data
            let url = "https://min-api.cryptocompare.com/data/price?fsym=\(self.symbolCrypto)&tsyms=USD"
            
            request(url).responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let value):
                    guard let dict = value as? [String: Double] else { return }
                    self.coinPrice = dict["USD"]!
                    self.updateUI()
                    
                case .failure(let error):
                    print(error)
                }
            }
        })
        
        DispatchQueue.global(qos: .userInitiated).async {
            CryptoNews.getCryptoNews { (data) in
                self.cryptoNews = data
                self.updateUI()
            }
        }
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
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

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section{
        case 0:
            return 1
        default:
            return cryptoNews.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoCoin", for: indexPath)
            let pic = cell.viewWithTag(1) as? UIImageView
            let name = cell.viewWithTag(2) as? UILabel
            let internalName = cell.viewWithTag(3) as? UILabel
            let algorithm = cell.viewWithTag(5) as? UILabel
            let proofType = cell.viewWithTag(6) as? UILabel
            let netHashesPerSecond = cell.viewWithTag(7) as? UILabel
            let blockNumber = cell.viewWithTag(8) as? UILabel
            let blockTime = cell.viewWithTag(9) as? UILabel
            let blockReward = cell.viewWithTag(10) as? UILabel
            let price = cell.viewWithTag(11) as? UILabel
            let overview = cell.viewWithTag(4) as? UIButton
            
            let url = "https://www.cryptocompare.com\(coin.imageUrl!)"
            pic?.loadLogo(for: url)
            name?.text = "Coin name: \(coin.fullName ?? "no name")"
            internalName?.text = "Internal exchange name: \(coin.internalName ?? "no internal name")"
            algorithm?.text = "Algorithm: \(coin.algorithm ?? "no algorithm")"
            proofType?.text = "Proof type: \(coin.proofType ?? "no proof type")"
            netHashesPerSecond?.text = "Net hashes per sec: \(coin.netHashesPerSecond ?? 0.0)"
            blockNumber?.text = "Block number: \(coin.blockNumber ?? 0)"
            blockTime?.text = "Block time: \(coin.blockTime ?? 0)"
            blockReward?.text = "Block reward: \(coin.blockReward ?? 0.0)\(coin.internalName!.lowercased())"
            price?.text = "Current price: \(coinPrice)$"
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoNews", for: indexPath)
            let title = cell.viewWithTag(1) as? UILabel
            let source = cell.viewWithTag(2) as? UILabel
            let body = cell.viewWithTag(3) as? UILabel
            let dateLabel = cell.viewWithTag(4) as? UILabel
            
            let index = indexPath.row
            title?.text = cryptoNews[index].title
            let date = Date(timeIntervalSince1970: TimeInterval(cryptoNews[index].date))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy hh:mm"
            let tmp = dateFormatter.string(from: date)
            dateLabel?.text = tmp
            source?.text = "Source: \(cryptoNews[index].source)"
            body?.text = cryptoNews[index].body
            return cell
        }

        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            showWebPage(at: cryptoNews[indexPath.row].url, isNews: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BuySomeCrypto" {
            let url = "https://www.cryptocompare.com\(coin.imageUrl!)"
            let destinationController = segue.destination as? BuyViewController
            destinationController?.setStock(with: coin.fullName!, price: coinPrice, type: "crypto", symbol: self.symbolCrypto, image: url)
        }
    }
}
