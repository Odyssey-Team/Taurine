//
//  TextButton.swift
//  Odyssey
//
//  Created by CoolStar on 7/6/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

protocol TextButtonDelegate: AnyObject {
    var defaultValue: String { get }
    var currentValue: String { get }
    func isInputValid(input: String) -> Bool
    func receiveInput(input: String)
}

class TextButton: TableButton, UITextFieldDelegate {
    @IBOutlet weak private var label: UILabel!
    @IBOutlet weak private var chevron: UIImageView!
    @IBOutlet weak public var textField: UITextField!
    @IBOutlet weak private var viewController: ViewController!
    
    @IBInspectable var alertTitle: String!
    @IBInspectable var alertMessage: String!
    
    public weak var delegate: TextButtonDelegate? {
        didSet {
            guard let delegate = delegate else {
                return
            }
            textField.placeholder = delegate.defaultValue
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addTarget(self, action: #selector(showTextField), for: .touchUpInside)
    }
    
    @objc func showTextField() {
        viewController.bindToKeyboard()
        viewController.cancelPopTimer()
        
        textField.text = delegate?.currentValue
        UIView.animate(withDuration: 0.25) {
            self.label.alpha = 0
            self.chevron.alpha = 0
            self.textField.alpha = 1
            
            self.textField.becomeFirstResponder()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.viewController.resetPopTimer()
        UIView.animate(withDuration: 0.25, animations: {
            self.label.alpha = 1
            self.chevron.alpha = 1
            self.textField.alpha = 0
        }, completion: { _ in
            self.viewController.unbindKeyboard()
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let delegate = self.delegate,
            let text = textField.text {
            if delegate.isInputValid(input: text) {
                delegate.receiveInput(input: text)
            } else {
                viewController.showAlert(alertTitle, alertMessage, sync: false)
            }
        }
        
        return false
    }
}
