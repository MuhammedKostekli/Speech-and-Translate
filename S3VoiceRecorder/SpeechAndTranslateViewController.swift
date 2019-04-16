//
//  SpeechAndTranslateViewController.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 2.01.2019.
//  Copyright © 2019 kostekli. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Speech
import ROGoogleTranslate
import PaddingLabel

class SpeechAndTranslateViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var InformationAboutTranslationLabel: UILabel!
    
    //Languages Variables
    var SpeechLanguageName = String()
    var ToLanguageName = String()
    var SpeechLanguageLocale = String()
    var ToLanguageLocale = String()
    var SpeechRecognizerLocale = String()
    
    // timer for button animation
    var timer : Timer?
    var holdAnimationCoor = CGPoint()
    
    @IBOutlet weak var HoldButtonArea: UIImageView!
    
    
    // Text Labels
    @IBOutlet weak var SpeechTextLabel: UITextView!
    @IBOutlet weak var ToTextLabel: UITextView!
    @IBOutlet weak var SpeechLanFlag: UIImageView!
    @IBOutlet weak var ToLanFlag: UIImageView!
    
    // Speech Recognizer Variables
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Google Translate Variables
    let translator = ROGoogleTranslate()
    
    override func viewDidLayoutSubviews(){
        
        // Add Rounded view to TextBox
        SpeechTextLabel.layer.masksToBounds = true
        SpeechTextLabel.layer.cornerRadius = 10
        
        ToTextLabel.layer.masksToBounds = true
        ToTextLabel.layer.cornerRadius = 10
        
        // use auto layout to set my textview frame...kinda
        SpeechTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        SpeechTextLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        
        SpeechTextLabel.delegate = self
        SpeechTextLabel.isScrollEnabled = false
        
        textViewDidChange(SpeechTextLabel)
        
        ToTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        ToTextLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        
        ToTextLabel.delegate = self
        ToTextLabel.isScrollEnabled = false
        
        textViewDidChange(ToTextLabel)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBarItems()
        
        
        // Add hold and release press gesture recognizer to main view
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(tapHandler))
        tap.minimumPressDuration = 0
        HoldButtonArea.addGestureRecognizer(tap)
        
        // Show Information About Translation
        InformationAboutTranslationLabel.text = SpeechLanguageName + " to " + ToLanguageName
        
        // Set Flags
        SpeechLanFlag.image = UIImage(named: SpeechLanguageName)
        ToLanFlag.image = UIImage(named: ToLanguageName)
        
        // Control Speech Authorization
        SpeechAuthorization()
        print(speechRecognizer.isAvailable)
        
        //ApiKeyForTranslator
        translator.apiKey = ""
        
        
        
        
        
        
    }
    @objc func tapHandler(gesture: UITapGestureRecognizer) {
        // handle touch down and touch up events separately
        let touchPoint = gesture.location(in: self.view)
        holdAnimationCoor = touchPoint
        if gesture.state == .began {
            // Pulse Animation Start
            startTimer()
            
            // Start Speech Recognation
            RecognizeTextFromSpeech()
            
        } else if  gesture.state == .ended {
            // Pulse Animation Stop
            stopTimer()
            
            // Stop Speech Recognation
            stopSpeechRecognation()
            
            // Translate Speech to Text String
            TranslateFromSourceText()
        }
    }
    
    // Setup Navigation Bar
    private func setupNavigationBarItems(){
        let label = UILabel()
        label.textColor = UIColor.black
        label.text = "Speech & Translate";
        label.font = UIFont(name: "Helvetica", size: 20.0)
        
        let attributes = [NSAttributedString.Key.font:  UIFont(name: "Helvetica-Bold", size: 20.0)!, NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationItem.title = label.text
        self.navigationController?.navigationBar.titleTextAttributes = attributes
        
    }
    
    @objc func addPulse(){ // Pulse Animation Creator
        let pulse = Pulsing(numberOfPulses: 1, radius: 100, position: holdAnimationCoor)
        pulse.animationDuration = 1.0
        pulse.backgroundColor = UIColor.white.cgColor
        self.view.layer.insertSublayer(pulse, above: self.view.layer)
        
    }
    
    // Functions for control Animation Timer
    func startTimer () {
        if timer == nil {
            timer =  Timer.scheduledTimer(timeInterval: TimeInterval(0.7),target: self,selector: #selector(self.addPulse),userInfo: nil,repeats: true)
        }
    }
    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func RecognizeTextFromSpeech(){ // Recognize User's Speech and Show it in label
        // Clear Recognized Text Before
        SpeechTextLabel.text = ""
        ToTextLabel.text = ""
        
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
        guard let SpeechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: SpeechRecognizerLocale)) else{
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
                self.SpeechTextLabel.text = clearString
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
    
    
    
    func TranslateFromSourceText(){ // Google Translate Api Function
        var params = ROGoogleTranslateParams()
        params.source = SpeechLanguageLocale
        params.target = ToLanguageLocale
        params.text = SpeechTextLabel.text ?? "The textfield is empty"
        
        
        translator.translate(params: params) { (result) in
            DispatchQueue.main.async {
                print(result)
                self.ToTextLabel.text = result
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
        okButton.setValue(UIColor.red.UIColorFromRGB(rgbValue: 0x870019), forKey: "titleTextColor")
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }

    

}

extension SpeechAndTranslateViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        print(textView.text)
        let size = CGSize(width: view.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        textView.constraints.forEach { (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = estimatedSize.height
            }
        }
    }
    
}
