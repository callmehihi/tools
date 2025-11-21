#!/bin/bash
set -e

SRSC_VERSION="0.0.1-alpha.1" 

LOYALSOLDIER_BASE_URL="https://raw.githubusercontent.com/Loyalsoldier/domain-list-custom/release"

RULES=(
    "geolocation-cn.txt:geosite-geolocation-cn.srs"
    "geolocation-!cn.txt:geosite-geolocation-!cn.srs"
    "category-ads-all.txt:category-ads-all.srs"
)

SRSC_URL="https://github.com/SagerNet/srsc/archive/refs/tags/v${SRSC_VERSION}.tar.gz"
echo "Downloading srsc tool from ${SRSC_URL}"
curl -L "$SRSC_URL" | tar zx -C /tmp

SRSC_PATH="/tmp/srsc-${SRSC_VERSION}"

mkdir -p /tmp/input
mkdir -p release

for RULE in "${RULES[@]}"; do
    INPUT_FILE=$(echo $RULE | cut -d: -f1)
    OUTPUT_FILE=$(echo $RULE | cut -d: -f2)
    
    REMOTE_URL="${LOYALSOLDIER_BASE_URL}/${INPUT_FILE}"
    LOCAL_PATH="/tmp/input/${INPUT_FILE}"

    echo "--- Processing ${INPUT_FILE} ---"

    echo "Downloading ${REMOTE_URL} to ${LOCAL_PATH}..."
    curl -sfL "$REMOTE_URL" -o "$LOCAL_PATH"

    if [ -f "$LOCAL_PATH" ] && [ -s "$LOCAL_PATH" ]; then
        echo "Compiling ${INPUT_FILE} to release/${OUTPUT_FILE}..."
        "$SRSC_PATH" compile -i "$LOCAL_PATH" -o "release/${OUTPUT_FILE}" -t domain
        echo "Compilation successful."
    else
        echo "Error: Input file ${INPUT_FILE} is empty or failed to download. Skipping compilation."
        exit 1
    fi
done

echo "All rules compiled successfully."
