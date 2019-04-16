//
//  UIColor.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 29.12.2018.
//  Copyright © 2018 kostekli. All rights reserved.
//

import Foundation
import UIKit
extension UIColor{
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
