//
//  LanguageCell.swift
//  S3VoiceRecorder
//
//  Created by Muhammed Köstekli on 30.12.2018.
//  Copyright © 2018 kostekli. All rights reserved.
//

import UIKit

class LanguageCell: UITableViewCell {

    @IBOutlet weak var LanguageFlag: UIImageView!
    @IBOutlet weak var LanguageName: UILabel!
    @IBOutlet weak var isSelectedMark: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
