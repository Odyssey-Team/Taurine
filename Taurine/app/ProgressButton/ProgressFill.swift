//
//  ProgressFill.swift
//  taurine
//
//  Created by CoolStar on 3/14/21.
//

import UIKit
import QuartzCore

class ProgressFill: UIView {
    let progressLayer: CAGradientLayer
    
    override init(frame: CGRect) {
        progressLayer = CAGradientLayer()
        
        super.init(frame: frame)
        self.layer.addSublayer(progressLayer)
        
        progressLayer.startPoint = CGPoint(x: 0, y: 0.5)
        progressLayer.endPoint = CGPoint(x: 1, y: 0.5)
        progressLayer.locations = [0.35, 0.5, 0.65]
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    func setGradient(colors : [UIColor], delta: CGFloat){
        progressLayer.colors = colors.map { $0.cgColor }
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-(delta * 2), -delta, 0]
        animation.toValue = [1, 1 + delta, 1 + (delta * 2)]
        animation.duration = 1
        animation.repeatCount = Float.infinity
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "flowAnimation")
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        progressLayer.frame = bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressLayer.frame = bounds
    }
}
