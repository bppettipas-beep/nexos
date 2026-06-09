import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#08080f"

    // ── Background gradient ────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Diagonal
            GradientStop { position: 0.0; color: "#08080f" }
            GradientStop { position: 0.6; color: "#06060c" }
            GradientStop { position: 1.0; color: "#030308" }
        }
    }

    // ── Animated grid ─────────────────────────────────────────
    Canvas {
        anchors.fill: parent
        opacity: 0.055
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = "#00f5ff"
            ctx.lineWidth   = 0.5
            var sp = 55
            for (var x = 0; x <= width;  x += sp) {
                ctx.beginPath(); ctx.moveTo(x, 0);    ctx.lineTo(x, height); ctx.stroke()
            }
            for (var y = 0; y <= height; y += sp) {
                ctx.beginPath(); ctx.moveTo(0, y);    ctx.lineTo(width, y);  ctx.stroke()
            }
        }
    }

    // ── Glow orbs (animated) ──────────────────────────────────
    Repeater {
        model: 4
        Item {
            property real ox: [0.15, 0.72, 0.40, 0.85][index] * root.width
            property real oy: [0.20, 0.60, 0.80, 0.15][index] * root.height
            property color gc: index % 2 === 0 ? "#00f5ff" : "#bf5fff"

            Rectangle {
                x: parent.ox - width / 2
                y: parent.oy - height / 2
                width:  320 + index * 90
                height: width
                radius: width / 2
                color:  parent.gc
                opacity: 0.045

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { to: parent.ox - width / 2 + 60;  duration: 9000 + index * 2200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: parent.ox - width / 2 - 40;  duration: 9000 + index * 2200; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { to: parent.oy - height / 2 - 50; duration: 11000 + index * 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: parent.oy - height / 2 + 35; duration: 11000 + index * 1600; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ── Floating scan-line ────────────────────────────────────
    Rectangle {
        id: scanLine
        width: root.width
        height: 2
        color: "#00f5ff"
        opacity: 0.0
        y: 0

        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: root.height; duration: 5000; easing.type: Easing.Linear }
        }
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 0.12; duration: 500 }
            PauseAnimation { duration: 4000 }
            NumberAnimation { from: 0.12; to: 0; duration: 500 }
        }
    }

    // ── Clock (top centre) ────────────────────────────────────
    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 62
        }
        spacing: 5

        Text {
            id: timeLbl
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#ffffff"
            font { pixelSize: 74; weight: Font.Light; family: "JetBrains Mono" }
            text: Qt.formatTime(new Date(), "HH:mm")
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: timeLbl.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#00f5ff"
            font { pixelSize: 15; family: "JetBrains Mono" }
            text: Qt.formatDate(new Date(), "dddd, MMMM d  yyyy")
        }
    }

    // ── NexOS logo (below clock) ──────────────────────────────
    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 238
        }
        spacing: 5

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "NEX"
            color: "#00f5ff"
            font { pixelSize: 50; weight: Font.Bold; family: "JetBrains Mono"; letterSpacing: 16 }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 190; height: 2; color: "#00f5ff"; opacity: 0.65
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OS"
            color: "#bf5fff"
            font { pixelSize: 22; family: "JetBrains Mono"; letterSpacing: 24 }
        }
    }

    // ── Login card ────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 52
        width: 370; height: 292
        radius: 12
        color: "#0a0a1c"
        opacity: 0.93
        border.color: "#00f5ff"
        border.width: 1

        // Inner glow top edge
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.35; color: "#00f5ff" }
                GradientStop { position: 0.65; color: "#00f5ff" }
                GradientStop { position: 1.0;  color: "transparent" }
            }
            opacity: 0.45
        }

        ColumnLayout {
            anchors { fill: parent; margins: 30 }
            spacing: 14

            // Username
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: "USERNAME"
                    color: "#00f5ff"
                    font { pixelSize: 9; family: "JetBrains Mono"; letterSpacing: 2 }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 42
                    color: "#0e0e28"; radius: 6
                    border.color: userField.activeFocus ? "#00f5ff" : "#22224a"
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    TextInput {
                        id: userField
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        font { pixelSize: 13; family: "JetBrains Mono" }
                        text: userModel.lastUser
                        KeyNavigation.tab: passField
                    }
                }
            }

            // Password
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: "PASSWORD"
                    color: "#00f5ff"
                    font { pixelSize: 9; family: "JetBrains Mono"; letterSpacing: 2 }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 42
                    color: "#0e0e28"; radius: 6
                    border.color: passField.activeFocus ? "#00f5ff" : "#22224a"
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    TextInput {
                        id: passField
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        font { pixelSize: 13; family: "JetBrains Mono" }
                        echoMode: TextInput.Password
                        Keys.onReturnPressed: doLogin()
                        Keys.onEnterPressed:  doLogin()
                    }
                }
            }

            // Login button
            Rectangle {
                id: loginBtn
                Layout.fillWidth: true; height: 44; radius: 6
                color: hoverArea.containsMouse ? "#00d8ee" : "#00f5ff"
                Behavior on color { ColorAnimation { duration: 130 } }

                Text {
                    anchors.centerIn: parent
                    text: "ENTER NEXOS"
                    color: "#000000"
                    font { pixelSize: 11; weight: Font.Bold; family: "JetBrains Mono"; letterSpacing: 2 }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }
    }

    function doLogin() {
        sddm.login(userField.text, passField.text, sessionBox.currentIndex)
    }

    // ── Error message ─────────────────────────────────────────
    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: card.bottom
            topMargin: 14
        }
        color: "#ff2d78"
        font { pixelSize: 12; family: "JetBrains Mono" }
        text: sddm.lastError
    }

    // ── Session selector (bottom-right) ───────────────────────
    ComboBox {
        id: sessionBox
        anchors { bottom: parent.bottom; right: parent.right; margins: 20 }
        width: 210; height: 32
        model: sessionModel
        textRole: "name"

        contentItem: Text {
            leftPadding: 10
            text: sessionBox.displayText
            color: "#666688"; font { pixelSize: 10; family: "JetBrains Mono" }
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: "#0d0d20"; radius: 5
            border.color: "#22224a"; border.width: 1
        }
    }

    // ── Power buttons (bottom-left) ───────────────────────────
    Row {
        anchors { bottom: parent.bottom; left: parent.left; margins: 20 }
        spacing: 10

        Repeater {
            model: [
                { label: "⏻", tip: "Shut Down",  cmd: function() { sddm.powerOff() }  },
                { label: "↺", tip: "Restart",    cmd: function() { sddm.reboot()   }  },
            ]
            Rectangle {
                width: 32; height: 32; radius: 5
                color: pma.containsMouse ? "#1c1c3a" : "#0d0d20"
                border.color: "#22224a"; border.width: 1
                Behavior on color { ColorAnimation { duration: 130 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: pma.containsMouse ? "#00f5ff" : "#555575"
                    font.pixelSize: 16
                    Behavior on color { ColorAnimation { duration: 130 } }
                }

                MouseArea {
                    id: pma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.cmd()
                }

                ToolTip.visible: pma.containsMouse
                ToolTip.text:    modelData.tip
            }
        }
    }

    // ── Focus / error handling ────────────────────────────────
    Connections {
        target: sddm
        function onLoginFailed() { passField.clear(); passField.forceActiveFocus() }
    }

    Component.onCompleted: {
        if (userField.text !== "") passField.forceActiveFocus()
        else userField.forceActiveFocus()
    }
}
