# Raspberry Pi Setup Guide

This guide walks you through setting up your Raspberry Pi 3 to automatically export Anki statistics for your website heatmap.

## Prerequisites

- Raspberry Pi 3 with Raspberry Pi OS installed
- Internet connection
- Anki installed on the Pi (or access to Anki database file)

## Step 1: Install Anki on Raspberry Pi

### Option A: Install Anki Desktop

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3-pip python3-pyqt5 python3-pyqt5.qtwebengine

# Download and install Anki
# Visit https://apps.ankiweb.net/ for the latest version
wget https://github.com/ankitects/anki/releases/download/23.12.1/anki-23.12.1-linux-qt6.tar.zst
tar xaf anki-23.12.1-linux-qt6.tar.zst
cd anki-23.12.1-linux-qt6
sudo ./install.sh
```

### Option B: Copy Database File

If you use Anki on another computer, you can sync the database to your Pi:

```bash
# Create directory for Anki data
mkdir -p ~/.local/share/Anki2/User\ 1/

# Use rsync, scp, or cloud sync to copy collection.anki2
# Example using scp from your main computer:
scp path/to/Anki2/User\ 1/collection.anki2 pi@raspberrypi:~/.local/share/Anki2/User\ 1/
```

**Tip**: Set up automatic sync using AnkiWeb or a cron job to keep the database updated.

## Step 2: Install Tailscale

Tailscale creates a secure private network between your Pi and GitHub Actions.

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
sudo tailscale up

# Note your Pi's Tailscale hostname
tailscale status
# Look for something like: raspberry-pi  [your-pi-ip]  linux   -
```

**Important**: Save your Pi's Tailscale hostname (e.g., `raspberry-pi`) - you'll need it for GitHub Actions.

## Step 3: Set Up Export Script

```bash
# Create directory for the export script
mkdir -p ~/anki-export
cd ~/anki-export

# Copy the export script
# (You'll need to transfer scripts/export_anki_stats.py from your website repo)
```

**From your development machine**, copy the script to your Pi:

```bash
scp scripts/export_anki_stats.py pi@YOUR_PI_IP:~/anki-export/
```

**On the Pi**, test the script:

```bash
cd ~/anki-export
python3 export_anki_stats.py --output /tmp/anki-stats.json

# If successful, you should see:
# ✓ Successfully exported X reviews
# ✓ Current streak: X days
# ✓ Longest streak: X days
# ✓ Output saved to: /tmp/anki-stats.json
```

### Filtering by Deck

If you want to export only specific deck stats (e.g., your Mandarin deck):

```bash
python3 export_anki_stats.py --deck-name "Mandarin" --output /tmp/anki-stats.json
```

## Step 4: Configure SSH Access

GitHub Actions needs SSH access to your Pi via Tailscale.

```bash
# On your Pi, generate a dedicated SSH key for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions-access" -f ~/.ssh/github_actions_key

# Add the public key to authorized_keys
cat ~/.ssh/github_actions_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Display the private key (you'll add this to GitHub Secrets)
cat ~/.ssh/github_actions_key
```

**Copy the private key** - you'll add it as `PI_SSH_KEY` secret in GitHub.

## Step 5: Configure GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

### Tailscale Secrets

1. **TAILSCALE_OAUTH_CLIENT_ID** and **TAILSCALE_OAUTH_SECRET**
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
   - Create OAuth client
   - Add tag: `tag:ci`
   - Copy client ID and secret

### Raspberry Pi Secrets

2. **PI_SSH_HOST**
   - Value: Your Pi's Tailscale hostname (e.g., `raspberry-pi`)

3. **PI_SSH_USER**
   - Value: Your Pi username (usually `pi`)

4. **PI_SSH_KEY**
   - Value: The private key you generated in Step 4

### Data Repository Secret

5. **DATA_REPO_DEPLOY_KEY** (if using separate repo)
   - Follow instructions in `DATA_REPO_SETUP.md`

## Step 6: Test the Connection

You can manually test the GitHub Actions workflow:

1. Go to your GitHub repository
2. Click "Actions" tab
3. Select "Update Anki Stats" workflow
4. Click "Run workflow"
5. Watch the logs to ensure it connects to your Pi successfully

## Step 7: Verify Automation

The workflow is scheduled to run daily at 2 AM UTC. To verify:

1. Wait for the scheduled run, or trigger manually
2. Check your data repository for updated `anki-stats.json`
3. Visit your website to see the updated heatmap

## Troubleshooting

### Anki Database Not Found

```bash
# Check if collection.anki2 exists
ls -la ~/.local/share/Anki2/User\ 1/collection.anki2

# If not found, locate it:
find ~ -name "collection.anki2"
```

### SSH Connection Fails

```bash
# On Pi, check SSH is running
sudo systemctl status ssh

# Check Tailscale status
tailscale status

# Test connection from another machine on Tailscale
ssh pi@raspberry-pi
```

### Export Script Fails

```bash
# Check Python version (needs 3.7+)
python3 --version

# Run script with verbose error output
python3 export_anki_stats.py --db-path ~/.local/share/Anki2/User\ 1/collection.anki2 --output /tmp/test.json
```

### GitHub Actions Can't Connect

- Verify Tailscale OAuth secrets are correct
- Check Pi SSH key is added to GitHub secrets
- Ensure Pi is online and connected to Tailscale
- Check GitHub Actions logs for specific error messages

## Optional: Keep Database Updated

If you're not running Anki desktop on the Pi, set up automatic sync:

### Option 1: AnkiWeb Sync

```bash
# Install AnkiConnect addon on your main computer
# Configure automatic sync in Anki preferences
# Copy synced database to Pi periodically
```

### Option 2: Rsync from Main Computer

```bash
# On main computer, create cron job:
crontab -e

# Add line (sync daily at midnight):
0 0 * * * rsync -avz ~/.local/share/Anki2/User\ 1/collection.anki2 pi@raspberry-pi:~/.local/share/Anki2/User\ 1/
```

## Security Notes

- Your Pi is never exposed to the public internet
- All connections go through Tailscale's encrypted private network
- GitHub Actions connects via Tailscale using ephemeral auth
- SSH key is dedicated and can be revoked anytime
- Anki database contains only your personal study data

## Maintenance

### Update Export Script

```bash
cd ~/anki-export
# Download updated script from your repo
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/export_anki_stats.py -O export_anki_stats.py
```

### Monitor Logs

```bash
# Check GitHub Actions runs
# Repository → Actions → Update Anki Stats

# Check Pi system logs
journalctl -u ssh -n 50
```

### Update Tailscale

```bash
sudo apt update
sudo apt upgrade tailscale
```

## Next Steps

After completing this setup:

1. Your Pi will be ready to export Anki stats
2. GitHub Actions will automatically fetch stats daily
3. Your website heatmap will update automatically
4. No manual intervention required!

For questions or issues, check the GitHub repository's Issues page.
