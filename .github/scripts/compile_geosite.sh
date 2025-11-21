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

    mkdir -p /tmp/input 
    if [ ! -d "/tmp/input" ]; then
        echo "FATAL ERROR: Could not create input directory /tmp/input"
        exit 1
    fi
    
    echo "--- Processing ${INPUT_FILE} ---"

    echo "Downloading ${REMOTE_URL} to ${LOCAL_PATH}..."
    curl -L "$REMOTE_URL" -o "$LOCAL_PATH"
    CURL_EXIT_CODE=$?

    if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Error: curl failed to download ${REMOTE_URL} with exit code ${CURL_EXIT_CODE}. Check connection or URL."
        exit 1
    fi
    
    if [ -s "$LOCAL_PATH" ]; then
        echo "File downloaded successfully. Size: $(du -h "$LOCAL_PATH" | cut -f1)"
        
        "$SRSC_EXECUTABLE" compile -i "$LOCAL_PATH" -o "release/${OUTPUT_FILE}" -t domain
        echo "Compilation successful."
    else
        echo "Error: Input file ${INPUT_FILE} is empty or invalid after download (Size 0). URL might be wrong or content failed."
        exit 1
    fi
done

echo "All rules compiled successfully."
