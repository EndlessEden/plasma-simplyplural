import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    // 1. Initialize Storage
    Storage { id: appStorage }

    // 2. Define the Compact View (Taskbar Icon)
    compactRepresentation: MouseArea {
        onClicked: root.expanded = !root.expanded
        
        PlasmaCore.IconItem {
            anchors.fill: parent
            source: "preferences-system-users" // Default Icon
        }
    }

    // 3. Define the Expanded View (The Popout)
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 25
        
        // This Loader swaps between Login and Popout View
        Loader {
            id: viewLoader
            anchors.fill: parent
            
            // Initial source: If token exists, go to Popout, else go to Login
            source: appStorage.authToken !== "" ? "popout.qml" : "login.qml"
            
            onLoaded: {
                if (item) {
                    // Pass the persistent storage object to the loaded item
                    item.storage = appStorage
                    
                    // Connect signals for view transitions
                    if (source.toString().includes("login.qml")) {
                        item.loginSuccess.connect(function() {
                            viewLoader.source = "popout.qml"
                        })
                    } else if (source.toString().includes("popout.qml")) {
                        item.loggedOut.connect(function() {
                            viewLoader.source = "login.qml"
                        })
                    }
                }
            }
        }
    }
}
