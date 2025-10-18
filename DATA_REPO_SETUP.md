# Anki Stats Data Repository Setup

This document explains how to set up a separate repository for storing Anki statistics data.

## Why a Separate Repository?

The Anki stats data is updated daily by an automated process. Storing it in a separate repository keeps your main website code repository clean and prevents daily automated commits from cluttering your git history.

## Setup Options

### Option 1: Separate GitHub Repository (Recommended)

1. **Create a new GitHub repository**
   ```bash
   # On GitHub, create a new public repo named "anki-stats-data"
   ```

2. **Initialize the repository**
   ```bash
   mkdir anki-stats-data
   cd anki-stats-data
   git init
   echo "# Anki Statistics Data" > README.md
   echo "This repository stores Anki review statistics for the heatmap visualization." >> README.md
   mkdir -p data
   cp /path/to/website/static/data/anki-stats.json data/
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin git@github.com:YOUR_USERNAME/anki-stats-data.git
   git push -u origin main
   ```

3. **Update your website to fetch from the new repo**

   Edit `layouts/partials/anki-heatmap.html` and change the fetch URL:
   ```javascript
   fetch('https://raw.githubusercontent.com/YOUR_USERNAME/anki-stats-data/main/data/anki-stats.json')
   ```

### Option 2: Orphan Branch in Same Repository

1. **Create an orphan branch** (no shared history with main)
   ```bash
   cd /path/to/website
   git checkout --orphan data
   git rm -rf .
   echo "# Anki Statistics Data" > README.md
   mkdir -p data
   cp static/data/anki-stats.json data/
   git add .
   git commit -m "Initialize data branch"
   git push -u origin data
   git checkout main
   ```

2. **Update your website to fetch from the data branch**

   Edit `layouts/partials/anki-heatmap.html` and change the fetch URL:
   ```javascript
   fetch('https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/data/data/anki-stats.json')
   ```

## GitHub Actions Configuration

After setting up your data repository, you'll need to:

1. **Generate SSH key for GitHub Actions**
   ```bash
   ssh-keygen -t ed25519 -C "github-actions" -f github-actions-key
   ```

2. **Add the public key as a deploy key** in your data repository:
   - Go to repository Settings > Deploy keys
   - Add the public key (github-actions-key.pub)
   - Check "Allow write access"

3. **Add the private key as a secret** in your main repository:
   - Go to repository Settings > Secrets and variables > Actions
   - Add new secret: `DATA_REPO_DEPLOY_KEY`
   - Paste the private key content (github-actions-key)

4. **Add Tailscale auth key as a secret**:
   - Go to Tailscale admin console
   - Generate an auth key (ephemeral, reusable)
   - Add as secret: `TAILSCALE_AUTH_KEY`

5. **Add Raspberry Pi SSH connection details as secrets**:
   - `PI_SSH_HOST`: Your Pi's Tailscale hostname (e.g., `raspberry-pi`)
   - `PI_SSH_USER`: SSH username (usually `pi`)
   - `PI_SSH_KEY`: SSH private key for connecting to Pi

## Directory Structure

### Separate Repo Option:
```
anki-stats-data/
├── README.md
└── data/
    └── anki-stats.json
```

### Orphan Branch Option:
```
(data branch)
├── README.md
└── data/
    └── anki-stats.json
```

## Updating the Workflow

Once you've chosen and set up your data repository, update the GitHub Actions workflow file (`.github/workflows/update-anki-stats.yml`) with your specific details:

- Repository URLs
- Branch names
- File paths
- Secrets names (if different)

See `PI_SETUP.md` for Raspberry Pi configuration instructions.
