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
    
    # Run the downloader as 'hytale' user. 
    su-exec hytale hytale-downloader-linux -download-path /hytale
    
    if [ $? -ne 0 ]; then
        echo "Error: Downloader failed. This might be because the server files aren't public yet (403 Forbidden)."
        exit 1
    fi
fi

# 5. START SERVER
# Standard execution as 'hytale' user
echo "Starting Hytale Server with ${HYTALE_RAM} of RAM..."
exec su-exec hytale java -Xmx${HYTALE_RAM} -jar "/hytale/$HYTALE_JAR" --assets "$HYTALE_ASSETS" nogui
