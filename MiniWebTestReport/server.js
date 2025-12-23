const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || process.env.IISNODE_HTTP_PORT || 3000;
const SETTINGS_FILE = path.join(__dirname, 'settings.json');

// Configure CORS to allow all origins and methods
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: false
}));

// Add headers to bypass referrer policy restrictions
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    res.header('Referrer-Policy', 'no-referrer-when-downgrade');
    res.header('X-Content-Type-Options', 'nosniff');
    if (req.method === 'OPTIONS') {
        res.sendStatus(200);
    } else {
        next();
    }
});

app.use(express.json());
app.use(express.static(__dirname));

// Helper function to read settings
async function readSettings() {
    try {
        const data = await fs.readFile(SETTINGS_FILE, 'utf8');
        const parsed = JSON.parse(data);
        // Ensure BaseUrls array exists
        if (!parsed.BaseUrls) {
            parsed.BaseUrls = [];
        }
        if (!parsed.Set) {
            parsed.Set = [];
        }
        return parsed;
    } catch (error) {
        // If file doesn't exist, return default structure
        return { BaseUrls: [], Set: [] };
    }
}

// Helper function to write settings
async function writeSettings(data) {
    await fs.writeFile(SETTINGS_FILE, JSON.stringify(data, null, 2), 'utf8');
}

// GET all settings
app.get('/api/settings', async (req, res) => {
    try {
        const data = await readSettings();
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: 'Failed to read settings' });
    }
});

// POST create new setting
app.post('/api/settings', async (req, res) => {
    try {
        const data = await readSettings();
        const newId = data.Set.length > 0 
            ? Math.max(...data.Set.map(s => s.id)) + 1 
            : 1;
        
        const newSetting = {
            id: newId,
            path: req.body.path,
            method: req.body.method,
            req: req.body.req || {},
            resp: req.body.resp || {}
        };
        
        data.Set.push(newSetting);
        await writeSettings(data);
        res.json(newSetting);
    } catch (error) {
        res.status(500).json({ error: 'Failed to create setting' });
    }
});

// PUT update setting
app.put('/api/settings/:id', async (req, res) => {
    try {
        const data = await readSettings();
        const id = parseInt(req.params.id);
        const index = data.Set.findIndex(s => s.id === id);
        
        if (index === -1) {
            return res.status(404).json({ error: 'Setting not found' });
        }
        
        data.Set[index] = {
            id: id,
            path: req.body.path,
            method: req.body.method,
            req: req.body.req || {},
            resp: req.body.resp || {}
        };
        
        await writeSettings(data);
        res.json(data.Set[index]);
    } catch (error) {
        res.status(500).json({ error: 'Failed to update setting' });
    }
});

// DELETE setting
app.delete('/api/settings/:id', async (req, res) => {
    try {
        const data = await readSettings();
        const id = parseInt(req.params.id);
        const index = data.Set.findIndex(s => s.id === id);
        
        if (index === -1) {
            return res.status(404).json({ error: 'Setting not found' });
        }
        
        data.Set.splice(index, 1);
        await writeSettings(data);
        res.json({ message: 'Setting deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete setting' });
    }
});

// Base URLs API endpoints
// GET all base URLs
app.get('/api/baseurls', async (req, res) => {
    try {
        const data = await readSettings();
        res.json(data.BaseUrls || []);
    } catch (error) {
        res.status(500).json({ error: 'Failed to read base URLs' });
    }
});

// POST create new base URL
app.post('/api/baseurls', async (req, res) => {
    try {
        const data = await readSettings();
        const newId = data.BaseUrls.length > 0 
            ? Math.max(...data.BaseUrls.map(b => b.id)) + 1 
            : 1;
        
        const newBaseUrl = {
            id: newId,
            name: req.body.name,
            url: req.body.url
        };
        
        data.BaseUrls.push(newBaseUrl);
        await writeSettings(data);
        res.json(newBaseUrl);
    } catch (error) {
        res.status(500).json({ error: 'Failed to create base URL' });
    }
});

// PUT update base URL
app.put('/api/baseurls/:id', async (req, res) => {
    try {
        const data = await readSettings();
        const id = parseInt(req.params.id);
        const index = data.BaseUrls.findIndex(b => b.id === id);
        
        if (index === -1) {
            return res.status(404).json({ error: 'Base URL not found' });
        }
        
        data.BaseUrls[index] = {
            id: id,
            name: req.body.name,
            url: req.body.url
        };
        
        await writeSettings(data);
        res.json(data.BaseUrls[index]);
    } catch (error) {
        res.status(500).json({ error: 'Failed to update base URL' });
    }
});

// DELETE base URL
app.delete('/api/baseurls/:id', async (req, res) => {
    try {
        const data = await readSettings();
        const id = parseInt(req.params.id);
        const index = data.BaseUrls.findIndex(b => b.id === id);
        
        if (index === -1) {
            return res.status(404).json({ error: 'Base URL not found' });
        }
        
        data.BaseUrls.splice(index, 1);
        await writeSettings(data);
        res.json({ message: 'Base URL deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete base URL' });
    }
});

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
    console.log(`Settings page: http://localhost:${PORT}/index.html`);
    console.log(`Actions page: http://localhost:${PORT}/actions.html`);
});

