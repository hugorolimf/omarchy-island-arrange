import QtQuick

// The models, just above the dock's line: a title, the keys and a card per model.
Rectangle {
  id: plate
  required property var arrange
  required property real screenWidth
  readonly property int pad: 14
  readonly property int head: 30
  readonly property int cardW: Math.max(132, Math.min(180, Math.floor((screenWidth - 64 - pad * 2) / Math.max(1, arrange.models.length)) - 8))
  anchors.horizontalCenter: parent.horizontalCenter
  y: Math.max(16, arrange.area.y + arrange.area.h - height - 20)
  width: cards.implicitWidth + pad * 2
  height: head + cards.implicitHeight + pad * 2
  radius: 18
  color: arrange.paper_(0.9)
  border.width: 1
  border.color: arrange.ink_(0.12)

  // Clicks on the plate itself stay here.
  MouseArea { anchors.fill: parent }

  Text {
    id: title
    x: plate.pad + 6
    y: plate.pad - 2
    height: 18
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    text: arrange.t.arrange + " · " + arrange.inCount + " " + (arrange.inCount === 1 ? arrange.t.window : arrange.t.windows)
      + (arrange.wins.length > arrange.inCount ? " · " + (arrange.wins.length - arrange.inCount) + " " + arrange.t.out : "")
    color: arrange.ink_(0.5)
    font.family: arrange.mono
    font.pixelSize: 10
    font.letterSpacing: 0.9
  }
  Row {
    anchors { right: parent.right; rightMargin: plate.pad + 6 }
    y: plate.pad - 2
    height: 18
    spacing: 12
    visible: plate.width > title.implicitWidth + implicitWidth + 60
    Repeater {
      model: {
        var n = arrange.models.length
        var list = [[n > 1 ? "1–" + n : "1", arrange.t.apply], ["← →", arrange.t.choose], ["ENTER", "OK"]]
        if (arrange.canUndo) list.push(["0", arrange.t.undo])
        list.push(["ESC", arrange.t.leave])
        return list
      }
      delegate: Row {
        required property var modelData
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
          width: keyText.implicitWidth + 8
          height: 15
          radius: 4
          color: "transparent"
          border.width: 1
          border.color: arrange.ink_(0.16)
          Text {
            id: keyText
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: modelData[0]
            color: arrange.ink_(0.62)
            font.family: arrange.mono
            font.pixelSize: 9
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: modelData[1]
          color: arrange.ink_(0.42)
          font.family: arrange.mono
          font.pixelSize: 10
          font.letterSpacing: 0.8
        }
      }
    }
  }
  Rectangle {
    x: plate.pad; y: plate.pad + plate.head - 12
    width: parent.width - plate.pad * 2; height: 1
    color: arrange.ink_(0.07)
  }

  Row {
    id: cards
    x: plate.pad
    y: plate.pad + plate.head - 4
    spacing: 8

    Repeater {
      model: arrange.models
      delegate: ArrangeCard {
        arrange: plate.arrange
        cardWidth: plate.cardW
      }
    }
  }
}
