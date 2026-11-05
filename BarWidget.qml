import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "sups.bluetooth-sound-control"
  ipcTarget: "sups.bluetooth-sound-control"

  property bool connected: false
  property string mode: "none"
  property string label: "Disconnected"
  property string deviceName: ""
  property string cardName: ""
  property string profileName: ""
  property string codecName: ""
  property bool autoswitch: false
  property string builtinMic: ""
  property string iconText: "󰋋"
  readonly property bool isHfp: (mode === "hfp")

  readonly property string scriptPath: Qt.resolvedUrl("bin/omarchy-bluetooth-sound-control").toString().replace(/^file:\/\//, "")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  visible: connected

  function updateFromJson(jsonStr) {
    try {
      var data = JSON.parse(jsonStr.trim())
      root.connected = !!data.connected
      root.mode = data.mode || "none"
      root.label = data.label || "Disconnected"
      root.deviceName = data.device || ""
      root.cardName = data.card || ""
      root.profileName = data.profile || ""
      root.codecName = data.codec || ""
      root.autoswitch = !!data.autoswitch
      root.builtinMic = data.builtin_mic || ""
      root.iconText = root.isHfp ? "󰍬" : "󰋋"
    } catch(e) {}
  }

  function setMode(targetMode) {
    if (actionProc.running) return
    actionProc.command = [root.scriptPath, targetMode]
    actionProc.running = true
  }

  function toggleAutoswitch() {
    if (actionProc.running) return
    actionProc.command = [root.scriptPath, "autoswitch", "toggle"]
    actionProc.running = true
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  Process {
    id: statusProc
    command: [root.scriptPath, "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateFromJson(text)
    }
  }

  Process {
    id: actionProc
    onExited: root.refresh()
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onOpenedChanged: {
    if (opened) root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.iconText
    active: root.opened || root.isHfp
    tooltipText: root.connected
      ? (root.deviceName + " (" + root.label + ") — Click to open control panel")
      : "Bluetooth: Disconnected"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.setMode("toggle")
      } else {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened && root.connected
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: PanelKeyCatcher {
      id: keyCatcher
      implicitHeight: mainCol.implicitHeight
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // Hero / Device Info Header
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroCol.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: root.isHfp ? "󰍬" : "󰋋"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroCol
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(12)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: root.deviceName !== "" ? root.deviceName : "Bluetooth Headset"
              textFormat: Text.PlainText
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: root.isHfp ? "Call / Headset Mode (Mono)" : "Music / Media Mode (Stereo)"
              textFormat: Text.PlainText
              color: root.bar.foreground
              opacity: 0.6
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        // Mode Selection Section
        PanelSectionHeader {
          text: "Audio Mode"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }

        Row {
          id: modeButtonsRow
          width: parent.width
          spacing: Style.space(8)

          readonly property real buttonWidth: (width - spacing) / 2

          Button {
            width: modeButtonsRow.buttonWidth
            iconText: "󰋋"
            text: "High Quality"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(4)
            bordered: true
            active: !root.isHfp
            onClicked: root.setMode("a2dp")
          }

          Button {
            width: modeButtonsRow.buttonWidth
            iconText: "󰍬"
            text: "Headset Mic"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(4)
            bordered: true
            active: root.isHfp
            onClicked: root.setMode("hfp")
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        // Status Details
        Column {
          width: parent.width
          spacing: Style.space(8)

          InfoRow {
            label: "Active Codec"
            value: root.codecName !== "" ? root.codecName : (root.isHfp ? "mSBC (16 kHz)" : "AAC / SBC (48 kHz)")
          }

          InfoRow {
            label: "Auto-Switch on Mic"
            Item {
              width: autoSwitch.implicitWidth
              height: autoSwitch.implicitHeight
              ToggleSwitch {
                id: autoSwitch
                checked: root.autoswitch
                busy: actionProc.running
                onToggled: root.toggleAutoswitch()
              }
            }
          }

          InfoRow {
            label: "Default Microphone"
            value: root.isHfp ? "Headset Microphone" : "Built-in Analog Stereo"
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        // Quick Actions Row
        Row {
          id: actionButtonsRow
          width: parent.width
          spacing: Style.space(8)
          readonly property real actionBtnWidth: (width - spacing) / 2

          Button {
            width: actionButtonsRow.actionBtnWidth
            text: "Audio Mixer"
            iconText: "󰓃"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: {
              root.close()
              root.bar.run("omarchy-shell shell toggle omarchy.audio")
            }
          }

          Button {
            width: actionButtonsRow.actionBtnWidth
            text: "Bluetooth"
            iconText: "󰂯"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: {
              root.close()
              root.bar.run("omarchy-shell shell toggle omarchy.bluetooth")
            }
          }
        }
      }
    }
  }

  component InfoRow: Row {
    property string label: ""
    property string value: ""
    default property alias extraContent: container.children

    width: parent.width
    spacing: Style.space(8)

    Text {
      text: label
      textFormat: Text.PlainText
      color: root.bar.foreground
      opacity: 0.65
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      width: Math.max(Style.space(8), parent.width - parent.children[0].implicitWidth - container.implicitWidth - parent.spacing * 2)
      height: 1
    }

    Item {
      id: container
      implicitWidth: value !== "" ? valText.implicitWidth : (children.length > 0 ? children[0].implicitWidth : 0)
      implicitHeight: value !== "" ? valText.implicitHeight : (children.length > 0 ? children[0].implicitHeight : 0)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: valText
        visible: value !== ""
        text: value
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }
  }
}
