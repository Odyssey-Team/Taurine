//
//  SeparatorView.swift
//  odysseyjb
//
//  Created by Hayden Seay on 6/24/20.
//  Copyright © 2020 Coolstar Org. All rights reserved.
//

import UIKit

class SeparatorView: UIView {

	override func didMoveToWindow() {
		super.didMoveToWindow()

		if let constraint = constraints.first(where: { $0.firstAttribute == .height || $0.secondAttribute == .height }) {
			constraint.constant = 1 / window!.screen.scale
		}
	}

}
