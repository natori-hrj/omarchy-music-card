import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons

BarWidget {
  id: root

  moduleName: "natori.music-card"

  readonly property var mediaService: bar && bar.shell ? bar.shell.serviceFor("natori.music-card") : null
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property bool hasMedia: !!(mediaService && mediaService.hasMedia)
  readonly property string title: mediaService ? mediaService.title : ""
  readonly property string artist: mediaService ? mediaService.artist : ""
  readonly property color accentColor: mediaService && mediaService.providerName === "YouTube Music" ? "#ff4e5d" : Color.accent
  readonly property string originalArtworkUrl: mediaService ? String(mediaService.artUrl || "") : ""
  property bool popupOpen: false
  property var waveformHeights: [7, 11, 16, 10, 14, 8, 18, 12, 6, 10, 15, 9, 17, 11, 7, 13, 18, 8, 12, 6, 15, 10, 17, 8, 13, 19, 9, 12, 7, 16, 10, 14, 6, 18, 11, 8, 15, 9, 13, 7, 16, 10]
  property bool useOriginalArtwork: false
  readonly property real artworkHeight: {
    var desiredHeight = Style.space(144)
    if (!popup || popup.availableCardHeight <= 0) return desiredHeight

    var fixedContentHeight = cardHeader.implicitHeight
      + trackDetails.implicitHeight
      + progressArea.height
      + timeLabels.height
      + controlRow.implicitHeight
      + cardContent.spacing * 5
      + Style.space(24)
      + Style.space(10)
      + 2
      + popup.verticalContentInset

    return Math.max(0, Math.min(desiredHeight, popup.availableCardHeight - fixedContentHeight))
  }

  visible: hasMedia
  implicitWidth: hasMedia ? barRow.implicitWidth + Style.space(16) : 0
  implicitHeight: barSize

  function close() {
    popupOpen = false
  }

  function requestClose() {
    closeTimer.restart()
  }

  function highResolutionArtworkUrl(url) {
    var source = String(url || "")
    if (!/https?:\/\/[^/]*googleusercontent\.com\//i.test(source)) return source

    return source
      .replace(/=w\d+-h\d+/, "=w640-h640")
      .replace(/=s\d+(?=[-?]|$)/, "=s640")
  }

  onOriginalArtworkUrlChanged: useOriginalArtwork = false

  Row {
    id: barRow
    anchors.centerIn: parent
    spacing: Style.space(7)

    Text {
      textFormat: Text.PlainText
      text: root.activePlayer && root.activePlayer.isPlaying ? "♫" : "♪"
      color: root.accentColor
      font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: compactLabel
      textFormat: Text.PlainText
      text: root.title + (root.artist ? "  ·  " + root.artist : "")
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
      font.pixelSize: Style.font.body
      width: Math.min(Style.space(220), implicitWidth)
      elide: Text.ElideRight
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  HoverHandler {
    id: barHover

    onHoveredChanged: {
      if (hovered) {
        closeTimer.stop()
        root.popupOpen = true
      } else {
        root.requestClose()
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) {
        if (root.mediaService) root.mediaService.next()
      } else {
        root.popupOpen = !root.popupOpen
      }
    }

    onWheel: function(wheel) {
      if (!root.mediaService) return
      if (wheel.angleDelta.y > 0) root.mediaService.previous()
      else if (wheel.angleDelta.y < 0) root.mediaService.next()
    }
  }

  Timer {
    id: closeTimer
    interval: 180

    onTriggered: {
      if (!barHover.hovered && !popup.containsMouse)
        root.popupOpen = false
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    triggerMode: "hover"
    margin: Style.space(10)
    padding: 0
    borderColor: "transparent"
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(cardContent.childrenRect.height + Style.space(24) + 2)

    Rectangle {
      anchors.fill: parent
      anchors.margins: 0
      radius: Style.space(26)
      color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.92)
      border.width: 0
      border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.14)

      Column {
        id: cardContent
        anchors.fill: parent
        anchors.margins: Style.space(12)
        spacing: Style.space(8)

        Row {
          id: cardHeader
          width: parent.width
          spacing: Style.space(8)

          Rectangle {
            id: headerDot
            width: Style.space(8)
            height: width
            radius: width / 2
            color: root.accentColor
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: headerTitle
            text: root.activePlayer && root.activePlayer.isPlaying ? "NOW PLAYING" : "MEDIA PLAYER"
            color: Color.popups.text
            font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }

          Item {
            width: Math.max(0, cardHeader.width
              - headerDot.width
              - headerTitle.implicitWidth
              - sourceLabel.width
              - stateLabel.implicitWidth
              - cardHeader.spacing * 4)
            height: 1
          }

          Text {
            id: sourceLabel
            text: root.mediaService ? root.mediaService.providerName : "MPRIS"
            color: root.accentColor
            font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: Math.min(Style.space(130), Math.max(0,
              cardHeader.width
              - headerDot.width
              - headerTitle.implicitWidth
              - stateLabel.implicitWidth
              - cardHeader.spacing * 4))
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: stateLabel
            text: "●"
            color: root.activePlayer && root.activePlayer.isPlaying ? root.accentColor : Color.muted
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Item {
          width: parent.width
          height: root.artworkHeight

          Rectangle {
            width: parent.height
            height: width
            anchors.centerIn: parent
            radius: Style.space(20)
            color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.045)
            border.width: 1
            border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10)
            clip: true

            Image {
              id: artwork
              anchors.fill: parent
              anchors.margins: 1
              source: root.useOriginalArtwork
                ? root.originalArtworkUrl
                : root.highResolutionArtworkUrl(root.originalArtworkUrl)
              sourceSize.width: Math.round(width * Screen.devicePixelRatio)
              sourceSize.height: Math.round(height * Screen.devicePixelRatio)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
              smooth: true
              mipmap: true
              visible: status === Image.Ready

              onStatusChanged: {
                if (status === Image.Error && !root.useOriginalArtwork)
                  root.useOriginalArtwork = true
              }
            }

            Text {
              anchors.centerIn: parent
              text: "♫"
              color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.65)
              font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
              font.pixelSize: Style.font.displayLarge
              visible: !artwork.visible
            }
          }
        }

        Column {
          id: trackDetails
          width: parent.width
          spacing: Style.space(3)

          Text {
            width: parent.width
            text: root.title || "Nothing playing"
            color: Color.popups.text
            font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
            font.pixelSize: Style.font.subtitle
            font.bold: true
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.artist + (root.mediaService && root.mediaService.album
              ? (root.artist ? "  ·  " : "") + root.mediaService.album
              : "")
            color: Qt.darker(Color.popups.text, 1.25)
            font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
            visible: text !== ""
          }

          Text {
            width: parent.width
            text: "via " + (root.mediaService ? root.mediaService.providerName : "MPRIS")
            color: Color.muted
            font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
          }
        }

        Item {
          id: progressArea
          width: parent.width
          height: Style.space(20)

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Style.space(2)
            radius: height / 2
            color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.13)
          }

          Row {
            anchors.fill: parent
            spacing: Style.space(3)

            Repeater {
              model: root.waveformHeights.length

              Rectangle {
                required property int index
                width: Style.space(3)
                height: Style.space(root.waveformHeights[index])
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: root.mediaService && index / root.waveformHeights.length < root.mediaService.progress
                  ? root.accentColor
                  : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.38)

                Behavior on color {
                  ColorAnimation { duration: 140 }
                }
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            enabled: !!(root.mediaService && root.mediaService.canSeek)
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: function(mouse) {
              if (root.mediaService)
                root.mediaService.seekToRatio(mouse.x / width)
            }
          }
        }

        Item {
          id: timeLabels
          width: parent.width
          height: Style.space(14)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.mediaService ? root.mediaService.formatTime(root.mediaService.position) : "0:00"
            color: Color.muted
            font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
            font.pixelSize: Style.font.caption
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.mediaService && root.mediaService.durationSupported
              ? root.mediaService.formatTime(root.mediaService.duration) : "--:--"
            color: Color.muted
            font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
            font.pixelSize: Style.font.caption
          }
        }

        Row {
          id: controlRow
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(8)

          IconControl {
            glyph: "⤨"
            active: root.activePlayer && root.activePlayer.shuffle
            actionEnabled: !!(root.activePlayer && root.activePlayer.canControl && root.activePlayer.shuffleSupported)
            onActivated: if (root.mediaService) root.mediaService.toggleShuffle()
          }

          IconControl {
            glyph: "◀"
            actionEnabled: !!(root.activePlayer && root.activePlayer.canGoPrevious)
            onActivated: if (root.mediaService) root.mediaService.previous()
          }

          IconControl {
            glyph: root.activePlayer && root.activePlayer.isPlaying ? "Ⅱ" : "▶"
            primary: true
            actionEnabled: !!(root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause))
            onActivated: if (root.mediaService) root.mediaService.togglePlaying()
          }

          IconControl {
            glyph: "▶"
            actionEnabled: !!(root.activePlayer && root.activePlayer.canGoNext)
            onActivated: if (root.mediaService) root.mediaService.next()
          }

          IconControl {
            glyph: root.activePlayer && root.activePlayer.loopState === MprisLoopState.Track ? "↻¹" : "↻"
            active: !!(root.activePlayer && root.activePlayer.loopState !== MprisLoopState.None)
            actionEnabled: !!(root.activePlayer && root.activePlayer.canControl && root.activePlayer.loopSupported)
            onActivated: if (root.mediaService) root.mediaService.cycleRepeat()
          }
        }
      }

      HoverHandler {
        id: popupHover

        onHoveredChanged: {
          if (hovered)
            closeTimer.stop()
          else
            root.requestClose()
        }
      }
    }
  }

  component IconControl: Item {
    id: control

    property string glyph: ""
    property bool actionEnabled: true
    property bool active: false
    property bool primary: false
    signal activated()

    width: primary ? Style.space(44) : Style.space(32)
    height: primary ? Style.space(44) : Style.space(32)
    opacity: actionEnabled ? 1 : 0.42

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: control.primary ? root.accentColor
        : (control.active ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
          : (controlHover.containsMouse ? Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10) : "transparent"))
      border.width: control.primary ? 0 : 1
      border.color: control.active ? root.accentColor : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
    }

    Text {
      anchors.centerIn: parent
      text: control.glyph
      color: control.primary ? Color.background : (control.active ? root.accentColor : Color.popups.text)
      font.family: root.bar ? root.bar.fontFamily : "Sans Serif"
      font.pixelSize: control.primary ? Style.font.iconLarge : Style.font.body
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
      id: controlHover
      anchors.fill: parent
      enabled: control.actionEnabled
      hoverEnabled: true
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: control.activated()
    }
  }
}
