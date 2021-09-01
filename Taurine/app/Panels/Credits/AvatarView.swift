//
//  AvatarView.swift
//  Chimera
//
//  Created by Ayden Panhuyzen on 2019-04-13.
//  Copyright © 2019 Electra Team. All rights reserved.
//
//  This file was taken from another project, and it’s inclusion here does not indicate the author’s endorsement.

import UIKit

class AvatarView: UIImageView {
    private var task: URLSessionDataTask?
    @IBInspectable var github: String = ""
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        backgroundColor = UIColor(white: 0.9, alpha: 1)
        layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        clipsToBounds = true
        layer.borderWidth = 1 / (window?.screen.scale ?? 1)
        
        self.url = URL(string: "https://github.com/\(github).png")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.size.width, bounds.size.height) / 2
    }
    
    var url: URL? {
        didSet {
            guard url != oldValue else { return }
            image = nil
            task?.cancel()
            guard let url = url else { return }
            let thisURL = url
            let start = DispatchTime.now()
            task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard thisURL == url else { return }
                guard let data = data, let image = UIImage(data: data), error == nil else { print("Couldn't load avatar image due to error:", error ?? "unknown"); return }
                let end = DispatchTime.now()
                let tookLong = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) >= 150000000 // if >= 0.15s
                self?.change(image: image, animated: tookLong)
            }
            task?.resume()
        }
    }
    
    private func change(image: UIImage, animated: Bool = true) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.change(image: image, animated: animated)
            }
            return
        }
        UIView.transition(with: self, duration: animated ? 0.35 : 0, options: [.allowAnimatedContent, .transitionCrossDissolve], animations: {
            self.image = image
        }, completion: nil)
    }

}
