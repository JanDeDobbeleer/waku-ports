import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Celeste.Components
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.components.controls
import qs.services
import "DetailsHelpers.js" as DetailsHelpers

ColumnLayout {
    id: root

    readonly final property bool hasUnknownLength: (Players.active?.length ?? 0) > 2147483647

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    spacing: Tokens.spacing.extraSmall

    Timer {
        running: DetailsHelpers.isPlaying(Players.active)
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: DetailsHelpers.refreshPosition(Players.active)
    }

    StyledText {
        Layout.fillWidth: true
        text: Players.active?.trackTitle ?? ""
        font: Tokens.font.title.large
        elide: Text.ElideRight
        animate: true
    }

    StyledText {
        Layout.fillWidth: true
        text: Players.active?.trackArtist || Tr.tr("Unknown artist")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.title.medium
        elide: Text.ElideRight
        animate: true
    }

    StyledText {
        Layout.fillWidth: true
        text: Players.active?.trackAlbum || Tr.tr("Unknown album")
        color: Colours.palette.m3secondary
        font: Tokens.font.title.medium
        elide: Text.ElideRight
        animate: true
    }

    RowLayout {
        Layout.topMargin: Tokens.spacing.extraLargeIncreased
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        TextMetrics {
            id: timeMetrics

            text: Players.active ? root.lengthStr(Math.max(DetailsHelpers.position(Players.active), root.hasUnknownLength ? 0 : DetailsHelpers.length(Players.active))).replace(/[1-9]/g, "0") : "00:00"
            font: Tokens.font.label.medium
        }

        StyledText {
            id: positionLabel

            Layout.preferredWidth: timeMetrics.width
            text: root.lengthStr(DetailsHelpers.position(Players.active))
            color: Colours.palette.m3onSurfaceVariant
            font: timeMetrics.font
            horizontalAlignment: Text.AlignHCenter
        }

        StyledSlider {
            id: positionSlider

            Layout.fillWidth: true
            value: DetailsHelpers.positionRatio(Players.active)
            enabled: DetailsHelpers.canSeek(Players.active) && !root.hasUnknownLength
            wavy: true
            animateWave: DetailsHelpers.isPlaying(Players.active)
            waveFrequency: 5
            waveDuration: 2000
            interactionOnMove: false
            onInteraction: value => {
                DetailsHelpers.seek(Players.active, value);
            }

            Binding {
                target: positionLabel
                property: "text"
                value: root.lengthStr(positionSlider.pos * DetailsHelpers.length(Players.active))
                when: positionSlider.dragging
            }
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: root.hasUnknownLength ? "--:--" : root.lengthStr(DetailsHelpers.length(Players.active))
            color: Colours.palette.m3onSurfaceVariant
            font: timeMetrics.font
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ButtonRow {
        Layout.topMargin: Tokens.spacing.largeIncreased
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        IconButton {
            type: IconButton.Tonal
            icon: "shuffle"
            isRound: true
            shapeMorph: true
            checked: DetailsHelpers.shuffle(Players.active)
            font: Tokens.styled("icon", "medium", { weight: Font.Medium })
            disabled: !DetailsHelpers.shuffleSupported(Players.active)
            onClicked: DetailsHelpers.toggleShuffle(Players.active)
            implicitWidth: Math.round(implicitHeight * 0.9)
        }

        IconButton {
            id: previousBtn

            type: IconButton.Tonal
            icon: "skip_previous"
            isRound: true
            shapeMorph: true
            font: Tokens.font.icon.large
            disabled: !DetailsHelpers.canGoPrevious(Players.active)
            onClicked: DetailsHelpers.previous(Players.active)
        }

        IconButton {
            id: playPauseBtn

            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            isRound: true
            shapeMorph: true
            fillWidth: true
            checked: DetailsHelpers.isPlaying(Players.active)
            font: Tokens.font.icon.large
            disabled: !DetailsHelpers.canTogglePlaying(Players.active)
            onClicked: DetailsHelpers.togglePlaying(Players.active)
        }

        IconButton {
            id: nextBtn

            type: IconButton.Tonal
            icon: "skip_next"
            isRound: true
            shapeMorph: true
            font: Tokens.font.icon.large
            disabled: !DetailsHelpers.canGoNext(Players.active)
            onClicked: DetailsHelpers.next(Players.active)
        }

        IconButton {
            type: IconButton.Tonal
            icon: DetailsHelpers.loopIcon(Players.active, MprisLoopState.Track)
            isRound: true
            shapeMorph: true
            checked: DetailsHelpers.isLooping(Players.active, MprisLoopState.Track, MprisLoopState.Playlist)
            font: Tokens.styled("icon", "medium", { weight: Font.Medium })
            disabled: !DetailsHelpers.loopSupported(Players.active)
            onClicked: DetailsHelpers.cycleLoop(Players.active, MprisLoopState.None, MprisLoopState.Track, MprisLoopState.Playlist)
            implicitWidth: Math.round(implicitHeight * 0.9)
        }
    }
}
