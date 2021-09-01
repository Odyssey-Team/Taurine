//
//  vnodeUtil.swift
//  Taurine
//
//  Created by CoolStar on 1/16/21.
//  Copyright © 2021 coolstar. All rights reserved.
//

import Foundation

func getVnode(file: String, our_proc: UInt64) -> (UInt64, Int32) {
    guard let cFile = file.cString(using: .utf8) else {
        return (0, 0)
    }
    
    let offsets = Offsets.shared
    
    let fd = open(cFile, O_RDONLY)
    if fd < 0 {
        return (0, 0)
    }
    
    let proc_fd = rk64(our_proc + offsets.proc.fd)
    
    let ofiles = rk64(proc_fd + offsets.filedesc.ofiles)
    let fproc = rk64(ofiles + UInt64(fd * 8))
    let fglob = rk64(fproc + offsets.fileproc.fglob)
    let vnode = rk64(fglob + offsets.fileglob.data)
    
    return (vnode, fd)
}

func retainFile(file: String, our_proc: UInt64) {
    let vnodeRet = getVnode(file: file, our_proc: our_proc)
    let vnode = vnodeRet.0
    let fd = vnodeRet.1
    
    let offsets = Offsets.shared
    wk32(vnode + offsets.vnode.usecount, rk32(vnode + offsets.vnode.usecount) + 1)
    
    close(fd)
}
