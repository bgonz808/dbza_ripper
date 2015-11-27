#!/bin/bash

IFS=$'\n'       # make newlines the only separator
for x in `ls -d */ | egrep "^\d+"`
do
    pushd ./$x
        ls -ln1 | grep \.ts | awk -F'\n' '{print "file ./"$1}' > ./list.txt
        ffmpeg -y -f concat -i ./list.txt -c copy -bsf:a aac_adtstoasc ../${x%/}.mp4
    popd
done

