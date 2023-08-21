TARGETNAME = ctbypass
OUTDIR ?= bin
ARCH = arm64

SWIFTC = xcrun -sdk iphoneos swiftc -target $(ARCH)-apple-ios14.0
ifneq (,$(wildcard /opt/procursus/bin/ldid))
LDID = /opt/procursus/bin/ldid
else
LDID = ./ldid
endif

all: ctbypass

ctbypass: helloworld.swift
	$(SWIFTC) -o $@ $^
	strip $@
	$(LDID) -Kdev_certificate.p12 -Upassword -M -SEntitlements.plist $@
