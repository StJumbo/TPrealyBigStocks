//
//  CongratsViewController.swift
//  realyBigStocks
//
//  Created by Сергей Грызин on 30/11/2018.
//  Copyright © 2018 Сергей Грызин. All rights reserved.
//

import UIKit

class CongratsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationController?.isNavigationBarHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}
