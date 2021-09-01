//
//  LogViewController.swift
//  Odyssey
//
//  Created by CoolStar on 7/1/20.
//  Copyright © 2020 coolstar. All rights reserved.
//
import UIKit

class LogViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(LogViewController.reload), name: LogStream.shared.reloadNotification, object: nil)
        self.reload()
    }
    
    @objc func reload() {
        guard let log = LogStream.shared.outputString.copy() as? NSAttributedString else {
            return
        }
        ObjcTryCatch {
            self.textView.attributedText = log
            self.textView.font = UIFont.monospacedSystemFont(ofSize: 0, weight: .regular)
            if log.string.count > 1 {
                self.textView.scrollRangeToVisible(NSRange(location: log.string.count - 1, length: 1))
            }
            self.textView.setNeedsDisplay()
        }
    }
}
