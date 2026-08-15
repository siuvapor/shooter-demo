# Push to GitHub

The complete project is committed in `godot4-3d-valorant.bundle` as commit
`d324bc5`. This sandbox has no GitHub credentials and no network certificate
store, so the final push needs one quick step from your machine.

## Option A: GitHub CLI

```powershell
gh auth login
cd C:\Users\Lenovo\Documents\Codex\2026-08-15\godot4-3d-valorant
git init -b main
git add .
git commit -m "Initial Godot 4 Valorant duel game"
gh repo create godot4-3d-valorant --public --source . --remote origin --push
```

## Option B: Create the repo on github.com first

1. Create an empty repository named `godot4-3d-valorant` on GitHub.
2. Run:

```powershell
cd C:\Users\Lenovo\Documents\Codex\2026-08-15\godot4-3d-valorant
git init -b main
git add .
git commit -m "Initial Godot 4 Valorant duel game"
git remote add origin https://github.com/YOUR_USERNAME/godot4-3d-valorant.git
git push -u origin main
```

## Option C: Push from the exported bundle

```powershell
cd C:\Users\Lenovo\Documents\Codex\2026-08-15\godot4-3d-valorant
git clone outputs\godot4-3d-valorant.bundle godot4-3d-valorant
cd godot4-3d-valorant
git remote add origin https://github.com/YOUR_USERNAME/godot4-3d-valorant.git
git push -u origin main
```
