BUNDLE := com.odysseyteam.taurine

.PHONY: all clean

all: clean
	$(MAKE) -C amfidebilitate clean all
	cd Taurine/resources && tar -xf basebinaries.tar
	rm -f Taurine/resources/{amfidebilitate,basebinaries.tar}        
	cp amfidebilitate/bin/* Taurine/resources
	cd Taurine/resources && tar -cf basebinaries.tar amfidebilitate img4tool jailbreakd jbexec launchjailbreak pspawn_payload-stg2.dylib pspawn_payload.dylib        
	rm -f Taurine/resources/{amfidebilitate,img4tool,jailbreakd,jbexec,launchjailbreak,*.dylib}
	xcodebuild clean build CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO PRODUCT_BUNDLE_IDENTIFIER="$(BUNDLE)" -sdk iphoneos -scheme Taurine -configuration Release -derivedDataPath build
	ln -sf build/Build/Products/Release-iphoneos Payload
	rm -rf Payload/Taurine.app/Frameworks
	cp -R Payload/Taurine.app/Base.lproj/Main.storyboardc Payload/Taurine.app
	zip -r9 Taurine.ipa Payload/Taurine.app
clean:
	rm -rf build Payload Taurine.ipa
	$(MAKE) -C amfidebilitate clean
