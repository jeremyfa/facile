package facile;

import facile.Facile;
import facile.Slug;

using StringTools;

class TextUtils {

    static final RE_PREFIXED = ~/^(.*?)([0-9]+)$/;

    static final RE_NUMERIC_PREFIX = ~/^[0-9]+/;

    static final RE_SPACES = ~/\s+/;

    static final RE_ASCII_CHAR = ~/^[a-zA-Z0-9]$/;

    public static function compareStrings(a:String, b:String) {
        a = a.toUpperCase();
        b = b.toUpperCase();

        if (a < b) {
          return -1;
        }
        else if (a > b) {
          return 1;
        }
        else {
          return 0;
        }
    }

    public static function compareStringFirstEntries(aArray:Array<Dynamic>, bArray:Array<Dynamic>) {
        var a:String = aArray[0];
        var b:String = bArray[0];

        a = a.toUpperCase();
        b = b.toUpperCase();

        if (a < b) {
          return -1;
        }
        else if (a > b) {
          return 1;
        }
        else {
          return 0;
        }
    }

    /** Transforms `SOME_IDENTIFIER` to `SomeIdentifier` */
    public static function upperCaseToCamelCase(input:String, firstLetterUppercase:Bool = true, ?between:String):String {

        var res = new StringBuf();
        var len = input.length;
        var i = 0;
        var nextLetterUpperCase = firstLetterUppercase;

        while (i < len) {

            var c = input.charAt(i);
            if (c == '_') {
                nextLetterUpperCase = true;
            }
            else if (nextLetterUpperCase) {
                nextLetterUpperCase = false;
                if (i > 0 && between != null) {
                    res.add(between);
                }
                res.add(c.toUpperCase());
            }
            else {
                res.add(c.toLowerCase());
            }

            i++;
        }

        return res.toString();

    }

    /**
     * Transforms `SomeIdentifier`/`someIdentifier`/`some identifier` to `SOME_IDENTIFIER`
     */
    public static function camelCaseToUpperCase(input:String, firstLetterUppercase:Bool = true):String {

        var res = new StringBuf();
        var len = input.length;
        var i = 0;
        var canAddSpace = false;

        while (i < len) {

            var c = input.charAt(i);
            if (c == '.') {
                res.add('_');
                canAddSpace = false;
            }
            else if (RE_ASCII_CHAR.match(c)) {

                var uc = c.toUpperCase();
                var isUpperCase = (c == uc);

                if (canAddSpace && isUpperCase) {
                    res.add('_');
                    canAddSpace = false;
                }

                res.add(uc);
                canAddSpace = !isUpperCase;
            }
            else {
                res.add('_');
                canAddSpace = false;
            }

            i++;
        }

        var str = res.toString();
        while (str.endsWith('_')) str = str.substr(0, str.length - 1);

        return str;

    }

    public static function getPrefix(str:String):String {

        if (RE_PREFIXED.match(str)) {
            str = RE_PREFIXED.matched(1);
        }
        while (str.length > 0 && str.charAt(str.length - 1) == '_') {
            str = str.substring(0, str.length - 1);
        }
        return str;

    }

    public static function uppercasePrefixFromClass(className:String):String {

        var parts = className.split('.');
        var str = parts[parts.length-1];
        str = TextUtils.camelCaseToUpperCase(str);
        while (str.length > 0 && str.charAt(str.length - 1) == '_') {
            str = str.substring(0, str.length - 1);
        }
        return str;

    }

    static final _slugUpperCase:SlugOptions = {
        lower: false,
        replacement: '_',
        remove: Slug.RE_SLUG_REMOVE_CHARS
    };

    public static function slugifyUpperCase(str:String):String {

        str = RE_SPACES.replace(str, '_');
        str = Slug.encode(str, _slugUpperCase);
        return str;

    }

    public static function sanitizeToIdentifier(str:String):String {

        str = RE_NUMERIC_PREFIX.replace(str, '');
        str = RE_SPACES.replace(str, '_');
        str = Slug.encode(str, {
            lower: false,
            replacement: '_'
        });
        return str;

    }

}