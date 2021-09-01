//
//  ProgressButton.swift
//  taurine
//
//  Created by CoolStar on 3/14/21.
//

import UIKit

class ProgressButton: UIButton {
    let progressView: ProgressFill
    let progressLabel: ProgressLabel
    
    let defaultGradientColors = [
        UIColor(white: 1, alpha: 0.5),
        UIColor(white: 1, alpha: 0.6),
        UIColor(white: 1, alpha: 0.5)
    ]
    let defaultGradientDelta = CGFloat(0.15)
    
    required init?(coder: NSCoder) {
        progressView = ProgressFill(frame: .zero)
        //progressView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        progressView.setGradient(colors: defaultGradientColors, delta: defaultGradientDelta)
        
        progressLabel = ProgressLabel(frame: .zero)
        
        super.init(coder: coder)
        self.addSubview(progressView)
        self.addSubview(progressLabel)
        
        progressLabel.title = self.titleLabel?.text
        progressLabel.titleColor = self.titleLabel?.textColor
        progressLabel.font = self.titleLabel?.font
        progressLabel.isUserInteractionEnabled = false
        
        self.titleLabel?.alpha = 0
    }
    
    public func setGradient(colors: [UIColor]?, delta: CGFloat){
        let colors = colors ?? defaultGradientColors
        progressView.setGradient(colors: colors, delta: delta)
    }
    
    private var _progress: CGFloat = 0
    public var progress: CGFloat {
        get {
            _progress
        }
        set {
            _progress = newValue
            progressLabel.progress = newValue
            
            self.layoutSubviews()
        }
    }
    
    public func setProgress(_ progress: CGFloat, animated: Bool){
        _progress = progress
        progressLabel.progress = progress
        
        UIView.animate(withDuration: animated ? 0.25 : 0){
            self.layoutSubviews()
        }
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        if state == .normal {
            progressLabel.titleColor = color
        }
    }
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        if state == .normal {
            progressLabel.title = title
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel?.alpha = 0
        progressView.frame = CGRect(origin: .zero, size: CGSize(width: self.bounds.width * progress, height: self.bounds.height))
        progressLabel.frame = bounds
        
        progressLabel.setNeedsDisplay()
    }
}
