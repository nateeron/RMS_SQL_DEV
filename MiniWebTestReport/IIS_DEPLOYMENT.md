# IIS Deployment Guide

This guide will help you deploy the MiniWebTestReport application to IIS (Internet Information Services) on Windows Server.

## Prerequisites

1. **Windows Server** with IIS installed
2. **Node.js** installed on the server (v14 or higher recommended)
3. **iisnode** module installed
4. **URL Rewrite Module** for IIS

## Step 1: Install Prerequisites

### Install Node.js
1. Download Node.js from https://nodejs.org/
2. Install it on your Windows Server
3. Verify installation: `node --version` and `npm --version`

### Install iisnode
1. Download iisnode from: https://github.com/Azure/iisnode/releases
2. Install the appropriate version (x64 or x86) for your server
3. This enables IIS to run Node.js applications

### Install URL Rewrite Module
1. Download from: https://www.iis.net/downloads/microsoft/url-rewrite
2. Install the module
3. This is required for the rewrite rules in web.config

## Step 2: Prepare Application Files

1. Copy all application files to a folder on your server (e.g., `C:\inetpub\wwwroot\MiniWebTestReport`)
2. Ensure the following files are present:
   - `server.js`
   - `package.json`
   - `web.config`
   - `index.html`
   - `actions.html`
   - `styles.css`
   - `app.js`
   - `actions.js`
   - `settings.json` (will be created automatically if missing)

## Step 3: Install Node.js Dependencies

1. Open Command Prompt or PowerShell as Administrator
2. Navigate to your application folder:
   ```cmd
   cd C:\inetpub\wwwroot\MiniWebTestReport
   ```
3. Install dependencies:
   ```cmd
   npm install
   ```

## Step 4: Configure IIS

### Create Application Pool

1. Open **IIS Manager**
2. Right-click **Application Pools** → **Add Application Pool**
3. Set:
   - **Name**: `MiniWebTestReport`
   - **.NET CLR version**: **No Managed Code**
   - **Managed pipeline mode**: **Integrated**
4. Click **OK**
5. Right-click the new pool → **Advanced Settings**
6. Set **Start Mode** to **AlwaysRunning** (optional, for better performance)

### Create Website/Application

1. In IIS Manager, right-click **Sites** → **Add Website** (or **Add Application** if adding to existing site)
2. Configure:
   - **Site name**: `MiniWebTestReport`
   - **Application pool**: Select `MiniWebTestReport`
   - **Physical path**: `C:\inetpub\wwwroot\MiniWebTestReport`
   - **Binding**: 
     - **Type**: `http` or `https`
     - **IP address**: `All Unassigned` or specific IP
     - **Port**: `80` (or your desired port)
     - **Host name**: (optional) your domain name
3. Click **OK**

### Set Permissions

1. Right-click your application folder → **Properties** → **Security**
2. Click **Edit** → **Add**
3. Add `IIS_IUSRS` with **Read & Execute** permissions
4. Add `IUSR` with **Read & Execute** permissions
5. Ensure the application pool identity has **Write** permissions for `settings.json` (if you want to allow file modifications)

## Step 5: Configure Application Pool Identity

1. In IIS Manager, select your **Application Pool**
2. Click **Advanced Settings**
3. Under **Process Model**, set **Identity** to `ApplicationPoolIdentity` or a specific user account
4. If using a specific account, ensure it has proper permissions

## Step 6: Test Deployment

1. Open a web browser
2. Navigate to: `http://localhost` (or your configured URL)
3. You should see the Settings Management page
4. Test CRUD operations and the Actions page

## Troubleshooting

### Check iisnode Logs
- Logs are located in: `C:\inetpub\wwwroot\MiniWebTestReport\iisnode\`
- Check `stderr-*.txt` for errors

### Common Issues

1. **500 Error**: 
   - Check that Node.js is installed
   - Verify iisnode is installed
   - Check application pool is running
   - Review iisnode logs

2. **404 Error**:
   - Verify URL Rewrite module is installed
   - Check web.config is present
   - Verify physical path is correct

3. **Cannot write to settings.json**:
   - Check folder permissions
   - Ensure application pool identity has write access

4. **Port already in use**:
   - Change the port in IIS binding
   - Or stop the service using that port

### Enable Detailed Errors (for debugging)

1. In IIS Manager, select your site
2. Double-click **Error Pages**
3. Click **Edit Feature Settings** in the right panel
4. Select **Detailed errors**
5. Click **OK**

**Note**: Disable detailed errors in production for security.

## Production Recommendations

1. **Use HTTPS**: Configure SSL certificate for secure connections
2. **Set up logging**: Configure IIS logging and monitor iisnode logs
3. **Performance tuning**: Adjust iisnode settings in web.config if needed
4. **Security**: 
   - Remove detailed error pages in production
   - Set proper folder permissions
   - Consider using Windows Authentication if needed
5. **Backup**: Regularly backup `settings.json` file

## Alternative: Using IISNode.yml

You can create an `iisnode.yml` file for additional configuration:

```yaml
nodeProcessCountPerApplication: 1
nodeProcessCommandLine: "node.exe"
loggingEnabled: true
logDirectory: "iisnode"
```

## Support

For issues with:
- **iisnode**: https://github.com/Azure/iisnode
- **IIS**: Microsoft IIS Documentation
- **Node.js**: https://nodejs.org/

