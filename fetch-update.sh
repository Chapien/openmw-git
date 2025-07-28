#!/usr/bin/env sh
eval `ssh-agent`
ssh-add

echo "Updating openmw-git"
mkdir -p /home/$USER/repos
cd /home/$USER/repos

echo "Making sure the repo is where we expect it to be"
if ! test -d "openmw-git"; then
    echo "No repo!"
    exit 1
fi

echo "Making sure our repo is up to date"
cd openmw-git
git pull
cd /HOME/$USER/repos

echo "Checking if we already have the openmw repo"
if test -d "openmw"; then
    echo "Found openmw repo"
    echo "Pulling latest from openmw..."
    cd openmw
    STATUS=$(git pull)
    if [ "$STATUS" = "Already up to date." ]; then
        echo $STATUS
        exit 0
    fi
else
    echo "openmw not found."
    echo "openmw SIF repo..."
    git clone git@gitlab.com:OpenMW/openmw.git
    cd openmw
fi

COMMITNUM=$(git rev-list --count --all)
echo "openmw commit number $COMMITNUM"

echo "Updating specfile"
cd /home/$USER/repos/openmw-git
sed "/^%global         commitnum.*/ s//%global         commitnum $COMMITNUM/" openmw-git.spec > openmw-git.spec
echo "Spec file updated"
git add -A
git commit -m "Updating repo"
git push
if [ $? -eq 0 ]; then
    echo "Successfully updated openmw build source and pushed to git!"
else
    echo "Git push failed."
    exit 1
fi

echo "Copy the spec file to our webserver"
cp openmw-git.spec /data/drive2/minhttps/copr/openmw-git/openmw-git.spec
echo "Starting copr build!"
copr-cli build --nowait chapien/openmw https://files.chapien.net/copr/openmw-git/openmw-git.spec
echo "Build started!"
exit 0