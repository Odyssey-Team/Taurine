//
//  ThemesManager.swift
//  Odyssey
//
//  Created by CoolStar on 7/6/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class ThemesManager {
    static let shared = ThemesManager()
    static let themeChangeNotification = NSNotification.Name("ThemeChangeNotification")
    
    public static var customImageDirectory: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CustomImage")
            .appendingPathExtension("png")
    }()
    
    private let themes: [String: Theme] = [
        "default": Theme(colorViewBackgrounds: [
            .init(baseColour: .black, linearGradients: [
                .init(colours: [UIColor(red: 165/255, green: 0/255, blue: 0/255, alpha: 1), UIColor(red: 0/255, green: 11/255, blue: 141/255, alpha: 1)], angle: 47)
            ], overlayImage: nil)
        ], backgroundImage: nil, backgroundOverlay: nil, enableBlur: false),
        
        "sugarfree": Theme(colorViewBackgrounds: [
            .init(baseColour: .black, linearGradients: [
                .init(colours: [UIColor(red: 40/255, green: 175/255, blue: 200/255, alpha: 0.8), UIColor(red: 160/255, green: 160/255, blue: 160/255, alpha: 1)], angle: 70)
            ], overlayImage: nil)
        ], backgroundImage: nil, backgroundOverlay: nil, enableBlur: false),
        
        "mangoCrazy": Theme(colorViewBackgrounds: [
            .init(baseColour: .black, linearGradients: [
                .init(colours: [UIColor(red: 4/255, green: 160/255, blue: 205/255, alpha: 1), UIColor(red: 226/255, green: 171/255, blue: 54/255, alpha: 1)], angle: 47)
            ], overlayImage: nil)
        ], backgroundImage: nil,
           backgroundOverlay: nil,
           enableBlur: false),
        
        "soLastYear": Theme(colorViewBackgrounds: [
            .init(baseColour: .black, linearGradients: [
                .init(colours: [UIColor(red: 210/255, green: 135/255, blue: 244/255, alpha: 1), UIColor(red: 247/255, green: 107/255, blue: 28/255, alpha: 1)], angle: 47)
            ], overlayImage: nil)
        ], backgroundImage: nil, backgroundOverlay: nil, enableBlur: false),
        
        "azurLane": Theme(
            colorViewBackgrounds: [
                .init(baseColour: .black, linearGradients: [
                    .init(colours: [.black], angle: 0)
                ], overlayImage: nil)
            ],
            backgroundImage: UIImage(named: "azurLane"),
            backgroundCenter: CGPoint(x: 1510, y: 800),
            backgroundOverlay: UIColor(white: 0, alpha: 0.3),
            enableBlur: true,
            copyrightString: "Neptune and Monarch (Azur Lane)\nWallpaper © 2019, Zolaida\nWallpaper used under CC BY-NC-ND 3.0 license\nOriginal wallpaper from DeviantArt"),
        
        "linus": Theme(
            colorViewBackgrounds: [
                .init(baseColour: .black, linearGradients: [
                    .init(colours: [.black], angle: 0)
                ], overlayImage: nil)
            ],
            backgroundImage: UIImage(named: "Linus"),
            backgroundCenter: CGPoint(x: 340, y: 340),
            backgroundOverlay: UIColor(white: 0, alpha: 0.3),
            enableBlur: true,
            copyrightString: "lttstore.com"),
        
        "pokemon": Theme(
            colorViewBackgrounds: [
                .init(baseColour: .black, linearGradients: [
                    .init(colours: [.black], angle: 0)
                ], overlayImage: nil)
            ],
            backgroundImage: UIImage(named: "pokemon"),
            backgroundCenter: CGPoint(x: 720, y: 720),
            backgroundOverlay: UIColor(white: 0, alpha: 0.3),
            enableBlur: true,
            copyrightString: "Misty (Pokemon)\nWallpaper © 2016, Zolaida\nWallpaper used under CC BY-NC-ND 3.0 license\nOriginal wallpaper from DeviantArt"),
        
        "overwatch": Theme(
            colorViewBackgrounds: [
                .init(baseColour: .black, linearGradients: [
                    .init(colours: [.black], angle: 0)
                ], overlayImage: nil)
            ],
            backgroundImage: UIImage(named: "overwatch"),
            backgroundCenter: CGPoint(x: 600, y: 480),
            backgroundOverlay: UIColor(white: 1, alpha: 0.1),
            enableBlur: true,
            copyrightString: "D.va n' Lucio (Overwatch)\nWallpaper © 2017, raikoart\nWallpaper used under CC BY-NC-ND 3.0 license\nOriginal wallpaper from DeviantArt"),
        
        "league": Theme(
            colorViewBackgrounds: [
                .init(baseColour: .black, linearGradients: [
                    .init(colours: [.black], angle: 0)
                ], overlayImage: nil)
            ],
            backgroundImage: UIImage(named: "league"),
            backgroundCenter: CGPoint(x: 750, y: 540),
            backgroundOverlay: UIColor(white: 0, alpha: 0.1),
            enableBlur: true,
            copyrightString: "Lux [Star Guardian] (League of Legends)\nWallpaper © 2016, Liang-Xing\nWallpaper used under CC BY-NC-ND 3.0 license\nOriginal wallpaper from DeviantArt"),
        
        "custom": Theme(
            colorViewBackgrounds: [
                .init(baseColour: .black, linearGradients: [
                    .init(colours: [.black], angle: 0)
                ], overlayImage: nil)
            ],

            backgroundImage: nil,
            backgroundCenter: CGPoint(x: 0, y: 0),
            backgroundOverlay: UIColor(white: 0, alpha: 0),
            enableBlur: false),

        "customColourTheme": Theme(colorViewBackgrounds: [
            .init(baseColour: .black, linearGradients: [
                .init(colours: [UIColor(red: 210/255, green: 135/255, blue: 244/255, alpha: 1), UIColor(red: 247/255, green: 107/255, blue: 28/255, alpha: 1)], angle: 47)
            ], overlayImage: nil)
        ], backgroundImage: nil, backgroundOverlay: nil, enableBlur: false)
    ]
    
    public var currentTheme: Theme {
        let currentThemeName = UserDefaults.standard.string(forKey: "theme") ?? "default"
        return themes[currentThemeName] ?? themes["default"]!
    }
    
    public var customImage: UIImage? {
        if let imgData = try? Data(contentsOf: ThemesManager.customImageDirectory),
           let image = UIImage(data: imgData) {
            return image
        }

        return nil
    }
    
    public var customThemeBlur: Bool {
        if UserDefaults.standard.string(forKey: "theme") == "custom" {
            return UserDefaults.standard.optionalBool(key: "customThemeBlur", for: true)
        } else if UserDefaults.standard.string(forKey: "theme") == "customColourTheme" {
            return UserDefaults.standard.optionalBool(key: "customColourThemeBlur", for: true)
        } else {
            return true
        }
    }

    public var customColourBackground: [AnimatingColourView.GradientBackground] {
        let baseColour = UserDefaults.standard.color(forKey: "customBaseColour") ?? .black
        let gradientColour1 = UserDefaults.standard.color(forKey: "customColourOne") ?? UIColor(red: 210/255, green: 135/255, blue: 244/255, alpha: 1)
        let gradientColour2 = UserDefaults.standard.color(forKey: "customColourTwo") ?? UIColor(red: 247/255, green: 107/255, blue: 28/255, alpha: 1)
        
        return [.init(baseColour: baseColour, linearGradients: [
            .init(colours: [gradientColour1, gradientColour2], angle: 47)
        ], overlayImage: nil)]
    }
    
    init() {
        if UserDefaults.standard.string(forKey: "theme") == nil {
            UserDefaults.standard.set("default", forKey: "theme")
        }
    }
}

extension UserDefaults {

    func color(forKey key: String) -> UIColor? {

        guard let colorData = data(forKey: key) else { return nil }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
        } catch let error {
            print("color error \(error.localizedDescription)")
            return nil
        }

    }

    func set(_ value: UIColor?, forKey key: String) {
        guard let color = value else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch let error {
            print("error color key data not saved \(error.localizedDescription)")
        }
    }
    
    func optionalBool(key: String, for defaultValue: Bool = false) -> Bool {
        if data(forKey: key) != nil {
            return bool(forKey: key)
        }
        return defaultValue
    }

}
