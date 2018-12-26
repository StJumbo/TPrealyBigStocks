//
//  WebViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 16/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import Firebase
import LocalAuthentication

class BuyViewController: UIViewController {

    
    @IBOutlet weak var youPayLabel: UILabel!
    @IBOutlet weak var priceForOneLabel: UILabel!
    @IBOutlet weak var wannaBuyTextLabel: UITextField!
    @IBOutlet weak var howMuchLabel: UILabel!
    
    private var name = ""
    private var price = 0.0
    private var type = ""
    private var symbol = ""
    private var imageURL = ""
    func setStock(with name: String, price: Double, type: String, symbol: String, image: String) {
        self.name = name
        self.price = price
        self.type = type
        self.symbol = symbol
        self.imageURL = image
    }
    private var wholePrice = 0.0
    private var buyNumber = 0
    
    let db = Firestore.firestore()
    
    override func viewWillAppear(_ animated: Bool) {
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if type == "cryptocurrency" {
            howMuchLabel.text = "How much coins you want to buy?"
        }
        navigationItem.title = "Buy \(type)"
        priceForOneLabel.text = "Current price for one: \(price)$"
        buyNumber = Int(wannaBuyTextLabel.text ?? "0") ?? 0
        youPayLabel.text = "You'll pay: \(price * Double(buyNumber))$"
        
        wannaBuyTextLabel.becomeFirstResponder()
    }
    
    @IBAction func numberChanged(_ sender: Any) {
        buyNumber = Int(wannaBuyTextLabel.text ?? "0") ?? 0
        let tmp = price * Double(buyNumber)
        wholePrice = Double(round(100 * tmp) / 100 )
        youPayLabel.text = "You'll pay: \(wholePrice)$"
    }
    
    
    @IBAction func confirmPay(_ sender: Any) {
        bioAuthToBuy()
    }
    
    
    
    //MARK: - Service functions
    private func bioAuthToBuy() {
        DispatchQueue.main.async {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reasonString = "Authentication needs to buy your stocks."
                
                context .evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) -> Void in
                    DispatchQueue.main.async {
                        if success {
                            self.buyAsset()
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
    private func buyAsset() {
        performSegue(withIdentifier: "Congrats", sender: nil)
        DispatchQueue.global(qos: .userInteractive).async {
            let uid = KeychainWrapper.standard.string(forKey: "uid") ?? ""
            self.db.collection("stocks").document("\(uid)").collection("userStocks").addDocument(data: [
                "companyName": self.name,
                "symbol": self.symbol,
                "buyPrice": self.price,
                "count": self.buyNumber,
                "type": self.type,
                "imageURL" : self.imageURL
                ],completion: { (error) in
                    if error != nil {
                        print(error?.localizedDescription)
                    }
            })
        }
    }
    

}
