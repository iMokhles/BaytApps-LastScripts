# !/bin/bash

IPALink="$1"
OUTPath="$2"

echo $OUTPath

result=$(sudo curl -L "$IPALink" -o $OUTPath)
echo "$result"
