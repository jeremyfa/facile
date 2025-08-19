package facile;

import haxe.CallStack.StackItem;
import haxe.CallStack;
import haxe.EnumFlags;

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

    public static function printStackTrace(returnOnly:Bool = false):String {

        var result = new StringBuf();

        inline function print(data:Dynamic) {
            if (!returnOnly) {
                #if cs
                trace(data);
                #elseif android
                trace('' + data);
                #elseif sys
                Sys.println('' + data);
                #else
                trace(data);
                #end
            }
            result.add(data);
            result.addChar('\n'.code);
        }

        var stack = CallStack.callStack();

        // Reverse stack
        var reverseStack = [].concat(stack);
        reverseStack.reverse();
        reverseStack.pop(); // Remove last element, no need to display it

        // Print stack trace and error
        for (item in reverseStack) {
            print(stackItemToString(item));
        }

        return result.toString();

    }

    public static function stackItemToString(item:StackItem):String {

        var colors = false; // TODO?

        var str:String = "";
        switch (item) {
            case CFunction:
                str = "a C function";
            case Module(m):
                str = "module " + m;
            case FilePos(itm, file, line):
                if (itm != null) {
                    str = stackItemToString(itm);
                    if (colors) {
                        str = '\033[31m' + str + '\033[0m';
                    }
                }
                if (colors) {
                    if (itm != null) {
                        str += ' \033[90m';
                    }
                }
                else {
                    if (itm != null) {
                        str += ' ';
                    }
                }
                str += file;
                #if HXCPP_STACK_LINE
                str += ":";
                str += line;
                #end
                if (colors) {
                    if (itm != null) {
                        str += '\033[0m';
                    }
                }
            case Method(cname, meth):
                if (cname != null) {
                    str += (cname);
                    str += (".");
                }
                str += (meth);
            #if (haxe_ver >= "3.1.0")
            case LocalFunction(n):
            #else
            case Lambda(n):
            #end
                str += ("local function #");
                str += (n);
        }

        return str;

    }

}
