//
//  CALayer.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 30.12.2018.
//  Copyright © 2018 kostekli. All rights reserved.
//

import Foundation
import UIKit
extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect(x: 0,y: 0,width: self.frame.height, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect(x: 0,y: self.frame.height - thickness,width: UIScreen.main.bounds.width,height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect(x: 0,y: 0,width: thickness, height: self.frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect(x: self.frame.height - thickness,y: 0,width: thickness,height: self.frame.height)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        self.addSublayer(border)
    }
    
}
