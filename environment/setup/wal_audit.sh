#!/usr/bin/env bash
# wal-audit: Reports WAL status around the damaged segment.
# Wraps pg_waldump and provides the agent with structured diagnostic output.

set -euo pipefail

PGDATA="${PGDATA:-/var/lib/postgresql/data}"
WALDIR="$PGDATA/pg_wal"

echo "=== WAL Audit Report ==="
echo "Generated: $(date -u)"
echo ""

echo "--- WAL Directory Contents ---"
ls -lh "$WALDIR/" | grep -v '^total' | grep -v '\.history' || true
echo ""

echo "--- Last Checkpoint Info ---"
pg_controldata "$PGDATA" | grep -E "(checkpoint|redo|state|WAL)" | head -20
echo ""

echo "--- pg_waldump: Scanning all WAL segments ---"
for seg in "$WALDIR"/[0-9A-F]*; do
    segname=$(basename "$seg")
    size=$(stat -c%s "$seg" 2>/dev/null || echo "?")
    echo ""
    echo "== Segment: $segname (size: $size bytes) =="
    # Dump last 50 records for brevity; full dump is available with: pg_waldump -p $PGDATA/pg_wal -n 9999 $segname
    pg_waldump -p "$WALDIR" -n 50 "$segname" 2>&1 | tail -60 || true
done

echo ""
echo "--- Current Database Row Counts ---"
psql -U postgres -d appdb -tA -c "
SELECT 'orders'  AS tbl, COUNT(*) FROM orders
UNION ALL
SELECT 'ledger',          COUNT(*) FROM ledger
UNION ALL
SELECT 'events',          COUNT(*) FROM events;
" 2>/dev/null || echo "(could not connect to database)"

echo ""
echo "--- Expected Checksums Reference ---"
cat /tmp/expected_checksums.txt 2>/dev/null || echo "(reference file not yet generated)"

echo ""
echo "=== End of WAL Audit ==="
