//
//  WalletTableViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 30/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import Firebase
import LocalAuthentication

class WalletTableViewController: UITableViewController {

    private let db = Firestore.firestore()
    
    private var stocks: [WalletStocks] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "Wallet"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 138
        tableView.tableFooterView = UIView(frame: .zero)
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        navigationController?.navigationBar.prefersLargeTitles = true
        
        getWalletAssets()
    }
    
    // MARK: - Service functions
    
    @objc func refresh(sender:AnyObject)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        getWalletAssets()
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    private func getWalletAssets() {
        stocks.removeAll()
        let uid = KeychainWrapper.standard.string(forKey: "uid") ?? ""
        let docRef = self.db.collection("stocks").document("\(uid)").collection("userStocks")
        docRef.getDocuments { (document, error) in
            if let document = document?.documents, document.isEmpty == false {
                for i in document {
                    let company = i.data()
                    var tmp = WalletStocks()
                    tmp.companyName = (company["companyName"] as? String)!
                    tmp.count = (company["count"] as? Int)!
                    tmp.price = (company["buyPrice"] as? Double)!
                    tmp.symbol = (company["symbol"] as? String)!
                    tmp.type = (company["type"] as? String)!
                    tmp.docID = i.documentID
                    tmp.imageURL = (company["imageURL"] as? String)!
                    self.stocks.append(tmp)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    private func bioAuthForSell(for index: Int) {
        DispatchQueue.main.async {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reasonString = "Authentication needs to sell your stocks."
                
                context .evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) -> Void in
                    DispatchQueue.main.async {
                        if success {
                            self.sellAsset(for: index)
                        }
                        else{
                            print(evalPolicyError?.localizedDescription as Any)
                        }
                    }
                })
            } else {
                return
            }
        }
    }
    
    private func sellAsset(for index: Int) {
        print("current index: \(index)")
        for i in 0..<stocks.count {
            print("\(i). current stock: \(stocks[i].docID)")
        }
        let uid = KeychainWrapper.standard.string(forKey: "uid") ?? ""
        self.db.collection("stocks").document("\(uid)").collection("userStocks").document("\(self.stocks[index].docID)").delete { (error) in
            if let error = error {
                print("current error: \(error.localizedDescription)")
            }
        }
        getWalletAssets()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockWallet", for: indexPath)
        
        let name = cell.viewWithTag(1) as? UILabel
        let ticker = cell.viewWithTag(2) as? UILabel
        let price = cell.viewWithTag(3) as? UILabel
        let count = cell.viewWithTag(4) as? UILabel
        let image = cell.viewWithTag(5) as? UIImageView
        
        let index = indexPath.row
        
        let url = stocks[index].imageURL
        image?.loadLogo(for: url)
        
        name?.text = stocks[index].companyName
        ticker?.text = "Ticker: \(stocks[index].symbol)"
        price?.text = "Your price: \(stocks[index].price)$"
        count?.text = "You have: \(stocks[index].count) pieces"

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let index = indexPath.row
        performSegue(withIdentifier: "ShowCurrentStockFromWallet", sender: self.stocks[index])
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if (editingStyle == .delete) {
//            bioAuthForSell(for: indexPath.row)
//
//        }
//    }
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var deleteStyle = UITableViewRowAction.init(style: .default, title: "Sell") { (action, indexPath) in
            self.bioAuthForSell(for: indexPath.row)
        }
        return [deleteStyle]
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCurrentStockFromWallet" {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            let destination = segue.destination as? CurrentPieceFormWalletViewController
            let index = sender as? WalletStocks
            destination?.setCurrStock(from: index!)
        }
    }
}
