!#/bin/bash
docker build .  --build-arg ace_releasetype=Release --build-arg ace_branch=master --tag ace:master
docker build .  --build-arg ace_releasetype=Debug --build-arg ace_branch=master --tag ace:masterdebug


