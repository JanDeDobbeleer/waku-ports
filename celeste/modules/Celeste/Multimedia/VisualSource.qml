import QtQuick

// Enum holder for celeste's C++ VisualSource. The real type decodes images and videos for Visual;
// here Visual does that itself and this file only supplies the `VisualSource.*` enum values that
// callers pass as `fillMode`, and the `Type` values Visual reports.
QtObject {
    enum Type {
        Unknown,
        Still,
        Live
    }

    enum FillMode {
        Stretch = 0,
        PreserveAspectFit,
        PreserveAspectCrop
    }
}
