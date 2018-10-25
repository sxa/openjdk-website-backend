#!/bin/bash
DATESTAMP=`date +%y%m%d`

function json2csv () {
  awk -F: '/"file":/{NAME=$2}/"count":/{print NAME " " $2}' $1 | tr -d '"' | tr -d ' '  > $2
}

function json2csvsplit () {
  awk -F: '/"file":/{NAME=$2}/"count":/{print NAME " " $2}' | tr -d '"' | tr -d ' '
}

function csv2summary () {
  for PLATFORM in ppc64_aix ppc64le_linux s390x_linux x64_linux x64_mac x64_windows x86-32_windows; do grep -v sha256.txt $1 | awk -F, "BEGIN{HOTSPOT=0; OPENJ9=0}/$PLATFORM.*hotspot/{HOTSPOT+=\$2}/$PLATFORM.*openj9/{OPENJ9+=\$2}END{print \"$PLATFORM \" HOTSPOT \" \" OPENJ9}" ; done > $2
}
for VERSION in openjdk8 openjdk8-openj9 openjdk9 openjdk9-openj9 openjdk10 openjdk10-openj9 openjdk11 openjdk11-openj9; do
  echo `date +%T` : Grabbing data for $VERSION ...
  mkdir -p $VERSION
  wget -q -O - https://api.github.com/repos/AdoptOpenJDK/${VERSION}-releases/releases | ./jq '.[] | { asset: .assets[] | { file: .name, count: .download_count } }' > $VERSION/releases.$DATESTAMP.json
  wget -q -O - https://api.github.com/repos/AdoptOpenJDK/${VERSION}-nightly/releases  | ./jq '.[] | { asset: .assets[] | { file: .name, count: .download_count } }' > $VERSION/nightly.$DATESTAMP.json
  # Convert JSON to CSV
  json2csv $VERSION/nightly.$DATESTAMP.json $VERSION/nightly.$DATESTAMP.csv
  json2csv $VERSION/releases.$DATESTAMP.json $VERSION/releases.$DATESTAMP.csv
done

for VERSION in openjdk8 openjdk9 openjdk10 openjdk11; do
  echo `date +%T` : Grabbing data for new releases for $VERSION
  mkdir -p $VERSION
  wget -q -O - https://api.github.com/repos/AdoptOpenJDK/${VERSION}-binaries/releases | ./jq '.[] | { asset: .assets[] | { file: .name, count: .download_count } }' > $VERSION/releases-new.$DATESTAMP.json
  # Convert JSON to CSV
  NIGHTLYREGEX='_20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
  json2csvsplit < $VERSION/releases-new.$DATESTAMP.json | grep    "$NIGHTLYREGEX" > $VERSION/nightly-new.$DATESTAMP.csv
  json2csvsplit < $VERSION/releases-new.$DATESTAMP.json | grep -v "$NIGHTLYREGEX" > $VERSION/releases-new.$DATESTAMP.csv
  # Convert CSV to per-platform/variant summary excluding sha256 files
  csv2summary $VERSION/nightly-new.$DATESTAMP.csv $VERSION/nightly-new.$DATESTAMP.summary.csv
  csv2summary $VERSION/releases-new.$DATESTAMP.csv $VERSION/releases-new.$DATESTAMP.summary.csv
done
