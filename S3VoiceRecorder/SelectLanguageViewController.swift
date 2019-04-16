//
//  SelectLanguageViewController.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 29.12.2018.
//  Copyright © 2018 kostekli. All rights reserved.
//

import UIKit

class SelectLanguageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var SearchBar: UISearchBar!
    
    @IBOutlet weak var LanguageSelectionTable: UITableView!
    
    // Language Array includes Recently Used and All Language
    var languageArray = [[String()]] // table view contents
    var languagesName = NSArray() // coming from first page
    var AllLanguagesName = [String()] // includes all name of languages
    var currentResultLanguage = [String()] // for search on languages
    let headersOfLanguages = ["RECENTLY USED","ALL LANGUAGES"]
    var customSelectedLanguageName = String() // custom selection which is coming from first page
    var isSelectionForSpeech = Bool() // Is selection for Speech or To Language
    var isFirstTableInsert = Bool() // It is true when page load first time
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBarItems()
        setupSearchBar()
        
        navigationController?.delegate = self
        
        // Take Recently Used Array and create table view contents
        let recentlyUsed = UserDefaults.standard.stringArray(forKey: "RecentlyUsed") ?? [String]()
        languageArray[0] = recentlyUsed
        print(recentlyUsed)
        AllLanguagesName = languagesName as! [String]
        currentResultLanguage = AllLanguagesName
        languageArray.append(currentResultLanguage)
        
        
        isFirstTableInsert = true
        // For Extensions
        LanguageSelectionTable.dataSource = self
        LanguageSelectionTable.delegate = self
        SearchBar.delegate = self
        
    }
    
    // Setup Navigation Bar
    private func setupNavigationBarItems(){
        let label = UILabel()
        label.textColor = UIColor.black
        label.text = "Select Language";
        label.font = UIFont(name: "Helvetica", size: 20.0)
        
        let attributes = [NSAttributedString.Key.font:  UIFont(name: "Helvetica-Bold", size: 20.0)!, NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationItem.title = label.text
        self.navigationController?.navigationBar.titleTextAttributes = attributes
    }
    
    // Setup custom Search Bar
    private func setupSearchBar(){
        SearchBar.searchBarStyle = .minimal
        SearchBar.placeholder = "Search"
        SearchBar.setTextColor(color: .white)
        SearchBar.setTextFieldColor(color: UIColor.red.UIColorFromRGB(rgbValue: 0x0098CA))
        SearchBar.setPlaceholderTextColor(color: .white)
        SearchBar.setSearchImageColor(color: .white)
        SearchBar.setTextFieldClearButtonColor(color: .white)
    }

    
    // fill in table view
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        

        let view = UIView(frame: CGRect(x: 0,y: 0,width: tableView.frame.size.width,height: 40))
        let label = UILabel(frame: CGRect(x: 20,y: 3,width: tableView.frame.size.width,height: 27))
        let font = UIFont(name: "Helvetica", size: 20.0)
        label.font = font
        label.textColor = UIColor.white
        label.text = headersOfLanguages[section]
        label.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor.white, thickness: 2)
        view.addSubview(label)
        view.backgroundColor = UIColor.lightGray.UIColorFromRGB(rgbValue: 0x0098CA)
        
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return languageArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languageArray[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as! LanguageCell
        
        let LanguageName = languageArray[indexPath.section][indexPath.row]
        cell.LanguageName.text = LanguageName
        cell.LanguageFlag.image = UIImage(named: LanguageName + ".png")
        
        // Control for custom selection
        if(isFirstTableInsert){
            if(languageArray[0][indexPath.row] == customSelectedLanguageName){
                cell.isSelectedMark.isHidden = false
                isFirstTableInsert = false
            }
        }
        
        // For clear all marks
        if(languageArray[indexPath.section][indexPath.row] == customSelectedLanguageName){
            cell.isSelectedMark.isHidden = false
        }else{
            cell.isSelectedMark.isHidden = true
        }
        
        return cell
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        
        let currentSelectedRow = LanguageSelectionTable.cellForRow(at: indexPath) as! LanguageCell
        customSelectedLanguageName = currentSelectedRow.LanguageName.text!
        LanguageSelectionTable.reloadData()
    
    }

    
    // Search Bar Operation
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else{
            currentResultLanguage = AllLanguagesName
            languageArray.remove(at: 1)
            languageArray.append(currentResultLanguage)
            LanguageSelectionTable.reloadData()
            return
        }
        currentResultLanguage = AllLanguagesName.filter({ (curr) -> Bool in
            curr.contains(searchText)
        })
        languageArray.remove(at: 1)
        languageArray.append(currentResultLanguage)
        LanguageSelectionTable.reloadData()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        currentResultLanguage = AllLanguagesName
        languageArray.remove(at: 1)
        languageArray.append(currentResultLanguage)
        LanguageSelectionTable.reloadData()
    }
    
    
    
    

}
// Extension for send selected Language to initial View Controller
extension SelectLanguageViewController {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        UpdateRecentlyUsedArray()
        let viewCntrl = (viewController as? FirstSceneViewController)
        if(isSelectionForSpeech){
            viewCntrl?.SpeechLanguageName = customSelectedLanguageName
        }else{
            viewCntrl?.ToLanguageName = customSelectedLanguageName
        }
        
    }
    
    func UpdateRecentlyUsedArray(){
        // Add Recently Used
        var recentlyUsed = UserDefaults.standard.stringArray(forKey: "RecentlyUsed") ?? [String]()
        if (recentlyUsed.count > 3){ // full capacity
            if(isSelectionForSpeech && !recentlyUsed.contains(customSelectedLanguageName)){
                recentlyUsed.removeLast()
                recentlyUsed.insert(customSelectedLanguageName, at: 0)
                UserDefaults.standard.set(recentlyUsed, forKey: "RecentlyUsed")
                UserDefaults.standard.synchronize()
            }else if(!isSelectionForSpeech && !recentlyUsed.contains(customSelectedLanguageName)){
                recentlyUsed.removeLast()
                recentlyUsed.insert(customSelectedLanguageName, at: 0)
                UserDefaults.standard.set(recentlyUsed, forKey: "RecentlyUsed")
                UserDefaults.standard.synchronize()
            }
        }else{
            if(isSelectionForSpeech && !recentlyUsed.contains(customSelectedLanguageName)){
                recentlyUsed.insert(customSelectedLanguageName, at: 0)
                UserDefaults.standard.set(recentlyUsed, forKey: "RecentlyUsed")
                UserDefaults.standard.synchronize()
            }else if(!isSelectionForSpeech && !recentlyUsed.contains(customSelectedLanguageName)){
                recentlyUsed.insert(customSelectedLanguageName, at: 0)
                UserDefaults.standard.set(recentlyUsed, forKey: "RecentlyUsed")
                UserDefaults.standard.synchronize()
            }
            
        }
    }
}
