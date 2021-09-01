TARGET  = test-kernrw
OUTDIR ?= bin

ifneq (,$(wildcard /opt/procursus/bin/ldid))
CODESIGN = /opt/procursus/bin/ldid -Ksigncert.p12 -SEnt.plist
else
CODESIGN = ./ldid -Ksigncert.p12 -SEnt.plist
endif
CXX       = xcrun -sdk iphoneos clang++ -arch arm64 -arch arm64e -std=c++11

CFLAGS  = -Wall -Iinclude -I.

.PHONY: all clean

all: $(OUTDIR)/$(TARGET).gz

DEBUG ?= 0
ifeq ($(DEBUG), 1)
    CFLAGS += -DDEBUG
else
    CFLAGS += -O2 -fvisibility=hidden
    CFLAGS += -DVERSION_COMMIT_COUNT='"The people who are crazy enough to think they can change the world are the ones who do"'
    CFLAGS += -DVERSION_COMMIT_SHA='"I Used To Be An Adventurer Like You, Then I Took An Arrow In The Knee."'
endif

CFLAGS += -DCUSTOM_LOGGING="\"serial_log.h\""
CXXFLAGS += -DCUSTOM_LOGGING="\"serial_log.h\""

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/$(TARGET): main.cpp KernelRW.cpp libgeneral_exception.cpp serial_log.c | $(OUTDIR)
	$(CXX) -o $@ $^ $(CFLAGS) -framework IOKit
	strip $@
	$(CODESIGN) $@

$(OUTDIR)/$(TARGET).gz: $(OUTDIR)/$(TARGET)
	zstd -9 $(OUTDIR)/$(TARGET) -o $(OUTDIR)/$(TARGET).gz

clean:
	rm -f $(OUTDIR)/$(TARGET) $(OUTDIR)/$(TARGET).gz
