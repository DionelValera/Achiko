import Quickshell
import QtQuick

PanelWindow {
    anchors{
        top:true
        left:true
        right:true
    }


implicitHeight: 30
implicitWidth: 30


Text {
    anchors.centerIn: parent
    text: "Nueva barra superior"
}
}