#!/bin/bash
# Holt die Daten aus dem Daten-Repo und legt sie unter data/ ab.
# Das Daten-Repo hat editions/ und indices/ (künftig meta/) im Wurzelverzeichnis,
# der Build erwartet sie unter data/.
set -euo pipefail

DATA_REPO=https://github.com/arthur-schnitzler/wohin-in-wien-damals_data.git
DATA_DIR=wohin-in-wien-damals_data

echo "fetching data from ${DATA_REPO}"
rm -rf data/ "${DATA_DIR}"
git clone --depth=1 --branch main --single-branch "${DATA_REPO}" "${DATA_DIR}"
git -C "${DATA_DIR}" rev-parse HEAD | tr -d '\n' > ./datahash.txt

mkdir -p data
mv "${DATA_DIR}/editions" "${DATA_DIR}/indices" data/

# Projekttexte: lokale Vorgaben aus meta/, Dateien aus dem Daten-Repo haben Vorrang
mkdir -p data/meta
cp meta/*.xml data/meta/
if [ -d "${DATA_DIR}/meta" ]; then
    cp "${DATA_DIR}"/meta/*.xml data/meta/
fi

rm -rf "${DATA_DIR}"

echo "fetch imprint"
./shellscripts/dl_imprint.sh
