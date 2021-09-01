//
//  CreditsButton.swift
//  Odyssey
//
//  Created by CoolStar on 7/5/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class CreditsButton: TableButton {
    @IBInspectable var twitter: String = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.addTarget(self, action: #selector(CreditsButton.openTwitter), for: .touchUpInside)
    }
    
    @objc func openTwitter() {
        UIApplication.shared.open(URL(string: "https://twitter.com/\(twitter)")!, options: [:], completionHandler: nil)
    }
}
