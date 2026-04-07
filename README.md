# 86 Billion Butterflies

A long-duration art installation that translates collective food choices into an evolving representation of a shared gut microbiome.

## Prerequisites

| Dependency | Install | Notes |
|---|---|---|
| Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | macOS package manager |
| Node.js | `brew install node` | Runs the Express API + Vite dev server |
| Python 3 + tkinter | `brew install python-tk` | Powers the launcher app |
| SuperCollider | [Download](https://supercollider.github.io/downloads) | Drag `SuperCollider.app` to `/Applications` |
| sc3-plugins | [Download](https://supercollider.github.io/sc3-plugins/) | Copy to the SuperCollider Extensions folder* |

\* On macOS: `~/Library/Application Support/SuperCollider/Extensions/`

## Quick Start

```bash
cd app
npm install
npm run dev
```

The app runs at `http://localhost:5173` (Vite dev server) with the API at `http://localhost:3000`.

To access the app from an iPad on the same network, open `http://<machine-ip>:5173`.

## Launcher (macOS .app)

A standalone macOS app that starts the Express server and SuperCollider with one click.

### Build the launcher

```bash
cd launcher
./build.sh
```

This produces `86BB Launcher.app` at the project root. Double-click it from Finder.

### Or run directly

```bash
python launcher/launcher.py
```

The launcher expects SuperCollider at `/Applications/SuperCollider.app`. Edit the `SCLANG_PATH` constant in `launcher/launcher.py` if yours differs.

## Installation Setup (Mac Mini)

On a fresh Mac Mini, run the following to get everything installed and built:

```bash
# 1. Install Homebrew (skip if already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Node.js and Python with tkinter
brew install node python-tk

# 3. Install SuperCollider + sc3-plugins manually:
#    - SuperCollider: https://supercollider.github.io/downloads
#      → drag SuperCollider.app to /Applications
#    - sc3-plugins:   https://supercollider.github.io/sc3-plugins/
#      → copy to ~/Library/Application Support/SuperCollider/Extensions/

# 4. Install npm dependencies
cd app
npm install
cd ..

# 5. Update av-engine/86bb_boot.scd audio device to match the Mac Mini output
#    (e.g. "Mac mini Speakers" or an external interface name)

# 6. Build the launcher
cd launcher
./build.sh
```

Then double-click `86BB Launcher.app` from Finder.

## Project Structure

- `app/` — React + Express web app (food ordering UI)
  - `src/client/` — React frontend
  - `src/server/` — Express backend (microbiome engine, persistence)
  - `src/shared/` — Types, data, and constants shared between client and server
- `av-engine/` — SuperCollider audio/visual engine (synths, LEDs, FluCoMa ML)
  - `86bb_boot.scd` — Installation boot script (started by launcher)
  - `86bb_main.scd` — LED test GUI (standalone)
  - `osc_responders.scd` — OSC handlers for Express ↔ SC communication
- `launcher/` — Python + tkinter launcher app (bundles as macOS .app)
- `analysis/` — Jupyter notebooks and derived data for microbiome research
- `data/` — Persistent runtime state (gut-state.json, order-history.jsonl)

## Configuration

Environment variables (all optional, sensible defaults provided):

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3000 | Server port |
| `ALPHA` | 0.05 | EMA blend factor per order |
| `NORM_FACTOR` | 3.0 | Sigmoid normalization |
| `DATA_DIR` | ../data | State file directory |
