IDEALS.TimeUtils = {};

/**
 * @param startTime {Integer}
 * @param percent {Float}
 * @return {Integer}
 */
IDEALS.TimeUtils.eta = function(startTime, percent) {
    if (Math.abs(percent) < 0.0000001) {
        return Date.parse("2100-01-01").getTime();
    } else {
        const now = new Date().getTime();
        return startTime + ((now - startTime) / percent);
    }
};

/**
 * @param time {Integer}
 * @return {String} Human-friendly ETA.
 */
IDEALS.TimeUtils.etaToHuman = function(time) {
    const diff    = new Date(time);
    const hours   = diff.getUTCHours();
    const minutes = diff.getUTCMinutes();
    const seconds = diff.getUTCSeconds();

    const parts = [];
    if (hours > 0) {
        let string = hours + " hour";
        if (hours > 1) {
            string += "s";
        }
        parts.push(string);
    }
    if (minutes > 0) {
        let string = minutes + " minute";
        if (minutes > 1) {
            string += "s";
        }
        parts.push(string);
    } else if (seconds > 0 && hours < 1) {
        let string = seconds + " second"
        if (seconds > 1) {
            string += "s";
        }
        parts.push(string);
    }
    if (parts.length > 0) {
        return parts.join(", ") + " remaining";
    }
    return "";
};
