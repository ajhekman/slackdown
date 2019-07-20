#!/usr/bin/env sh
set -euo pipefail
IFS=$'\n\t'

pandoc -f gfm -t ../lib/slack_doc.lua example.md

