#!/bin/bash
[ ! -r jq ] && wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod u+x jq

function json2csvsplit () {
  awk -F: '/"file":/{NAME=$2}/"count":/{print NAME " " $2}' | tr -d '"' | tr -d ' '
}

function csv2summary () {
  for PLATFORM in ppc64_aix ppc64le_linux s390x_linux x64_linux x64_mac x64_windows x86-32_windows; do grep -v sha256.txt $1 | awk -F, "BEGIN{HOTSPOT=0; OPENJ9=0}/$PLATFORM.*hotspot/{HOTSPOT+=\$2}/$PLATFORM.*openj9/{OPENJ9+=\$2}END{print \"$PLATFORM \" HOTSPOT \" \" OPENJ9}" ; done > $2
}

for VERSION in openjdk8 openjdk9 openjdk10 openjdk11; do
  wget -q -O - https://api.github.com/repos/AdoptOpenJDK/${VERSION}-binaries/releases | ./jq '.[] | { asset: .assets[] | { file: .name, count: .download_count } }' > releases.json
  # Convert JSON to CSV
  NIGHTLYREGEX='_20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
  json2csvsplit < releases.json | grep    "$NIGHTLYREGEX" > nightly.csv
  json2csvsplit < releases.json | grep -v "$NIGHTLYREGEX" > releases.csv
  # Convert CSV to per-platform/variant summary excluding sha256 files
  csv2summary nightly.csv  nightly.summary.csv
  csv2summary releases.csv releases.summary.csv
  echo "=== NIGHTLY INFORMATION for $VERSION (platform hotspot openj9 figures)"
  cat nightly.summary.csv
  awk '{HOTSPOT+=$2; OPENJ9+=$3}END{print "TOTAL " HOTSPOT " " OPENJ9}' nightly.summary.csv
  echo "=== RELEASE INFORMATION for $VERSION (platform hotspot openj9 figures)"
  cat releases.summary.csv
  awk '{HOTSPOT+=$2; OPENJ9+=$3}END{print "TOTAL " HOTSPOT " " OPENJ9}' releases.summary.csv
done
