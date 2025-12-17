import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtWebSockets 1.1 // Required for WebSocket
import "../code/api.js" as Api

Kirigami.ScrollablePage {
    id: page
    title: "Simply Plural Fronters"
    
    ListModel { id: fronterModel }
    required property var storage
    signal loggedOut()

    // --- WebSocket Component for Real-Time Updates ---
    WebSocket {
        id: spSocket
        // Production WebSocket URL for Simply Plural
        url: "wss://api.apparyllis.com/v1/socket" 
        active: false 
        
        onStatusChanged: {
            if (spSocket.status === WebSocket.Open) {
                console.log("WebSocket: Connection established. Authenticating...");
                var authPayload = { 'op': 'authenticate', 'token': page.storage.getToken() };
                spSocket.sendTextMessage(JSON.stringify(authPayload));
                pingTimer.start();
            } else if (spSocket.status === WebSocket.Closed || spSocket.status === WebSocket.Error) {
                console.error("WebSocket Status:", spSocket.status === WebSocket.Error ? spSocket.errorString : "Closed. Attempting reconnect...");
                pingTimer.stop();
                reconnectTimer.start();
            }
        }
        
        onTextMessageReceived: function(message) {
            var data = JSON.parse(message);
            
            if (data.msg === "Successfully authenticated") {
                console.log("WebSocket: Authenticated. Fetching initial data...");
                page.refresh(true); 
            } else if (data.msg === "Update" && data.target === "frontHistory") {
                console.log("Front change detected via WebSocket! Performing refresh.");
                page.refresh(true);
            }
        }
    }

    // --- Keep-Alive Ping Timer (Required by Simply Plural Socket) ---
    Timer {
        id: pingTimer
        interval: 10000 // 10 seconds
        repeat: true
        active: false
        onTriggered: spSocket.sendTextMessage("ping")
    }

    // --- Reconnect Timer ---
    Timer {
        id: reconnectTimer
        interval: 5000 // 5 seconds wait before retrying
        repeat: false
        active: false
        onTriggered: {
            if (page.storage.getToken() !== "") {
                spSocket.active = true;
            }
        }
    }

    // --- Action Header (Logout Button) ---
    header: Kirigami.ActionToolBar {
        actions: [
            Kirigami.Action {
                text: i18n("Logout")
                icon.name: "system-log-out"
                
                onTriggered: {
                    spSocket.close(1000, "User logged out");
                    pingTimer.stop();
                    reconnectTimer.stop();
                    page.storage.setToken("");
                    fronterModel.clear();
                    page.loggedOut();
                }
            }
        ]
    }

    // --- Fronter List View ---
    ListView {
        model: fronterModel
        clip: true
        
        delegate: RowLayout {
            width: parent.width
            spacing: 10
            
            Kirigami.UrlImage {
                source: model.avatarUrl
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                sourceSize.width: 40
                sourceSize.height: 40
                // Use a standard circle mask for avatars
                layer.effect: ShaderEffect {
                    // This is a common QML trick to circle-crop an image
                    property real radius: 20
                    property real width: 40
                    fragmentShader: "
                        varying highp vec2 qt_TexCoord0;
                        uniform sampler2D source;
                        uniform highp float radius;
                        uniform highp float width;
                        void main() {
                            highp vec2 center = vec2(width / 2.0, width / 2.0);
                            highp vec2 coords = qt_TexCoord0 * width;
                            if (distance(coords, center) > radius) {
                                discard;
                            }
                            gl_FragColor = texture2D(source, qt_TexCoord0);
                        }
                    "
                }
                layer.enabled: true
            }

            ColumnLayout {
                Label { 
                    text: model.name 
                    font.bold: true 
                }
                Label { 
                    text: "System ID: " + model.systemId.substring(0,5) + "..." 
                    font.pointSize: 8
                    opacity: 0.7
                }
            }
        }
        
        // Placeholder text if no fronters are found
        footer: Label {
            visible: fronterModel.count === 0
            text: i18n("No friends are currently fronting.")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.gridUnit
        }
    }

    /**
     * Fetches data from the REST API. Called on WebSocket auth and updates.
     * @param {boolean} forceApiCall - Always call API if true.
     */
    function refresh(forceApiCall) {
        if (page.storage.getToken() === "") {
            console.log("Token missing, cannot refresh. Deactivating socket.");
            spSocket.active = false;
            page.loggedOut(); 
            return;
        }

        // Only call the REST API if explicitly requested (by WebSocket update) or if we are loading the first time.
        if (forceApiCall) {
            Api.fetchFronters(page.storage.getToken(), page.storage, function(data) {
                fronterModel.clear();
                for (var i=0; i < data.length; i++) {
                    fronterModel.append(data[i]);
                }
            });
        }
    }
    
    // --- Component Lifetime Hooks ---
    Component.onCompleted: {
        if (page.storage.getToken() !== "") {
            spSocket.active = true; // Initiate connection
        }
    }

    Component.onDestruction: {
        spSocket.close();
        pingTimer.stop();
        reconnectTimer.stop();
    }
}
