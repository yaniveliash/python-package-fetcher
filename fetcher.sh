#!/bin/bash
JSON_BASE_URL="https://pypi.org/pypi"
RAW_JSON=$(mktemp)

OUTPUT_DIR="$PWD/output"

mkdir $OUTPUT_DIR > /dev/null 2>&1

if ! [[ $(which jq) ]]; then
    echo "jq must be installed"
    exit 1
fi

while IFS="" read -r PACKAGE || [ -n "$PACKAGE" ]
do
    if [[ $(echo $PACKAGE | grep '==') ]]; then
        # split package name and version
        PACKAGE_NAME=$(echo $PACKAGE | cut -d '=' -f1 )
        PACKAGE_VERSION=$(echo $PACKAGE | cut -d '=' -f3 )
        curl -sL $JSON_BASE_URL/$PACKAGE_NAME/$PACKAGE_VERSION/json | jq -r '.urls[].url' > $RAW_JSON
    else
        # no version specified - grab latest
        PACKAGE_NAME=$PACKAGE
        PACKAGE_VERSION=$(curl -sL $JSON_BASE_URL/$PACKAGE_NAME/json | jq -r '.info.version')
        curl -sL $JSON_BASE_URL/$PACKAGE_NAME/$PACKAGE_VERSION/json | jq -r '.urls[].url' > $RAW_JSON
    fi

    while IFS="" read -r FILE_URL || [ -n "$FILE_URL" ]
    do
        FILENAME=$(basename $FILE_URL)
        if ! [[ $(ls $OUTPUT_DIR/$FILENAME 2>/dev/null) ]]; then
            echo -e "Downloading:\n   $FILENAME\nFrom:\n   $FILE_URL\n"
            curl -L -s "$FILE_URL" -o $OUTPUT_DIR/$FILENAME
        else
            echo "$FILENAME exists, skip..."
        fi
    done < $RAW_JSON

done < requirements.txt

tar -zcf $PWD/output.tgz output/*.*

echo "done"
exit 0
