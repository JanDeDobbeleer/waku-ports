pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.components.filedialog
import "DashboardContentHelpers.js" as DashboardContentHelpers

Item {
    id: root

    required final property ScreenState screenState
    required final property FileDialog facePicker
    final property string faceOverride

    readonly final property var dashboardTabs: {
        const allTabs = [
            {
                component: dashComponent,
                iconName: "dashboard",
                text: Tr.tr("Dashboard"),
                enabled: Config.dashboard.showDashboard
            },
            {
                component: mediaComponent,
                iconName: "queue_music",
                text: Tr.tr("Media"),
                enabled: Config.dashboard.showMedia
            },
            {
                component: performanceComponent,
                iconName: "speed",
                text: Tr.tr("Performance"),
                enabled: Config.dashboard.showPerformance
            },
            {
                component: weatherComponent,
                iconName: "cloud",
                text: Tr.tr("Weather"),
                enabled: Config.dashboard.showWeather
            },
            // Port: quick actions that open Windows UI.
            {
                component: utilitiesComponent,
                iconName: "grid_view",
                text: Tr.tr("Utilities"),
                enabled: Config.dashboard.showUtilities
            }
        ];
        return DashboardContentHelpers.enabledTabs(allTabs);
    }

    readonly final property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2
    readonly final property real nonAnimHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    // Port: test harness only. CELESTE_DASH_TAB opens the dashboard on that tab.
    Component.onCompleted: {
        const tab = Number(Quickshell.env("CELESTE_DASH_TAB"));
        if (tab > 0)
            screenState.dashboardTab = tab;
    }

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: CUtils.clamp(anchors.margins - Config.border.thickness, 0, anchors.margins)
        anchors.margins: Tokens.padding.large

        nonAnimWidth: root.nonAnimWidth - anchors.margins * 2
        screenState: root.screenState
        tabs: root.dashboardTabs
    }

    ClipRect {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large

        radius: Tokens.rounding.large
        color: "transparent"

        Flickable {
            id: view

            readonly final property int currentIndex: root.screenState.dashboardTab
            readonly final property Item currentItem: {
                CUtils.dependency(repeater.count); // Trigger update on count change
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: DashboardContentHelpers.itemWidth(currentItem)
            implicitHeight: DashboardContentHelpers.itemHeight(currentItem)

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving || !currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > DashboardContentHelpers.itemWidth(currentItem) / 2)
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, tabs.count - 1);
                else if (x < -DashboardContentHelpers.itemWidth(currentItem) / 2)
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);
            }

            onDragEnded: {
                if (!currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > DashboardContentHelpers.itemWidth(currentItem) / 10)
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, tabs.count - 1);
                else if (x < -DashboardContentHelpers.itemWidth(currentItem) / 10)
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);
                else
                    contentX = DashboardContentHelpers.contentXBinding(Qt, view);
            }

            RowLayout {
                id: row

                Repeater {
                    id: repeater

                    model: ScriptModel {
                        values: root.dashboardTabs
                    }

                    delegate: Loader {
                        id: paneLoader

                        required final property int index
                        required final property var modelData

                        // Port: `active` is updated from handlers, not bound. A binding that reads the
                        // pane geometry and the flickable content width makes Qt report a loop
                        // (active -> implicitWidth -> layout -> contentWidth -> active).
                        function updateActive(): void {
                            if (index === view.currentIndex) {
                                active = true;
                                return;
                            }
                            const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
                            const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
                            active = (vx >= x && vx <= x + implicitWidth) || (vex >= x && vex <= x + implicitWidth);
                        }

                        Layout.alignment: Qt.AlignTop

                        sourceComponent: DashboardContentHelpers.component(modelData)

                        onImplicitWidthChanged: Qt.callLater(updateActive)
                        onXChanged: Qt.callLater(updateActive)
                        Component.onCompleted: updateActive()

                        Connections {
                            function onContentXChanged(): void {
                                paneLoader.updateActive();
                            }

                            function onContentWidthChanged(): void {
                                paneLoader.updateActive();
                            }

                            function onCurrentIndexChanged(): void {
                                paneLoader.updateActive();
                            }

                            target: view
                        }
                    }
                }
            }

            Component {
                id: dashComponent

                Dash {
                    screenState: root.screenState
                    facePicker: root.facePicker
                    faceOverride: root.faceOverride
                }
            }

            Component {
                id: mediaComponent

                Media {
                    screenState: root.screenState
                }
            }

            Component {
                id: performanceComponent

                Performance {}
            }

            Component {
                id: weatherComponent

                WeatherTab {}
            }

            Component {
                id: utilitiesComponent

                UtilitiesTab {
                    screenState: root.screenState
                }
            }

            Behavior on contentX {
                Anim {}
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
