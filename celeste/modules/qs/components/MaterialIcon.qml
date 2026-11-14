import QtQuick
import Celeste.Config
import qs.services

StyledText {
    final property real fill
    final property int grade: Colours.light ? 0 : -25
    final property font fontStyle: Tokens.font.icon.small

    font: Tokens.styled("icon", "small", { size: fontStyle.pointSize, weight: fontStyle.weight, vaxes: fontStyle.variableAxes, fill: fill.toFixed(1), grade: grade })
}
