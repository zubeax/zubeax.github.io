#!/bin/bash

gitearepo='../zubeax.gitea.io'

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

sed -i -e 's/^theme:/#theme:/' -e 's/^#remote_theme:/remote_theme:/' _config.yml

docommit

sed -i -e 's/^#theme:/theme:/' -e 's/^remote_theme:/#remote_theme:/' _config.yml

rsync -av . $gitearepo -f '- .git/' -f '- _site/' -f '- vendor/' -f '- .jekyll-cache/'

[[ -d $gitearepo/_site  ]] && { echo "unexpected dir $gitearepo/_site found"; exit -4; }
[[ -d $gitearepo/vendor ]] && { echo "unexpected dir $gitearepo/vendor found"; exit -4; }

pushd . 2>&1 > /dev/null
cd $gitearepo
docommit
popd 2>&1 > /dev/null

exit 0
