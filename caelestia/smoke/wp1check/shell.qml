import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import Caelestia.Shaders

// WP1 value check: logs "CHECK ..." lines for the singletons. Not a visual shell.
ShellRoot {
    id: root

    function log(label: string, value: var): void {
        console.log("CHECK", label, "=", typeof value === "object" ? JSON.stringify(value) : value);
    }

    CircularBuffer {
        id: buf
        capacity: 3
    }

    NumberAnimation {
        id: easeUser
        easing: Tokens.anim.expressiveFastSpatial
    }

    Timer {
        interval: 700
        running: true
        onTriggered: {
            root.log("toasts.length", Toaster.toasts.length);
            root.log("toast0", [Toaster.toasts[0].title, Toaster.toasts[0].icon, Toaster.toasts[0].type, Toaster.toasts[0].timeout, Toaster.toasts[0].closed]);
            Toaster.toasts[0].close();
            root.log("toasts.length after close", Toaster.toasts.length);
        }
    }

    Component.onCompleted: {
        Toaster.toast("T1", "msg", "", Toast.Error);
        Toaster.toast("T2", "msg", "bolt", Toast.Info, 400);

        log("rounding.large", Tokens.rounding.large);
        log("rounding.full", Tokens.rounding.full);
        log("rounding.scale", Tokens.rounding.scale);
        log("spacing.medium", Tokens.spacing.medium);
        log("padding.extraExtraLarge", Tokens.padding.extraExtraLarge);
        log("transparency", [Tokens.transparency.enabled, Tokens.transparency.base, Tokens.transparency.layers]);
        log("sizes.bar.innerWidth", Tokens.sizes.bar.innerWidth);
        log("sizes.launcher.itemWidth/Height", [Tokens.sizes.launcher.itemWidth, Tokens.sizes.launcher.itemHeight]);
        log("sizes.nexus.ratio", Tokens.sizes.nexus.ratio);
        log("durations", [Tokens.anim.durations.small, Tokens.anim.durations.normal, Tokens.anim.durations.large, Tokens.anim.durations.expressiveDefaultSpatial, Tokens.anim.durations.expressiveSlowEffects, Tokens.anim.durations.scale]);
        log("curve standard", Tokens.anim.curves.standard);
        log("curve emphasized", Tokens.anim.curves.emphasized);
        log("easing user type/bezier", [easeUser.easing.type, easeUser.easing.bezierCurve]);
        log("Config.bar.persistent/showOnHover/dragThreshold", [Config.bar.persistent, Config.bar.showOnHover, Config.bar.dragThreshold]);
        log("Config.bar.workspaces.shown/displayType/specialDisplayType", [Config.bar.workspaces.shown, Config.bar.workspaces.displayType, Config.bar.workspaces.specialDisplayType]);
        log("workspaces.label codepoints", Array.from(Config.bar.workspaces.label).map(c => c.codePointAt(0).toString(16)));
        log("bar.entries ids", Config.bar.entries.values.filter(e => e.enabled).map(e => e.id));
        log("bar.entries.count/at(1)", [Config.bar.entries.count, Config.bar.entries.at(1)]);
        log("statusIcons enabled", Config.bar.statusIcons.values.filter(e => e.enabled).map(e => e.id));
        log("specialWorkspaceIcons", GlobalConfig.bar.workspaces.specialWorkspaceIcons.values.map(e => e.name + ":" + e.icon));
        log("ignoredTags", Config.bar.workspaces.ignoredTags);
        log("hiddenIcons includes", GlobalConfig.bar.tray.hiddenIcons.includes("x"));
        log("border", [Config.border.thickness, Config.border.rounding, Config.border.smoothing, Config.border.minThickness, Config.border.clampedThickness]);
        log("launcher", [Config.launcher.maxShown, Config.launcher.maxWallpapers, Config.launcher.actionPrefix, Config.launcher.specialPrefix, GlobalConfig.launcher.actions.values.length]);
        log("osd", [Config.osd.hideDelay, Config.osd.enableBrightness, Config.osd.enableMicrophone]);
        log("services", [GlobalConfig.services.maxVolume, GlobalConfig.services.audioIncrement, GlobalConfig.services.defaultPlayer, GlobalConfig.services.visualiserBars, GlobalConfig.services.clockFormat, GlobalConfig.services.dataUnits]);
        log("notifs", [Config.notifs.defaultExpireTimeout, Config.notifs.clearThreshold, Config.notifs.fullscreen]);
        log("utilities", [Config.utilities.maxToasts, GlobalConfig.utilities.toasts.fullscreen, GlobalConfig.utilities.quickToggles.values.length]);
        log("session", [Config.session.dragThreshold, Config.session.icons.shutdown, Config.session.commands.reboot]);
        log("battery warn", GlobalConfig.general.battery.warnLevels.values.map(w => w.level));
        log("idle timeouts", GlobalConfig.general.idle.timeouts.values.map(w => w.timeout));
        log("paths", [Config.paths.mediaGif, Config.paths.wallpaperDir]);
        log("forScreen", GlobalConfig.forScreen("DP-1").background.enabled);
        log("enum WallpaperTransition.Crossfade/Smoke", [WallpaperTransition.Crossfade, WallpaperTransition.Smoke]);
        log("enumToString", CUtils.enumToString(Config.background, "wallpaperTransition"));
        log("enumToString TemperatureUnit", CUtils.enumToString(null, "weatherUnits", 3));

        // Fonts
        for (const style of ["headline", "title", "body", "label", "mono", "icon"]) {
            const s = Tokens.font[style];
            log("font." + style, ["L", s.large.family, s.large.pointSize, s.large.weight, JSON.stringify(s.large.variableAxes), "M", s.medium.pointSize, "S", s.small.pointSize]);
        }
        log("font.icon.extraLarge", [Tokens.font.icon.extraLarge.family, Tokens.font.icon.extraLarge.pointSize]);
        const b = Tokens.font.body.builders.small.weight(Font.Bold).scale(2).fill(1).grade(-25).build();
        log("builder chain", [b.family, b.pointSize, b.weight, JSON.stringify(b.variableAxes)]);
        const c = Tokens.font.clock.size(30).build();
        log("clock builder", [c.family, c.pointSize]);
        const i2 = Tokens.font.icon.size(20).fill(1).build();
        log("icon.size(20).fill(1)", [i2.family, i2.pointSize, JSON.stringify(i2.variableAxes)]);
        log("workspaces font", Tokens.font.workspaces);

        // Tr / Units
        log("Tr.tr arg", Tr.tr("hello %1 and %2").arg("a").arg("b"));
        log("Tr.mark", Tr.mark("Run: %1", ["sudo x"]));
        log("Tr.trN", [Tr.trN("%n issue", "%n issues", 1), Tr.trN("%n issue", "%n issues", 3)]);
        log("Tr.formatDateTime", Tr.formatDateTime(new Date(2026, 9, 30), "dddd, MMMM d"));
        log("Units", [Units.formatBytes(123456789), Units.formatTemp(41, 1), Units.twelveHourClock, Units.formatKibUsage(1024, 4096)]);

        // State
        log("states", [PersistentState.wallpaperPlaying, PersistentState.doNotDisturb, RuntimeState.gameMode, RuntimeState.inhibitIdle, RuntimeState.inhibitingIdleSince]);

        // CUtils / CircularBuffer
        log("CUtils", [CUtils.clamp(7, 0, 5), CUtils.toLocalFile("file:///D:/a%20b/c.txt"), CUtils.version]);
        buf.push(1);
        buf.push(5);
        buf.push(2);
        buf.push(3);
        log("CircularBuffer", [buf.count, buf.maximum, buf.at(0), buf.at(1), buf.at(2), buf.at(3)]);

        // List mutators
        const l = Config.bar.statusIcons;
        l.insert({
            id: "x",
            enabled: true
        });
        l.move(l.count - 1, 0);
        log("list after insert/move", l.values.map(e => e.id));
        l.remove(0);
        log("list after remove", l.count);

        // Shaders
        log("Shaders.iris", [Shaders.iris.duration, Shaders.iris.url]);
    }
}
