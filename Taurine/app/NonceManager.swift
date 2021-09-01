//
//  NonceManager.swift
//  Odyssey
//
//  Created by CoolStar on 7/6/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import Foundation

class NonceManager: TextButtonDelegate {
    public static let shared = NonceManager()
    let defaultGenerator = "0xbd34a880be0b53f3"
    
    init() {
        if UserDefaults.standard.string(forKey: "generator") == nil {
            UserDefaults.standard.set(defaultGenerator, forKey: "generator")
        }
        guard let currentGenerator = UserDefaults.standard.string(forKey: "generator") else {
            return
        }
        if !isGeneratorValid(generator: currentGenerator) {
            UserDefaults.standard.set(defaultGenerator, forKey: "generator")
        }
    }
    
    var defaultValue: String {
        defaultGenerator
    }
    
    var currentValue: String {
        let generator = UserDefaults.standard.string(forKey: "generator") ?? defaultGenerator
        if !isGeneratorValid(generator: generator) {
            return defaultGenerator
        }
        return generator
    }
    
    func isInputValid(input: String) -> Bool {
        if input.isEmpty {
            return true
        }
        return isGeneratorValid(generator: input)
    }
    
    func receiveInput(input: String) {
        if input.isEmpty || !isGeneratorValid(generator: input) {
            UserDefaults.standard.set(defaultGenerator, forKey: "generator")
        } else {
            UserDefaults.standard.set(input, forKey: "generator")
        }
        UserDefaults.standard.synchronize()
    }
}
