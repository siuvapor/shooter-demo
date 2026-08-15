# Push to GitHub

The complete project is exported as `godot4-3d-valorant.bundle` (kept locally;
the bundle is not committed to Git to avoid recursive bundle updates). This
sandbox has no GitHub credentials and no access to the Windows Credential
Manager, so the final push needs one quick login step from your machine.

Target repository: `https://github.com/siuvapor/shooter-demo`

## Option A: GitHub CLI

```powershell
gh auth login
cd C:\Users\Lenovo\Documents\Codex\2026-08-15\godot4-3d-valorant
git init -b main
git add .
git commit -m "Initial Godot 4 Valorant duel game"
git remote add origin https://github.com/siuvapor/shooter-demo.git
git push -u origin main
```

## Option B: Push from the exported bundle

```powershell
cd C:\Users\Lenovo\Documents\Codex\2026-08-15\godot4-3d-valorant
git clone outputs\godot4-3d-valorant.bundle shooter-demo
cd shooter-demo
git remote add origin https://github.com/siuvapor/shooter-demo.git
git push -u origin main
```
