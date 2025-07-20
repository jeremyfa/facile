package facile;

/**
 * Utility to validate emails
 */
class Email {

    /**
     * Validates an email address using a regular expression
     * @param email The email address to validate
     * @param strict If `true` (default), performs additional checks
     * @return true if the email is valid, false otherwise
     */
    public inline static function isValidEmail(email:String, strict:Bool = true):Bool {
        if (strict) {
            return isValidEmailStrict(email);
        }
        else {
            return isValidEmailLoose(email);
        }
    }

    static function isValidEmailLoose(email:String):Bool {
        // Check if email is null or empty
        if (email == null || email.length == 0) {
            return false;
        }

        // Regular expression to validate email
        // This regex checks:
        // - Local part: alphanumeric characters, dots, hyphens, underscores
        // - Single @ symbol
        // - Domain: alphanumeric characters and hyphens
        // - Extension: at least 2 alphabetic characters
        var emailRegex = ~/^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

        return emailRegex.match(email);
    }

    /**
     * Stricter email validation
     * Checks additional rules
     */
    static function isValidEmailStrict(email:String):Bool {
        if (email == null || email.length == 0) {
            return false;
        }

        // Additional checks
        if (email.length > 254) { // Maximum RFC length
            return false;
        }

        // No consecutive dots
        if (email.indexOf("..") != -1) {
            return false;
        }

        // Should not start or end with a dot
        if (email.charAt(0) == "." || email.charAt(email.length - 1) == ".") {
            return false;
        }

        // Split local and domain parts
        var parts = email.split("@");
        if (parts.length != 2) {
            return false;
        }

        var localPart = parts[0];
        var domainPart = parts[1];

        // Local part should not exceed 64 characters
        if (localPart.length > 64) {
            return false;
        }

        // Check that domain contains at least one dot
        if (domainPart.indexOf(".") == -1) {
            return false;
        }

        // Stricter regular expression
        var strictRegex = ~/^[a-zA-Z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$/;

        return strictRegex.match(email);
    }

}
