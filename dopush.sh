#!/bin/bash

commitmessage="$1"
if [ x"$commitmessage" == x ]
then
    echo "usage: $(basename $0) <commitmessage>"
    exit 1
fi

function docommit()
{
git add -A .
git commit -m "$commitmessage"
git push
}

sed -i -e 's/^#theme:/theme:/' -e 's/^remote_theme:/#remote_theme:/' _config.yml

docommit

sed -i -e 's/^theme:/#theme:/' -e 's/^#remote_theme:/remote_theme:/' _config.yml

[[ -d $gitearepo/_site  ]] && { echo "unexpected dir $gitearepo/_site found"; exit -4; }
[[ -d $gitearepo/vendor ]] && { echo "unexpected dir $gitearepo/vendor found"; exit -4; }


exit 0
