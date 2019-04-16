//
//  UILabel.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 2.01.2019.
//  Copyright © 2019 kostekli. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    var optimalHeight : CGFloat {
        get
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            label.numberOfLines = 0
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.font = self.font
            label.text = self.text
            label.sizeToFit()
            return label.frame.height
        }
        
    }
}
