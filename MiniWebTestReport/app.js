let settings = [];
let baseUrls = [];

// Load settings on page load
document.addEventListener('DOMContentLoaded', () => {
    loadSettings();
    loadBaseUrls();
    document.getElementById('settingForm').addEventListener('submit', handleFormSubmit);
    document.getElementById('baseUrlForm').addEventListener('submit', handleBaseUrlSubmit);
});

// Load settings from server
async function loadSettings() {
    try {
        const response = await fetch('/api/settings');
        const data = await response.json();
        settings = data.Set || [];
        renderTable();
    } catch (error) {
        console.error('Error loading settings:', error);
        alert('Failed to load settings');
    }
}

// Load base URLs from server
async function loadBaseUrls() {
    try {
        const response = await fetch('/api/baseurls');
        baseUrls = await response.json();
        renderBaseUrlsTable();
    } catch (error) {
        console.error('Error loading base URLs:', error);
        alert('Failed to load base URLs');
    }
}

// Render base URLs table
function renderBaseUrlsTable() {
    const tbody = document.getElementById('baseUrlsBody');
    tbody.innerHTML = '';

    if (baseUrls.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; padding: 20px; color: #858585;">No base URLs found. Click "Add Base URL" to create one.</td></tr>';
        return;
    }

    baseUrls.forEach(baseUrl => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${baseUrl.id}</td>
            <td>${baseUrl.name}</td>
            <td style="font-family: monospace; color: #ce9178;">${baseUrl.url}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-edit" onclick="editBaseUrl(${baseUrl.id})">Edit</button>
                    <button class="btn btn-danger" onclick="deleteBaseUrl(${baseUrl.id})">Delete</button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Render table with settings
function renderTable() {
    const tbody = document.getElementById('settingsBody');
    tbody.innerHTML = '';

    if (settings.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; padding: 40px; color: #858585;">No settings found. Click "Add New" to create one.</td></tr>';
        return;
    }

    settings.forEach(setting => {
        const row = document.createElement('tr');
        const respPreview = JSON.stringify(setting.resp || {});
        const reqPreview = setting.method === 'POST' ? JSON.stringify(setting.req || {}) : '-';
        const previewText = setting.method === 'POST' 
            ? `Req: ${reqPreview.substring(0, 30)}${reqPreview.length > 30 ? '...' : ''} | Resp: ${respPreview.substring(0, 30)}${respPreview.length > 30 ? '...' : ''}`
            : respPreview;
        const titleText = setting.method === 'POST' 
            ? `Request: ${reqPreview} | Response: ${respPreview}`
            : respPreview;
        
        row.innerHTML = `
            <td>${setting.id}</td>
            <td>${setting.path}</td>
            <td><span class="method-badge method-${setting.method}">${setting.method}</span></td>
            <td class="resp-preview" title="${titleText}">${previewText}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-edit" onclick="editSetting(${setting.id})">Edit</button>
                    <button class="btn btn-danger" onclick="deleteSetting(${setting.id})">Delete</button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Toggle request field based on method
function toggleRequestField() {
    const method = document.getElementById('method').value;
    const reqGroup = document.getElementById('reqGroup');
    if (method === 'POST') {
        reqGroup.style.display = 'block';
    } else {
        reqGroup.style.display = 'none';
    }
}

// Open add modal
function openAddModal() {
    document.getElementById('modalTitle').textContent = 'Add Setting';
    document.getElementById('editId').value = '';
    document.getElementById('path').value = '';
    document.getElementById('method').value = 'GET';
    document.getElementById('req').value = '{}';
    document.getElementById('resp').value = '{}';
    toggleRequestField();
    document.getElementById('modal').style.display = 'block';
}

// Open edit modal
function editSetting(id) {
    const setting = settings.find(s => s.id === id);
    if (!setting) return;

    document.getElementById('modalTitle').textContent = 'Edit Setting';
    document.getElementById('editId').value = setting.id;
    document.getElementById('path').value = setting.path;
    document.getElementById('method').value = setting.method;
    document.getElementById('req').value = JSON.stringify(setting.req || {}, null, 2);
    document.getElementById('resp').value = JSON.stringify(setting.resp || {}, null, 2);
    toggleRequestField();
    document.getElementById('modal').style.display = 'block';
}

// Close modal
function closeModal() {
    document.getElementById('modal').style.display = 'none';
}

// Handle form submit
async function handleFormSubmit(e) {
    e.preventDefault();

    const id = document.getElementById('editId').value;
    const path = document.getElementById('path').value;
    const method = document.getElementById('method').value;
    let req = {};
    let resp = {};

    try {
        const reqText = document.getElementById('req').value.trim();
        if (reqText) {
            req = JSON.parse(reqText);
        }
    } catch (error) {
        alert('Invalid JSON in Request Body field');
        return;
    }

    try {
        const respText = document.getElementById('resp').value.trim();
        if (respText) {
            resp = JSON.parse(respText);
        }
    } catch (error) {
        alert('Invalid JSON in Response field');
        return;
    }

    const settingData = { path, method, req, resp };

    try {
        if (id) {
            // Update existing
            await fetch(`/api/settings/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(settingData)
            });
        } else {
            // Create new
            await fetch('/api/settings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(settingData)
            });
        }
        
        closeModal();
        loadSettings();
    } catch (error) {
        console.error('Error saving setting:', error);
        alert('Failed to save setting');
    }
}

// Delete setting
async function deleteSetting(id) {
    if (!confirm('Are you sure you want to delete this setting?')) {
        return;
    }

    try {
        await fetch(`/api/settings/${id}`, {
            method: 'DELETE'
        });
        loadSettings();
    } catch (error) {
        console.error('Error deleting setting:', error);
        alert('Failed to delete setting');
    }
}

// Base URL Modal Functions
function openBaseUrlModal() {
    document.getElementById('baseUrlModalTitle').textContent = 'Add Base URL';
    document.getElementById('baseUrlEditId').value = '';
    document.getElementById('baseUrlName').value = '';
    document.getElementById('baseUrlUrl').value = '';
    document.getElementById('baseUrlModal').style.display = 'block';
}

function editBaseUrl(id) {
    const baseUrl = baseUrls.find(b => b.id === id);
    if (!baseUrl) return;

    document.getElementById('baseUrlModalTitle').textContent = 'Edit Base URL';
    document.getElementById('baseUrlEditId').value = baseUrl.id;
    document.getElementById('baseUrlName').value = baseUrl.name;
    document.getElementById('baseUrlUrl').value = baseUrl.url;
    document.getElementById('baseUrlModal').style.display = 'block';
}

function closeBaseUrlModal() {
    document.getElementById('baseUrlModal').style.display = 'none';
}

async function handleBaseUrlSubmit(e) {
    e.preventDefault();

    const id = document.getElementById('baseUrlEditId').value;
    const name = document.getElementById('baseUrlName').value;
    const url = document.getElementById('baseUrlUrl').value;

    const baseUrlData = { name, url };

    try {
        if (id) {
            // Update existing
            await fetch(`/api/baseurls/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(baseUrlData)
            });
        } else {
            // Create new
            await fetch('/api/baseurls', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(baseUrlData)
            });
        }
        
        closeBaseUrlModal();
        loadBaseUrls();
    } catch (error) {
        console.error('Error saving base URL:', error);
        alert('Failed to save base URL');
    }
}

async function deleteBaseUrl(id) {
    if (!confirm('Are you sure you want to delete this base URL?')) {
        return;
    }

    try {
        await fetch(`/api/baseurls/${id}`, {
            method: 'DELETE'
        });
        loadBaseUrls();
    } catch (error) {
        console.error('Error deleting base URL:', error);
        alert('Failed to delete base URL');
    }
}

// Close modals when clicking outside
window.onclick = function(event) {
    const modal = document.getElementById('modal');
    const baseUrlModal = document.getElementById('baseUrlModal');
    if (event.target === modal) {
        closeModal();
    }
    if (event.target === baseUrlModal) {
        closeBaseUrlModal();
    }
}

