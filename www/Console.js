// Safety net.  Don't error if somebody accidentally leaves a console statement in the code.
(function (undefined) {
    var noop = function () { };

    if (typeof window.console === "undefined") {
        var console = {};
        console.assert = noop;
        console.count = noop;
        console.debug = noop;
        console.dir = noop;
        console.dirxml = noop;
        console.error = noop;
        console.group = noop;
        console.groupCollapsed = noop;
        console.groupEnd = noop;
        console.info = noop;
        console.log = noop;
        console.markTimeline = noop;
        console.profile = noop;
        console.profileEnd = noop;
        console.time = noop;
        console.timeEnd = noop;
        console.trace = noop;
        console.warn = noop;
        window.console = window.console || console;
    } else {
        // IE decided to implement partial methods of the console.
        if (!window.console.log) window.console.log = noop;

        if (!window.console.debug) window.console.debug = window.console.log;
        if (!window.console.error) window.console.error = window.console.log;
        if (!window.console.info) window.console.info = window.console.log;
        if (!window.console.trace) window.console.trace = window.console.log;
        if (!window.console.warn) window.console.warn = window.console.log;

        if (!window.console.assert) window.console.assert = noop;
        if (!window.console.count) window.console.count = noop;
        if (!window.console.dir) window.console.dir = noop;
        if (!window.console.dirxml) window.console.dirxml = noop;
        if (!window.console.group) window.console.group = noop;
        if (!window.console.groupCollapsed) window.console.groupCollapsed = noop;
        if (!window.console.groupEnd) window.console.groupEnd = noop;
        if (!window.console.markTimeline) window.console.markTimeline = noop;
        if (!window.console.profile) window.console.profile = noop;
        if (!window.console.profileEnd) window.console.profileEnd = noop;
        if (!window.console.time) window.console.time = noop;
        if (!window.console.timeEnd) window.console.timeEnd = noop;
    }
} ());
