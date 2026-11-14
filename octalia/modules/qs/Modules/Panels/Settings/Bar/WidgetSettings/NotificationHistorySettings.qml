import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  // Local state
  property bool valueShowUnreadBadge: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "showUnreadBadge")
  property bool valueHideWhenZero: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideWhenZero")
  property bool valueHideWhenZeroUnread: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "hideWhenZeroUnread")
  property string valueUnreadBadgeColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "unreadBadgeColor")
  property string valueIconColor: SettingsValue.undefinedFallback(widgetData, widgetMetadata, "iconColor")

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.showUnreadBadge = valueShowUnreadBadge;
    settings.hideWhenZero = valueHideWhenZero;
    settings.hideWhenZeroUnread = valueHideWhenZeroUnread;
    settings.unreadBadgeColor = valueUnreadBadgeColor;
    settings.iconColor = valueIconColor;
    settingsChanged(settings);
  }

  NToggle {
    label: I18n.tr("bar.notification-history.show-unread-badge-label")
    description: I18n.tr("bar.notification-history.show-unread-badge-description")
    checked: root.valueShowUnreadBadge
    onToggled: checked => {
                 root.valueShowUnreadBadge = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "showUnreadBadge")
  }

  NColorChoice {
    label: I18n.tr("common.select-icon-color")
    currentKey: root.valueIconColor
    onSelected: key => {
                  root.valueIconColor = key;
                  root.saveSettings();
                }
    defaultValue: SettingsValue.read(root.widgetMetadata, "iconColor")
  }

  NColorChoice {
    label: I18n.tr("bar.notification-history.unread-badge-color-label")
    description: I18n.tr("bar.notification-history.unread-badge-color-description")
    currentKey: root.valueUnreadBadgeColor
    onSelected: key => {
                  root.valueUnreadBadgeColor = key;
                  root.saveSettings();
                }
    visible: root.valueShowUnreadBadge
    defaultValue: SettingsValue.read(root.widgetMetadata, "unreadBadgeColor")
  }

  NToggle {
    label: I18n.tr("bar.notification-history.hide-widget-when-zero-label")
    description: I18n.tr("bar.notification-history.hide-widget-when-zero-description")
    checked: root.valueHideWhenZero
    onToggled: checked => {
                 root.valueHideWhenZero = checked;
                 root.saveSettings();
               }
    enabled: !root.valueHideWhenZeroUnread
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideWhenZero")
  }

  NToggle {
    label: I18n.tr("bar.notification-history.hide-widget-when-zero-unread-label")
    description: I18n.tr("bar.notification-history.hide-widget-when-zero-unread-description")
    checked: root.valueHideWhenZeroUnread
    onToggled: checked => {
                 root.valueHideWhenZeroUnread = checked;
                 root.saveSettings();
               }
    defaultValue: SettingsValue.read(root.widgetMetadata, "hideWhenZeroUnread")
  }
}
