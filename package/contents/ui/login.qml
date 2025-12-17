import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "../code/api.js" as Api

Kirigami.ScrollablePage {
    id: loginPage
    title: "Simply Plural Login"

    signal loginSuccess()
    required property var storage

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.9
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            TextField {
                id: usernameField
                Kirigami.FormData.label: "Username/Email:"
                placeholderText: "Enter your username"
                onAccepted: passwordField.forceActiveFocus()
            }

            TextField {
                id: passwordField
                Kirigami.FormData.label: "Password:"
                placeholderText: "Enter your password"
                echoMode: TextInput.Password
                onAccepted: loginButton.clicked()
            }
        }

        Label {
            id: statusLabel
            Layout.alignment: Qt.AlignHCenter
            color: Kirigami.Theme.negativeTextColor
            visible: text !== ""
            text: ""
        }

        Button {
            id: loginButton
            text: "Log In"
            Layout.alignment: Qt.AlignHCenter
            
            onClicked: {
                statusLabel.text = "Logging in...";
                statusLabel.color = Kirigami.Theme.neutralTextColor;
                enabled = false;

                Api.login(usernameField.text, passwordField.text, function(success, token, msg) {
                    loginButton.enabled = true;
                    
                    if (success) {
                        loginPage.storage.setToken(token);
                        statusLabel.text = "Success!";
                        statusLabel.color = Kirigami.Theme.positiveTextColor;
                        loginPage.loginSuccess();
                    } else {
                        statusLabel.text = msg;
                        statusLabel.color = Kirigami.Theme.negativeTextColor;
                    }
                });
            }
        }
    }
}
