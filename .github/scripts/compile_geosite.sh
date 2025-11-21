#!/bin/bash
set -e

SRSC_REPO="https://github.com/SagerNet/srsc.git"
SRSC_BUILD_DIR="/tmp/srsc_source"
SRSC_EXECUTABLE="/tmp/srsc"
LOYALSOLDIER_BASE_URL="https://raw.githubusercontent.com/Loyalsoldier/domain-list-custom/release"

RULES=(
    "geolocation-cn.txt:geosite-geolocation-cn.srs"
    "geolocation-!cn.txt:geosite-geolocation-!cn.srs"
    "category-ads-all.txt:category-ads-all.srs"
)


echo "1. Cloning srsc repository..."
git clone --depth 1 --branch "dev" "$SRSC_REPO" "$SRSC_BUILD_DIR"

echo "2. Compiling srsc tool..."
cd "$SRSC_BUILD_DIR"
go build -o "$SRSC_EXECUTABLE" ./cmd/srsc

cd -

if [ ! -x "$SRSC_EXECUTABLE" ]; then
    echo "Error: srsc executable not found or failed to compile at $SRSC_EXECUTABLE"
    exit 1
fi
echo "srsc tool compiled successfully."


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
