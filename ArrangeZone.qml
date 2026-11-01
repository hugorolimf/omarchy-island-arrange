import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// One window in the preview, gliding to its spot in the highlighted model:
// a frame of it, its size, and its icon, app and title.
Item {
  id: zone
  required property var arrange
  required property int index
  // Top of the models plate, on screen.
  property real panelTop: 0
  readonly property var w: arrange.wins[index] || ({})
  readonly property var spot: arrange.settled ? (arrange.spotFor(arrange.current, index) || w) : w
  readonly property var toplevel: arrange.toplevelFor(w.a)
  readonly property bool out: !!w.out
  // Left out: only its outline where it stays, over the others so
  // it can still be clicked back in.
  z: out ? 1 : 0
  x: spot.x || 0
  y: spot.y || 0
  width: spot.w || 0
  height: spot.h || 0
  Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: arrange.ease } }
  Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: arrange.ease } }
  Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: arrange.ease } }
  Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: arrange.ease } }

  Rectangle {
    anchors.fill: parent
    radius: 12
    color: arrange.paper_(zone.out ? 0 : 0.96)
    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: arrange.ease } }
  }
  // A frame of the window, cropped to its new spot (top kept), faint.
  Item {
    id: shot
    anchors.fill: parent
    opacity: zone.out ? 0 : 0.22
    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: zoneMask
      maskThresholdMin: 0.5
      maskSpreadAtMin: 0.05
    }
    ScreencopyView {
      id: view
      readonly property real aspect: sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 16 / 10
      readonly property bool wide: aspect > shot.width / Math.max(1, shot.height)
      anchors.horizontalCenter: parent.horizontalCenter
      y: 0
      width: wide ? shot.height * aspect : shot.width
      height: wide ? shot.height : shot.width / aspect
      captureSource: zone.toplevel ? zone.toplevel.wayland : null
      live: false
      paintCursor: false
      constraintSize: Qt.size(width, height)
      visible: hasContent
    }
  }
  Item {
    id: zoneMask
    anchors.fill: shot
    visible: false
    layer.enabled: true
    Rectangle { anchors.fill: parent; radius: 12; color: "white"; antialiasing: true }
  }
  Rectangle {
    anchors.fill: parent
    radius: 12
    color: "transparent"
    border.width: 1
    border.color: arrange.ink_(zone.out ? 0.45 : zone.w.main ? 0.55 : 0.32)
  }

  // Right click: out of the arrangement, or back in. Left clicks
  // go through (to leave the panel).
  MouseArea {
    id: zoneMouse
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    hoverEnabled: true
    onClicked: arrange.exclude(zone.w.a)
  }

  // Its size there, like a measurement on a drawing.
  Text {
    x: 12; y: 10
    visible: parent.width > 120 && parent.height > 60
    textFormat: Text.PlainText
    text: Math.round(zone.width) + " × " + Math.round(zone.height)
    color: arrange.ink_(0.45)
    font.family: arrange.mono
    font.pixelSize: 10
    font.letterSpacing: 0.8
  }

  // What lands here: icon, app, title.
  // In the middle of the spot, or higher up when the panel of
  // models would cover the middle.
  Rectangle {
    id: chip
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.max(28, Math.min((parent.height - height) / 2, panelTop - zone.y - height - 16))
    width: Math.min(parent.width - 24, Math.max(appText.implicitWidth, titleText.implicitWidth, hintWidth.width, 96) + 36)
    TextMetrics { id: hintWidth; font.family: arrange.mono; font.pixelSize: 10; font.letterSpacing: 0.8; text: arrange.t.rightLeaveOut }
    height: label.implicitHeight + 24
    radius: 12
    color: arrange.paper_(0.9)
    border.width: 1
    border.color: arrange.ink_(0.14)
    opacity: zone.out ? 0.7 : 1
    visible: parent.width > 80 && parent.height > 70
    Column {
      id: label
      anchors.centerIn: parent
      width: chip.width - 28
      spacing: 4
      Image {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 36; height: 36
        sourceSize: Qt.size(72, 72)
        source: arrange.iconFor(zone.w.c)
        smooth: true
        asynchronous: true
      }
      Text {
        id: appText
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: arrange.appLabel(zone.w.c)
        color: arrange.ink
        font.family: arrange.sans
        font.pixelSize: 15
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }
      Text {
        id: titleText
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: arrange.cleanTitle(zone.toplevel && zone.toplevel.title ? zone.toplevel.title : zone.w.t)
        color: arrange.ink_(0.6)
        font.family: arrange.sans
        font.pixelSize: 12
        elide: Text.ElideRight
      }
      Text {
        readonly property bool last: !zone.out && arrange.inCount <= 1
        visible: zoneMouse.containsMouse ? !last : (zone.out || !!zone.w.main)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: zoneMouse.containsMouse ? (zone.out ? arrange.t.rightBack : arrange.t.rightLeaveOut)
          : zone.out ? arrange.t.leftOut : arrange.t.inUse
        elide: Text.ElideRight
        color: arrange.ink_(0.5)
        font.family: arrange.mono
        font.pixelSize: 10
        font.letterSpacing: 0.8
      }
    }
  }
}
