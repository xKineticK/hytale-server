# Hytale Server Docker 🎮

![Hytale Server](https://hytale.com/static/images/logo.png)

Official-manual-aligned Docker environment for running a **Hytale Server** using Java 25.

## Features
- **Java 25 (Eclipse Temurin)**: Ready for the Hytale runtime requirements.
- **Automated Setup**: Includes the Hytale Downloader CLI to fetch server files automatically.
- **Permission Management**: Automatically handles volume permissions for easy host-container mapping.
- **Official Specs**: Pre-configured to use the official command line arguments and UDP 5520 port.
- **Easy Management**: Uses `docker-compose` and a `Makefile` for common tasks.

## 🛠️ Requirements
- Docker & Docker Compose
- A valid Hytale account (for OAuth authentication)
- At least 4GB of RAM dedicated to the server

## 🚀 Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/xKineticK/hytale-server.git
   cd hytale-server
   ```

2. **Configure Environment**:
   Copy the example environment file and edit it:
   ```bash
   cp .env.example .env
   ```
   *Note: Set your RAM allocation and preferred port in `.env`.*

3. **Start the Server**:
   ```bash
   make up
   ```

4. **Authenticate**:
   Check the logs to get your authorization code:
   ```bash
   make logs
   ```
   Visit the Hytale OAuth URL provided in the logs and enter the code.

## 📁 Directory Structure
- `data/`: (Auto-created) Stores server binaries, `Assets.zip`, and world data.
- `Dockerfile`: Multi-stage build with Downloader CLI and Java 25.
- `entrypoint.sh`: Intelligent script for permissions and startup logic.

## ⚖️ License
MIT License. Content from Hytale is subject to Hypixel Studios terms.
