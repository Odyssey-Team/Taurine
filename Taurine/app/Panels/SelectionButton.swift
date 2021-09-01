//
//  SelectionButton.swift
//  Odyssey
//
//  Created by CoolStar on 7/5/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class SelectionButton: TableButton {
    @IBInspectable private var defaultsKey: String = ""
    @IBInspectable private var defaultsValue: String = ""
    @IBInspectable private var notificationName: String = ""
    
    @IBOutlet private var checkmarkImage: UIImageView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.addTarget(self, action: #selector(SelectionButton.selectOption), for: .touchUpInside)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateCheckmark()
        
        guard !notificationName.isEmpty else {
            return
        }
        let notification = Notification.Name(notificationName)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCheckmark), name: notification, object: nil)
    }
    
    @objc func updateCheckmark() {
        if UserDefaults.standard.string(forKey: defaultsKey) == defaultsValue {
            checkmarkImage.alpha = 1
        } else {
            checkmarkImage.alpha = 0
        }
    }
    
    @objc func selectOption() {
        guard !defaultsKey.isEmpty else {
            fatalError("Need to set a key in storyboard")
        }
        UserDefaults.standard.set(defaultsValue, forKey: defaultsKey)
        UserDefaults.standard.synchronize()
        
        guard !notificationName.isEmpty else {
            return
        }
        let notification = Notification(name: Notification.Name(notificationName))
        NotificationCenter.default.post(notification)
    }
}
