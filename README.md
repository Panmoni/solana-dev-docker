# Solana Development Docker Environment

A minimal, persistent Docker container for Solana development on Ubuntu 25.10.

## Features

- ✅ Ubuntu 25.10 base image pinned to a digest
- ✅ Persistent workspace stored in Docker volume (defaults to `solana-workspace`)
- ✅ Auto-restart on failure
- ✅ Starts on system boot
- ✅ Data survives container deletion
- ✅ Minimal setup - students install Solana tools themselves
- ✅ Resource limits and logging configured via `docker-compose.yml`

## Prerequisites

- Ubuntu 25.10 VPS or local machine
- Docker and Docker Compose installed

> **Note on Docker Installation**: Ubuntu 25.10 is a very new release, and Docker's official repository doesn't yet have packages specifically for it. The installation instructions below use the Ubuntu 24.04 LTS (noble) repository, which is fully compatible with Ubuntu 25.10. This is a safe and recommended workaround until Docker adds official support for Ubuntu 25.10.

### Install Docker (if not already installed)

```bash
# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
# Note: Using 'noble' (Ubuntu 24.04 LTS) repository as Docker doesn't yet support Ubuntu 25.10
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  noble stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

Verify Docker installation:
```bash
docker --version
docker compose version
```

## Quick Start

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd solana-dev-docker
```

### 2. Configure Environment

```bash
cp env.example .env
nano .env  # or your editor of choice
```

Key values:
- `SOLANA_VOLUME_NAME`: Docker volume name for persistent workspace (defaults to `solana-workspace`).
- `SOLANA_DEV_MEMORY` / `SOLANA_DEV_CPUS`: optional Docker resource limits.
- `SOLANA_CLUSTER` / `SOLANA_RPC_URL`: Solana network defaults inside the container.

### 3. Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### 4. Setup and Start Container

```bash
./scripts/setup.sh
```

This will:
- Create the Docker volume for persistent workspace storage
- Build/pull the pinned Ubuntu 25.10 image
- Start the container with auto-restart enabled

### 5. Access Container

```bash
docker compose exec solana-dev bash
```

You should now be inside the container as the `solana` user.

### 6. Install Solana Development Tools (One-time setup)

Inside the container, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash
```

Reload your shell configuration:

```bash
source ~/.bashrc
```

Verify installation:

```bash
rustc --version
solana --version
anchor --version
node --version
yarn --version
```

### 7. Start Developing!

Your workspace is at `/home/solana` inside the container, stored in a Docker volume that persists across container restarts.

```bash
# Create a new project
mkdir my-solana-project
cd my-solana-project

# Your work is automatically persisted in the Docker volume
```

## Daily Usage

### Access Container Shell

```bash
docker compose exec solana-dev bash
```

### Start Container (if stopped)

```bash
docker compose up -d
```

### Stop Container

```bash
docker compose down
```

### Restart Container

```bash
docker compose restart
```

### View Container Logs

```bash
docker compose logs -f
```

### Check Container Status

```bash
docker compose ps
```

## Working with Files

Your workspace is stored in a Docker volume, which persists data even if the container is deleted. The volume is mounted at `/home/solana` inside the container.

### From Inside Container

Files are at `/home/solana`:

```bash
docker compose exec solana-dev bash
cd /home/solana
ls -la
```

### Accessing Files from Host Machine

To access files from the host, you can copy them from the volume:

```bash
# Copy a file from the volume to your host
docker compose exec solana-dev cat /home/solana/my-file.rs > ~/my-file.rs

# Or use docker cp
docker cp solana-dev-container:/home/solana/my-file.rs ~/my-file.rs

# View volume location and details
docker volume inspect solana-workspace
```

Alternatively, you can mount the volume temporarily to access files directly:

```bash
# Create a temporary container to access volume files
docker run --rm -v solana-workspace:/workspace ubuntu:25.10 ls -la /workspace
```

## Backup & Restore

### Create Backup

```bash
./scripts/backup.sh
```

This script reads `.env`, snapshots everything in the Docker volume, and drops the archive under `backups/` inside the repo:
```
backups/solana-workspace-backup-20241118_143022.tar.gz
```

### List Available Backups

```bash
ls -lh backups/
```

### Restore from Backup

```bash
./scripts/restore.sh backups/solana-workspace-backup-YYYYMMDD_HHMMSS.tar.gz
```

⚠️ **Warning**: This will overwrite the contents of the Docker volume. The script removes all existing data in the volume before restoring.

### Automated Backups (Optional)

Add to crontab for daily backups:

```bash
crontab -e
```

Add this line (backs up daily at 2 AM):
```
0 2 * * * cd /path/to/solana-dev-docker && ./scripts/backup.sh
```

## Container Management

### Rebuild Container

If you modify `docker-compose.yml`:

```bash
docker compose down
docker compose up -d --force-recreate
```

### Remove Container (keeps data)

```bash
docker compose down
```

Your data in the Docker volume is preserved.

### Remove Container AND Data (⚠️ Destructive)

```bash
docker compose down -v
```

This removes both the container and the associated volume. All data will be lost.

### View Container Resource Usage

```bash
docker stats solana-dev-container
```

### Execute Commands Without Entering Container

```bash
docker compose exec solana-dev solana --version
docker compose exec solana-dev ls -la /home/solana
```

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker compose logs
```

Check if port conflicts exist:
```bash
docker compose ps
```

### Permission Issues

Fix permissions inside container:
```bash
docker compose exec solana-dev bash
sudo chown -R solana:solana /home/solana
```

### "Cannot connect to Docker daemon"

Ensure Docker is running:
```bash
sudo systemctl status docker
sudo systemctl start docker
```

Add your user to docker group:
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Container Keeps Restarting

Check logs for errors:
```bash
docker compose logs --tail=50
```

### Solana Tools Not Found After Installation

Reload shell configuration:
```bash
source ~/.bashrc
```

Or exit and re-enter the container:
```bash
exit
docker compose exec solana-dev bash
```

### Out of Disk Space

Check Docker disk usage:
```bash
docker system df
```

Clean up unused Docker resources:
```bash
docker system prune -a
```

### Reset Everything

Complete reset (⚠️ destroys all data):

```bash
# Stop and remove container and volume
docker compose down -v

# Remove Docker image
docker rmi ubuntu:25.10

# Start fresh
./scripts/setup.sh
```

## Testing Your Setup

### Test 1: Container Persistence

```bash
# Create a test file
docker compose exec solana-dev bash -c "echo 'test' > /home/solana/test.txt"

# Stop container
docker compose down

# Start container
docker compose up -d

# Check file still exists
docker compose exec solana-dev cat /home/solana/test.txt
# Should output: test
```

### Test 2: Volume Persistence

```bash
# Create file in container
docker compose exec solana-dev bash -c "echo 'from container' > /home/solana/volume-test.txt"

# Stop and remove container (but keep volume)
docker compose down

# Start container again
docker compose up -d

# Check file still exists in volume
docker compose exec solana-dev cat /home/solana/volume-test.txt
# Should output: from container
```

### Test 3: Auto-Restart

```bash
# Kill the container process
docker kill solana-dev-container

# Wait a few seconds, then check status
docker compose ps
# Should show container running again
```

### Test 4: Solana Tools

Inside container:
```bash
docker compose exec solana-dev bash

# Test Solana CLI
solana --version

# Test Anchor
anchor --version

# Test Rust
rustc --version

# Create a test Solana keypair
solana-keygen new --no-bip39-passphrase -o ~/test-keypair.json

# Check balance (should be 0)
solana balance ~/test-keypair.json
```

## Advanced Configuration

### Custom Environment Variables

Copy the example environment file:
```bash
cp env.example .env
```

Edit `.env` to customize defaults for all students. Example:
```bash
SOLANA_VOLUME_NAME=solana-workspace
SOLANA_DEV_MEMORY=4g
SOLANA_DEV_CPUS=2.0
SOLANA_CLUSTER=devnet
# SOLANA_RPC_URL=https://api.devnet.solana.com
```

### Expose Ports (for local validator)

Edit `docker-compose.yml` and add:
```yaml
ports:
  - "8899:8899"  # RPC
  - "8900:8900"  # WebSocket
```

Then restart:
```bash
docker compose down
docker compose up -d
```

### Change Container Name

Edit `docker-compose.yml`:
```yaml
container_name: my-custom-name
```

### Allocate More Resources

Adjust `SOLANA_DEV_MEMORY` and `SOLANA_DEV_CPUS` in `.env`, then rerun:
```bash
docker compose down
docker compose up -d --force-recreate
```

## Security Best Practices

1. **Never commit keypairs to git**
   - The `.gitignore` already excludes `solana-workspace/`
   
2. **Use devnet for testing**
   ```bash
   solana config set --url devnet
   ```

3. **Backup your keypairs separately**
   ```bash
   docker compose exec solana-dev bash -c "cp /home/solana/*.json /tmp/" && docker cp solana-dev-container:/tmp/ ~/keypair-backup/
   ```

4. **Keep Docker updated**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade docker-ce docker-ce-cli containerd.io
   ```

## Updating Solana Tools

Inside the container:

```bash
# Update Solana CLI
solana-install update

# Update Anchor
cargo install --git https://github.com/coral-xyz/anchor anchor-cli --locked --force

# Update Rust
rustup update
```

## Uninstall

### Remove Container Only

```bash
docker compose down
```

### Remove Everything

```bash
# Stop and remove container and volume
docker compose down -v

# Remove Docker image
docker rmi ubuntu:25.10

# Remove repository
cd ..
rm -rf solana-dev-docker
```

## FAQ

**Q: Where is my data stored?**  
A: In a Docker volume (default name: `solana-workspace`), mounted at `/home/solana` inside the container. Use `docker volume inspect solana-workspace` to see the physical location on your host.

**Q: Will my data survive if I delete the container?**  
A: Yes! Data in the Docker volume persists even after `docker compose down`. The volume is only removed if you use `docker compose down -v`.

**Q: Can I use VS Code with this setup?**  
A: Yes! Use VS Code Remote-Containers extension to work directly inside the container, or copy files to/from the volume as needed.

**Q: How do I update the container?**  
A: `docker compose down && docker compose up -d --force-recreate`

**Q: Can multiple people use this setup?**  
A: Yes! Each user can create their own volume by setting `SOLANA_VOLUME_NAME` in their `.env` file.

**Q: Does this work on Mac/Windows?**  
A: This is optimized for Ubuntu 25.10. For Mac/Windows, use Docker Desktop and adjust paths.

## Contributing

Issues and pull requests welcome!

## License

MIT

## Support

- [Solana Documentation](https://docs.solana.com)
- [Solana Stack Exchange](https://solana.stackexchange.com/)
- [Anchor Documentation](https://www.anchor-lang.com/)

---

**Happy Building on Solana! 🚀**