#!/bin/bash

echo "fetching transkriptions from data_repo"
rm -rf data/
git clone --depth=1 --branch main --single-branch https://github.com/arthur-schnitzler/wohin-in-wien-damals_data.git
dataHash=$(git -C ./wohin-in-wien-damals_data rev-parse HEAD)
echo -n "${dataHash}" > ./datahash.txt
mv ./wohin-in-wien-damals_data/data .
rm -rf ./wohin-in-wien-damals_data
echo "fetch imprint"
./shellscripts/dl_imprint.sh


