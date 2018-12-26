//
//  TouchIDViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 24/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import Firebase

class BiometricAuthViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        auth()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("current user: \(KeychainWrapper.standard.string(forKey: "userEmail") ?? "no password") with \(KeychainWrapper.standard.string(forKey: "uid") ?? "no uid")")
    }
    
    //MARK: - Service functions
    
    private func auth() {
        let mail = KeychainWrapper.standard.string(forKey: "userEmail") ?? ""
        let pswd = KeychainWrapper.standard.string(forKey: "userPswd") ?? ""
        Auth.auth().signIn(withEmail: mail, password: pswd) { [weak self] (user, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
                self?.performSegue(withIdentifier: "CantTouchTryPassword", sender: nil)
                return
            }
            if user != nil {
                let uid = user?.user.uid ?? ""
                KeychainWrapper.standard.set(uid, forKey: "uid")
                self?.performSegue(withIdentifier: "LoginWithTouchID", sender: nil)
                return
            } else {
                print("No user with such e-mail")
                self?.performSegue(withIdentifier: "CantTouchTryPassword", sender: nil)
                return
            }
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CantTouchTryPassword" {
            KeychainWrapper.standard.set("", forKey: "userEmail")
            KeychainWrapper.standard.set("", forKey: "userPswd")
            KeychainWrapper.standard.set(false, forKey: "userLogin")
            KeychainWrapper.standard.set("", forKey: "uid")
        }
    }
}



