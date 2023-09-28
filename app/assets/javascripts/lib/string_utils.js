IDEALS.StringUtils = {};

/**
 * Converts a byte size integer (like 50000) into a string like
 * "50 KB." The output harmonizes with that of Rails'
 * `number_to_human_size()` method.
 *
 * @param bytes {Number} Byte size integer.
 * @return {String}
 */
IDEALS.StringUtils.formatBytes = function(bytes, decimalPlaces) {
    if (!decimalPlaces) {
        decimalPlaces = 0;
    }
    const sizes = ["bytes", "KB", "MB", "GB", "TB"];
    if (bytes === 0) {
        return "0 bytes";
    }
    const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
    return (bytes / Math.pow(1024, i)).toFixed(decimalPlaces) + " " + sizes[i];
};

/**
 * @param length {Number}
 * @returns {String} Random string of the given length.
 */
IDEALS.StringUtils.randomString = function(length) {
    let output = "";
    for (let i = 0; i < length; i++) {
        output += (Math.floor(Math.random() * 16)).toString(16);
    }
    return output;
};
