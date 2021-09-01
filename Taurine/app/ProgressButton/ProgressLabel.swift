//
//  ProgressLabel.swift
//  taurine
//
//  Created by CoolStar on 3/14/21.
//

import UIKit

extension UIColor {
    var inverted: UIColor {
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: (1 - r), green: (1 - g), blue: (1 - b), alpha: a) // Assuming you want the same alpha value.
    }
}

class ProgressLabel: UIView {
    public var progress = CGFloat(0)
    public var titleColor: UIColor?
    public var title: String?
    public var font: UIFont?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func draw(_ rect: CGRect) {
        titleColor = UIColor.white
        guard let ctx = UIGraphicsGetCurrentContext(),
              let font = font,
              let titleStr = title as? NSString,
              let titleColor = titleColor else {
            return
        }
        
        let size = bounds.size
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        attributes[.foregroundColor] = titleColor.inverted
        
        let textSize = titleStr.size(withAttributes: attributes)
        let progressX = self.progress * size.width
        let textPoint = CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2)
        
        UIColor.clear.setFill()
        ctx.fill(bounds)
        
        titleStr.draw(at: textPoint, withAttributes: attributes)
        
        ctx.saveGState()
        let remainingProgressRect = CGRect(x: progressX, y: 0, width: size.width - progress, height: size.height)
        ctx.addRect(remainingProgressRect)
        ctx.clip()
        
        UIColor.clear.setFill()
        ctx.fill(bounds)
        attributes[.foregroundColor] = titleColor
        
        titleStr.draw(at: textPoint, withAttributes: attributes)
        
        ctx.restoreGState()
    }
}
