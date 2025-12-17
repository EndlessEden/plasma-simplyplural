import QtQuick
import Qt.labs.settings

QtObject {
    id: storage

    // QSettings wrapper for persistent storage on disk
    property Settings settings: Settings {
        category: "SimplyPluralCache"
        property string authToken: ""
        // JSON string of friend data to persist across reboots
        property string cachedFriendsJson: "{}" 
    }

    // In-Memory cache object (parsed on load)
    property var friendCache: {
        try {
            return JSON.parse(settings.cachedFriendsJson);
        } catch (e) {
            console.error("Error parsing friendCache:", e);
            return {};
        }
    }

    function saveCache() {
        settings.cachedFriendsJson = JSON.stringify(friendCache)
    }

    /**
     * Updates or inserts a member's data, checking if avatar_url has changed.
     * @param {string} systemId 
     * @param {string} memberId 
     * @param {string} memberName 
     * @param {string} avatarUrl 
     * @returns {boolean} True if data changed, false otherwise.
     */
    function updateMember(systemId, memberId, memberName, avatarUrl) {
        if (!friendCache[systemId]) {
            friendCache[systemId] = { members: {} };
        }
        if (!friendCache[systemId].members[memberId]) {
            friendCache[systemId].members[memberId] = {};
        }
        
        var currentData = friendCache[systemId].members[memberId];
        var dataChanged = (currentData.avatar_url !== avatarUrl || currentData.name !== memberName);

        if (dataChanged) {
            friendCache[systemId].members[memberId] = {
                name: memberName,
                avatar_url: avatarUrl,
                last_updated: Date.now()
            };
            saveCache();
            return true;
        }
        return false;
    }

    function getToken() { return settings.authToken }
    function setToken(token) { settings.authToken = token }
}
