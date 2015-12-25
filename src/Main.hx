package ;

import flash.Lib;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;

class Main 
{
    private static var stage = Lib.current.stage;

    private static function initialize()
    {
        //
        // TODO: BEGIN HERE
        //
    }
    
    private static function main() 
    {
        Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.addEventListener(Event.RESIZE, onResize);
    }

    private static function onResize(e:Event)
    {
        var correctSizeReported = cast(stage.fullScreenWidth,  Int) == stage.stageWidth 
                               && cast(stage.fullScreenHeight, Int) == stage.stageHeight;

        if (correctSizeReported) {
            stage.removeEventListener(Event.RESIZE, onResize);
            initialize();
        }
    }

}