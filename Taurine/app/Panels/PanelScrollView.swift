//
//  PanelScrollView.swift
//  Odyssey
//
//  Created by CoolStar on 7/6/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class PanelScrollView: UIScrollView, UIScrollViewDelegate, PanelView {
    @IBInspectable var isRootView: Bool = false
    @IBOutlet var parentView: (UIView & PanelView)!
    @IBOutlet var viewController: ViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewController.cancelPopTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            viewController.resetPopTimer()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewController.resetPopTimer()
    }
    
    func viewShown() {
        self.flashScrollIndicators()
    }
}
