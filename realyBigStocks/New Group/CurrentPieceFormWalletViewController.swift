//
//  CurrentPieceFormWalletViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 30/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import LocalAuthentication

class CurrentPieceFormWalletViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var sellButton: UIButton!
    
    private var currStock = WalletStocks()
    private var actualPrice = 0.0
    
    private let db = Firestore.firestore()
    
    func setCurrStock(from stock: WalletStocks) {
        self.currStock.companyName = stock.companyName
        self.currStock.type = stock.type
        self.currStock.price = stock.price
        self.currStock.symbol = stock.symbol
        self.currStock.count = stock.count
        self.currStock.docID = stock.docID
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getActualPrice()
    }
    
    @IBAction func sellButtonPressed(_ sender: Any) {
        bioAuthForSell()
    }
    
    
    
    //MARK: - Service functions
    
    func bioAuthForSell() {
        DispatchQueue.main.async {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reasonString = "Authentication needs to sell your stocks."
                
                context .evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) -> Void in
                    DispatchQueue.main.async {
                        if success {
                            self.sellAsset()
                        }
                        else{
                            print(evalPolicyError?.localizedDescription as Any)
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
            } else {
                return
            }
        }
    }
    
    private func getActualPrice() {
        DispatchQueue.main.async {
            if self.currStock.type == "crypto" {
                let url = "https://min-api.cryptocompare.com/data/price?fsym=\(self.currStock.symbol)&tsyms=USD"
                
                request(url).responseJSON { responseJSON in
                    switch responseJSON.result {
                    case .success(let value):
                        guard let dict = value as? [String: Double] else { return }
                        self.actualPrice = dict["USD"]!
                        self.showMessage(with: self.actualPrice)
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            } else {
                let url = "https://api.iextrading.com/1.0/stock/\(self.currStock.symbol)/quote?filter=latestPrice"
                
                request(url).responseJSON { responseJSON in
                    switch responseJSON.result {
                    case .success(let value):
                        guard let dict = value as? [String: Double] else { return }
                        self.actualPrice = dict["latestPrice"]!
                        self.showMessage(with: self.actualPrice)
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    
    private func sellAsset() {
        DispatchQueue.main.async {
            let uid = KeychainWrapper.standard.string(forKey: "uid") ?? ""
            DispatchQueue.global(qos: .userInteractive).async {
                self.db.collection("stocks").document("\(uid)").collection("userStocks").document("\(self.currStock.docID)").delete { (error) in
                    if let error = error {
                        print("current error: \(error.localizedDescription)")
                    }
                }
            }
            
            self.sellButton.setTitle("Successfully sold!", for: .normal)
            self.sellButton.layer.backgroundColor = UIColor(red: CGFloat(Float(141)/255), green: CGFloat(Float(228)/255), blue: CGFloat(Float(242)/255), alpha: 1).cgColor
            self.sellButton.isEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    private func showMessage(with actualPrice: Double) {
        var tmp = Double(self.currStock.count) * ( actualPrice - self.currStock.price )
        let wholeDifference = Double(round(100 * tmp ) / 100)
        tmp = actualPrice - self.currStock.price
        let oneDifference = Double(round(100 * tmp ) / 100)
        if oneDifference < 0.0 {
            self.resultLabel.text = "You've bought \(self.currStock.companyName) stocks for \(self.currStock.price)$. Now it costs \(actualPrice)$ for one, so you lost \(oneDifference)$ or \(wholeDifference)$ for all stocks you have (\(self.currStock.count) pieces)."
        } else if oneDifference > 0.0 {
            self.resultLabel.text = "You've bought \(self.currStock.companyName) stocks for \(self.currStock.price)$. Now it costs \(actualPrice)$ for one, so you win \(oneDifference)$ or \(wholeDifference)$ for all stocks you have (\(self.currStock.count) pieces)!"
        } else {
            self.resultLabel.text = "You've bought \(self.currStock.companyName) stocks for \(self.currStock.price)$. Now it costs \(actualPrice)$ for one, so you didn't lost anything. However, you didn't win too."
        }
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}
