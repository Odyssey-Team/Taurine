//
//  AnimatingColourView.swift
//  Chimera
//
//  Created by Ayden Panhuyzen on 2019-04-24.
//  Copyright © 2019 Electra Team. All rights reserved.
//
//  This file was taken from another project, and it’s inclusion here does not indicate the author’s endorsement.
//

import UIKit

class AnimatingColourView: UIView {
    private var gradientViewContainer = UIView()
    private var overlayImageView = UIImageView()
    
    struct GradientBackground {
        let baseColour: UIColor
        let linearGradients: [GradientView.Gradient]
        let overlayImage: UIImage?
    }
    
    private var backgroundsToUse: [AnimatingColourView.GradientBackground] {
        if UserDefaults.standard.string(forKey: "theme") == "customColourTheme" {
            return ThemesManager.shared.customColourBackground
        } else {
            return ThemesManager.shared.currentTheme.colorViewBackgrounds
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gradientViewContainer.frame = bounds
        gradientViewContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(gradientViewContainer)
        
        let backgrounds = backgroundsToUse
        setup(for: backgrounds[0])
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tick), name: ThemesManager.themeChangeNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tick() {
        UIView.transition(with: self, duration: 4, options: .transitionCrossDissolve, animations: {
            let backgrounds = self.backgroundsToUse
            self.setup(for: backgrounds.randomElement())
        }, completion: nil)
    }
    
    private func setup(for background: GradientBackground?) {
        backgroundColor = background?.baseColour
        gradientViewContainer.subviews.forEach { $0.removeFromSuperview() }
        guard let background = background else { return }
        for (index, gradient) in background.linearGradients.enumerated() {
            let view = GradientView(gradient: gradient)
            view.frame = gradientViewContainer.bounds
            view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            view.rotationAnimationSpeed = 1.0 / Double(index + 1)
            gradientViewContainer.addSubview(view)
        }
    }

    class GradientView: UIView {
        struct Gradient {
            typealias Stop = (colour: UIColor, position: Double)
            let stops: [Stop]
            /// Angle in degrees (0º means the gradient moves top to bottom)
            let angle: Double
            
            init(stops: [Stop], angle: Double = 0) {
                self.stops = stops
                self.angle = angle
            }
            
            init(colours: [UIColor], angle: Double = 0) {
                self.stops = colours.enumerated().map { (colour: $0.element, position: 1.0 / Double(colours.count - 1) * Double($0.offset)) }
                self.angle = angle
            }
        }
        
        private class _GradientView: UIView {
            init(gradient: Gradient) {
                super.init(frame: .zero)
                
                gradientLayer.colors = gradient.stops.map { $0.colour.cgColor }
                gradientLayer.locations = gradient.stops.map { NSNumber(value: $0.position) }
                
                let (start, end) = points(forAngle: gradient.angle)
                gradientLayer.startPoint = start
                gradientLayer.endPoint = end
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            override class var layerClass: AnyClass {
                CAGradientLayer.self
            }
            
            var gradientLayer: CAGradientLayer {
                //swiftlint:disable:next force_cast
                layer as! CAGradientLayer
            }
            
            private func points(forAngle angle: Double) -> (start: CGPoint, end: CGPoint) {
                // I'm too lazy to do math -- https://stackoverflow.com/a/44922976/5539613
                let angle = angle / 360
                let a = pow(sin(2 * Double.pi * (angle + 0.75) / 2), 2)
                let b = pow(sin(2 * Double.pi * angle / 2), 2)
                let c = pow(sin(2 * Double.pi * (angle + 0.25) / 2), 2)
                let d = pow(sin(2 * Double.pi * (angle + 0.5) / 2), 2)
                
                return (start: CGPoint(x: CGFloat(a), y: CGFloat(b)), end: CGPoint(x: CGFloat(c), y: CGFloat(d)))
            }
        }
        
        private let innerGradientView: _GradientView!, rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z"), scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        
        init(gradient: Gradient) {
            innerGradientView = _GradientView(gradient: gradient)
            super.init(frame: .zero)
        
            addSubview(innerGradientView)
            
            rotationAnimation.fromValue = 0
            rotationAnimation.toValue = CGFloat.pi * 2
            rotationAnimation.isRemovedOnCompletion = false
            rotationAnimation.fillMode = .forwards
            rotationAnimation.repeatCount = .infinity
            
            scaleAnimation.fromValue = 1
            scaleAnimation.toValue = 2
            scaleAnimation.autoreverses = true
            scaleAnimation.isRemovedOnCompletion = false
            scaleAnimation.fillMode = .forwards
            scaleAnimation.repeatCount = .infinity
            
            NotificationCenter.default.addObserver(self, selector: #selector(receivedApplicationStatus(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(receivedApplicationStatus(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        
        @objc func receivedApplicationStatus(notification: Notification) {
            animationsEnabled = notification.name == UIApplication.didBecomeActiveNotification
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            setupAnimations()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var rotationAnimationSpeed: Double = 0 {
            didSet { setupAnimations() }
        }
        
        private var animationsEnabled = true {
            didSet { setupAnimations() }
        }
        
        private func setupAnimations() {
            innerGradientView.layer.removeAllAnimations()
            guard animationsEnabled, rotationAnimationSpeed > 0 else { return }
            
            innerGradientView.frame = bounds
            layoutIfNeeded()
            UIView.animate(withDuration: rotationAnimation.duration / 4, delay: 0, options: [.autoreverse, .repeat], animations: {
                let width = self.bounds.width
                let height = self.bounds.height
                self.innerGradientView.frame = CGRect(x: width / 2 - height / 2, y: height / 2 - width / 2, width: height, height: width)
            }, completion: nil)
            
            rotationAnimation.duration = 20 / rotationAnimationSpeed
            innerGradientView.layer.add(rotationAnimation, forKey: "rotation")
            
            scaleAnimation.duration = rotationAnimation.duration / 8
            innerGradientView.layer.add(scaleAnimation, forKey: "scale")
        }
    }

}
