//
//  BecomePremiumViewController.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 4.01.2019.
//  Copyright © 2019 kostekli. All rights reserved.
//

import UIKit

class BecomePremiumViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
    }
    
    // Setup Navigation Bar
    private func setupNavigationBarItems(){
        let label = UILabel()
        label.textColor = UIColor.black
        label.text = "More";
        label.font = UIFont(name: "Helvetica", size: 20.0)
        
        let attributes = [NSAttributedString.Key.font:  UIFont(name: "Helvetica-Bold", size: 20.0)!, NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationItem.title = label.text
        self.navigationController?.navigationBar.titleTextAttributes = attributes
    }

}


