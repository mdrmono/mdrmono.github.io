# Implementation Checklist

Use this checklist to track your progress implementing the Anki heatmap feature.

## ✅ Phase 1: Website Setup (COMPLETED)

- [x] Initialize Nightfall theme submodule
- [x] Create heatmap visualization partial
- [x] Override homepage layout to include heatmap
- [x] Style heatmap to match theme
- [x] Create mock data for testing
- [x] Test locally (requires Hugo installation)

## 📦 Phase 2: Data Repository

- [ ] Choose repository strategy (separate repo vs orphan branch)
- [ ] Create data repository
- [ ] Generate SSH deploy key
- [ ] Add deploy key to data repository
- [ ] Add deploy key secret to main repository
- [ ] Copy initial `anki-stats.json` to data repository
- [ ] Update fetch URL in `layouts/partials/anki-heatmap.html`
- [ ] Commit and push changes

## 🍓 Phase 3: Raspberry Pi Setup

### Installation
- [ ] Update Pi system (`sudo apt update && sudo apt upgrade`)
- [ ] Install Anki desktop OR copy database file
- [ ] Install Tailscale
- [ ] Note Pi's Tailscale hostname

### Configuration
- [ ] Create `~/anki-export` directory on Pi
- [ ] Copy `export_anki_stats.py` to Pi
- [ ] Test export script manually
- [ ] Verify JSON output is correct
- [ ] Generate GitHub Actions SSH key on Pi
- [ ] Add public key to Pi's `authorized_keys`
- [ ] Copy private key for GitHub secret

### Optional: Database Sync
- [ ] Set up AnkiWeb sync OR rsync from main computer
- [ ] Test that database stays updated

## 🤖 Phase 4: GitHub Actions

### Tailscale Setup
- [ ] Create Tailscale OAuth application
- [ ] Generate OAuth client ID and secret
- [ ] Add tag `tag:ci` to OAuth client

### GitHub Secrets
Add these secrets to your repository (Settings → Secrets → Actions):

- [ ] `TAILSCALE_OAUTH_CLIENT_ID`
- [ ] `TAILSCALE_OAUTH_SECRET`
- [ ] `PI_SSH_HOST`
- [ ] `PI_SSH_USER`
- [ ] `PI_SSH_KEY`
- [ ] `DATA_REPO_DEPLOY_KEY` (if using separate repo)

### Workflow Configuration
- [ ] Edit `.github/workflows/update-anki-stats.yml`
- [ ] Update data repository URL (line 14)
- [ ] Adjust cron schedule if needed (line 5)
- [ ] Commit and push workflow file

### Testing
- [ ] Manually trigger workflow
- [ ] Check workflow logs for errors
- [ ] Verify data repository was updated
- [ ] Check that new `anki-stats.json` looks correct

## 🚀 Phase 5: Deployment

### Deploy Website
Choose your hosting platform:

- [ ] **GitHub Pages**: Enable in repo settings
- [ ] **Netlify**: Connect repo, set build command
- [ ] **Vercel**: Import project, select Hugo preset
- [ ] Other: _______________

### Verification
- [ ] Visit deployed website
- [ ] Verify heatmap loads correctly
- [ ] Check that stats display properly
- [ ] Test on mobile device
- [ ] Verify tooltips work on hover

## 🔧 Optional Enhancements

- [ ] Customize heatmap colors
- [ ] Adjust time range displayed
- [ ] Filter by specific Anki deck
- [ ] Add more statistics to display
- [ ] Implement multiple deck comparison
- [ ] Add detailed stats page
- [ ] Create weekly/monthly summary view

## 🎯 Final Checks

- [ ] Automated updates working (wait 24 hours or trigger manually)
- [ ] No errors in GitHub Actions logs
- [ ] Raspberry Pi stays online and connected to Tailscale
- [ ] Website loads quickly
- [ ] No console errors in browser
- [ ] Mobile responsive layout works
- [ ] Tooltips display correctly

## 📚 Documentation Review

Make sure you've read:

- [ ] `QUICK_START.md` - Step-by-step setup
- [ ] `ANKI_HEATMAP_README.md` - Comprehensive documentation
- [ ] `PI_SETUP.md` - Raspberry Pi configuration
- [ ] `DATA_REPO_SETUP.md` - Data repository options

## 🆘 Troubleshooting

If something doesn't work:

1. Check GitHub Actions logs
2. Verify all secrets are added correctly
3. Test Pi connection manually: `ssh pi@HOSTNAME`
4. Run export script manually on Pi
5. Check browser console for JavaScript errors
6. Verify JSON file is accessible via URL

## ✨ Success!

When everything is checked off:

- Your website displays a beautiful Anki study heatmap
- Stats update automatically every day
- Your Raspberry Pi safely exports data via private network
- You have a visual record of your Mandarin study progress!

---

**Estimated Total Time**: 1-2 hours

**Next Steps After Completion**:
- Share your website with friends
- Stay motivated by watching your streak grow
- Consider adding more features
- Keep studying! 加油！

