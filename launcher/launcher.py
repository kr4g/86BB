#!/usr/bin/env python3
"""86 Billion Butterflies — Launcher

Starts and stops the Express server and SuperCollider (sclang) from a single
toggle button.  Run directly (`python launcher.py`) or bundle as a .app with
build.sh.
"""

import os
import signal
import subprocess
import sys
import threading
import tkinter as tk
from tkinter import scrolledtext
from pathlib import Path

# ---------------------------------------------------------------------------
# Config — edit these if your paths differ
# ---------------------------------------------------------------------------
SCLANG_PATH = "/Applications/SuperCollider.app/Contents/MacOS/sclang"
NPM_CMD = "npm"

# ---------------------------------------------------------------------------
# Resolve project root (works both as a script and inside a .app bundle)
# ---------------------------------------------------------------------------
_THIS_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = _THIS_DIR.parent

APP_DIR = PROJECT_ROOT / "app"
SC_BOOT = PROJECT_ROOT / "av-engine" / "86bb_boot.scd"


class Launcher:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("86BB Launcher")
        self.root.geometry("720x480")
        self.root.configure(bg="#1a1a2e")
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)

        self._procs: dict[str, subprocess.Popen] = {}
        self._threads: list[threading.Thread] = []
        self._running = False

        self._build_ui()

    def _build_ui(self):
        header = tk.Frame(self.root, bg="#1a1a2e")
        header.pack(fill=tk.X, padx=12, pady=(12, 4))

        tk.Label(
            header,
            text="86 BILLION BUTTERFLIES",
            font=("Courier", 16, "bold"),
            fg="#cccccc",
            bg="#1a1a2e",
        ).pack(side=tk.LEFT)

        status_frame = tk.Frame(self.root, bg="#1a1a2e")
        status_frame.pack(fill=tk.X, padx=12, pady=4)

        self._express_dot = tk.Label(
            status_frame, text="\u25cf", font=("Courier", 14), fg="#555", bg="#1a1a2e"
        )
        self._express_dot.pack(side=tk.LEFT)
        tk.Label(
            status_frame,
            text=" Express ",
            font=("Courier", 12),
            fg="#999",
            bg="#1a1a2e",
        ).pack(side=tk.LEFT)

        self._sc_dot = tk.Label(
            status_frame, text="\u25cf", font=("Courier", 14), fg="#555", bg="#1a1a2e"
        )
        self._sc_dot.pack(side=tk.LEFT)
        tk.Label(
            status_frame,
            text=" sclang",
            font=("Courier", 12),
            fg="#999",
            bg="#1a1a2e",
        ).pack(side=tk.LEFT)

        self._toggle_btn = tk.Button(
            self.root,
            text="Start 86BB",
            font=("Courier", 14, "bold"),
            fg="#fff",
            bg="#2d6a4f",
            activebackground="#40916c",
            activeforeground="#fff",
            relief=tk.FLAT,
            padx=20,
            pady=6,
            command=self._toggle,
        )
        self._toggle_btn.pack(pady=8)

        self._log = scrolledtext.ScrolledText(
            self.root,
            wrap=tk.WORD,
            font=("Courier", 11),
            bg="#0a0a0f",
            fg="#77cc77",
            insertbackground="#77cc77",
            state=tk.DISABLED,
            height=18,
        )
        self._log.pack(fill=tk.BOTH, expand=True, padx=12, pady=(4, 12))

    def _toggle(self):
        if self._running:
            self._kill_all()
        else:
            self._start_all()

    def _start_all(self):
        self._running = True
        self._toggle_btn.config(text="Kill 86BB", bg="#ae2012")
        self._log_msg("=== Starting 86BB ===\n")

        self._start_process(
            "express",
            [NPM_CMD, "run", "dev"],
            cwd=str(APP_DIR),
            dot=self._express_dot,
        )
        self._start_process(
            "sclang",
            [SCLANG_PATH, str(SC_BOOT)],
            dot=self._sc_dot,
        )

    def _kill_all(self):
        self._log_msg("\n=== Stopping 86BB ===\n")
        for name in list(self._procs):
            self._kill_process(name)
        self._running = False
        self._toggle_btn.config(text="Start 86BB", bg="#2d6a4f")
        self._express_dot.config(fg="#555")
        self._sc_dot.config(fg="#555")

    def _start_process(
        self,
        name: str,
        cmd: list[str],
        cwd: str | None = None,
        dot: tk.Label | None = None,
    ):
        env = os.environ.copy()
        env["FORCE_COLOR"] = "0"
        try:
            proc = subprocess.Popen(
                cmd,
                cwd=cwd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                start_new_session=True,
                env=env,
            )
        except FileNotFoundError:
            self._log_msg(f"[{name}] ERROR: command not found: {cmd[0]}\n")
            if dot:
                dot.config(fg="#ae2012")
            return

        self._procs[name] = proc
        if dot:
            dot.config(fg="#52b788")
        self._log_msg(f"[{name}] started (pid {proc.pid})\n")

        t = threading.Thread(target=self._tail, args=(name, proc, dot), daemon=True)
        t.start()
        self._threads.append(t)

    def _tail(
        self,
        name: str,
        proc: subprocess.Popen,
        dot: tk.Label | None,
    ):
        assert proc.stdout is not None
        for raw_line in proc.stdout:
            line = raw_line.decode("utf-8", errors="replace")
            self._log_msg(f"[{name}] {line}")
        proc.wait()
        self._log_msg(f"[{name}] exited (code {proc.returncode})\n")
        self._procs.pop(name, None)
        if dot:
            self.root.after(0, lambda: dot.config(fg="#555"))

    def _kill_process(self, name: str):
        proc = self._procs.pop(name, None)
        if proc is None or proc.poll() is not None:
            return
        pgid = os.getpgid(proc.pid)
        self._log_msg(f"[{name}] sending SIGTERM to process group {pgid}\n")
        try:
            os.killpg(pgid, signal.SIGTERM)
        except ProcessLookupError:
            return
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self._log_msg(f"[{name}] SIGKILL\n")
            try:
                os.killpg(pgid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    def _log_msg(self, text: str):
        def _append():
            self._log.config(state=tk.NORMAL)
            self._log.insert(tk.END, text)
            self._log.see(tk.END)
            self._log.config(state=tk.DISABLED)

        self.root.after(0, _append)

    def _on_close(self):
        if self._running:
            self._kill_all()
        self.root.destroy()


def main():
    root = tk.Tk()
    Launcher(root)
    root.mainloop()


if __name__ == "__main__":
    main()
