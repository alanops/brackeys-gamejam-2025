# Deployment Guide

## Itch.io Deployment Setup

The project is configured to deploy to **itch.io** under the project name `brackeys25`.

**Game URL**: https://alanops.itch.io/brackeys25

## Manual Deployment

### Prerequisites
1. **Butler CLI** installed
   ```bash
   curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default
   unzip butler.zip
   chmod +x butler
   sudo mv butler /usr/local/bin/
   ```

2. **Login to Butler**
   ```bash
   butler login
   ```

### Deploy Commands

**Quick Deploy:**
```bash
./scripts/deploy-itch.sh
```

**Build Only:**
```bash
./scripts/build-web.sh
```

**Test Locally:**
```bash
cd builds/web
python -m http.server 8000
# Visit: http://localhost:8000
```

## Automated Deployment

### GitHub Actions
- **Auto-deploy**: Pushes to `main` branch automatically deploy
- **Manual deploy**: Use "Actions" tab > "Deploy to itch.io" > "Run workflow"
- **Tagged releases**: Push tags like `v1.0.0` for versioned releases

### Setup Requirements
1. **Butler API Key**: 
   - Get from: https://itch.io/user/settings/api-keys
   - Add as GitHub secret: `BUTLER_CREDENTIALS`

2. **Repository Settings**:
   - Go to Settings > Secrets and variables > Actions
   - Add secret: `BUTLER_CREDENTIALS` = your butler API key

## Build Configuration

### Export Settings
- **Platform**: Web (HTML5)
- **Target**: Browser optimized
- **Compression**: Enabled
- **File Size Limit**: 50MB (web build constraint)

### Project Structure
```
builds/web/           # Web build output
├── index.html        # Main game file
├── *.wasm           # Game binary
├── *.pck            # Game data
└── *.js             # Game scripts
```

## Testing Checklist

Before deploying:
- [ ] Game runs in Godot editor
- [ ] No console errors in browser
- [ ] Controls work (WASD, mouse)
- [ ] Performance acceptable in browser
- [ ] File size under 50MB
- [ ] All assets loading correctly

## Deployment Workflow

1. **Development**
   ```bash
   # Make changes, test locally
   git add .
   git commit -m "Feature: add new mechanics"
   git push origin main
   ```

2. **Automatic Deploy**
   - GitHub Actions builds and deploys automatically
   - Check Actions tab for deployment status

3. **Manual Deploy** (if needed)
   ```bash
   ./scripts/deploy-itch.sh
   ```

4. **Test Live**
   - Visit: https://alanops.itch.io/brackeys25
   - Test in different browsers
   - Check performance on different devices

## Version Management

Versions are managed through:
- **project.godot** `config/version` field
- **Git tags** for releases
- **Butler** auto-versioning by timestamp

Update version:
```bash
# Edit project.godot version
git tag v1.0.0
git push origin v1.0.0
```

## Troubleshooting

### Common Issues
- **Export failed**: Check Godot export templates installed
- **Butler login failed**: Re-run `butler login`
- **File size too large**: Optimize assets, check texture compression
- **Game won't load**: Check browser console for errors

### Debug Steps
1. Test web export locally first
2. Check GitHub Actions logs for errors
3. Verify itch.io project settings
4. Test in incognito/private browser mode