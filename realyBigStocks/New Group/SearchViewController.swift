//
//  ViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 08/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import CoreData

class SearchViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    private enum SearchType: Int {
        case all
        case crypto
    }
    
    @IBOutlet weak var trashButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet var stocksTableView: UITableView!
    
    private let search = UISearchController(searchResultsController: nil)
    
    private var companies: [Symbol] = []
    private var companiesCoreData: [Companies] = []
    private var searchRequest: [Companies] = []
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appDelegate?.persistentContainer.viewContext
        
        let fetchRequest : NSFetchRequest<Companies> = Companies.fetchRequest()
        do {
            self.companiesCoreData = try context?.fetch(fetchRequest) ?? []
        } catch {
            print(error.localizedDescription)
        }
        companiesCoreData.sort(by: {$0.symbol! < $1.symbol!})
        searchRequest = companiesCoreData
        stocksTableView.keyboardDismissMode = .onDrag
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search stocks or crypto"
        search.searchBar.scopeButtonTitles = ["All", "Crypto"]
        search.searchBar.delegate = self
        search.searchBar.enablesReturnKeyAutomatically = true
        search.searchBar.returnKeyType = .search
        tableView.tableFooterView = UIView(frame: .zero)
        
        definesPresentationContext = true
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResults(for: search)
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    @IBAction func clearCoreDataButtonPressed(_ sender: Any) {
        companies.removeAll()
        clearCoreData(for: "Companies")
        tableView.reloadData()
    }
    
    //MARK: - Service functions
    
    @objc func refresh(sender:AnyObject)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        getNewData()
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    internal func updateSearchResults(for searchController: UISearchController) {
        
        let type = searchController.searchBar.selectedScopeButtonIndex
        
        guard let text = searchController.searchBar.text?.uppercased() else { return }
        
        guard let searchType = SearchType(rawValue: type) else { return }
        
        switch searchType {
        case .crypto:
            let tmp = self.companiesCoreData.filter({$0.type!.contains("crypto")})
            searchRequest = tmp.filter({$0.searchString!.contains(text)})
            if text.isEmpty && searchRequest.count == 0 {
                searchRequest = tmp
            }
        default:
            searchRequest = companiesCoreData.filter({$0.searchString!.hasPrefix(text)})
            let tmp = companiesCoreData.filter({$0.searchString!.contains(text)})
            for i in tmp {
                if i.searchString?.hasPrefix(text) == false {
                    searchRequest.append(i)
                }
            }
            if text.isEmpty && searchRequest.count == 0 {
                searchRequest = companiesCoreData
            }
            
        }
        tableView.reloadData()
    }
    
    private func getNewData() {
        Symbol.getSymbols { (json) in
            self.companies.removeAll()
            for comp in json {
                if comp.companyName.count != 0 {
                    let tmp = Symbol.init(symb: comp.symbol, name: comp.companyName, type: comp.type)
                    self.companies.append(tmp)
                }
            }
            
            self.getSymbolsToCompanies(from: self.companies)
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    private func getSymbolsToCompanies(from symbols: [Symbol]) {
        companiesCoreData.removeAll()
        searchRequest.removeAll()
        self.clearCoreData(for: "Companies")
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let context = appDelegate?.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Companies", in: context!)
            
            for i in symbols {
                let companiesObject = NSManagedObject(entity: entity!, insertInto: context) as! Companies
                companiesObject.companyName = i.companyName
                companiesObject.symbol = i.symbol
                companiesObject.type = i.type
                companiesObject.searchString = i.searchString!
                self.companiesCoreData.append(companiesObject)
            }
            self.searchRequest = self.companiesCoreData
            do {
                try context?.save()
            } catch {
                print(error.localizedDescription)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    private func clearCoreData(for entity: String) {
        self.companiesCoreData.removeAll()
        self.searchRequest.removeAll()
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let context = appDelegate?.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            
            let objects = try! context?.fetch(fetchRequest)
            for i in objects! {
                let j = i as? NSManagedObject
                context?.delete(j!)
            }
            do {
                try context?.save()
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    //MARK:  - Tableview Data Source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Company", for: indexPath)
        let companyTitle = cell.viewWithTag(1) as? UILabel
        companyTitle?.text = String(indexPath.row + 1) + ". " + searchRequest[indexPath.row].companyName!
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.searchRequest[indexPath.row].type == "crypto" {
            performSegue(withIdentifier: "ShowCryptoInfo", sender: self.searchRequest[indexPath.row].symbol)
        } else {
            performSegue(withIdentifier: "ShowCompanyInfo", sender: self.searchRequest[indexPath.row].symbol)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchRequest.count
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        if segue.identifier == "ShowCryptoInfo" {
            let destinationController = segue.destination as? CryptoTableViewController
            destinationController?.setSymbolCrypto(for: switchCrypto(for: (sender as? String)!))
            
        }
        
        if segue.identifier == "ShowCompanyInfo" {
            
            let destinationController = segue.destination as? CurrentStockTableViewController
            destinationController?.setSymbolForDownload(sender: sender as? String)
            
        }
    }
    
    func switchCrypto(for symbol: String) -> String{
        switch symbol {
        case "ADAUSDT":
            return "ada"
        case "BCCUSDT":
            return "bch"
        case "BNBUSDT":
            return "bnb"
        case "BTCUSDT":
            return "btc"
        case "EOSUSDT":
            return "eos"
        case "ETCUSDT":
            return "etc"
        case "ETHUSDT":
            return "eth"
        case "ICXUSDT":
            return "icx"
        case "IOTAUSDT":
            return "iot"
        case "LTCUSDT":
            return "ltc"
        case "NEOUSDT":
            return "neo"
        case "ONTUSDT":
            return "ont"
        case "QTUMUSDT":
            return "qtum"
        case "TRXUSDT":
            return "trx"
        case "TUSDUSDT":
            return "tusd"
        case "VENUSDT":
            return "vet"
        case "XLMUSDT":
            return "xlm"
        default:
            return "xrp"
        }
    }
}


