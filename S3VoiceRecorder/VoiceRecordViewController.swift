//
//  VoiceRecordViewController.swift
//  S3VoiceRecorder
//
//  Created by MuhammedKostekli on 20.11.2018.
//  Copyright © 2018 MuhammedKostekli. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import AWSCognito
import AWSS3
import Speech
import ROGoogleTranslate
import Firebase
import FacebookCore


class VoiceRecordViewController: UIViewController,AVAudioRecorderDelegate, SFSpeechRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, AVSpeechSynthesizerDelegate{
    
    // TextField AND PickerViewArea
    @IBOutlet weak var Area1: UIImageView!
    @IBOutlet weak var Area2: UIImageView!
    
    
    // Text Result from Speech
    @IBOutlet weak var SpeechToTextLabel: UILabel!
    
    // Translation Result Variables
    let translator = ROGoogleTranslate()
    @IBOutlet weak var TranslatedToLabel: UILabel!
    var translateSourceLocale = "en" // Source Language Short name for Google Translate
    var translateToLocale = "es" // Translated Language Short name for Google Translate
    var translatedcustomSelection = 0 // Custom selection for first state
    
    // Supported Languages Variables
    var languagesName = NSArray()
    var locales = NSArray()
    var sourceLanguage = "en-US" // Source Language long name for Speech to Text
    var translateToLanguage = "es-ES" // Translated Language long name for Text to Speech
    var customSelection = 0
    
   
    
    // Microphone Record Variables
    var recordSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder! // Recorder Object which use microphone
    @IBOutlet weak var recordAudioButton: UIButton!
    
    // Amazon S3 variables
    let bucketName = "recorded-voices" // Your Amazon S3 Bucket Name
    var fileName = String()    // Variable for keep unique name of recorded voice
    var filePath = URL(fileURLWithPath: "")
    
    // Speech Recognizer Variables
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // timer for button animation
    var timer : Timer?
    
    // timer for Chronometer
    var countUpTimer : Timer?
    var seconds = 0
    @IBOutlet weak var ChronometerLabel: UILabel!
    
    // pickerview for language selection
    @IBOutlet weak var pickerView: UIPickerView! // Source Language
    @IBOutlet weak var TranslatedLanguage: UIPickerView! // Selected Language
    
    
    override func viewDidLayoutSubviews(){
        SpeechToTextLabel.layer.cornerRadius = SpeechToTextLabel.frame.size.width / 15
        SpeechToTextLabel.clipsToBounds = true
        
        TranslatedToLabel.layer.cornerRadius = TranslatedToLabel.frame.size.width / 15
        TranslatedToLabel.clipsToBounds = true
        
        Area1.layer.cornerRadius = Area1.frame.size.width / 15
        Area1.clipsToBounds = true
        
        Area2.layer.cornerRadius = Area2.frame.size.width / 15
        Area2.clipsToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Navigation Items
        //setupNavigationBarItems()
        
        // Try to log event to Facebook
        AppEventsLogger.log("My_custom_event");
        
        // Parse for Supported Languages
        ParseLanguageJson()
        
        // Set PickerViews Data for Language Selection
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(customSelection, inComponent: 0, animated: false)
        TranslatedLanguage.delegate = self
        TranslatedLanguage.dataSource = self
        TranslatedLanguage.selectRow(translatedcustomSelection, inComponent: 0, animated: false)
        
        //ApiKeyForTranslator
        translator.apiKey = "" // Add your API Key here
        
        // Control Speech Authorization
        SpeechAuthorization()
        print(speechRecognizer.isAvailable)
        
        
        // Set action to Button
        recordAudioButton.addTarget(self, action: #selector(holdRelease(sender:)), for: UIControl.Event.touchUpInside);
        recordAudioButton.addTarget(self, action: #selector(HoldDown(sender:)), for: UIControl.Event.touchDown)
        
       
        
        // Create Record Session
        recordSession = AVAudioSession.sharedInstance()
        AVAudioSession.sharedInstance().requestRecordPermission { (Permission) in
            if Permission{
                print("Recording Request Accepted.")
            }
        }
        
    }
    /*
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
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 35)
        currWidth?.isActive = true
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 35)
        currHeight?.isActive = true
        
        self.navigationItem.leftBarButtonItem = menuBarItem
 
        
        
    }
    */
    
    
    func TranslateFromSourceText(){ // Google Translate Api Function
        var params = ROGoogleTranslateParams()
        params.source = translateSourceLocale
        params.target = translateToLocale
        params.text = SpeechToTextLabel.text ?? "The textfield is empty"
        
        
        translator.translate(params: params) { (result) in
            DispatchQueue.main.async {
                print(result)
                self.TranslatedToLabel.text = result
                self.TextToSpeech() // Speech for Translated text
            }
        }
    }
    

    func RecognizeTextFromSpeech(){ // Recognize User's Speech and Show it in label
        // Clear Recognized Text Before
        self.SpeechToTextLabel.text = ""
        self.TranslatedToLabel.text = ""
        
        // Setup AudioEngine and Speech Recognizer
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _ ) in
            self.recognitionRequest.append(buffer)
        }
        
        // Prepare and Start Audio Engine
        audioEngine.prepare()
        do{
            try audioEngine.start()
        }catch{
            return print(error)
        }
        
        // Check Recognizer Availability
        guard let SpeechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: sourceLanguage)) else{
            return
        }
        if(!SpeechRecognizer.isAvailable){
            print("Speech Recognizer Not Available")
            return
        }
        
        // Call Recognition Task
        recognitionTask = SpeechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            if let result = result {
                let clearString = result.bestTranscription.formattedString
                self.SpeechToTextLabel.text = clearString
            } else if let error = error{
                print(error)
            }
        })
        
        
    }
    
    func stopSpeechRecognation() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest.endAudio()
        // Cancel the previous task if it's running
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
    }
    
    @objc func addPulse(){ // Pulse Animation Creator
        let pulse = Pulsing(numberOfPulses: 1, radius: 150, position: recordAudioButton.center)
        pulse.animationDuration = 0.8
        pulse.backgroundColor = UIColorFromRGB(rgbValue: 0xD30505).cgColor
        
        self.view.layer.insertSublayer(pulse, below: recordAudioButton.layer)
        
    }
    
    
    func getPath() -> URL{ // Take the root URL of Application
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = path[0]
        return directory
    }
    
    func showAlertMessage(title:String , message:String){ // Give Alert Message
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okey", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    func findUniqueName() -> String{ // Unique name for each file
        let uuid = UUID().uuidString
        return uuid
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    // Functions for control Animation Timer
    func startTimer () {
        if timer == nil {
            timer =  Timer.scheduledTimer(timeInterval: TimeInterval(0.8),target: self,selector: #selector(self.addPulse),userInfo: nil,repeats: true)
        }
    }
    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    @objc func HoldDown(sender:UIButton) // Start Record and Animation
    {
        Analytics.logEvent("start_recording_clicked", parameters: nil) // Send values to Google Analytics
        if audioRecorder == nil {
            // Start Speech Recognation
            RecognizeTextFromSpeech()
            
            // Start Audio Recording for Send it to Amazon S3
            fileName = findUniqueName()
            filePath = getPath().appendingPathComponent("\(fileName).m4a") // find unique name for Audio File
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            do{
                audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.record()
                startTimer()
            }catch{
                showAlertMessage(title: "Error", message: "Something goes wrong... Please Try Again")
            }
            
            recordTimeStart() // Start chronometer
        }
    }
    
    @objc func holdRelease(sender:UIButton) // Button Release, finish record and send it to S3
    {
        Analytics.logEvent("recording_finished", parameters: ["record_time" : seconds]) // Send GA for recording time
        if (audioRecorder != nil){
            // Translate Speech to Text String
            TranslateFromSourceText()
            
            // Stop Speech Recognation
            stopSpeechRecognation()
            
            // Stop and Reset Chronometer
            recordTimeFinished()
            
            // Stop Recording 
            audioRecorder.stop()
            audioRecorder = nil
            stopTimer()
            

            
        }
    }
    
    func recordTimeStart() // Chronometer Start
    {
        ChronometerLabel.text = ""
        countUpTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(VoiceRecordViewController.counter), userInfo: nil, repeats: true)
        ChronometerLabel.text = "00:00"
    }
    
    func recordTimeFinished() // Because Speech to Text 60 Seconds Limit
    {
        countUpTimer?.invalidate()
        seconds = 0
    }
    
    @objc func counter() // Chronometer Counter
    {
        seconds += 1
        ChronometerLabel.text = "00:" + String(format: "%02d", seconds)
        if (seconds == 60)
        {
            ChronometerLabel.text = "01:00"
            holdRelease(sender: recordAudioButton)
            AlertMessage(alertMessage: "You can use Speech to Text 60 Seconds for each record")
        }
    }
    
    func ParseLanguageJson(){ // Parse json file for Supported Languages
        if let path = Bundle.main.path(forResource: "languages", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let JSONResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String,AnyObject>
                let fullArray = JSONResult["languages"] as! NSArray
                languagesName = fullArray.value(forKey: "LanguageName") as! NSArray
                locales = fullArray.value(forKey: "Locale") as! NSArray
                customSelection = languagesName.index(of: "English (United States)")
                translatedcustomSelection = languagesName.index(of: "Spanish (Spain)")
            } catch {
                print("error parsing json")
            }
        }
    }
    
    func SpeechAuthorization(){ // Function for Speech Authorization Control
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                var alertTitle = ""
                
                switch authStatus {
                case .authorized:
                    print("okey")
                    return
                case .denied:
                    alertTitle = "Speech recognizer not allowed"
                    
                case .restricted, .notDetermined:
                    alertTitle = "Could not start the speech recognizer"
            
                    
                }
                if alertTitle != "" {
                    self.AlertMessage(alertMessage: alertTitle)
                }
            }
        }
    }
    func AlertMessage( alertMessage: String){ // General Alert Message Function
        let alert = UIAlertController(title: "", message: alertMessage , preferredStyle: UIAlertController.Style.alert)
        let okButton = UIKit.UIAlertAction(title: "Okey", style: UIAlertAction.Style.default, handler: {(UIAlertAction) in
            
            
        })
        okButton.setValue(self.UIColorFromRGB(rgbValue: 0x870019), forKey: "titleTextColor")
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Set picker Views
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languagesName.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let languages = languagesName[row] as! String
        let coreLanguageName = languages.components(separatedBy: "(")
        return coreLanguageName[0]
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let locale = locales[row] as! String
        let coreLocale = locale.components(separatedBy: "-")
        if(pickerView == TranslatedLanguage){ // if second picker view changed
            translateToLanguage = locale
            translateToLocale = coreLocale[0]
        }else{
            translateSourceLocale = coreLocale[0]
            sourceLanguage = locale
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: sourceLanguage))!
        }
        
        print(sourceLanguage + " " + translateSourceLocale + " " + translateToLocale + " " + translateToLanguage )
        
        
    }
    
    // Speech To Text Delegates
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.red, range: characterRange)
            TranslatedToLabel.attributedText = mutableAttributedString
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        TranslatedToLabel.attributedText = NSAttributedString(string: utterance.speechString)
    }
    
    func TextToSpeech() { // Read Translated Text
        let string = TranslatedToLabel.text!
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: translateToLanguage)
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }
    
    
}

