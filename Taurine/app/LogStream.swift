//
//  LogStream.swift
//  Odyssey
//
//  Created by CoolStar on 7/1/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import Foundation
import UIKit

final class StandardOutputStream: TextOutputStream {
    static let shared = StandardOutputStream()
    private let fileHandle = FileHandle(fileDescriptor: LogStream.shared.outputFd[1])
    func write(_ string: String) {
        fileHandle.write(Data(string.utf8))
    }
}

final class StandardErrorOutputStream: TextOutputStream {
    static let shared = StandardErrorOutputStream()
    private let fileHandle = FileHandle(fileDescriptor: LogStream.shared.errFd[1])
    func write(_ string: String) {
        fileHandle.write(Data(string.utf8))
    }
}

private var debugOutput = StandardOutputStream.shared
func debugPrint(items: Any...) {
    print(items, to: &debugOutput)
}

@_cdecl("swiftDebug_internal")
func swiftDebug(str: UnsafePointer<CChar>?){
    guard let str = str else {
        return
    }
    let swiftString = String(cString: str)
    debugPrint(swiftString)
}

@_cdecl("logger_stdout")
func logger_stdout() -> Int32 {
    LogStream.shared.outputFd[1]
}

@_cdecl("logger_stderr")
func logger_stderr() -> Int32 {
    LogStream.shared.errFd[1]
}

class LogStream {
    static let shared = LogStream()
    
    private(set) var outputString: NSMutableAttributedString = NSMutableAttributedString()
    public let reloadNotification = Notification.Name("LogStreamReloadNotification")
    
    private(set) var outputFd: [Int32] = [0, 0]
    private(set) var errFd: [Int32] = [0, 0]
    
    private let readQueue: DispatchQueue
    
    private let outputSource: DispatchSourceRead
    private let errorSource: DispatchSourceRead
    
    init() {
        readQueue = DispatchQueue(label: "org.coolstar.sileo.logstream",
                                  qos: .userInteractive,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        
        guard pipe(&outputFd) != -1,
            pipe(&errFd) != -1 else {
                fatalError("pipe failed")
        }
        
        let origOutput = dup(STDOUT_FILENO)
        let origErr = dup(STDERR_FILENO)
        
        setvbuf(stdout, nil, _IONBF, 0)
        
        guard dup2(outputFd[1], STDOUT_FILENO) >= 0,
            dup2(errFd[1], STDERR_FILENO) >= 0 else {
                fatalError("dup2 failed")
        }
        
        outputSource = DispatchSource.makeReadSource(fileDescriptor: outputFd[0], queue: readQueue)
        errorSource = DispatchSource.makeReadSource(fileDescriptor: errFd[0], queue: readQueue)
        
        outputSource.setCancelHandler {
            close(self.outputFd[0])
            close(self.outputFd[1])
        }
        
        errorSource.setCancelHandler {
            close(self.errFd[0])
            close(self.errFd[1])
        }
        
        let bufsiz = Int(BUFSIZ)
        
        outputSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }
            
            let bytesRead = read(self.outputFd[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }
                
                self.outputSource.cancel()
                return
            }
            write(origOutput, buffer, bytesRead)
            
            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                let textColor = UIColor.white
                let substring = NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor: textColor])
                
                self.outputString.append(substring)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: self.reloadNotification, object: nil)
                }
            }
        }
        
        errorSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }
            
            let bytesRead = read(self.errFd[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }
                
                self.errorSource.cancel()
                return
            }
            write(origErr, buffer, bytesRead)
            
            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                let textColor = UIColor(red: 219/255.0, green: 44.0/255.0, blue: 56.0/255.0, alpha: 1)
                let substring = NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor: textColor])
                
                self.outputString.append(substring)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: self.reloadNotification, object: nil)
                }
            }
        }
        
        outputSource.resume()
        errorSource.resume()
    }
    
    func pause(){
        outputSource.suspend()
        errorSource.suspend()
    }
    
    func resume(){
        outputSource.resume()
        errorSource.resume()
    }
}
