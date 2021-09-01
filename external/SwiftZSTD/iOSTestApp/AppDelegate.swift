//
//  AppDelegate.swift
//  iOSTestApp
//
//  Created by Anatoli on 1/20/20.
//

import UIKit

/**
 * This is a GUI-less app for testing SwiftZSTD on a real iOS device.
 * Alternatively one can test the SwiftZSTD_iOS target on a simulator.
 * Either way the set of tests is the same one that is used for testing
 * the SwiftZSTD_macOS target.
 */

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}

