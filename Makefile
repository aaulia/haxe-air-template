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

ANE_SWF_LIB := $(sort $(wildcard $(LIB_HOME)/$(ANE_HOME)/*/library.swf))
ANE_EXT_IDS := $(shell find ./$(LIB_HOME)/$(ANE_HOME) -type f -name 'extension.xml' -exec grep -oP '(?<=<id>).*(?=</id>)' "{}" \;)
ANDROID_SDK := $(ANDROID_SDK)

BUILD_FLAGS += $(patsubst %,-cp %, $(SOURCE_PATH))
BUILD_FLAGS += $(patsubst %,-lib %,$(HAXE_LIBS))
BUILD_FLAGS += $(patsubst %,-swf-lib %,$(ANE_SWF_LIB))
BUILD_FLAGS += -main $(HAXE_MAIN)
BUILD_FLAGS += --flash-strict
BUILD_FLAGS += -swf-version $(SWF_VERSION)
BUILD_FLAGS += -swf-header $(SWF_WIDTH):$(SWF_HEIGHT):$(SWF_FPS):$(SWF_COLOR)

SIGNING_OPT := -storetype pkcs12 -keystore $(CER_HOME)/android/$(APP_FILE).p12 -storepass $(CER_PASS)
ADT_FLAGS   += $(SIGNING_OPT) $(PKG_HOME)/$(APP_FILE).apk app.xml.out
ADT_FLAGS   += -C $(SWF_HOME) $(APP_FILE).swf
ADT_FLAGS   += -C $(RES_HOME)/android icons
ADT_FLAGS   += -C $(RES_HOME) assets
ADT_FLAGS   += -extdir $(ANE_HOME)/
ADT_FLAGS   += -platformsdk $(ANDROID_SDK)

ADL_FLAGS   += -profile mobileDevice
ADL_FLAGS   += -screensize $(SWF_WIDTH)x$(SWF_HEIGHT):$(SWF_WIDTH)x$(SWF_HEIGHT)
ADL_FLAGS   += app.xml.out
ADL_FLAGS   += $(SWF_HOME)
ADL_FLAGS   += -extdir $(LIB_HOME)/$(ANE_HOME)/



export WINEDEBUG=-all
export AIR_NOANDROIDFLAIR=true



.PHONY: all clean swf swf-dbg swf-run apk apk-dbg apk-run apk-log hxml

all: clean swf
swf:
	@echo [-] Building swf
	@$(HAXE) $(BUILD_FLAGS) -swf $(SWF_HOME)/$(APP_FILE).swf --no-traces -D advanced-telemetry

swf-dbg:
	@echo [-] Building debug swf
	@$(HAXE) $(BUILD_FLAGS) -swf $(SWF_HOME)/$(APP_FILE).swf -debug -D fdb

swf-run: app.xml.out
	@echo [-] Running swf through AIR Debug Launcher
	@$(ADL) $(ADL_FLAGS)
	@rm app.xml.out

apk: swf $(CER_HOME)/android/$(APP_FILE).p12 app.xml.out
	@echo [-] Building Android Package \(APK\)
	@$(ADT) -package -target apk-captive-runtime $(ADT_FLAGS)
	@rm app.xml.out

apk-dbg: swf-dbg $(CER_HOME)/android/$(APP_FILE).p12 app.xml.out
	@echo [-] Building debug Android Package \(APK\)
	@$(ADT) -package -target apk-debug $(ADT_FLAGS)
	@rm app.xml.out

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
	@rm -f app.xml.out

hxml:
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

$(CER_HOME)/android/$(APP_FILE).p12:
	@echo [-] Generating Android certificate
	@$(ADT) \
	-certificate -cn SelfSign -ou Self -o Self -validityPeriod 25 2048-RSA $@ $(CER_PASS)

app.xml.out:
	@echo [-] Generating Application Descriptor
	@rm -f app.xml.out
	@cp app.xml app.xml.out
	@$(SED) -i s/{PACKAGE_ID}/$(PACKAGE_ID)/g app.xml.out
	@$(SED) -i s/{APP_FILE}/$(APP_FILE)/g app.xml.out
	@$(SED) -i s/{APP_TITLE}/$(APP_TITLE)/g app.xml.out
	@$(SED) -i s/{VER_NUMBER}/$(VER_NUMBER)/g app.xml.out
	@$(SED) -i s/{VER_LABEL}/$(VER_LABEL)/g app.xml.out
	@$(SED) -i s/{ORIENTATION}/$(ORIENTATION)/g app.xml.out
	@$(SED) -i s/{AUTO_ORIENT}/$(AUTO_ORIENT)/g app.xml.out
	@$(SED) -i s/{RENDER_MODE}/$(RENDER_MODE)/g app.xml.out
	@$(SED) -i s/{EXTENSION_IDS}/'$(patsubst %,\n\t\t<extensionID>%<\/extensionID>,$(ANE_EXT_IDS))'/g app.xml.out
