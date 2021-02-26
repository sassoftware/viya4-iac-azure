#!/usr/bin/env bash

# We need to return an error if things don't work
set -e

if [[ -f $(which git) ]] && ( [[ -d "$(pwd)/.git" ]] || ( [[ -f "$(pwd)/.git" ]] && [[ $(cat "$(pwd)/.git" | grep "modules" ) ]] )) ; then
  git log -1 --format=format:'{ "git-hash": "%H" }'
else
  echo '{ "git-hash": "N/A" }'
fi
