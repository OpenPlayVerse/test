#!/bin/bash

packwiz refresh
git add .
git commit -m "$*"
git push