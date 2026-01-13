#!/bin/sh

# 1. FIX PERMISSIONS
echo "Fixing permissions for /hytale..."
chown -R hytale:hytale /hytale

# 2. MANAGE STRUCTURE
# If the user copied a 'Server' folder directly, we move its contents to the root
if [ -d "/hytale/Server" ] && [ ! -f "/hytale/HytaleServer.jar" ]; then
    echo "Detected 'Server' directory. Moving contents to /hytale for standard execution..."
    mv /hytale/Server/* /hytale/ 2>/dev/null
    # Clean up empty dir
    rmdir /hytale/Server 2>/dev/null
fi

# 3. CONFIGURATION
HYTALE_RAM=${HYTALE_RAM:-4G}
HYTALE_JAR=${HYTALE_JAR:-HytaleServer.jar}
HYTALE_ASSETS=${HYTALE_ASSETS:-/hytale/Assets.zip}

echo "Starting Hytale Server Setup..."

# 4. DOWNLOAD (if JAR is missing)
if [ ! -f "/hytale/$HYTALE_JAR" ]; then
    echo "Server files not found. Starting downloader..."
    
    # We use su-exec to run as 'hytale' user.
    # We specify a download path INSIDE /hytale where we have permissions.
    # Note: Using -download-path followed by a zip file name.
    su-exec hytale hytale-downloader-linux -download-path /hytale/server_temp.zip
    
    if [ $? -eq 0 ]; then
        echo "Download successful. Extracting..."
        su-exec hytale unzip -o /hytale/server_temp.zip -d /hytale/
        su-exec hytale rm /hytale/server_temp.zip
        
        # Move files from 'Server' subdir if the downloader created it
        if [ -d "/hytale/Server" ]; then
            mv /hytale/Server/* /hytale/ 2>/dev/null
            rmdir /hytale/Server 2>/dev/null
        fi
    else
        echo "Error: Downloader failed. This might be because the server files aren't public yet (403 Forbidden)."
        exit 1
    fi
fi

# 5. START SERVER
echo "Starting Hytale Server with ${HYTALE_RAM} of RAM..."
exec su-exec hytale java -Xmx${HYTALE_RAM} -jar "/hytale/$HYTALE_JAR" --assets "$HYTALE_ASSETS"
