//
//  amfidhook.swift
//  Odyssey
//
//  Created by CoolStar on 5/8/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import Foundation
import CommonCrypto

func getOverriddenSignature(path: String) -> [UInt8]? {
    guard let pathdata = path.data(using: .utf8) else {
        return nil
    }
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    _ = pathdata.withUnsafeBytes { CC_SHA256($0.baseAddress, CC_LONG(pathdata.count), &hash) }
    let hashStr = hash.map { String(format: "%02hhx", $0) }.joined()
    let pathStr = "/taurine/cstmp/" + hashStr
    
    guard let cdHashData = try? Data(contentsOf: URL(fileURLWithPath: pathStr)) else {
        return nil
    }
    guard cdHashData.count == CS_CDHASH_LEN else {
        return nil
    }
    return [UInt8](cdHashData)
}
