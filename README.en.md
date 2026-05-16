# SitWatcher · macOS sitting reminder

[**简体中文版 README**](README.md)

<sub>This file is secondary to <code>README.md</code> — GitHub’s repo homepage only auto‑renders that default README; bilingual repos usually swap between two Markdown files linked at the top.</sub>

SitWatcher is a small open‑source utility that runs in the **macOS menu bar** to combat **sedentary / sitting too long**. When the countdown ends it shows an **ambient floating reminder** first (snooze or confirm). If you ignore it for too long, it can escalate to a **full‑screen takeover** until you confirm you actually got up—which helps reset long stretches at the desk.

## How it works

1. **Countdown**: intervals are configurable for how often you’d like “time to move” cues.  
2. **Floating window**: unobtrusive banner + actions (confirm / snooze).  
3. **Full‑screen escalation**: configurable delay after the banner if you remain inactive. Same underlying timer—just stronger prompting.  
4. **Away detection**: if there’s essentially no meaningful mouse keyboard activity for long enough we treat it as stepping away—the timer backs off accordingly.

For search / discovery (“menu bar posture timer”, “stand up reminder”) this is that style of lightweight Mac utility.

## Preview · English UI

<table>
  <tr>
    <td align="center"><img src="screenshots/panel-en.png" width="220" /><br />Menu bar panel · stats</td>
    <td align="center"><img src="screenshots/floating-reminder-demo-en.gif" width="360" alt="Floating reminder demo" /><br />Floating reminder</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay-demo-en.gif" width="400" alt="Full-screen reminder demo" /><br />Full-screen reminder</td>
    <td align="center"><img src="screenshots/settings-en.png" width="220" /><br />Settings · intervals</td>
  </tr>
</table>

### Chinese UI snapshots

<details>
<summary><strong>Show Chinese UI previews</strong> (GIFs tuned for Zh strings)</summary>

<table>
  <tr>
    <td align="center"><img src="screenshots/panel.png" width="220" /><br />Menu bar panel</td>
    <td align="center"><img src="screenshots/floating-reminder-demo.gif" width="360" alt="Floating reminder Zh" /><br />Floating reminder</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay-demo.gif" width="400" alt="Full-screen Zh" /><br />Full-screen reminder</td>
    <td align="center"><img src="screenshots/settings.png" width="220" /><br />Settings</td>
  </tr>
</table>

</details>

<sub>In‑repo English assets share the same <code>-en</code> naming for PNG / GIF demos. Scripts: <code>bash scripts/regenerate_floating_demo_gif_en.sh</code> · <code>bash scripts/regenerate_fullscreen_demo_gif_en.sh</code> (<code>.mov</code> stays local/gitignored—need ffmpeg). Chinese demo GIF regeneration: <code>bash scripts/regenerate_floating_demo_gif.sh</code> · <code>bash scripts/regenerate_fullscreen_demo_gif.sh</code>.</sub>

## Features

- Circular menu‑bar countdown plus simple daily counters (stretch breaks taken, interruptions, approximate focus streaks on the timeline we track)  
- “Idle-aware” pacing that tries to approximate real stepping away versus tiny mouse jitter scripts  
- Tweak reminders, escalation delay, dwell thresholds for “away”, pointer sensitivity knobs  
- **[Sparkle](https://sparkle-project.org/)**‑based checks for newer builds from inside the menu bar extras

## Installation

### 1) One‑liner installer (recommended)

Installs whatever the latest Release packages into Applications and launches SitWatcher:

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Aarontaken/sit-watcher@master/install.sh | bash
```

Raw GitHub (note the branch **`master`** here):

```bash
curl -fsSL https://raw.githubusercontent.com/Aarontaken/sit-watcher/master/install.sh | bash
```

### 2) Homebrew

```bash
brew tap Aarontaken/tap
brew install --cask sit-watcher
```

### 3) Manual

Grab `SitWatcher.dmg` under [Releases](https://github.com/Aarontaken/sit-watcher/releases); mount → run **`Install.app`**.

Maintainers can sanity‑check downloader logic without spraying `/Applications` via `bash scripts/verify-install.sh` after editing `install.sh`.

## Building from sources

```bash
brew install xcodegen create-dmg
xcodegen generate
./scripts/build.sh
```

Or Xcode → SitWatcher scheme → Run (⌘R).

## System requirements

- macOS Sonoma (14)+  
- Works on Apple Silicon and Intel installs

## License

MIT
