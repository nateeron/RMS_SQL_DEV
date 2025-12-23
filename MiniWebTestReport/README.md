# Mini Web Test Report

A web application for managing API settings with CRUD operations and response viewing.

## Features

- **CRUD Operations**: Create, Read, Update, and Delete settings
- **Settings Management**: Manage API endpoints with ID, Path, Method (GET/POST), and Response
- **Actions Page**: View all settings with their responses displayed

## Installation

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

3. Open your browser and navigate to:
   - Settings page: http://localhost:3000/index.html
   - Actions page: http://localhost:3000/actions.html

## Usage

### Settings Page
- Click "Add New" to create a new setting
- Click "Edit" to modify an existing setting
- Click "Delete" to remove a setting
- All changes are saved to `settings.json`

### Actions Page
- View all settings with their responses
- Responses are displayed in formatted JSON

## File Structure

- `index.html` - Main CRUD interface
- `actions.html` - Actions and response viewer page
- `styles.css` - Styling for both pages
- `app.js` - JavaScript for settings management
- `actions.js` - JavaScript for actions page
- `server.js` - Express server for API endpoints
- `settings.json` - Data storage file

