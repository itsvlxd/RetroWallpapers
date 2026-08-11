<div align="center">

<p align="center" style="vertical-align: middle">
  <img src="assets/logo-palm-transparent-bg.png" alt="Logo" width="90" style="margin-right: 2px; vertical-align: middle">
  <img src="assets/logo-main-transparent-bg.png" alt="Logo" width="520" style="margin-right: 2px; vertical-align: middle">
  <img src="assets/logo-palm-transparent-bg.png" alt="Logo" width="90" style="vertical-align: middle">
</p>

**RetroWallpapers** — the wallpaper collection for [RetroLinux](https://github.com/itsvlxd/RetroLinux).

Arch. Retro. Neon. Hand-tuned packs for every mood — pulled straight into your desktop with one command.

</div>

---

## 📦 What's inside

| Collection | Branch | Wallpapers | Size | Mood |
|------------|:------:|:----------:|:----:|------|
| **noir** | `noir` | 8 | 83 MB | Dark, monochrome, cinematic |
| **retro** | `retro` | 21 | 130 MB | Neon-soaked synthwave, outrun |
| **sunset** | `sunset` | 9 | 275 MB | Golden hour, calm skies |

> Sizes auto-computed by GitHub Actions and stored in [`metadata.json`](metadata.json).

---

## ⬇️ Installing

### With RetroLinux

```bash
retro wallpaper pull              # list available collections
retro wallpaper pull noir         # download the noir pack
retro wallpaper pull --all        # download everything
retro wallpaper sync              # refresh installed packs to latest
```

### Manually

```bash
git clone --depth 1 --branch retro --single-branch https://github.com/itsvlxd/retrowallpapers.git
```

Each collection is an **orphan branch** — a clean, history-free branch with only its own files. Shallow-cloning the branch you want keeps the download minimal.

---

## 🖼️ Collections

### noir

<sub>Dark, monochrome and cinematic. Stripped of color, full of mood.</sub>

<p align="center">
  <kbd><img src="screenshots/noir.png" width="600" alt="noir preview"></kbd>
</p>

### retro

<sub>Neon-soaked synthwave, retro cars and outrun vibes.</sub>

<p align="center">
  <kbd><img src="screenshots/retro.png" width="600" alt="retro preview"></kbd>
</p>

### sunset

<sub>Golden-hour landscapes, calm oceans and warm skies.</sub>

<p align="center">
  <kbd><img src="screenshots/sunset.png" width="600" alt="sunset preview"></kbd>
</p>

---

## 🏗️ Adding or updating a collection

Collections live on **orphan branches**. Each branch holds only its own wallpapers; `main` holds this README, previews, and `metadata.json`.

1. Checkout the orphan branch:

   ```bash
   git checkout --orphan mypack
   git rm -rf . >/dev/null 2>&1 || true
   ```

2. Drop your wallpaper files in, then:

   ```bash
   git add .
   git commit -m "Add mypack collection"
   git push origin mypack
   ```

3. On push, a GitHub Action recomputes `metadata.json` (file count, total size, branch SHA) and pushes it to `main` automatically.

To remove a collection, delete the branch:

```bash
git push origin --delete mypack
```

---

## 📜 License

The wallpapers in this repository are provided for personal use with RetroLinux.

<br><br>

<div align="center">
  <img src="assets/logo-palm-transparent-bg.png" alt="Palm" width="35" style="vertical-align: middle; margin-right: 4px;">
  <img src="assets/logo-main-transparent-bg.png" alt="RetroLinux" width="180" style="vertical-align: middle;">
  <br>
  <sub>© 2026 itsvlxd • Part of the <a href="https://github.com/itsvlxd/RetroLinux">RetroLinux</a> ecosystem</sub>
</div>
