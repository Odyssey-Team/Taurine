BUNDLE := org.coolstar.taurine

.PHONY: all clean

all: clean
	#$(MAKE) -C amfidebilitate clean all
	#cd Taurine/resources && tar -xf basebinaries.tar
	#rm -f Taurine/resources/{amfidebilitate,basebinaries.tar}
	#cp {amfidebilitate}/bin/* Taurine/resources
	#cd Taurine/resources && tar -cf basebinaries.tar amfidebilitate jailbreakd jbexec pspawn_payload-stg2.dylib pspawn_payload.dylib
	#rm -f Taurine/resources/{amfidebilitate,jailbreakd,jbexec,*.dylib}
	xcodebuild clean build CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO PRODUCT_BUNDLE_IDENTIFIER="$(BUNDLE)" -sdk iphoneos -scheme Taurine -configuration Release -derivedDataPath build
	ln -sf build/Build/Products/Release-iphoneos Payload
	rm -rf Payload/Taurine.app/Frameworks
	zip -r9 Taurine.ipa Payload/Taurine.app

clean:
	rm -rf build Payload Taurine.ipa
	#$(MAKE) -C amfidebilitate clean
