package ;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display.StageQuality;
import flash.Lib;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;


class Main {

    public static function main() {
        Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

        var stage = Lib.current.stage;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.quality = StageQuality.LOW;

        //
        // Begin here
        //
    }

}