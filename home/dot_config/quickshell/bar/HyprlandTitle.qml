import QtQuick
import Quickshell.Hyprland

Text {
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
}
