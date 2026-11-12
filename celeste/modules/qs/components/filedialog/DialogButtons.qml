import QtQuick.Layouts
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.services
import "FileDialogHelpers.js" as FileDialogHelpers

StyledRect {
    id: root

    required final property var dialog
    required final property FolderContents folder

    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.trCtx("Filter:", "file filter")
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Tokens.spacing.medium

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            StyledText {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium

                text: {
                    const filters = FileDialogHelpers.filtersText(root.dialog, Tr.trCtx(", ", "file filter separator"));
                    return Tr.trCtx("%1 (%2)", "file filter label and patterns").arg(FileDialogHelpers.filterLabel(root.dialog)).arg(filters);
                }
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                disabled: !FileDialogHelpers.validSelection(root.dialog, root.folder.currentItem)
                onClicked: FileDialogHelpers.acceptCurrent(root.dialog, root.folder.currentItem)
            }

            StyledText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: Tr.trCtx("Select", "button")
                color: FileDialogHelpers.validSelection(root.dialog, root.folder.currentItem) ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                onClicked: {
                    FileDialogHelpers.reject(root.dialog);
                }
            }

            StyledText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: Tr.trCtx("Cancel", "button")
            }
        }
    }
}
