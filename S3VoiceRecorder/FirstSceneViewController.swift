//
//  FirstSceneViewController.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 28.12.2018.
//  Copyright © 2018 kostekli. All rights reserved.
//

import UIKit

class FirstSceneViewController: UIViewController {
    
    // Open More Button
    var showMoreButton = UIButton()
    
    // Language Selection Buttons
    @IBOutlet weak var SpeechLanguageButton: UIButton!
    
    @IBOutlet weak var ToLanguageButton: UIButton!
    
    @IBOutlet weak var ExchangeLanguageButton: UIButton!
    
    
    // Go Speech and Translate Page Buttons
    @IBOutlet weak var TapButton1: UILabel!
    
    @IBOutlet weak var TapButton2: UIImageView!
    
    //Languages Variables
    var SpeechLanguageName = String()
    var ToLanguageName = String()
    var SpeechLanguageLocale = String()
    var ToLanguageLocale = String()
    
    // Supported Languages Variables
    var languagesName = NSArray()
    var locales = NSArray()
    
    
    // Which button click for select Language
    var isButtonForSpeechLanguage = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Setup Navigation Items
        setupNavigationBarItems()
        
        
        // Parse json for take all supported Languages
        ParseLanguageJson()
        
        // Take last selected Language Option
        SpeechLanguageLocale = UserDefaults.standard.string(forKey: "SpeechLanguageLocale")!
        ToLanguageLocale = UserDefaults.standard.string(forKey: "ToLanguageLocale")!
        
        SpeechLanguageName = UserDefaults.standard.string(forKey: "SpeechLanguageName")!
        ToLanguageName = UserDefaults.standard.string(forKey: "ToLanguageName")!
        
    
        // Set flags to last selected Option with using these variables
        SpeechLanguageButton.setImage(UIImage(named: SpeechLanguageName), for: .normal)
        ToLanguageButton.setImage(UIImage(named: ToLanguageName), for: .normal)
        
        
        // add gesture recognizer to all page
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(GoSpeechAndTranslatePage))
        let gestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(GoSpeechAndTranslatePage))
        TapButton1.addGestureRecognizer(gestureRecognizer)
        TapButton2.addGestureRecognizer(gestureRecognizer2)
        
    }
    
    // This used when navigation Controller back button pressed
    override func viewDidAppear(_ animated: Bool) {
        SetUserDefaultsAndButtonImage()
        
    }
    
    // Navigation Bar Functions
    private func setupNavigationBarItems(){
        
        
        let label = UILabel()
        label.textColor = UIColor.black
        label.text = "Speech & Translate";
        label.font = UIFont(name: "Helvetica", size: 20.0)
        
        let attributes = [NSAttributedString.Key.font:  UIFont(name: "Helvetica-Bold", size: 20.0)!, NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationItem.title = label.text
        self.navigationController?.navigationBar.titleTextAttributes = attributes
        
        
        showMoreButton = UIButton(type: .custom)
        showMoreButton.frame = CGRect(x: 0.0, y: 0.0, width: 20, height: 20)
        showMoreButton.setImage(UIImage(named:"showMore"), for: .normal)
        showMoreButton.addTarget(self, action: #selector(showMoreButtonClicked), for: UIControl.Event.touchUpInside)
        
        let menuBarItem = UIBarButtonItem(customView: showMoreButton)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 30)
        currWidth?.isActive = true
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 30)
        currHeight?.isActive = true
        
        self.navigationItem.leftBarButtonItem = menuBarItem
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    
        
    }
    @objc func showMoreButtonClicked(){
        performSegue(withIdentifier: "ToBecomePremiumPage", sender: nil)
        
    }
    
    // Parsing for Supporting Language
    func ParseLanguageJson(){ // Parse json file for Supported Languages
        if let path = Bundle.main.path(forResource: "languages", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let JSONResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String,AnyObject>
                let fullArray = JSONResult["languages"] as! NSArray
                languagesName = fullArray.value(forKey: "LanguageName") as! NSArray
                locales = fullArray.value(forKey: "Locale") as! NSArray
                
            } catch {
                print("error parsing json")
            }
        }
    }
    
    
    //Select Language Buttons Function
    @IBAction func SpeechLanguageSelectionClicked(_ sender: Any) {
        isButtonForSpeechLanguage = true
        performSegue(withIdentifier: "ToSelectLanguagePage", sender: nil)
    }
    
    
    @IBAction func ToLanguageSelectionClicked(_ sender: Any) {
        isButtonForSpeechLanguage = false
        performSegue(withIdentifier: "ToSelectLanguagePage", sender: nil)
    }
    
    
    @IBAction func ExchangeLanguageButtonClicked(_ sender: Any) {
        var tmp = SpeechLanguageName
        SpeechLanguageName = ToLanguageName
        ToLanguageName = tmp
        
        tmp = SpeechLanguageLocale
        SpeechLanguageLocale = ToLanguageLocale
        ToLanguageLocale = tmp
        
        SetUserDefaultsAndButtonImage()
       
        
    }
    
    
    // Go Speech and Translate Page Clicked
    @objc func GoSpeechAndTranslatePage(){
        performSegue(withIdentifier: "ToSpeechAndTranslatePage", sender: nil)
    }
    
    // Set all setup with current Language Values
    func SetUserDefaultsAndButtonImage(){
        // Set flags to last selected Option with using these variables
        SpeechLanguageButton.setImage(UIImage(named: SpeechLanguageName), for: .normal)
        ToLanguageButton.setImage(UIImage(named: ToLanguageName), for: .normal)
        
        // Exchange User Database
        UserDefaults.standard.set(SpeechLanguageName, forKey: "SpeechLanguageName")
        UserDefaults.standard.set(ToLanguageName, forKey: "ToLanguageName")
        
        UserDefaults.standard.set(SpeechLanguageLocale, forKey: "SpeechLanguageLocale")
        UserDefaults.standard.set(ToLanguageLocale, forKey: "ToLanguageLocale")
        
        
        UserDefaults.standard.synchronize()
    }
    
    // Segue prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Select Language Page Prepare
        if segue.identifier == "ToSelectLanguagePage"{
            // Set back button color
            self.navigationItem.backBarButtonItem?.tintColor = UIColor.white
            
            let destinationVC = segue.destination as! SelectLanguageViewController
            destinationVC.languagesName = languagesName
            // if SpeechLanguage Selection
            if (isButtonForSpeechLanguage)
            {
                destinationVC.isSelectionForSpeech = true
                destinationVC.customSelectedLanguageName = SpeechLanguageName
            }
            else // if ToLanguage Selection
            {
                destinationVC.isSelectionForSpeech = false
                destinationVC.customSelectedLanguageName = ToLanguageName
            }
            
        }
            
        // Speech and Translate Page Prepare
        else if segue.identifier == "ToSpeechAndTranslatePage"{
            self.navigationItem.backBarButtonItem?.tintColor = UIColor.white
            let destinationVC = segue.destination as! SpeechAndTranslateViewController
            destinationVC.SpeechLanguageName = SpeechLanguageName
            destinationVC.ToLanguageName = ToLanguageName
            
            
            // Locale preparation
            let SpeechLocale = locales[languagesName.index(of: SpeechLanguageName)] as! String
            destinationVC.SpeechRecognizerLocale = SpeechLocale
            SpeechLanguageLocale = SpeechLocale.components(separatedBy: "-")[0]
            destinationVC.SpeechLanguageLocale = SpeechLanguageLocale
            
            let ToLocale = locales[languagesName.index(of: ToLanguageName)] as! String
            ToLanguageLocale = ToLocale.components(separatedBy: "-")[0]
            destinationVC.ToLanguageLocale = ToLanguageLocale
            
            
            
            
        }
        else if segue.identifier == "ToBecomePremiumPage"{
            self.navigationItem.backBarButtonItem?.tintColor = UIColor.white
        }
    }
}

