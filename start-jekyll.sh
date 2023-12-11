#!/bin/bash

export PAGES_REPO_NWO=zubeax.github.io

bundle exec jekyll serve --host=0.0.0.0 --incremental --watch --force_polling

exit 0


