//
//  AlderisButton.swift
//  Odyssey
//
//  Created by Amy While on 06/09/2020.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class ColourPickerCell: UIControl {
    
    static let showColourPicker = NSNotification.Name("Odyssey.ShowColourPicker")
    
    @IBInspectable var defaultKey: String = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
                
        self.addTarget(self, action: #selector(ColourPickerCell.showColourPickerControl), for: .touchUpInside)
    }
    
    @objc func showColourPickerControl() {
        NotificationCenter.default.post(name: ColourPickerCell.showColourPicker, object: nil, userInfo: ["default": defaultKey])
    }
}

class ColourViewer: UIView {
    
    @IBInspectable private var defaultKey: String = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
                
        self.clipsToBounds = true
        self.layer.cornerRadius = 5
                
        NotificationCenter.default.addObserver(self, selector: #selector(setColour), name: ThemesManager.themeChangeNotification, object: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setColour()
    }
    
    @objc private func setColour() {
        self.backgroundColor = UserDefaults.standard.color(forKey: defaultKey) ?? .gray
    }
}
