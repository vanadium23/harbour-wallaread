import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: settingsDialog
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        width: parent.width

        Column {
            id: column
            width: parent.width

            DialogHeader {
                acceptText: qsTr( "Save" )
            }

            TextField {
                id: urlField
                width: parent.width
                label: qsTr( "URL" )
                placeholderText: qsTr( "Server URL" )
                text: settings.base_url
                inputMethodHints: Qt.ImhUrlCharactersOnly
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: userField.focus = true
            }

            TextField {
                id: userField
                width: parent.width
                label: qsTr( "Login" )
                placeholderText: qsTr( "User Login" )
                text: settings.username
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: passwordField.focus = true
            }

            PasswordField {
                id: passwordField
                width: parent.width
                label: "Password"
                text: settings.password
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: clientIdField.focus = true
            }

            TextField {
                id: clientIdField
                width: parent.width
                label: qsTr( "Client ID" )
                placeholderText: qsTr( "Client ID" )
                text: settings.client_id
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: clientSecretField.focus = true
            }

            TextField {
                id: clientSecretField
                width: parent.width
                label: qsTr( "Client Secret" )
                placeholderText: qsTr( "Client Secret" )
                text: settings.client_secret
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData
            }

            VerticalScrollDecorator {}
        }
    }

    onDone: {
        if (result == DialogResult.Accepted) {
            settings.base_url = urlField.text
            settings.username = userField.text
            settings.password = passwordField.text
            settings.client_id = clientIdField.text
            settings.client_secret = clientSecretField.text
        }
    }
}
