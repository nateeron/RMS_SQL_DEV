let settings = [];
let baseUrls = [];
let selectedBaseUrlId = null;

// Load saved base URL selection from localStorage
function loadSavedBaseUrlSelection() {
    const saved = localStorage.getItem('selectedBaseUrlId');
    if (saved) {
        selectedBaseUrlId = saved;
    }
}

// Save base URL selection to localStorage
function saveBaseUrlSelection(id) {
    if (id) {
        localStorage.setItem('selectedBaseUrlId', id);
    } else {
        localStorage.removeItem('selectedBaseUrlId');
    }
}

// Load settings on page load
document.addEventListener('DOMContentLoaded', () => {
    loadSavedBaseUrlSelection();
    loadSettings();
    loadBaseUrls();
    
    // Add event listener for base URL select after DOM is ready
    setTimeout(() => {
        const select = document.getElementById('baseUrlSelect');
        if (select) {
            // Set default to first base URL if nothing is selected
            if (!selectedBaseUrlId && baseUrls.length > 0) {
                selectedBaseUrlId = baseUrls[0].id.toString();
                saveBaseUrlSelection(selectedBaseUrlId);
                select.value = selectedBaseUrlId;
            } else if (selectedBaseUrlId) {
                select.value = selectedBaseUrlId;
            }
            
            select.addEventListener('change', function() {
                selectedBaseUrlId = this.value;
                saveBaseUrlSelection(selectedBaseUrlId);
            });
        }
    }, 100);
});

// Load settings from server
async function loadSettings() {
    try {
        const response = await fetch('/api/settings');
        const data = await response.json();
        settings = data.Set || [];
        renderActions();
    } catch (error) {
        console.error('Error loading settings:', error);
        document.getElementById('actionsList').innerHTML = 
            '<div class="empty-state"><h2>Error loading actions</h2><p>Please check the server connection.</p></div>';
    }
}

// Load base URLs from server
async function loadBaseUrls() {
    try {
        const response = await fetch('/api/baseurls');
        baseUrls = await response.json();
        
        // Set default to first base URL if nothing is saved and base URLs exist
        if (!selectedBaseUrlId && baseUrls.length > 0) {
            selectedBaseUrlId = baseUrls[0].id.toString();
            saveBaseUrlSelection(selectedBaseUrlId);
        }
        
        renderActions();
        
        // Update select element after rendering
        setTimeout(() => {
            const select = document.getElementById('baseUrlSelect');
            if (select && selectedBaseUrlId) {
                select.value = selectedBaseUrlId;
            }
        }, 50);
    } catch (error) {
        console.error('Error loading base URLs', error);
    }
}

// Get selected base URL
function getSelectedBaseUrl() {
    if (!selectedBaseUrlId) return null;
    return baseUrls.find(b => b.id === parseInt(selectedBaseUrlId));
}

// Render actions list
function renderActions() {
    const container = document.getElementById('actionsList');
    
    if (settings.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <h2>No Actions Available</h2>
                <p>Add some settings first to see actions here.</p>
            </div>
        `;
        return;
    }

    // Determine which base URL should be selected
    let defaultSelectedId = selectedBaseUrlId;
    if (!defaultSelectedId && baseUrls.length > 0) {
        defaultSelectedId = baseUrls[0].id.toString();
    }
    
    const baseUrlSelect = baseUrls.length > 0 ? `
        <div class="base-url-section">
            <label for="baseUrlSelect">Select Base URL:</label>
            <select id="baseUrlSelect" onchange="selectedBaseUrlId = this.value; saveBaseUrlSelection(this.value);">
                <option value="">-- None (use relative path) --</option>
                ${baseUrls.map(b => {
                    const isSelected = defaultSelectedId == b.id;
                    return `<option value="${b.id}" ${isSelected ? 'selected' : ''}>${b.name} - ${b.url}</option>`;
                }).join('')}
            </select>
        </div>
    ` : '';

    container.innerHTML = baseUrlSelect + settings.map(setting => {
        const respJson = JSON.stringify(setting.resp || {}, null, 2);
        const reqJson = setting.method === 'POST' ? JSON.stringify(setting.req || {}, null, 2) : null;
        return `
            <div class="action-card" id="action-${setting.id}">
                <div class="action-header">
                    <div class="action-title">Action #${setting.id}</div>
                    <button class="btn btn-send" onclick="sendRequest(${setting.id})" id="btn-${setting.id}">
                        Send
                    </button>
                </div>
                <div class="action-meta">
                    <span class="method-badge method-${setting.method}">${setting.method}</span>
                    <span class="action-path">${setting.path}</span>
                </div>
                ${reqJson ? `
                <div class="action-response">
                    <div class="response-label">Request Body (REQ) - for POST</div>
                    <div class="response-content stored-response">${escapeHtml(reqJson)}</div>
                </div>
                ` : ''}
                <div class="action-response">
                    <div class="response-label">Stored Response (RESP)</div>
                    <div class="response-content stored-response">${escapeHtml(respJson)}</div>
                </div>
                <div class="action-response" id="actual-response-${setting.id}" style="display: none;">
                    <div class="response-label">Actual Response</div>
                    <div class="response-content actual-response" id="response-content-${setting.id}"></div>
                </div>
            </div>
        `;
    }).join('');
}

// Send HTTP request
async function sendRequest(id) {
    const setting = settings.find(s => s.id === id);
    if (!setting) return;

    const btn = document.getElementById(`btn-${id}`);
    const responseDiv = document.getElementById(`actual-response-${id}`);
    const responseContent = document.getElementById(`response-content-${id}`);
    
    // Remove existing status info if any
    const existingStatus = responseDiv.querySelector('.status-info');
    if (existingStatus) {
        existingStatus.remove();
    }
    
    // Disable button and show loading
    btn.disabled = true;
    btn.textContent = 'Sending...';
    responseDiv.style.display = 'block';
    responseContent.textContent = 'Loading...';
    responseContent.className = 'response-content actual-response loading';

    try {
        const selectedBaseUrl = getSelectedBaseUrl();
        const url = selectedBaseUrl ? `${selectedBaseUrl.url}${setting.path}` : setting.path;
        const options = {
            method: setting.method,
            mode: 'cors',
            credentials: 'omit',
            referrerPolicy: 'no-referrer-when-downgrade',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        };

        // For POST requests, include body from req field
        if (setting.method === 'POST' && setting.req && Object.keys(setting.req).length > 0) {
            options.body = JSON.stringify(setting.req);
        }

        const response = await fetch(url, options);
        let data;
        const contentType = response.headers.get('content-type');
        
        if (contentType && contentType.includes('application/json')) {
            data = await response.json();
        } else {
            data = await response.text();
        }
        
        // Display response
        const responseText = typeof data === 'string' ? data : JSON.stringify(data, null, 2);
        responseContent.textContent = responseText;
        responseContent.className = 'response-content actual-response success';
        
        // Show status
        const statusLabel = document.createElement('div');
        statusLabel.className = 'status-info';
        const statusClass = response.status >= 200 && response.status < 300 ? 'success' : 'error';
        statusLabel.innerHTML = `<span class="status-badge status-${statusClass}">Status: ${response.status} ${response.statusText}</span>`;
        responseDiv.insertBefore(statusLabel, responseContent);
        
    } catch (error) {
        responseContent.textContent = `Error: ${error.message}`;
        responseContent.className = 'response-content actual-response error';
        
        // Show error status
        const statusLabel = document.createElement('div');
        statusLabel.className = 'status-info';
        statusLabel.innerHTML = `<span class="status-badge status-error">Error: ${error.message}</span>`;
        responseDiv.insertBefore(statusLabel, responseContent);
    } finally {
        btn.disabled = false;
        btn.textContent = 'Send';
    }
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

