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
 * @return {String}
 */
IDEALS.TimeUtils.timeToHMS = function(time) {
    const diff    = new Date(time);
    const hours   = diff.getUTCHours();
    const minutes = diff.getUTCMinutes();
    const seconds = diff.getUTCSeconds();

    let string = seconds + " seconds";
    if (minutes > 0) {
        string = minutes + " minutes, " + string;
    }
    if (hours > 0) {
        string = hours + " hours, " + string;
    }
    return string;
};
