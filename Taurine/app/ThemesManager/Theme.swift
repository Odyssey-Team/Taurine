//
//  File.swift
//  Odyssey
//
//  Created by CoolStar on 7/6/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class Theme {
    let colorViewBackgrounds: [AnimatingColourView.GradientBackground]
    let backgroundImage: UIImage?
    let backgroundCenter: CGPoint
    let backgroundOverlay: UIColor?
    let progressGradientColors: [UIColor]?
    let progressGradientDelta: CGFloat
    let enableBlur: Bool
    let copyrightString: String
    
    init(colorViewBackgrounds: [AnimatingColourView.GradientBackground],
         backgroundImage: UIImage?,
         backgroundCenter: CGPoint = .zero,
         backgroundOverlay: UIColor?,
         progressGradientColors: [UIColor]? = nil,
         progressGradientDelta: CGFloat = 0.15,
         enableBlur: Bool,
         copyrightString: String = "") {
        self.colorViewBackgrounds = colorViewBackgrounds
        self.backgroundImage = backgroundImage
        self.backgroundCenter = backgroundCenter
        self.backgroundOverlay = backgroundOverlay
        self.progressGradientColors = progressGradientColors
        self.progressGradientDelta = progressGradientDelta
        self.enableBlur = enableBlur
        self.copyrightString = copyrightString
    }
}
