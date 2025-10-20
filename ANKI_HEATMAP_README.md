# Anki Study Streak Heatmap

This Hugo website features an interactive heatmap visualization showing your Anki study streak, similar to GitHub's contribution graph.

## Features

- **GitHub-style heatmap** showing daily review activity
- **Streak tracking** - current and longest streak display
- **Total review count** statistics
- **Automatic daily updates** via Raspberry Pi cron job
- **Simple architecture** - direct push from Pi to GitHub
- **Dark theme** styled to match Nightfall Hugo theme
- **Responsive design** - works on mobile and desktop
- **Hover tooltips** showing exact review counts per day

## Architecture Overview

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
│  Hugo Website        │
│  (Fetches via        │
│   Submodule)         │
└──────────────────────┘
```

**Why this approach?**
- ✅ Simple and reliable
- ✅ No external services needed (no Tailscale, no GitHub Actions)
- ✅ Faster execution (local)
- ✅ Fewer failure points
- ✅ Easy to debug

## Quick Start

### 1. Website is Already Set Up

The heatmap visualization is already integrated into your Hugo site:

- `layouts/index.html` - Homepage with heatmap
- `layouts/partials/anki-heatmap.html` - Heatmap component
- `static/data/` - Git submodule pointing to data repository

### 2. Test Locally

```bash
# Install Hugo if you haven't
# https://gohugo.io/installation/

# Initialize all submodules (theme + data)
git submodule update --init --recursive

# Start development server
hugo server -D

# Visit http://localhost:1313
```

You should see the heatmap on your homepage with sample data.

### 3. Set Up Automation on Raspberry Pi

Follow the comprehensive guide in [`PI_CRON_SETUP.md`](./PI_CRON_SETUP.md):

**Summary:**
1. Create GitHub data repository (`anki-stats-data`)
2. Copy scripts to your Raspberry Pi
3. Run the setup script: `bash setup-pi-cron.sh`
4. Add deploy key to GitHub
5. Verify the cron job is working

The setup script guides you through everything interactively!

```bash
# On your Pi
cd ~/anki-export
bash setup-pi-cron.sh
```

### 4. Add Data Repository as Submodule

In your website repository:

```bash
# Add the data repo as a submodule
git submodule add git@github.com:YOUR_USERNAME/anki-stats-data.git static/data

# Commit the submodule
git add .gitmodules .gitignore static/data
git commit -m "Add anki-stats-data as submodule"
git push
```

**Note:** Update `YOUR_USERNAME` in `.gitmodules` with your actual GitHub username.

### 5. Deploy Your Website

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
│   └── workflows-archive/
│       └── update-anki-stats.yml    # Archived (old GitHub Actions approach)
├── layouts/
│   ├── index.html                   # Homepage (includes heatmap)
│   └── partials/
│       └── anki-heatmap.html        # Heatmap component
├── static/
│   └── data/                        # Git submodule → anki-stats-data repo
│       └── anki-stats.json          # Stats data (auto-updated by Pi)
├── scripts/
│   ├── export_anki_stats.py         # Export script for Pi
│   └── pi/
│       ├── update-anki-stats.sh     # Main automation script
│       └── setup-pi-cron.sh         # One-time setup script
├── ANKI_HEATMAP_README.md           # This file
└── PI_CRON_SETUP.md                 # Raspberry Pi setup guide
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

Edit the cron job on your Raspberry Pi:

```bash
# On your Pi
crontab -e

# Modify the time (current: 2 AM UTC)
0 2 * * * /home/pi/anki-export/update-anki-stats.sh >> /home/pi/anki-export/cron.log 2>&1

# Examples:
# Daily at 3 AM local: 0 3 * * *
# Every 6 hours:       0 */6 * * *
# Daily at midnight:   0 0 * * *
```

Use [crontab.guru](https://crontab.guru/) to generate cron expressions.

### Filter by Deck

Edit `~/anki-export/update-anki-stats.sh` on your Pi:

```bash
# Change this line:
DECK_NAME="Mandarin"

# To your deck name:
DECK_NAME="Your Deck Name"

# Or leave empty for all decks:
DECK_NAME=""
```

### Adjust Time Range

Change the number of months shown in `layouts/partials/anki-heatmap.html`:

```javascript
start: new Date(new Date().setMonth(new Date().getMonth() - 11)),  // 12 months
range: 12,  // Number of months to display
```

## Maintenance

### Manual Update

Run the update script manually on your Pi:

```bash
cd ~/anki-export
bash update-anki-stats.sh
```

### Check Logs

View logs on your Raspberry Pi:

```bash
# Main script log
tail -f ~/anki-export/update-anki-stats.log

# Cron execution log
tail -f ~/anki-export/cron.log

# Last 50 lines
tail -n 50 ~/anki-export/update-anki-stats.log
```

### Update Export Script

On your Pi:
```bash
cd ~/anki-export
# Download updated script from your repo
scp your-dev-machine:/path/to/export_anki_stats.py .
```

### Pull Latest Data in Website

When deploying your website, pull the latest submodule data:

```bash
# Update submodule to latest commit
git submodule update --remote static/data

# Rebuild
hugo

# Or add to your deploy script:
git submodule update --remote --merge && hugo
```

## Troubleshooting

### Heatmap Shows "Loading..."

1. Check browser console for errors (F12 → Console)
2. Verify JSON file exists: `static/data/anki-stats.json`
3. Ensure submodule is initialized: `git submodule update --init`
4. Check Hugo is serving static files correctly

### No Data Updates

1. Check Pi cron logs: `tail -f ~/anki-export/cron.log`
2. Test manually: `bash ~/anki-export/update-anki-stats.sh`
3. Verify Pi has internet: `ping github.com`
4. Check deploy key permissions on GitHub

### Stats Look Wrong

1. Verify Anki database is up to date on Pi
2. Check export script output: `tail ~/anki-export/update-anki-stats.log`
3. Validate JSON file format
4. Test export manually: `python3 ~/anki-export/export_anki_stats.py --output /tmp/test.json`

### Git Push Fails from Pi

1. Test SSH connection: `ssh -T git@github.com`
2. Check deploy key is added with write access
3. Verify repository exists: `https://github.com/YOUR_USERNAME/anki-stats-data`
4. Check git config: `cd ~/anki-export/anki-stats-data && git config --list`

## Security

- **Standard Git SSH authentication** - Secure deploy key with write access
- **Private Pi** - No need to expose Pi to internet
- **Revocable keys** - SSH deploy keys can be rotated anytime
- **Separate data repo** - Clean separation of concerns
- **Read-only website** - No write operations on public site

## Performance

- **Static site** - Fast loading with Hugo
- **CDN-hosted libraries** - Cal-heatmap from jsDelivr CDN
- **Lightweight** - ~25KB for visualization library
- **Git submodule** - Efficient data management

## Migration from GitHub Actions

If you previously used the GitHub Actions approach:

1. ✅ Follow the setup guide in `PI_CRON_SETUP.md`
2. ✅ Verify the cron job works
3. ✅ The old workflow is archived in `.github/workflows-archive/`
4. ✅ You can remove Tailscale from your Pi if no longer needed
5. ✅ Remove old GitHub secrets (optional)

**Benefits of the new approach:**
- Much simpler setup (10 min vs 45 min)
- Fewer dependencies (no Tailscale needed)
- More reliable (fewer network hops)
- Easier debugging (logs are local)
- Faster execution (local processing)

## License

This implementation is free to use and modify for your personal website.

## Credits

- **Hugo Theme**: [Nightfall](https://github.com/LordMathis/hugo-theme-nightfall) by LordMathis
- **Visualization**: [Cal-Heatmap](https://cal-heatmap.com/)
- **Automation**: Raspberry Pi + cron

## Support

For issues or questions:
1. Check the documentation: [`PI_CRON_SETUP.md`](./PI_CRON_SETUP.md)
2. Review Pi logs: `~/anki-export/update-anki-stats.log`
3. Test components individually
4. Open an issue on the repository

Happy studying! 学习愉快！
