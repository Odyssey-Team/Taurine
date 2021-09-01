//
//  UIApplication+Window.swift
//  Odyssey
//
//  Created by CoolStar on 7/3/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

extension UIApplication {
    var currentWindow: UIWindow? {
        connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .first(where: { $0.isKeyWindow })
    }
}
