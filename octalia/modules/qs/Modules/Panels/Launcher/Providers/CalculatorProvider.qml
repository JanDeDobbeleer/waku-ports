import QtQuick 6.10
import "../../../../Helpers/AdvancedMath.js" as AdvancedMath
import qs.Commons
import qs.compat
import qs.Services.UI
import "./CalculatorProviderUtils.js" as CalculatorProviderUtils

Item {
  id: root

  // Provider metadata
  property string name: I18n.tr("launcher.providers.calculator")
  property var launcher: null
  property string iconMode: Settings.data.appLauncher.iconMode
  property bool handleSearch: true // Contribute to regular search
  property string supportedLayouts: "list"

  // Initialize provider
  function init(): void {
    Logger.d("CalculatorProvider", "Initialized");
  }

  // Get search results - evaluates math expressions inline
  function getResults(query: string): var {
    return CalculatorProviderUtils.getResults(query, AdvancedMath, I18n, iconMode, root, Os, ToastService, launcher);
  }

}
