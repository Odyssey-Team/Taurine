TARGETNAME = amfidebilitate
OUTDIR ?= bin

SWIFTC = xcrun -sdk iphoneos swiftc -target $(ARCH)-apple-ios14.0
CC = xcrun -sdk iphoneos clang -arch $(ARCH) -target $(ARCH)-apple-ios14.0
CXX = xcrun -sdk iphoneos clang -arch $(ARCH) -target $(ARCH)-apple-ios14.0 -std=c++11
ifneq (,$(wildcard /opt/procursus/bin/ldid))
LDID = /opt/procursus/bin/ldid
else
LDID = ./ldid
endif

.PHONY: all clean

all: fat

SWIFTFLAGS = -Xcc "-Iinclude" -Xcc -DENABLE_XPC
CFLAGS = -Iinclude -DENABLE_XPC -miphoneos-version-min=14.0

DEBUG ?= 0
SERIAL = 0

LOG_FILES =
ifeq ($(DEBUG), 1)
	SWIFTFLAGS += -D DEBUG
	CFLAGS += -DDEBUG
else
	SWIFTFLAGS += -O
	CFLAGS += -O3
	CFLAGS += -DVERSION_COMMIT_COUNT='"The people who are crazy enough to think they can change the world are the ones who do"'
	CFLAGS += -DVERSION_COMMIT_SHA='"I Used To Be An Adventurer Like You, Then I Took An Arrow In The Knee."'
endif

$(OUTDIR):
	mkdir -p $(OUTDIR)

%-$(ARCH).o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

%-$(ARCH).co: %.cpp
	$(CXX) -c -o $@ $< $(CFLAGS)

$(OUTDIR)/$(TARGETNAME)-$(ARCH): main.swift machoparse.swift amfidtakeover.swift amfidhook.swift offsets.swift electra.swift swiftUtil.swift cutils-$(ARCH).o kernrw_daemonUser-$(ARCH).o signPAC-$(ARCH).o $(LOG_FILES) KernelRW-$(ARCH).co KernelRwWrapper-$(ARCH).co libgeneral_exception-$(ARCH).co | $(OUTDIR)
	$(SWIFTC) -o $@ $^ -import-objc-header amfidebilitate-Bridging-Header.h $(SWIFTFLAGS) -framework IOKit -lc++
	strip $@
	$(LDID) -Ksigncert.p12 -Sent.plist $@
	rm *.o

fat:
	$(MAKE) $(OUTDIR)/$(TARGETNAME)-arm64 ARCH=arm64 DEBUG=$(DEBUG)
	$(MAKE) $(OUTDIR)/$(TARGETNAME)-arm64e ARCH=arm64e DEBUG=$(DEBUG)
	lipo -create $(OUTDIR)/$(TARGETNAME)-arm64 $(OUTDIR)/$(TARGETNAME)-arm64e -output $(OUTDIR)/$(TARGETNAME)
	rm $(OUTDIR)/$(TARGETNAME)-arm64 $(OUTDIR)/$(TARGETNAME)-arm64e

clean:
	rm -f $(OUTDIR)/$(TARGETNAME) $(OUTDIR)/$(TARGETNAME)-arm64 $(OUTDIR)/$(TARGETNAME)-arm64e *.o *.co
