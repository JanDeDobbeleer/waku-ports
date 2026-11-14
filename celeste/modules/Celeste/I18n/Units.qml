pragma Singleton

import QtQuick
import Celeste.Config
import "UnitsHelpers.js" as UnitsHelpers

QtObject {
    // Whether to show a 12-hour clock, guessing from the locale when Auto
    readonly final property bool twelveHourClock: {
        const format = GlobalConfig.services.clockFormat;
        if (format === ClockFormat.Auto)
            return Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().includes("a");
        return format === ClockFormat.TwelveHour;
    }

    // Resolves TemperatureUnit.Auto to a concrete unit based on the locale
    function resolveTempUnit(unit: int): int {
        if (Number(unit) !== TemperatureUnit.Auto)
            return unit;
        const system = Qt.locale().measurementSystem;
        return system === Locale.ImperialUSSystem || system === Locale.ImperialUKSystem ? TemperatureUnit.Fahrenheit : TemperatureUnit.Celsius;
    }

    // Converts a temperature in Celsius to the given TemperatureUnit
    function toTemperature(celsius: real, unitIn: int): real {
        const unit = resolveTempUnit(unitIn);
        if (Number(unit) === TemperatureUnit.Fahrenheit)
            return celsius * 9 / 5 + 32;
        if (Number(unit) === TemperatureUnit.Kelvin)
            return celsius + 273.15;
        return celsius;
    }

    // Formats an already converted temperature with the given TemperatureUnit's suffix
    function formatTemp(value: var, unitIn: int, compact: bool): string {
        const unit = resolveTempUnit(unitIn);
        if (compact)
            return Number(unit) === TemperatureUnit.Kelvin ? String(value) : Tr.trCtx("%1°", "temperature").arg(value);

        if (Number(unit) === TemperatureUnit.Fahrenheit)
            return Tr.trCtx("%1°F", "temperature").arg(value);
        if (Number(unit) === TemperatureUnit.Kelvin)
            return Tr.trCtx("%1 K", "temperature").arg(value);
        return Tr.trCtx("%1°C", "temperature").arg(value);
    }

    // Converts and formats a sensor temperature given in Celsius
    function formatSensorTemp(celsius: real): string {
        const unit = GlobalConfig.services.sensorUnits;
        return formatTemp(Math.round(toTemperature(celsius, unit)), unit, false);
    }

    // Formats an already scaled value with the given data unit suffix
    function withDataUnit(value: var, unit: string): string {
        const formats = {
            "B": Tr.tr("%1 B"),
            "KB": Tr.tr("%1 KB"),
            "MB": Tr.tr("%1 MB"),
            "GB": Tr.tr("%1 GB"),
            "TB": Tr.tr("%1 TB"),
            "KiB": Tr.tr("%1 KiB"),
            "MiB": Tr.tr("%1 MiB"),
            "GiB": Tr.tr("%1 GiB"),
            "TiB": Tr.tr("%1 TiB"),
            "B/s": Tr.tr("%1 B/s"),
            "KB/s": Tr.tr("%1 KB/s"),
            "MB/s": Tr.tr("%1 MB/s"),
            "GB/s": Tr.tr("%1 GB/s"),
            "TB/s": Tr.tr("%1 TB/s"),
            "KiB/s": Tr.tr("%1 KiB/s"),
            "MiB/s": Tr.tr("%1 MiB/s"),
            "GiB/s": Tr.tr("%1 GiB/s"),
            "TiB/s": Tr.tr("%1 TiB/s")
        };
        return (formats[unit] ?? ("%1 " + unit)).arg(value);
    }

    // Scales and formats a raw byte count
    function formatBytes(bytes: real): string {
        return UnitsHelpers.formatBytes(bytes, false, Number(GlobalConfig.services.dataUnits) === DataUnit.Binary, Tr);
    }

    function formatBytesWithRate(bytes: real, rate: bool): string {
        return UnitsHelpers.formatBytes(bytes, rate, Number(GlobalConfig.services.dataUnits) === DataUnit.Binary, Tr);
    }

    // Formats a used/total pair given in KiB, both scaled to the total's magnitude
    function formatKibUsage(usedKib: real, totalKib: real): string {
        return UnitsHelpers.formatKibUsage(usedKib, totalKib, Number(GlobalConfig.services.dataUnits) === DataUnit.Binary, Tr);
    }

}
