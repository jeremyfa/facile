package facile;

class Facile {

    inline public static function radToDeg(rad:Float):Float {
        return rad * 57.29577951308232;
    }

    inline public static function degToRad(deg:Float):Float {
        return deg * 0.017453292519943295;
    }

    inline public static function round(value:Float, decimals:Int = 0):Float {
        return if (decimals > 0) {
            var factor = 1.0;
            while (decimals-- > 0) {
                factor *= 10.0;
            }
            Math.round(value * factor) / factor;
        }
        else {
            Math.round(value);
        }
    }

}
