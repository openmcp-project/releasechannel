#!/usr/bin/env bash
# scripts/shift-versions.sh
# Called by Renovate postUpgradeTasks after bumping "latest" version.
# Copies the OLD latest version into the "previous" (second) block.
#
# Usage: shift-versions.sh <file> <old-version> <new-version>
#
# Example: When Renovate bumps crossplane from v2.3.4 → v2.4.0,
# this script updates the second block from v2.2.4 → v2.3.4.
# It also updates the matching reference in releasechannel.yaml.

set -euo pipefail

FILE="$1"
OLD_VERSION="$2"  # what the latest was before Renovate bumped it

if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE" >&2
  exit 1
fi

OLD_BARE="${OLD_VERSION#v}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASECHANNEL="${SCRIPT_DIR}/../components/releasechannel.yaml"

python3 -c "
import re, sys

file_path = sys.argv[1]
old_ver = sys.argv[2]      # e.g. v2.3.4
old_bare = sys.argv[3]     # e.g. 2.3.4
rc_path = sys.argv[4]

with open(file_path) as f:
    content = f.read()

# Split on top-level component entries
blocks = re.split(r'(^  - name: )', content, flags=re.MULTILINE)

if len(blocks) < 5:
    sys.exit(0)

# Reconstruct: header + first block stays, second block gets version replaced
header = blocks[0]
first_block = blocks[1] + blocks[2]
second_prefix = blocks[3]
second_body = blocks[4]
rest = ''.join(blocks[5:]) if len(blocks) > 5 else ''

# Capture the OLD previous version before replacing
prev_ver_match = re.search(r'version: (v[\d]+\.[\d]+\.[\d]+)', second_body)
prev_ver = prev_ver_match.group(1) if prev_ver_match else None

# Replace versions in second block
second_body = re.sub(r'version: v[\d]+\.[\d]+\.[\d]+', f'version: {old_ver}', second_body)
second_body = re.sub(r'(imageReference: [^:]+:)v[\d]+\.[\d]+\.[\d]+', rf'\g<1>{old_ver}', second_body)
second_body = re.sub(r'(helmChart: [^:]+:)[\d]+\.[\d]+\.[\d]+', rf'\g<1>{old_bare}', second_body)

with open(file_path, 'w') as f:
    f.write(header + first_block + second_prefix + second_body + rest)

# Also update releasechannel.yaml: replace the old previous version reference
# with old_ver for this component
if prev_ver and prev_ver != old_ver:
    try:
        with open(rc_path) as f:
            rc = f.read()
        rc = rc.replace(f'version: {prev_ver}', f'version: {old_ver}', 1)
        with open(rc_path, 'w') as f:
            f.write(rc)
    except FileNotFoundError:
        pass
" "$FILE" "$OLD_VERSION" "$OLD_BARE" "$RELEASECHANNEL"
