# 🧹 Win-Janitor: Core Invariants

1. **Sakshi Immutable Shield (Rule Zero)**: Never kill, pause, modify, or delete `\Sakshi` scheduled task, `%USERPROFILE%\Void\Sakshi\`, or any asset matching `*Sakshi*`. Abort any action touching Sakshi immediately.
2. **Safe Working-Set Trimming**: Reclaim RAM primarily via Win32 `EmptyWorkingSet` memory flush (`psapi.dll`). Never kill developer workflows (active Neovim, PowerShell, IDEs, active browser tabs). Only terminate known background ghosts (`Widgets`, `CrossDeviceResume`, orphaned WebView2 subprocesses).
3. **Quarantine Backups**: Registry dumps and PATH backups live strictly in `%LOCALAPPDATA%\win-janitor\backups\`, never inside git trees.
