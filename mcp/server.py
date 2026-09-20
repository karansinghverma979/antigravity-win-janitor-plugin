#!/usr/bin/env python3
"""
Win-Janitor MCP Server
Autonomous Windows 11 System Janitor, Bloatware Eradicator & Performance Governor.
Pure Python standard library stdio JSON-RPC implementation.
"""

import sys
import json
import os
import subprocess
import traceback
from pathlib import Path

# Force UTF-8 on Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = PLUGIN_ROOT / "skills" / "win-janitor"
SCRIPTS_DIR = SKILLS_DIR / "scripts"
JANITOR_SCRIPT = SCRIPTS_DIR / "janitor.ps1"

TOOLS = [
    {
        "name": "win_janitor_audit",
        "description": "Execute instant diagnostic scan of physical RAM, top 10 memory consumers, baseline services, and startup registry items.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "win_janitor_trim",
        "description": "Flush inactive process working sets via EmptyWorkingSet Win32 API, terminate detached background ghosts (Widgets, CrossDeviceResume, IGCCTray, TextInputHost), and reclaim RAM.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "win_janitor_purge",
        "description": "Deep wipe of leftover AppData directories, orphaned caches, and installer temp files.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "win_janitor_fix_shell",
        "description": "Remediate Windows Shell, virtual desktop lag, DWM compositor stalls, desktop right-click freezes, and thumbnail RPC deadlocks (AppHangXProcB1).",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "win_janitor_diagnose",
        "description": "Deep root-cause investigation for performance anomalies, process deadlocks, and shell freezes.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "scenario": {
                    "type": "string",
                    "description": "Diagnostic scenario: 'ram', 'cpu', 'shell', or 'drift'.",
                    "enum": ["ram", "cpu", "shell", "drift"],
                    "default": "ram"
                }
            },
            "required": ["scenario"]
        }
    },
    {
        "name": "win_janitor_path_clean",
        "description": "Deduplicate User PATH and prune non-existent directory paths with automatic pre-cleanup backup outside git tree.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "win_janitor_reg_clean",
        "description": "Scan and remove residual vendor registry hives from uninstalled software (Google, VMware, Notion, Ollama, etc.) with pre-deletion .reg export backups outside git tree.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "win_janitor_enforce_baseline",
        "description": "Enforce 10 bloat/telemetry background services to Disabled and enforce Edge and Windows Widget blocking policies.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "win_janitor_dev_hygiene",
        "description": "Audit global Python pip installations vs. local venvs and verify developer path portability.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    }
]

def run_janitor(action: str, target: str = None) -> dict:
    if not JANITOR_SCRIPT.exists():
        return {
            "exit_code": 1,
            "success": False,
            "error": f"Script not found: {JANITOR_SCRIPT}"
        }

    cmd = ["pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(JANITOR_SCRIPT), action]
    if target:
        cmd.append(target)

    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return {
        "exit_code": proc.returncode,
        "success": proc.returncode == 0,
        "action": action,
        "target": target,
        "output": proc.stdout.strip(),
        "errors": proc.stderr.strip() if proc.stderr else None
    }

def handle_audit(args: dict) -> dict:
    return run_janitor("audit")

def handle_trim(args: dict) -> dict:
    return run_janitor("trim")

def handle_purge(args: dict) -> dict:
    return run_janitor("purge")

def handle_fix_shell(args: dict) -> dict:
    return run_janitor("fix-shell")

def handle_diagnose(args: dict) -> dict:
    scenario = args.get("scenario", "ram")
    return run_janitor("diagnose", scenario)

def handle_path_clean(args: dict) -> dict:
    return run_janitor("path-clean")

def handle_reg_clean(args: dict) -> dict:
    return run_janitor("reg-clean")

def handle_enforce_baseline(args: dict) -> dict:
    return run_janitor("enforce-baseline")

def handle_dev_hygiene(args: dict) -> dict:
    return run_janitor("dev-hygiene")

def send_json(payload: dict):
    line = json.dumps(payload, ensure_ascii=False)
    sys.stdout.write(line + "\n")
    sys.stdout.flush()

def handle_jsonrpc(line: str):
    if not line.strip():
        return
    try:
        req = json.loads(line)
    except Exception as e:
        send_json({
            "jsonrpc": "2.0",
            "id": None,
            "error": {"code": -32700, "message": f"Parse error: {str(e)}"}
        })
        return

    req_id = req.get("id")
    method = req.get("method")
    params = req.get("params", {})

    if method == "initialize":
        send_json({
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                },
                "serverInfo": {
                    "name": "win-janitor",
                    "version": "1.3.0"
                }
            }
        })
    elif method == "notifications/initialized":
        pass
    elif method == "tools/list":
        send_json({
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "tools": TOOLS
            }
        })
    elif method == "tools/call":
        tool_name = params.get("name")
        tool_args = params.get("arguments", {})

        handlers = {
            "win_janitor_audit": handle_audit,
            "win_janitor_trim": handle_trim,
            "win_janitor_purge": handle_purge,
            "win_janitor_fix_shell": handle_fix_shell,
            "win_janitor_diagnose": handle_diagnose,
            "win_janitor_path_clean": handle_path_clean,
            "win_janitor_reg_clean": handle_reg_clean,
            "win_janitor_enforce_baseline": handle_enforce_baseline,
            "win_janitor_dev_hygiene": handle_dev_hygiene
        }

        handler = handlers.get(tool_name)
        if not handler:
            send_json({
                "jsonrpc": "2.0",
                "id": req_id,
                "error": {"code": -32601, "message": f"Tool '{tool_name}' not found."}
            })
            return

        try:
            res_data = handler(tool_args)
            send_json({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": json.dumps(res_data, indent=2)
                        }
                    ],
                    "isError": False
                }
            })
        except Exception as err:
            send_json({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Error in '{tool_name}': {str(err)}\n{traceback.format_exc()}"
                        }
                    ],
                    "isError": True
                }
            })
    elif method == "ping":
        send_json({"jsonrpc": "2.0", "id": req_id, "result": {}})
    else:
        if req_id is not None:
            send_json({
                "jsonrpc": "2.0",
                "id": req_id,
                "error": {"code": -32601, "message": f"Method '{method}' not implemented."}
            })

def main():
    for line in sys.stdin:
        handle_jsonrpc(line)

if __name__ == "__main__":
    main()
