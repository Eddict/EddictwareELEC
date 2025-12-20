#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   .logs/collect_ci_diagnostics.sh [BUILD_DIR]
# Defaults to: $DEFAULT_BUILD_DIR
DEFAULT_BUILD_DIR="/root/actions-runners/Eddict/EddictwareELEC/_work/EddictwareELEC/EddictwareELEC/build.EddictwareELEC-RPi4.aarch64-13.0-devel"
echo "Default build dir: $DEFAULT_BUILD_DIR"
BUILD_DIR=${1:-$DEFAULT_BUILD_DIR}
echo "Using build dir: $BUILD_DIR"
TS=$(date +%Y%m%d%H%M%S)
OUTFILE=".logs/ci_diagnostics_${TS}.log"
mkdir -p .logs

echo "Collecting diagnostics for build dir: $BUILD_DIR" > "$OUTFILE"
echo "Timestamp: $(date -u)" >> "$OUTFILE"
echo "" >> "$OUTFILE"

append() { printf "\n--- %s ---\n\n" "$1" >> "$OUTFILE"; }

append "Listing top-level build dir"
ls -la "$BUILD_DIR" 2>/dev/null | sed -n '1,200p' >> "$OUTFILE" || echo "(no build dir)" >> "$OUTFILE"

LOGS_DIR="$BUILD_DIR/.threads/logs"
append "Thread logs list ($LOGS_DIR)"
if [ -d "$LOGS_DIR" ]; then
  ls -l "$LOGS_DIR" | sed -n '1,200p' >> "$OUTFILE" || true
else
  echo "(no thread logs dir)" >> "$OUTFILE"
fi

append "Head of failing thread log 17.log (if present)"
if [ -f "$LOGS_DIR/17.log" ]; then
  sed -n '1,400p' "$LOGS_DIR/17.log" >> "$OUTFILE" || true
  printf "\n... (tail) ...\n\n" >> "$OUTFILE"
  tail -n 200 "$LOGS_DIR/17.log" >> "$OUTFILE" || true
else
  echo "(no $LOGS_DIR/17.log)" >> "$OUTFILE"
fi

append "Build-system debug.log (head)"
if [ -f "$BUILD_DIR/.threads/debug.log" ]; then
  sed -n '1,800p' "$BUILD_DIR/.threads/debug.log" >> "$OUTFILE" || true
else
  echo "(no debug.log)" >> "$OUTFILE"
fi

append "Environment snapshot (host running this script)"
printenv | sort >> "$OUTFILE" 2>/dev/null || true

append "Which cmake and version"
{ command -v cmake || which cmake || true; cmake --version 2>/dev/null || true; } >> "$OUTFILE" 2>&1 || true

append "Toolchain candidate listings (limited)"
TOOLCHAIN_CANDIDATES=("$BUILD_DIR/toolchain" "$BUILD_DIR/toolchain-*/bin" "/usr/local/bin" "/usr/bin" "$HOME/toolchain/bin")
for p in "${TOOLCHAIN_CANDIDATES[@]}"; do
  echo "Listing: $p" >> "$OUTFILE"
  ls -la $p 2>/dev/null | sed -n '1,200p' >> "$OUTFILE" || echo "(not present)" >> "$OUTFILE"
  echo "" >> "$OUTFILE"
done

append "Find any ccache-related build dirs and note config.log presence"
find "$BUILD_DIR" -type d -iname '*ccache*' -maxdepth 6 2>/dev/null | sed -n '1,200p' >> "$OUTFILE" || true
find "$BUILD_DIR" -type f -iname 'config.log' -path "*/ccache/*" -maxdepth 8 2>/dev/null | sed -n '1,200p' >> "$OUTFILE" || true

append "Search for recent error/fail/not found messages (first 200 matches)"
grep -iR --line-number -E 'error|fail|not found|command not found' "$BUILD_DIR" 2>/dev/null | sed -n '1,200p' >> "$OUTFILE" || true

append "Top-level Makefile and scripts/image snippet"
if [ -f Makefile ]; then echo "--- Makefile (head) ---" >> "$OUTFILE"; sed -n '1,120p' Makefile >> "$OUTFILE" || true; fi
if [ -f scripts/image ]; then echo "--- scripts/image (head) ---" >> "$OUTFILE"; sed -n '1,120p' scripts/image >> "$OUTFILE" || true; fi

echo "\nDiagnostics written to: $OUTFILE"
echo "$(ls -lh "$OUTFILE")"

exit 0
