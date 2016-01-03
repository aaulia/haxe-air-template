HAXE_MAIN   := Main
SOURCE_PATH := src
HAXE_LIBS   := air3

SWF_VERSION := 17
SWF_WIDTH   := 405
SWF_HEIGHT  := 720
SWF_FPS     := 60
SWF_COLOR   := 2b303b

PACKAGE_ID  := air.template.haxe
APP_FILE    := haxe-air-template
APP_TITLE   := 'Haxe AIR Template'
CER_PASS    := android-cer-password

VER_NUMBER 	:= 1.0.0
VER_LABEL 	:= $(VER_NUMBER)

# values: portrait, landscape, any
ORIENTATION := portrait
AUTO_ORIENT := true

# values: cpu, direct, gpu
RENDER_MODE := gpu



ADB         := adb
ADL         := adl
ADT         := adt
SED         := sed
HAXE        := haxe

SWF_HOME    := bin
PKG_HOME    := pkg
CER_HOME    := cer
RES_HOME    := res
ANE_HOME    := ane
LIB_HOME    := lib

ANDROID_SDK := $(ANDROID_SDK)

ANE_SWF_LIB  = $(sort $(wildcard $(LIB_HOME)/$(ANE_HOME)/*/library.swf))
ANE_EXT_IDS  = $(shell find ./$(LIB_HOME)/$(ANE_HOME) -type f -name 'extension.xml' -exec grep -oP '(?<=<id>).*(?=</id>)' "{}" \;)
APP_XML_OUT := .app.xml.out

BUILD_FLAGS += $(patsubst %,-cp %, $(SOURCE_PATH))
BUILD_FLAGS += $(patsubst %,-lib %,$(HAXE_LIBS))
BUILD_FLAGS += $(patsubst %,-swf-lib %,$(ANE_SWF_LIB))
BUILD_FLAGS += -main $(HAXE_MAIN)
BUILD_FLAGS += --flash-strict
BUILD_FLAGS += -swf-version $(SWF_VERSION)
BUILD_FLAGS += -swf-header $(SWF_WIDTH):$(SWF_HEIGHT):$(SWF_FPS):$(SWF_COLOR)

SIGNING_OPT := -storetype pkcs12 -keystore $(CER_HOME)/android/$(APP_FILE).p12 -storepass $(CER_PASS)
ADT_FLAGS   += $(SIGNING_OPT) $(PKG_HOME)/$(APP_FILE).apk $(APP_XML_OUT)
ADT_FLAGS   += -C $(SWF_HOME) $(APP_FILE).swf
ADT_FLAGS   += -C $(RES_HOME)/android icons
ADT_FLAGS   += -C $(RES_HOME) assets
ADT_FLAGS   += -extdir $(ANE_HOME)/
ADT_FLAGS   += -platformsdk $(ANDROID_SDK)

ADL_FLAGS   += -profile mobileDevice
ADL_FLAGS   += -screensize $(SWF_WIDTH)x$(SWF_HEIGHT):$(SWF_WIDTH)x$(SWF_HEIGHT)
ADL_FLAGS   += $(APP_XML_OUT)
ADL_FLAGS   += $(SWF_HOME)
ADL_FLAGS   += -extdir $(LIB_HOME)/$(ANE_HOME)/



export WINEDEBUG=-all
export AIR_NOANDROIDFLAIR=true
export UNZIP=-uq


.PHONY: all clean swf swf-dbg swf-run apk apk-dbg apk-run apk-log hxml unpack-ane

all: clean swf
swf:
	@echo [-] Building swf
	@$(HAXE) $(BUILD_FLAGS) -swf $(SWF_HOME)/$(APP_FILE).swf --no-traces -D advanced-telemetry

swf-dbg:
	@echo [-] Building debug swf
	@$(HAXE) $(BUILD_FLAGS) -swf $(SWF_HOME)/$(APP_FILE).swf -debug -D fdb

swf-run: unpack-ane
	@echo [-] Running swf through AIR Debug Launcher
	@$(ADL) $(ADL_FLAGS)

apk: swf $(CER_HOME)/android/$(APP_FILE).p12 $(APP_XML_OUT)
	@echo [-] Building Android Package \(APK\)
	@$(ADT) -package -target apk-captive-runtime $(ADT_FLAGS)
	@rm -f $(APP_XML_OUT)

apk-dbg: swf-dbg $(CER_HOME)/android/$(APP_FILE).p12 $(APP_XML_OUT)
	@echo [-] Building debug Android Package \(APK\)
	@$(ADT) -package -target apk-debug $(ADT_FLAGS)
	@rm -f $(APP_XML_OUT)

apk-run:
	@echo [-] Running on Android device/emulator
	@$(ADB) install -r $(PKG_HOME)/$(APP_FILE).apk
	@$(ADB) shell am start -n $(PACKAGE_ID)/.AppEntry

apk-log:
	@echo [-] Start Android Logcat
	@$(ADB) logcat -c
	@$(ADB) logcat $(PACKAGE_ID):I *:S

clean:
	@echo [-] Cleaning
	@rm -f $(SWF_HOME)/$(APP_FILE).swf
	@rm -f $(PKG_HOME)/$(APP_FILE).apk
	@rm -f $(APP_XML_OUT)
	@rm -rf $(LIB_HOME)/$(ANE_HOME)/*

hxml: unpack-ane
	@echo [-] Generating HXML file
	@rm -f build.hxml
	@for src_path in $(SOURCE_PATH); do echo "-cp $$src_path"     >> build.hxml; done
	@for haxe_lib in $(HAXE_LIBS);   do echo "-lib $$haxe_lib"    >> build.hxml; done
	@for swf_lib  in $(ANE_SWF_LIB); do echo "-swf-lib $$swf_lib" >> build.hxml; done
	@echo -main $(HAXE_MAIN) >> build.hxml
	@echo -swf dummy.swf >> build.hxml
	@echo -swf-version $(SWF_VERSION) >> build.hxml
	@echo -swf-header $(SWF_WIDTH):$(SWF_HEIGHT):$(SWF_FPS):$(SWF_COLOR) >> build.hxml
	@echo --flash-strict >> build.hxml
	@echo --no-output >> build.hxml

unpack-ane:
	@for ane in `find $(ANE_HOME) -type f -name '*.ane'`; do unzip $$ane -d $(LIB_HOME)/$(ANE_HOME)/$$(basename $$ane); done

$(CER_HOME)/android/$(APP_FILE).p12:
	@echo [-] Generating Android certificate
	@$(ADT) \
	-certificate -cn SelfSign -ou Self -o Self -validityPeriod 25 2048-RSA $@ $(CER_PASS)

$(APP_XML_OUT): unpack-ane
	@echo [-] Generating Application Descriptor
	@rm -f $(APP_XML_OUT)
	@cp app.xml $(APP_XML_OUT)
	@$(SED) -i s/{PACKAGE_ID}/$(PACKAGE_ID)/g   $(APP_XML_OUT)
	@$(SED) -i s/{APP_FILE}/$(APP_FILE)/g       $(APP_XML_OUT)
	@$(SED) -i s/{APP_TITLE}/$(APP_TITLE)/g     $(APP_XML_OUT)
	@$(SED) -i s/{VER_NUMBER}/$(VER_NUMBER)/g   $(APP_XML_OUT)
	@$(SED) -i s/{VER_LABEL}/$(VER_LABEL)/g     $(APP_XML_OUT)
	@$(SED) -i s/{ORIENTATION}/$(ORIENTATION)/g $(APP_XML_OUT)
	@$(SED) -i s/{AUTO_ORIENT}/$(AUTO_ORIENT)/g $(APP_XML_OUT)
	@$(SED) -i s/{RENDER_MODE}/$(RENDER_MODE)/g $(APP_XML_OUT)
	@$(SED) -i s/{EXTENSION_IDS}/'$(patsubst %,\n\t\t<extensionID>%<\/extensionID>,$(ANE_EXT_IDS))'/g $(APP_XML_OUT)
