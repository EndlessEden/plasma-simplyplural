// --- Simply Plural API Configuration ---
const API_URL_BASE = "https://api.simplyplural.com/api/v2";

/**
 * Handles the login request to obtain the Bearer Token.
 * @param {string} username - User's email or username.
 * @param {string} password - User's password.
 * @param {function} callback - Callback(success, token, msg).
 */
function login(username, password, callback) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", `${API_URL_BASE}/tokens`);
    xhr.setRequestHeader("Content-Type", "application/json");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.token) {
                        callback(true, response.token, "");
                    } else {
                        callback(false, "", "Invalid response structure from server.");
                    }
                } catch (e) {
                    console.error("Login JSON Parse Error:", e);
                    callback(false, "", "Server returned invalid JSON.");
                }
            } else {
                var errorMsg = `Login Failed (${xhr.status})`;
                try {
                    var errJson = JSON.parse(xhr.responseText);
                    if (errJson.message) errorMsg = errJson.message;
                } catch(e) {}
                
                callback(false, "", errorMsg);
            }
        }
    }

    var data = JSON.stringify({
        "username": username,
        "password": password
    });

    xhr.send(data);
}

/**
 * Fetches the current fronter list for all friends.
 * @param {string} token - The Bearer token.
 * @param {object} storageItem - The QML Storage component object.
 * @param {function} callback - Callback(activeFrontersArray).
 */
function fetchFronters(token, storageItem, callback) {
    var xhr = new XMLHttpRequest();
    // Endpoint returns friends' fronters. Use the main /fronters endpoint to get full member data (including avatar_url).
    xhr.open("GET", `${API_URL_BASE}/friends/fronters`);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var response = JSON.parse(xhr.responseText);
                var activeFronters = [];

                for (var i = 0; i < response.length; i++) {
                    var friendData = response[i];
                    
                    if (friendData.members && friendData.members.length > 0) {
                        for (var j = 0; j < friendData.members.length; j++) {
                            var member = friendData.members[j];
                            
                            var sysId = friendData.system_id || "unknown_sys";
                            var memId = member.content.uid; // Unique UUID
                            var name = member.content.name;
                            var rawAvatarUrl = member.content.avatar_url || "";

                            // Update cache (for persistence and URL tracking)
                            storageItem.updateMember(sysId, memId, name, rawAvatarUrl);

                            // Prepare display data
                            activeFronters.push({
                                systemId: sysId,
                                memberId: memId,
                                name: name,
                                avatarUrl: rawAvatarUrl
                            });
                        }
                    }
                }
                callback(activeFronters);
            } else {
                console.error("API Error during fetchFronters:", xhr.status, xhr.responseText);
                // Optionally handle token expiration by forcing logout here
            }
        }
    }
    xhr.send();
}
