#!/bin/bash

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $(cat ghAPI.token)"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/OpenPlayVerse/test/releases \
  -d '{"tag_name":"v0.0.2","target_commitish":"master","name":"bash test","body":"Description of the release","draft":false,"prerelease":false,"generate_release_notes":false}'