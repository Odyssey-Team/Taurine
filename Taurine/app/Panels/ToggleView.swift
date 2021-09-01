//
//  ToggleView.swift
//  Odyssey
//
//  Created by CoolStar on 7/11/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class ToggleView: UIView {
    @IBOutlet weak private var toggle: UISwitch!
    @IBInspectable private var prefsName: String!
    @IBInspectable private var sendNotification: Bool = false
    @IBInspectable private var notifcationName: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !prefsName.isEmpty {
            if UserDefaults.standard.value(forKey: prefsName) != nil {
                let value = UserDefaults.standard.bool(forKey: prefsName)
                toggle.isOn = value
            }
        }
    }
    
    @IBAction func valueChanged() {
        if !prefsName.isEmpty {
            UserDefaults.standard.set(toggle.isOn, forKey: prefsName)
        }
        
        if sendNotification {
            let notification = Notification(name: Notification.Name(notifcationName))
            NotificationCenter.default.post(notification)
        }
    }
}
