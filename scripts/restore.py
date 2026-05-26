#!/usr/bin/env python3
"""
Restore tables from a backup JSON written by scripts/backup.py.

USAGE
  python3 scripts/restore.py backups/2026-05-27.json
        # restores ALL tables (DELETE then INSERT)

  python3 scripts/restore.py backups/2026-05-27.json sleep_entries water_entries
        # restores only the named tables

This is destructive — existing rows in restored tables are deleted first.
Run only after confirming the right snapshot file.
"""
import sys
import json
import urllib.request
import urllib.error

SUPA = "https://oqlnsqtveilnphvchwtn.supabase.co"
KEY  = "sb_publishable_DL0kGfHLr_l3sX-KjMkbqg_lyIS8oMu"
H = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}

def call(method, path, body=None):
    req = urllib.request.Request(
        f"{SUPA}/rest/v1/{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers=H,
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status
    except urllib.error.HTTPError as e:
        msg = e.read().decode()[:200]
        raise RuntimeError(f"{method} {path}: {e.code} {msg}")

def restore(table, rows):
    if not rows:
        print(f"  {table:22s} empty — skip")
        return
    print(f"  {table:22s} clearing...", end=" ", flush=True)
    call("DELETE", f"{table}?id=gte.0")
    print(f"inserting {len(rows)} rows...", end=" ", flush=True)
    # chunk inserts to keep payloads small
    chunk = 200
    for i in range(0, len(rows), chunk):
        call("POST", table, rows[i:i+chunk])
    print("ok")

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    path = sys.argv[1]
    only = sys.argv[2:]
    with open(path, encoding="utf-8") as f:
        snap = json.load(f)
    print(f"Snapshot: {snap.get('snapshot_at_utc','?')}")
    print(f"Restoring from {path}")
    print(f"  scope: {'all tables' if not only else ', '.join(only)}")
    confirm = input("type 'yes' to proceed: ").strip()
    if confirm.lower() != "yes":
        print("Aborted.")
        sys.exit(1)
    for t, rows in snap["tables"].items():
        if only and t not in only:
            continue
        restore(t, rows)
    print("Done.")

if __name__ == "__main__":
    main()
