# Anki Study Streak Heatmap

This Hugo website features an interactive heatmap visualization showing your Anki study streak, similar to GitHub's contribution graph.

## Features

- **GitHub-style heatmap** showing daily review activity
- **Streak tracking** - current and longest streak display
- **Total review count** statistics
- **Automatic daily updates** via GitHub Actions
- **Secure architecture** - Raspberry Pi never exposed to public internet
- **Dark theme** styled to match Nightfall Hugo theme
- **Responsive design** - works on mobile and desktop
- **Hover tooltips** showing exact review counts per day

## Architecture Overview

```
┌─────────────────┐
│  Raspberry Pi   │
│  - Anki Desktop │
│  - Tailscale    │──┐
│  - Export Script│  │
└─────────────────┘  │
                     │ Private Network
                     │ (Tailscale)
┌─────────────────┐  │
│ GitHub Actions  │  │
│  - Runs daily   │──┘
│  - Connects Pi  │
│  - Updates data │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Data Repo      │
│  anki-stats.json│
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Hugo Website   │
│  - Heatmap      │
│  - Stats Display│
└─────────────────┘
```

## Quick Start

### 1. Website is Already Set Up

The heatmap visualization is already integrated into your Hugo site:

- `layouts/index.html` - Homepage with heatmap
- `layouts/partials/anki-heatmap.html` - Heatmap component
- `static/data/anki-stats.json` - Mock data (will be replaced with real data)

### 2. Test Locally

```bash
# Install Hugo if you haven't
# https://gohugo.io/installation/

# Initialize theme
git submodule update --init --recursive

# Start development server
hugo server -D

# Visit http://localhost:1313
```

You should see the heatmap on your homepage with sample data.

### 3. Set Up Data Repository

Choose one of these options:

**Option A: Separate Repository (Recommended)**
- Cleaner git history
- See [`DATA_REPO_SETUP.md`](./DATA_REPO_SETUP.md) for instructions

**Option B: Orphan Branch**
- Single repository
- See [`DATA_REPO_SETUP.md`](./DATA_REPO_SETUP.md) for instructions

### 4. Configure Raspberry Pi

Follow the comprehensive guide in [`PI_SETUP.md`](./PI_SETUP.md):

1. Install Anki on Pi (or sync database)
2. Install Tailscale
3. Set up export script
4. Configure SSH access
5. Add GitHub secrets

### 5. Deploy GitHub Actions

1. Edit `.github/workflows/update-anki-stats.yml`
2. Update `YOUR_USERNAME/anki-stats-data` with your data repo
3. Commit and push to GitHub
4. Add required secrets (see `PI_SETUP.md`)
5. Test workflow manually

### 6. Update Website Configuration

Once your data repo is set up, update the fetch URL in `layouts/partials/anki-heatmap.html`:

```javascript
// Change this line:
fetch('/data/anki-stats.json')

// To:
fetch('https://raw.githubusercontent.com/YOUR_USERNAME/anki-stats-data/main/data/anki-stats.json')
```

### 7. Deploy Your Website

Deploy to your preferred hosting:

**GitHub Pages:**
```bash
# Push to GitHub
git add .
git commit -m "Add Anki heatmap"
git push

# Enable GitHub Pages in repo settings
# Source: GitHub Actions or branch
```

**Netlify:**
```bash
# Connect your GitHub repo to Netlify
# Build command: hugo
# Publish directory: public
```

**Vercel:**
```bash
# Import project from GitHub
# Framework preset: Hugo
```

## Files Structure

```
website/
├── .github/
│   └── workflows/
│       └── update-anki-stats.yml    # GitHub Actions workflow
├── layouts/
│   ├── index.html                    # Homepage (includes heatmap)
│   └── partials/
│       └── anki-heatmap.html         # Heatmap component
├── static/
│   └── data/
│       └── anki-stats.json           # Stats data (mock/real)
├── scripts/
│   └── export_anki_stats.py          # Export script for Pi
├── ANKI_HEATMAP_README.md            # This file
├── DATA_REPO_SETUP.md                # Data repository setup
└── PI_SETUP.md                       # Raspberry Pi setup
```

## Customization

### Change Colors

Edit `layouts/partials/anki-heatmap.html` and modify the color values:

```css
.legend-box.level-1 {
    background: rgba(76, 175, 80, 0.3);  /* Light green */
}
/* Change to your preferred color scheme */
```

### Change Schedule

Edit `.github/workflows/update-anki-stats.yml`:

```yaml
schedule:
  - cron: '0 2 * * *'  # Change time here
```

Use [crontab.guru](https://crontab.guru/) to generate cron expressions.

### Filter by Deck

When running the export script on your Pi, specify a deck:

```bash
python3 export_anki_stats.py --deck-name "Mandarin" --output /tmp/anki-stats.json
```

Update the script path in GitHub Actions workflow accordingly.

### Adjust Time Range

Change the number of months shown in `layouts/partials/anki-heatmap.html`:

```javascript
start: new Date(new Date().setMonth(new Date().getMonth() - 11)),  // 12 months
range: 12,  // Number of months to display
```

## Maintenance

### Manual Update

Trigger GitHub Actions workflow manually:
1. Go to repository → Actions tab
2. Select "Update Anki Stats"
3. Click "Run workflow"

### Check Logs

- **GitHub Actions**: Repository → Actions → Select workflow run
- **Raspberry Pi**: `journalctl -u ssh -n 50`

### Update Export Script

On your Pi:
```bash
cd ~/anki-export
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/export_anki_stats.py -O export_anki_stats.py
```

## Troubleshooting

### Heatmap Shows "Loading..."

1. Check browser console for errors (F12 → Console)
2. Verify JSON file is accessible at the fetch URL
3. Check CORS settings if using external URL

### No Data Updates

1. Check GitHub Actions logs for errors
2. Verify Pi is online and Tailscale is running
3. Test export script manually on Pi
4. Verify GitHub secrets are correct

### Stats Look Wrong

1. Verify Anki database is up to date on Pi
2. Check export script output for errors
3. Validate JSON file format
4. Compare with mock data structure

## Security

- **Zero public exposure** - Pi stays on private Tailscale network
- **Encrypted connections** - All traffic over Tailscale VPN
- **Ephemeral access** - GitHub Actions uses temporary Tailscale auth
- **Revocable keys** - SSH keys can be rotated anytime
- **Read-only website** - No write operations on public site

## Performance

- **Static site** - Fast loading with Hugo
- **CDN-hosted libraries** - Cal-heatmap from jsDelivr CDN
- **Lightweight** - ~25KB for visualization library
- **Cached data** - JSON file cached at CDN edge

## License

This implementation is free to use and modify for your personal website.

## Credits

- **Hugo Theme**: [Nightfall](https://github.com/LordMathis/hugo-theme-nightfall) by LordMathis
- **Visualization**: [Cal-Heatmap](https://cal-heatmap.com/)
- **Infrastructure**: [Tailscale](https://tailscale.com/) for secure networking
- **Automation**: GitHub Actions

## Support

For issues or questions:
1. Check the documentation files (`PI_SETUP.md`, `DATA_REPO_SETUP.md`)
2. Review GitHub Actions logs
3. Open an issue on the repository

Happy studying! 学习愉快！
