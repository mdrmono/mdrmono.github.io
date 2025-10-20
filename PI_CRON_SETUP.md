# Raspberry Pi Cron-Based Anki Stats Setup Guide

This guide walks you through setting up **automated Anki stats updates directly on your Raspberry Pi** using a cron job. This approach is **simpler and more reliable** than the GitHub Actions method.

## Overview

```
┌──────────────────────┐
│   Raspberry Pi       │
│  - Anki Database     │
│  - Export Script     │
│  - Cron Job (2AM)    │
└──────────┬───────────┘
           │ Local execution
           ▼
     Export to JSON
           │
           ▼
     Git commit & push
           │
           ▼
┌──────────────────────┐
│  GitHub Repository   │
│  anki-stats-data     │
│  (Git Submodule)     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Your Website        │
│  (Hugo + Submodule)  │
└──────────────────────┘
```

## Prerequisites

Before starting, ensure you have:

- ✅ Raspberry Pi with Raspberry Pi OS
- ✅ Anki installed (or access to `collection.anki2` database file)
- ✅ Internet connection
- ✅ GitHub account
- ✅ Basic command-line knowledge

## Part 1: GitHub Repository Setup

### Step 1: Create the Data Repository

1. **Go to GitHub** and create a new repository:
   - Repository name: `anki-stats-data`
   - Description: "Anki review statistics data for website heatmap"
   - Visibility: **Public** (so your website can fetch it) or Private (requires auth)
   - ✓ Initialize with a README

2. **Create the initial data file:**

   After creating the repo, add a placeholder JSON file:

   ```bash
   # On your development machine
   mkdir anki-stats-data
   cd anki-stats-data

   # Initialize git
   git init
   git remote add origin git@github.com:YOUR_USERNAME/anki-stats-data.git

   # Create placeholder JSON
   cat > anki-stats.json << 'EOF'
   {
     "metadata": {
       "last_updated": "2025-01-01T00:00:00Z",
       "total_reviews": 0,
       "current_streak": 0,
       "longest_streak": 0,
       "deck_name": "All Decks",
       "export_days": 365
     },
     "daily_reviews": {}
   }
   EOF

   # Commit and push
   git add anki-stats.json
   git commit -m "Initial commit with placeholder data"
   git branch -M main
   git push -u origin main
   ```

3. **Verify the repository** is accessible at:
   ```
   https://github.com/YOUR_USERNAME/anki-stats-data
   ```

## Part 2: Raspberry Pi Setup

### Step 2: Prepare the Pi

1. **SSH into your Raspberry Pi:**

   ```bash
   ssh pi@raspberrypi.local
   # Or: ssh pi@YOUR_PI_IP
   ```

2. **Update system packages:**

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Install required packages** (if not already installed):

   ```bash
   sudo apt install -y python3 python3-pip git
   ```

4. **Create the export directory:**

   ```bash
   mkdir -p ~/anki-export
   cd ~/anki-export
   ```

### Step 3: Copy Scripts to Pi

From your **development machine**, copy the necessary files to your Pi:

```bash
# Copy the export script
scp scripts/export_anki_stats.py pi@YOUR_PI_IP:~/anki-export/

# Copy the automation scripts
scp scripts/pi/update-anki-stats.sh pi@YOUR_PI_IP:~/anki-export/
scp scripts/pi/setup-pi-cron.sh pi@YOUR_PI_IP:~/anki-export/

# Make scripts executable
ssh pi@YOUR_PI_IP "chmod +x ~/anki-export/*.sh"
```

**Alternative:** Use `rsync` for easier syncing:

```bash
rsync -avz scripts/export_anki_stats.py \
           scripts/pi/update-anki-stats.sh \
           scripts/pi/setup-pi-cron.sh \
           pi@YOUR_PI_IP:~/anki-export/
```

### Step 4: Verify Anki Database

Ensure the Anki database is accessible on your Pi:

```bash
# Check if the database exists
ls -la ~/.local/share/Anki2/User\ 1/collection.anki2

# If not found, locate it
find ~ -name "collection.anki2" 2>/dev/null
```

**If the database is not on your Pi**, you have two options:

#### Option A: Install Anki Desktop on Pi

```bash
# Install dependencies
sudo apt install -y python3-pyqt5 python3-pyqt5.qtwebengine

# Download Anki (check for latest version at https://apps.ankiweb.net/)
wget https://github.com/ankitects/anki/releases/download/23.12.1/anki-23.12.1-linux-qt6.tar.zst
tar xaf anki-23.12.1-linux-qt6.tar.zst
cd anki-23.12.1-linux-qt6
sudo ./install.sh
```

#### Option B: Sync Database from Main Computer

```bash
# Create Anki data directory on Pi
mkdir -p ~/.local/share/Anki2/User\ 1/

# From your main computer, copy the database
scp ~/.local/share/Anki2/User\ 1/collection.anki2 \
    pi@YOUR_PI_IP:~/.local/share/Anki2/User\ 1/
```

**Pro Tip:** Set up automatic database sync (see "Keeping Database Updated" section below).

### Step 5: Run the Setup Script

On your Pi, run the interactive setup script:

```bash
cd ~/anki-export
bash setup-pi-cron.sh
```

The script will guide you through:

1. ✓ **Prerequisites Check** - Validates Python, Git, SSH, and cron
2. ✓ **Export Script Check** - Verifies the export script is ready
3. ✓ **SSH Key Generation** - Creates a GitHub deploy key
4. ✓ **Repository Clone** - Clones your `anki-stats-data` repo
5. ✓ **Cron Job Installation** - Sets up daily automation at 2 AM UTC
6. ✓ **Test Run** - Executes a test to verify everything works

### Step 6: Add Deploy Key to GitHub

The setup script will display your SSH public key. Copy it and:

1. Go to your repository: `https://github.com/YOUR_USERNAME/anki-stats-data`
2. Click **Settings** → **Deploy keys** → **Add deploy key**
3. Title: `Raspberry Pi - Anki Stats Automation`
4. Paste the public key
5. ✓ **Check "Allow write access"** (important!)
6. Click **Add key**

### Step 7: Verify Setup

The setup script runs a test execution. Verify success by:

```bash
# Check the log file
tail -n 50 ~/anki-export/update-anki-stats.log

# Check the data repository
cd ~/anki-export/anki-stats-data
git log -1  # Should show a recent commit
```

## Part 3: Website Integration (Git Submodule)

### Step 8: Add Data Repo as Submodule

On your **development machine**, in your website repository:

```bash
cd /path/to/your/website

# Add the data repo as a submodule
git submodule add git@github.com:YOUR_USERNAME/anki-stats-data.git static/data

# This creates static/data/ pointing to your data repo
```

### Step 9: Update .gitignore

Prevent tracking of the submodule's contents in the main repo:

```bash
# Add to .gitignore
echo "static/data/anki-stats.json" >> .gitignore

# Commit the changes
git add .gitmodules .gitignore static/data
git commit -m "Add anki-stats-data as submodule at static/data/"
git push
```

### Step 10: Initialize Submodule for New Clones

When you clone your website repo on a new machine:

```bash
# Clone the main repo
git clone git@github.com:YOUR_USERNAME/your-website.git
cd your-website

# Initialize and update submodules
git submodule init
git submodule update

# Or do both in one command:
git submodule update --init --recursive
```

### Step 11: Update Heatmap Path (if needed)

Your heatmap already fetches from `/data/anki-stats.json`, which will now be served from `static/data/anki-stats.json`. No changes needed if using Hugo's static serving!

Verify in `layouts/partials/anki-heatmap.html` line 180:

```javascript
fetch('/data/anki-stats.json')  // ✓ Correct - Hugo serves static/data/ as /data/
```

### Step 12: Pull Latest Stats

To update your website with the latest stats:

```bash
cd /path/to/your/website

# Pull latest submodule changes
git submodule update --remote static/data

# Rebuild your Hugo site
hugo

# Or if using a build script:
./build.sh
```

**Automate this** in your deployment pipeline:

```bash
# Add to your build/deploy script
git submodule update --remote --merge
hugo
```

## Part 4: Testing & Verification

### Manual Test Run

Test the automation manually on your Pi:

```bash
# Run the update script directly
bash ~/anki-export/update-anki-stats.sh

# Check the output
tail -n 100 ~/anki-export/update-anki-stats.log

# Verify the commit
cd ~/anki-export/anki-stats-data
git log -1
```

### Verify Cron Job

```bash
# List installed cron jobs
crontab -l

# You should see:
# 0 2 * * * /home/pi/anki-export/update-anki-stats.sh >> /home/pi/anki-export/cron.log 2>&1

# Check cron logs (after 2 AM UTC)
tail -f ~/anki-export/cron.log
```

### Test Website Integration

1. **Wait for the next update** (or run manually)
2. **Pull the submodule** in your website repo:
   ```bash
   git submodule update --remote static/data
   ```
3. **Rebuild and check** your local site:
   ```bash
   hugo server
   # Visit http://localhost:1313
   ```
4. **Deploy and verify** the heatmap loads with updated data

## Part 5: Maintenance & Monitoring

### Viewing Logs

```bash
# Main script log
tail -f ~/anki-export/update-anki-stats.log

# Cron execution log
tail -f ~/anki-export/cron.log

# Last 50 lines with timestamps
tail -n 50 ~/anki-export/update-anki-stats.log | grep "ERROR"
```

### Customizing the Schedule

Edit the cron job to change the schedule:

```bash
crontab -e

# Examples:
# Every day at 3 AM local time:
0 3 * * * /home/pi/anki-export/update-anki-stats.sh >> /home/pi/anki-export/cron.log 2>&1

# Every 6 hours:
0 */6 * * * /home/pi/anki-export/update-anki-stats.sh >> /home/pi/anki-export/cron.log 2>&1

# Every day at midnight UTC:
0 0 * * * /home/pi/anki-export/update-anki-stats.sh >> /home/pi/anki-export/cron.log 2>&1
```

Use [crontab.guru](https://crontab.guru/) to help create cron expressions.

### Updating Scripts

When you update the scripts in your repository:

```bash
# On your development machine
cd /path/to/your/website
# Make changes to scripts/pi/*.sh

# Copy updated scripts to Pi
scp scripts/pi/update-anki-stats.sh pi@YOUR_PI_IP:~/anki-export/
```

### Keeping Database Updated

If your Pi doesn't run Anki desktop, sync the database regularly:

#### Option A: Rsync from Main Computer (Recommended)

```bash
# On your main computer, create a cron job
crontab -e

# Add (sync nightly at 1 AM):
0 1 * * * rsync -avz ~/.local/share/Anki2/User\ 1/collection.anki2 \
                       pi@YOUR_PI_IP:~/.local/share/Anki2/User\ 1/
```

#### Option B: AnkiWeb Sync Script

```bash
# On Pi, create a sync script
cat > ~/anki-export/sync-anki.sh << 'EOF'
#!/bin/bash
# This requires Anki desktop with AnkiWeb configured
anki --sync
EOF

chmod +x ~/anki-export/sync-anki.sh

# Add to crontab (runs before the stats update)
crontab -e
# Add:
0 1 * * * /home/pi/anki-export/sync-anki.sh
0 2 * * * /home/pi/anki-export/update-anki-stats.sh >> /home/pi/anki-export/cron.log 2>&1
```

## Troubleshooting

### Issue: Export script fails

```bash
# Test the export script manually
cd ~/anki-export
python3 export_anki_stats.py --output /tmp/test.json

# Check for errors
python3 export_anki_stats.py --help

# Verify database path
ls -la ~/.local/share/Anki2/User\ 1/collection.anki2
```

### Issue: Git push fails

```bash
# Test SSH connection to GitHub
ssh -T git@github.com
# Should see: "Hi USERNAME! You've successfully authenticated..."

# Check deploy key permissions
# Go to: https://github.com/YOUR_USERNAME/anki-stats-data/settings/keys
# Ensure "Allow write access" is checked

# Test push manually
cd ~/anki-export/anki-stats-data
git pull
git push
```

### Issue: Cron job not running

```bash
# Check cron service status
sudo systemctl status cron

# Restart cron service
sudo systemctl restart cron

# Check system logs for cron errors
sudo journalctl -u cron -n 50

# Verify cron job is installed
crontab -l
```

### Issue: No changes detected

This is normal if you haven't done any Anki reviews since the last update. The script only commits when data changes.

```bash
# Force a test run to verify it works
cd ~/anki-export
bash update-anki-stats.sh
```

### Issue: Submodule not updating on website

```bash
# Pull latest from submodule
git submodule update --remote static/data

# Or force update
cd static/data
git pull origin main
cd ../..
```

## Comparison: Cron vs GitHub Actions

| Aspect | Pi Cron (New) | GitHub Actions (Old) |
|--------|---------------|---------------------|
| **Complexity** | ⭐ Very simple | ⭐⭐⭐⭐ Complex |
| **Setup Time** | ~10 minutes | ~45 minutes |
| **Dependencies** | Git + SSH | Tailscale + SSH + GitHub Actions |
| **Maintenance** | Minimal | Multiple services |
| **Failure Points** | Few | Many (VPN, SSH, GitHub) |
| **Performance** | Fast (local) | Slower (network) |
| **Reliability** | High | Medium |
| **Security** | Standard Git SSH | Excellent (VPN) |

## Migration from GitHub Actions

If you're migrating from the GitHub Actions setup:

1. ✅ **Complete this setup** (Parts 1-3)
2. ✅ **Verify the cron job** works (Part 4)
3. ✅ **Disable GitHub Actions** workflow:
   ```bash
   # Archive the workflow
   mkdir -p .github/workflows-archive
   git mv .github/workflows/update-anki-stats.yml \
          .github/workflows-archive/
   git commit -m "Archive GitHub Actions workflow - migrated to Pi cron"
   ```
4. ✅ **Clean up Tailscale** (optional):
   - Remove Tailscale from Pi: `sudo tailscale down && sudo apt remove tailscale`
   - Remove GitHub secrets (TAILSCALE_*, PI_SSH_*)

5. ✅ **Update documentation** to reference this guide

## Next Steps

After completing this setup:

- ✅ Your Pi exports stats daily at 2 AM UTC
- ✅ Stats are automatically committed and pushed to GitHub
- ✅ Your website fetches from the submodule
- ✅ No manual intervention required!

**Recommended:**

1. Monitor logs for the first week: `tail -f ~/anki-export/update-anki-stats.log`
2. Set up database sync if Pi doesn't run Anki desktop
3. Configure your deployment pipeline to pull submodule updates
4. Consider backing up your Anki database regularly

## Additional Resources

- **Anki Database Location**: `~/.local/share/Anki2/User 1/collection.anki2`
- **Cron Syntax**: https://crontab.guru/
- **Git Submodules**: https://git-scm.com/book/en/v2/Git-Tools-Submodules
- **GitHub Deploy Keys**: https://docs.github.com/en/developers/overview/managing-deploy-keys

## Questions or Issues?

If you encounter problems:

1. Check the logs: `~/anki-export/update-anki-stats.log`
2. Review the troubleshooting section above
3. Test components individually (export, git, cron)
4. Open an issue on the repository

---

**Setup Complete!** Your Anki stats will now update automatically every day. 🎉
