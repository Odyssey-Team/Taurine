//
//  BackgroundView.swift
//  Chimera
//
//  Created by Ayden Panhuyzen on 2019-04-12.
//  Copyright © 2019 Electra Team. All rights reserved.
//
//  This file was taken from another project, and it’s inclusion here does not indicate the author’s endorsement.
// swiftlint:disable all

import UIKit

class BackgroundView: UIView { 
    let animatingColourView = AnimatingColourView()
    private var blurView = UIVisualEffectView()
    private var vibrancyViews = NSHashTable<UIVisualEffectView>.weakObjects()
    
    enum Mode {
        case normal, escaped
        
        var blurEffect: UIBlurEffect {
            switch self {
            case .normal:
                let blur = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init(style: .extraLight)
                blur.setValue(45, forKey: "blurRadius")
                blur.setValue(2.75, forKey: "saturationDeltaFactor")
                blur.setValue(UIScreen.main.scale, forKey: "scale")
                return blur
            case .escaped:
                let blur = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
                blur.setValue(45, forKey: "blurRadius")
                blur.setValue(UIColor(red: 255, green: 255, blue: 255, alpha: 0.3), forKey: "colorTint")
                blur.setValue(1.8, forKey: "saturationDeltaFactor")
                blur.setValue(1, forKey: "darkeningTintAlpha")
                blur.setValue(1, forKey: "darkeningTintSaturation")
                blur.setValue(UIScreen.main.scale, forKey: "scale")
                return blur
            }
        }
        
        var vibrancyEffect: UIVibrancyEffect? {
            switch self {
            case .normal: return UIVibrancyEffect(blurEffect: UIBlurEffect(style: .extraLight))
            default: return nil
            }
        }
        
        #if os(iOS)
        var navigationBarStyle: UIBarStyle {
            return self == .escaped ? .black : .default
        }
        #endif
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        animatingColourView.frame = bounds
        animatingColourView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(animatingColourView)
        
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.effect = UIBlurEffect(style: .regular)
        blurView.overrideUserInterfaceStyle = .light
        addSubview(blurView)
    }
    
    private var _mode = Mode.normal
    var mode: Mode {
        get { return _mode }
        set { set(mode: newValue, animated: true) }
    }
    
    func set(mode: Mode, animated: Bool) {
        let effect = mode.blurEffect
        let vibrancyEffect = mode.vibrancyEffect
        _mode = mode
        
        updateBlurView(with: effect, animated: animated)
        vibrancyViews.allObjects.forEach { update(vibrancyView: $0, with: vibrancyEffect, animated: animated) }
    }
    
    private func updateBlurView(with effect: UIVisualEffect?, animated: Bool) {
        guard animated else { blurView.effect = effect; return }
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.9, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.updateBlurView(with: effect, animated: false)
        }, completion: nil)
    }
    
    private func update(vibrancyView: UIVisualEffectView, with effect: UIVisualEffect?, animated: Bool) {
        guard animated else { vibrancyView.effect = effect; return }
        UIView.transition(with: vibrancyView, duration: 0.35, options: .allowAnimatedContent, animations: {
            vibrancyView.effect = effect
        }, completion: nil)
    }

    func createVibrancyView() -> UIVisualEffectView {
        let vibrancyView = UIVisualEffectView(effect: mode.vibrancyEffect)
        vibrancyView.contentView.tintColor = .white
        vibrancyViews.add(vibrancyView)
        return vibrancyView
    }
    
}
