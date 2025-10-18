# Quick Start Guide - Anki Heatmap

Follow these steps in order to get your Anki study heatmap live.

## ✅ Phase 1: Website (Done!)

The heatmap is already integrated into your Hugo site and ready to test.

To view locally:
```bash
hugo server -D
```

Visit `http://localhost:1313` to see the heatmap with mock data.

---

## 📦 Phase 2: Data Repository (15 minutes)

### Step 1: Create Data Repository

**Option A** (Recommended): Separate repository
```bash
# On GitHub, create new repo: anki-stats-data
mkdir anki-stats-data
cd anki-stats-data
git init
echo "# Anki Stats Data" > README.md
mkdir data
cp /path/to/website/static/data/anki-stats.json data/
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:YOUR_USERNAME/anki-stats-data.git
git push -u origin main
```

**Option B**: Orphan branch (see `DATA_REPO_SETUP.md`)

### Step 2: Generate Deploy Keys

```bash
ssh-keygen -t ed25519 -C "github-actions" -f deploy-key
```

- Add `deploy-key.pub` to data repo (Settings → Deploy keys → Allow write)
- Add `deploy-key` (private) to main repo (Settings → Secrets → `DATA_REPO_DEPLOY_KEY`)

### Step 3: Update Website Fetch URL

Edit `layouts/partials/anki-heatmap.html`, line ~83:
```javascript
fetch('https://raw.githubusercontent.com/YOUR_USERNAME/anki-stats-data/main/data/anki-stats.json')
```

---

## 🍓 Phase 3: Raspberry Pi (30 minutes)

### Step 1: Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale status  # Note your hostname
```

### Step 2: Copy Export Script

```bash
mkdir ~/anki-export
# Copy scripts/export_anki_stats.py to Pi
```

From your computer:
```bash
scp scripts/export_anki_stats.py pi@YOUR_PI_IP:~/anki-export/
```

### Step 3: Test Export

On Pi:
```bash
cd ~/anki-export
python3 export_anki_stats.py --output /tmp/test.json
cat /tmp/test.json  # Verify output
```

### Step 4: Generate SSH Key

```bash
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions_key
cat ~/.ssh/github_actions_key.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/github_actions_key  # Copy this for GitHub secret
```

---

## 🤖 Phase 4: GitHub Actions (15 minutes)

### Step 1: Set Up Tailscale OAuth

1. Go to https://login.tailscale.com/admin/settings/oauth
2. Create OAuth client with tag `tag:ci`
3. Copy client ID and secret

### Step 2: Add GitHub Secrets

Go to your repo → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `TAILSCALE_OAUTH_CLIENT_ID` | From Step 1 |
| `TAILSCALE_OAUTH_SECRET` | From Step 1 |
| `PI_SSH_HOST` | Your Pi's Tailscale hostname |
| `PI_SSH_USER` | Usually `pi` |
| `PI_SSH_KEY` | Private key from Phase 3, Step 4 |

### Step 3: Edit Workflow File

Edit `.github/workflows/update-anki-stats.yml`:

```yaml
repository: YOUR_USERNAME/anki-stats-data  # Line 14
```

### Step 4: Test Workflow

1. Commit and push workflow file
2. Go to Actions tab
3. Select "Update Anki Stats"
4. Click "Run workflow"
5. Watch logs for success ✅

---

## 🚀 Phase 5: Deploy (10 minutes)

### GitHub Pages

```bash
# Push everything
git add .
git commit -m "Add Anki heatmap feature"
git push

# In repo settings:
# Pages → Source → GitHub Actions
# or Branch → main → /public
```

### Netlify

1. Connect GitHub repo
2. Build command: `hugo`
3. Publish directory: `public`
4. Deploy!

### Vercel

1. Import from GitHub
2. Framework: Hugo
3. Deploy!

---

## 🎉 Done!

Your heatmap should now:
- ✅ Display on your website
- ✅ Update automatically every day at 2 AM UTC
- ✅ Show your real Anki study streak
- ✅ Stay secure with Tailscale

## Quick Commands

**Test export on Pi:**
```bash
ssh pi@YOUR_PI python3 ~/anki-export/export_anki_stats.py --output /tmp/test.json
```

**Manual trigger GitHub Actions:**
- Repo → Actions → Update Anki Stats → Run workflow

**Local development:**
```bash
hugo server -D
```

**Check logs:**
```bash
# GitHub Actions: Actions tab → Select run
# Pi: journalctl -u ssh -n 50
```

## Next Steps

- Customize colors in `layouts/partials/anki-heatmap.html`
- Adjust schedule in `.github/workflows/update-anki-stats.yml`
- Filter by specific deck in export script
- Add more stats or visualizations

## Need Help?

- Full docs: `ANKI_HEATMAP_README.md`
- Pi setup: `PI_SETUP.md`
- Data repo: `DATA_REPO_SETUP.md`

Good luck! 加油！
