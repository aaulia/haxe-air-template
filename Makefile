HAXE_MAIN   := Main
HAXE_PATH   := src
HAXE_LIBS   := air3

SWF_VERSION := 11.3
SWF_WIDTH   := 405
SWF_HEIGHT  := 720
SWF_FPS     := 60
SWF_COLOR   := 012345

SWF_HOME    := bin
PKG_HOME    := pkg
CER_HOME    := cer

PACKAGE_ID  := air.template.haxe
APP_NAME    := haxe-air-template
CER_PASS    := android-cer-password

ADB         := adb
ADL         := adl
ADT         := adt
HAXE        := haxe

BUILD_FLAGS += $(patsubst %,-cp %, $(HAXE_PATH))
BUILD_FLAGS += $(patsubst %,-lib %,$(HAXE_LIBS))
BUILD_FLAGS += -main $(HAXE_MAIN)
BUILD_FLAGS += --flash-strict
BUILD_FLAGS += -swf-version $(SWF_VERSION)
BUILD_FLAGS += -swf-header $(SWF_WIDTH):$(SWF_HEIGHT):$(SWF_FPS):$(SWF_COLOR)

SIGNING_OPT := -storetype pkcs12 -keystore $(CER_HOME)/android/$(APP_NAME).p12 -storepass $(CER_PASS)

ADL_FLAGS   += -profile mobileDevice
ADL_FLAGS   += -screensize $(SWF_WIDTH)x$(SWF_HEIGHT):$(SWF_WIDTH)x$(SWF_HEIGHT)
ADL_FLAGS   += app.xml
ADL_FLAGS   += $(SWF_HOME)



.PHONY: all clean swf swf-dbg hxml apk apk-dbg apk-install swf-run apk-run apk-log

all: clean swf
swf:
	@$(HAXE) $(BUILD_FLAGS) -swf $(SWF_HOME)/$(APP_NAME).swf --no-traces

swf-dbg:
	@$(HAXE) $(BUILD_FLAGS) -swf $(SWF_HOME)/$(APP_NAME).swf -debug -D fdb

swf-run:
	@WINEDEBUG=-all $(ADL) $(ADL_FLAGS)

apk: $(CER_HOME)/android/$(APP_NAME).p12 swf
	@AIR_NOANDROIDFLAIR=true \
	$(ADT) -package -target apk-captive-runtime $(SIGNING_OPT) $(PKG_HOME)/$(APP_NAME).apk app.xml \
	-C $(SWF_HOME) $(APP_NAME).swf \
	-C res/android icons

apk-dbg: $(CER_HOME)/android/$(APP_NAME).p12 swf-dbg
	@AIR_NOANDROIDFLAIR=true \
	$(ADT) -package -target apk-debug $(SIGNING_OPT) $(PKG_HOME)/$(APP_NAME).apk app.xml \
	-C $(SWF_HOME) $(APP_NAME).swf \
	-C res/android icons

apk-run:
	@$(ADB) install -r $(PKG_HOME)/$(APP_NAME).apk
	@$(ADB) shell am start -n $(PACKAGE_ID)/.AppEntry

apk-log:
	@$(ADB) logcat -c
	@$(ADB) logcat $(PACKAGE_ID):I *:S

clean:
	@rm -f $(SWF_HOME)/$(APP_NAME).swf
	@rm -f $(PKG_HOME)/$(APP_NAME).apk

hxml:
	@rm -f build.hxml
	@echo "$(patsubst %,-cp %,$(HAXE_PATH))" >> build.hxml
	@echo "-main $(HAXE_MAIN)" >> build.hxml
	@echo "$(patsubst %,-lib %,$(HAXE_LIBS))" >> build.hxml
	@echo "-swf dummy.swf" >> build.hxml
	@echo "-swf-version $(SWF_VERSION)" >> build.hxml
	@echo "-swf-header $(SWF_WIDTH):$(SWF_HEIGHT):$(SWF_FPS):$(SWF_COLOR)" >> build.hxml
	@echo "--flash-strict" >> build.hxml
	@echo "--no-output" >> build.hxml

$(CER_HOME)/android/$(APP_NAME).p12:
	@$(ADT) \
	-certificate -cn SelfSign -ou Self -o Self -validityPeriod 25 2048-RSA $@ $(CER_PASS)
