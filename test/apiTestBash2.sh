#!/bin/bash

curl -L \
  -X GET \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  http://localhost:8023/dumpRequest \
  -d '{"tag_name":"v0.0.1","target_commitish":"master","name":"bash test","body":"Description of the release","draft":false,"prerelease":false,"generate_release_notes":false}'