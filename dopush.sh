#!/bin/bash

commitmessage="$1"
if [ x"$commitmessage" == x ]; then
    echo "usage: $(basename $0) <commitmessage>"
    exit 1
fi

sed -i -e 's/^theme:/#theme:/' -e 's/^#remote_theme:/remote_theme:/' _config.yml

git add -A .
git commit -m "$commitmessage"
git push

sed -i -e 's/^#theme:/theme:/' -e 's/^remote_theme:/#remote_theme:/' _config.yml

exit 0

