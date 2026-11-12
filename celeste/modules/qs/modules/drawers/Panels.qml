import QtQuick
import Quickshell
import Celeste.Config
import qs.components
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts
import qs.modules.launcher as Launcher
import qs.modules.osd as Osd
import qs.modules.session as Session
import qs.modules.dashboard as Dashboard
import qs.modules.notifications as Notifications
import qs.modules.sidebar as Sidebar
import qs.modules.utilities as Utilities
import qs.modules.utilities.toasts as Toasts

Item {
    id: root

    required final property ShellScreen screen
    required final property ScreenState screenState
    required final property Bar.BarWrapper bar
    required final property real barWidth
    required final property real borderThickness

    readonly final property Osd.Wrapper osd: osdItem
    readonly final property Item osdWrapper: osdWrapperItem
    readonly final property Notifications.Wrapper notifications: notificationsItem
    readonly final property Session.Wrapper session: sessionItem
    readonly final property Item sessionWrapper: sessionWrapperItem
    readonly final property Launcher.Wrapper launcher: launcherItem
    readonly final property Dashboard.Wrapper dashboard: dashboardItem
    readonly final property BarPopouts.Wrapper popouts: popoutsWrapperItem.content
    readonly final property BarPopouts.ClipWrapper popoutsWrapper: popoutsWrapperItem
    readonly final property Utilities.Wrapper utilities: utilitiesItem
    readonly final property Toasts.Toasts toasts: toastsItem
    readonly final property Sidebar.Wrapper sidebar: sidebarItem

    anchors.fill: parent
    anchors.margins: borderThickness
    anchors.leftMargin: barWidth

    function closePopouts(): void {
        popoutsWrapperItem.close();
    }

    Item {
        id: osdWrapperItem

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sessionWrapperItem.anchors.rightMargin + sessionItem.width * (1 - sessionItem.offsetScale)
        clip: sidebarItem.visible || sessionItem.visible

        implicitWidth: osdItem.implicitWidth * (1 - osdItem.offsetScale)
        implicitHeight: osdItem.implicitHeight

        Osd.Wrapper {
            id: osdItem

            screen: root.screen
            screenState: root.screenState
            sidebarOrSessionVisible: sidebarItem.visible || sessionItem.visible

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    Notifications.Wrapper {
        id: notificationsItem

        screenState: root.screenState
        sidebarPanel: sidebarItem
        osdPanel: osdWrapperItem
        sessionPanel: sessionWrapperItem
        utilitiesPanel: utilitiesItem

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Item {
        id: sessionWrapperItem

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sidebarItem.width * (1 - sidebarItem.offsetScale)
        clip: sidebarItem.visible

        implicitWidth: sessionItem.implicitWidth * (1 - sessionItem.offsetScale)
        implicitHeight: sessionItem.implicitHeight

        Session.Wrapper {
            id: sessionItem

            screenState: root.screenState
            sidebarVisible: sidebarItem.visible

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    Launcher.Wrapper {
        id: launcherItem

        screen: root.screen
        screenState: root.screenState
        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    Dashboard.Wrapper {
        id: dashboardItem

        screenState: root.screenState

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapperItem

        screen: root.screen
        borderThickness: root.borderThickness
    }

    Utilities.Wrapper {
        id: utilitiesItem

        screenState: root.screenState
        sidebar: sidebarItem
        popouts: popoutsWrapperItem.content

        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    Toasts.Toasts {
        id: toastsItem

        anchors.bottom: sidebarItem.visible ? parent.bottom : utilitiesItem.top
        anchors.right: sidebarItem.left
        anchors.margins: Tokens.padding.medium
    }

    Sidebar.Wrapper {
        id: sidebarItem

        screenState: root.screenState

        anchors.top: notificationsItem.bottom
        anchors.bottom: utilitiesItem.top
        anchors.right: parent.right
        anchors.topMargin: -notificationsItem.anchors.topMargin
    }
}
