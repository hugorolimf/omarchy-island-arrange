import QtQuick

// One model: the screen in small with each window's spot and icon, its number
// key and name, then what it is (or that it's the suggestion, or what's on screen).
Item {
  id: card
  required property var arrange
  required property real cardWidth
  required property var modelData
  required property int index
  readonly property bool selected: index === arrange.current
  readonly property real dw: cardWidth - 16
  readonly property real dh: Math.round(dw * arrange.area.h / Math.max(1, arrange.area.w))
  readonly property real sc: dw / Math.max(1, arrange.area.w)
  width: cardWidth
  height: 8 + dh + 10 + 18 + 16 + 8

  Rectangle {
    anchors.fill: parent
    radius: 12
    color: card.selected ? arrange.ink_(0.08) : arrange.ink_(cardMouse.containsMouse ? 0.04 : 0)
    border.width: 1
    border.color: card.selected ? arrange.ink_(0.3) : "transparent"
    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: arrange.ease } }
  }

  // The screen in small, with each window's spot and icon.
  Item {
    x: 8; y: 8
    width: card.dw
    height: card.dh
    Rectangle {
      anchors.fill: parent
      radius: 6
      color: arrange.ink_(0.04)
      border.width: 1
      border.color: arrange.ink_(0.08)
    }
    Repeater {
      model: card.modelData.spots
      delegate: Rectangle {
        required property var modelData
        readonly property var win_: arrange.wins[modelData.i] || ({})
        x: (modelData.x - arrange.area.x) * card.sc
        y: (modelData.y - arrange.area.y) * card.sc
        width: Math.max(2, modelData.w * card.sc)
        height: Math.max(2, modelData.h * card.sc)
        radius: 4
        color: arrange.ink_(card.selected ? (win_.main ? 0.3 : 0.18) : (win_.main ? 0.2 : 0.11))
        border.width: 1
        border.color: arrange.ink_(card.selected ? 0.4 : 0.2)
        Behavior on color { ColorAnimation { duration: 140 } }
        Image {
          anchors.centerIn: parent
          width: Math.min(20, Math.min(parent.width, parent.height) * 0.6)
          height: width
          visible: width >= 8
          sourceSize: Qt.size(40, 40)
          source: arrange.iconFor(parent.win_.c)
          smooth: true
          asynchronous: true
          opacity: card.selected ? 1 : 0.75
        }
      }
    }
  }

  // Key and name, then what it is (or that it's the pick / what's on screen).
  Row {
    x: 10
    y: 8 + card.dh + 10
    width: parent.width - 20
    height: 18
    spacing: 7
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 16
      height: 16
      radius: 4
      color: card.selected ? arrange.ink_(0.12) : "transparent"
      border.width: 1
      border.color: arrange.ink_(card.selected ? 0.4 : 0.2)
      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: card.index < 9 ? String(card.index + 1) : ""
        color: arrange.ink_(0.75)
        font.family: arrange.mono
        font.pixelSize: 10
      }
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 23
      textFormat: Text.PlainText
      text: arrange.modelName(card.modelData.name)
      color: card.selected ? arrange.ink : arrange.ink_(0.78)
      font.family: arrange.sans
      font.pixelSize: 13
      font.weight: card.selected ? Font.DemiBold : Font.Medium
      elide: Text.ElideRight
    }
  }
  Text {
    x: 10
    y: 8 + card.dh + 10 + 20
    width: parent.width - 20
    textFormat: Text.PlainText
    text: card.modelData.sug ? "★ " + arrange.t.suggested : card.modelData.cur ? "● " + arrange.t.current : arrange.modelNote(card.modelData.note)
    color: arrange.ink_(card.modelData.sug ? 0.78 : 0.45)
    font.family: arrange.mono
    font.pixelSize: 10
    font.letterSpacing: 0.8
    elide: Text.ElideRight
  }

  MouseArea {
    id: cardMouse
    anchors.fill: parent
    hoverEnabled: true
    onContainsMouseChanged: if (containsMouse) arrange.current = card.index
    onClicked: arrange.apply(card.index)
  }
}
