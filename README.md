# Hytale Server Docker

This project provides a Dockerized environment for running a Hytale dedicated server with automated authentication handling.

## Requirements

- Linux
- Docker & Docker Compose
- Make
- curl
- jq

## Usage

### Starting the Server
Run the following command to start the server stack:
```bash
make up
```
This command performs the following actions:
1. Executes `scripts/auth.sh` to validate or refresh authentication tokens.
2. Updates the `.env` file with valid session credentials.
3. Starts the Docker container using valid credentials.

### Stopping the Server
```bash
make down
```

### Viewing Logs
```bash
make logs
```

## Authentication Workflow

The Hytale Dedicated Server requires active authentication to start (to verify ownership/access). This project automates the OAuth 2.0 Device Code flow to minimize manual intervention.

### Token Persistence
Authentication tokens are stored in the `.env` file in the root directory:
- **REFRESH_TOKEN**: A long-lived token (approx. 30 days) used to generate new session tokens without user interaction.
- **HYTALE_SERVER_SESSION_TOKEN** & **HYTALE_SERVER_IDENTITY_TOKEN**: Short-lived EdDSA-signed tokens required by the server runtime.

### First-Time Installation (Double Authentication)
On a fresh installation, you will be prompted to authenticate twice. This is normal behavior due to the server architecture:

1. **Runtime Authentication**: The `auth.sh` script runs first. It will prompt you to visit a URL to generate the initial Refresh Token and Session Tokens.
2. **Downloader Authentication**: When the Docker container starts for the first time, if `HytaleServer.jar` is missing, the `hytale-downloader-linux` binary runs. This binary requires its own authentication and will prompt you to visit a URL again via the logs.

Once the initial download is complete and the Refresh Token is stored, subsequent restarts via `make up` are fully automated.

## Technical Details

### Script: scripts/auth.sh
This script handles the interaction with Hytale's OAuth endpoints.
1. Checks for a valid `REFRESH_TOKEN` in `.env`.
2. If found, it refreshes the token and generates a new Game Session (`POST /game-session/new`).
3. If not found, it initiates the Device Code Flow (`POST /oauth2/device/auth`) and waits for user approval.
4. Updates `.env` with the new tokens for `docker-compose.yml` to consume.

### Docker Configuration
The container is configured via `docker-compose.yml` to accept tokens as environment variables:
- `HYTALE_SERVER_SESSION_TOKEN`
- `HYTALE_SERVER_IDENTITY_TOKEN`
- `HYTALE_DOWNLOADER_TOKEN`

Data is persisted in the `./data` directory, which is mounted to `/hytale` inside the container.
