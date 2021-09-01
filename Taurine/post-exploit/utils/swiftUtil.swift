//
//  swiftUtil.swift
//  Taurine
//
//  Created by CoolStar on 4/3/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import Foundation

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}

func queryDaemon(daemonLabel: String) -> Int {
    let dict = xpc_dictionary_create(nil, nil, 0)
    xpc_dictionary_set_uint64(dict, "subsystem", 3)
    xpc_dictionary_set_uint64(dict, "handle", UInt64(HANDLE_SYSTEM))
    xpc_dictionary_set_uint64(dict, "routine", UInt64(ROUTINE_LIST))
    xpc_dictionary_set_uint64(dict, "type", 1)
    xpc_dictionary_set_bool(dict, "legacy", true)
    
    var outDict: xpc_object_t?
    var queriedPid = 0
    
    let rc = xpc_pipe_routine(xpc_bootstrap_pipe(), dict, &outDict)
    if rc == 0,
       let outDict = outDict {
        let err = xpc_dictionary_get_uint64(outDict, "error")
        if err == 0 {
            //We actually got a reply!
            if let svcs = xpc_dictionary_get_value(outDict, "services"),
               xpc_object_is_dict(svcs) {
                xpc_dictionary_apply(svcs) { label, svc -> Bool in
                    let pid = xpc_dictionary_get_int64(svc, "pid")
                    if pid != 0 {
                        let labelStr = String(cString: label)
                        if labelStr == daemonLabel {
                            queriedPid = Int(pid)
                        }
                    }
                    return true
                }
            } else {
                print("Incorrect response from launchd")
            }
        } else {
            print(String(format: "Error: %d - %s", err, xpc_strerror(Int32(err))))
        }
    } else {
        print(String(format: "Unable to get launchd: %d", rc))
    }
    return queriedPid
}
