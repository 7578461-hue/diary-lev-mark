#!/usr/bin/env python3
"""
Daily Supabase backup for lev-mark-tracker.

Downloads every row from every table and writes a single JSON file
backups/YYYY-MM-DD.json so the git history acts as the snapshot store.

Restore: see scripts/restore.py.
"""
import os
import json
import urllib.request
from datetime import datetime, timezone

SUPA  = "https://oqlnsqtveilnphvchwtn.supabase.co"
KEY   = "sb_publishable_DL0kGfHLr_l3sX-KjMkbqg_lyIS8oMu"
TABLES = [
    "formula_entries",
    "water_entries",
    "sleep_entries",
    "feeding_entries",
    "medication_entries",
    "daily_summaries",
    "weight_entries",
]

def fetch(table):
    req = urllib.request.Request(
        f"{SUPA}/rest/v1/{table}?select=*",
        headers={
            "apikey": KEY,
            "Authorization": f"Bearer {KEY}",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def main():
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    snapshot = {
        "snapshot_at_utc": datetime.now(timezone.utc).isoformat(),
        "supabase_project": "oqlnsqtveilnphvchwtn",
        "tables": {},
    }
    total = 0
    for t in TABLES:
        rows = fetch(t)
        snapshot["tables"][t] = rows
        print(f"  {t:22s} {len(rows):5d} rows")
        total += len(rows)
    print(f"  ──────────────────────────────")
    print(f"  total                  {total:5d} rows")

    os.makedirs("backups", exist_ok=True)
    path = f"backups/{today}.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(snapshot, f, ensure_ascii=False, indent=2)
    print(f"\nWrote {path}")

if __name__ == "__main__":
    main()
