//
//  TableButton.swift
//  Odyssey
//
//  Created by CoolStar on 7/5/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class TableButton: UIControl {
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = UIColor(white: 1, alpha: 0.3)
            } else {
                self.backgroundColor = UIColor.clear
            }
        }
    }
}
