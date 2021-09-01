//
//  electra-stub.swift
//  Taurine
//
//  Created by CoolStar on 2/28/21.
//

import Foundation

/*@_cdecl("start_electra")
func startElectra(any_proc: UInt64){
    let electra = Electra(ui: UIStub(), any_proc: any_proc, enable_tweaks: true, restore_rootfs: false, nonce: "0xbd34a880be0b53f3")
    let status = electra.jailbreak()
    print("Jailbreak Status:", status)
}

@_cdecl("electra_presanitycheck")*/
func sanityCheck(){
    guard getSafeEntitlements().count >= 3 else {
        fatalError("We need at least 3 entitlements")
    }
    
    /*let signingThread = signPAC_initSigningOracle()
    
    let pcDiscriminator = UInt64(0x7481) //ptrauth_string_discriminator("pc")
    let lrDiscriminator = UInt64(0x77d3) //ptrauth_string_discriminator("lr")
    
    var signPac: [signPac_data] = []
    signPac.append(signPac_data(ptr: findSymbol("MISValidateSignatureAndCopyInfo"), context: UInt64(0)));
    signPac.append(signPac_data(ptr: findSymbol("posix_spawnp"), context: UInt64(0)));
    signPac.append(signPac_data(ptr: findSymbol("posix_spawn"), context: UInt64(0)));
    
    for data in signPac {
        print(String(format: "Unsigned: 0x%llx", data.ptr))
    }
    
    signPac_signPointers(&signPac, 3)
    
    for data in signPac {
        print(String(format: "Signed: 0x%llx", data.ptr))
    }
    
    signPac_destroySigningOracle()*/
    
    var statfsptr: UnsafeMutablePointer<statfs>?
    let mntsize = getmntinfo(&statfsptr, MNT_NOWAIT)
    guard mntsize != 0 else {
        fatalError("Unable to get mount info")
    }
    for _ in 0..<mntsize {
        if var statfs = statfsptr?.pointee {
            let on = withUnsafePointer(to: &statfs.f_mntonname.0){
                $0.withMemoryRebound(to: UInt8.self, capacity: Int(MAXPATHLEN)){
                    String(cString: $0)
                }
            }
            let from = withUnsafePointer(to: &statfs.f_mntfromname.0){
                $0.withMemoryRebound(to: UInt8.self, capacity: Int(MAXPATHLEN)){
                    String(cString: $0)
                }
            }
            print("Mounted on", on, "from",from)
        }
        statfsptr = statfsptr?.successor()
    }
}
