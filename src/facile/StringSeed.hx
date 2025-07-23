package facile;

import haxe.crypto.Md5;

class StringSeed {

    /**
     * Generates a deterministic float between 0 (included) and 1 (excluded)
     * using the input string as a seed. Same string always produces the same result.
     *
     * @param seed The string seed for deterministic generation
     * @return A deterministic float value in the range [0, 1)
     */
    public static function stringSeed(seed: String): Float {
        // Generate MD5 hash of the seed string
        var hash = Md5.encode(seed);

        // Take the first 8 characters of the hex hash and convert to integer
        var hexSubstring = hash.substr(0, 8);
        var intValue = Std.parseInt("0x" + hexSubstring);

        // Convert to float in range [0, 1)
        // 0xFFFFFFFF is the maximum value for 32-bit unsigned integer
        // 0x100000000 would be 2^32, so we use float literal instead
        var result = intValue / 4294967296.0;

        return result;
    }

}
