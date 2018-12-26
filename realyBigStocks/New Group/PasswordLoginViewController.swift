//
//  LoginViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 23/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit
import Firebase

class PasswordLoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var warning: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var pswdTextfield: UITextField!
    @IBOutlet weak var switchKeep: UISwitch!
    
    override func viewWillAppear(_ animated: Bool) {
        warning.alpha = 0
        let sw = KeychainWrapper.standard.bool(forKey: "userLogin") ?? false
        switchKeep.setOn(sw, animated: false)
        emailTextField.keyboardType = .emailAddress
        
        
        emailTextField.textContentType = .emailAddress
        pswdTextfield.textContentType = .password
        
        emailTextField.returnKeyType = .continue
        pswdTextfield.returnKeyType = .continue
        
        emailTextField.becomeFirstResponder()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        pswdTextfield.delegate = self
        emailTextField.becomeFirstResponder()
    }

    @IBAction func changeEntrySaving(_ sender: Any) {
        KeychainWrapper.standard.set(switchKeep.isOn, forKey: "userLogin")
        changeSwitch()
    }
    

    @IBAction func login(_ sender: UIButton) {
        userLogin()
    }
    
    @IBAction func register(_ sender: UIButton) {
        userReg()
    }
    
    //MARK: - Service functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.resignFirstResponder()
            pswdTextfield.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    private func userReg() {
        guard let email = emailTextField.text, email != "" else {
            warning.text = "Empty e-mail field!"
            warning.alpha = 1
            return
        }
        guard let password = pswdTextfield.text, password != "" else {
            warning.text = "Empty password field!"
            warning.alpha = 1
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (user, error) in
            if error != nil {
                self?.warning.text = "Cannot create new user!"
                
            }
            if user != nil {
                let userKeepLogin = KeychainWrapper.standard.bool(forKey: "userLogin") ?? false
                if userKeepLogin == true {
                    let uid = user?.user.uid
                    KeychainWrapper.standard.set(uid ?? "", forKey: "uid")
                    KeychainWrapper.standard.set(email, forKey: "userEmail")
                    KeychainWrapper.standard.set(password, forKey: "userPswd")
                }
                self?.performSegue(withIdentifier: "LoginWithPassword", sender: nil)
            }
        }
    }
    
    
    private func changeSwitch() {
        if switchKeep.isOn == false {
            KeychainWrapper.standard.set("", forKey: "userEmail")
            KeychainWrapper.standard.set("", forKey: "userPswd")
            KeychainWrapper.standard.set("", forKey: "uid")
        }
    }
    
    private func userLogin() {
        guard let email = emailTextField.text else {
            warning.text = "Empty e-mail field!"
            warning.alpha = 1
            return
        }
        guard let  password = pswdTextfield.text else {
            warning.text = "Empty password field!"
            warning.alpha = 1
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            if error != nil {
                let userKeepLogin = KeychainWrapper.standard.bool(forKey: "userLogin")
                if userKeepLogin == true {
                    let mail = KeychainWrapper.standard.string(forKey: "userEmail") ?? ""
                    let pswd = KeychainWrapper.standard.string(forKey: "userPswd") ?? ""
                    Auth.auth().signIn(withEmail: mail, password: pswd) { [weak self] (user, error) in
                        if error != nil {
                            self?.warning.text = error?.localizedDescription
                            self?.warning.alpha = 1
                            self?.pswdTextfield.text = ""
                            return
                        }
                        if user != nil {
                            let uid = user?.user.uid ?? ""
                            KeychainWrapper.standard.set(uid, forKey: "uid")
                            self?.performSegue(withIdentifier: "LoginWithPassword", sender: nil)
                            return
                        } else {
                            self?.warning.text = "No user with such e-mail"
                            self?.warning.alpha = 1
                            self?.pswdTextfield.text = ""
                            return
                        }
                    }
                } else {
                    self?.warning.text = error?.localizedDescription
                    self?.warning.alpha = 1
                    self?.pswdTextfield.text = ""
                    return
                }
            }
            
            if user != nil {
                let userKeepLogin = KeychainWrapper.standard.bool(forKey: "userLogin")
                if userKeepLogin == true {
                    KeychainWrapper.standard.set(email, forKey: "userEmail")
                    KeychainWrapper.standard.set(password, forKey: "userPswd")
                    let uid = user?.user.uid ?? ""
                    KeychainWrapper.standard.set(uid, forKey: "uid")
                }
                self?.performSegue(withIdentifier: "LoginWithPassword", sender: nil)
                return
            } else {
                self?.warning.text = "No user with such e-mail"
                self?.warning.alpha = 1
                self?.pswdTextfield.text = ""
                return
            }
        }
    }
}
