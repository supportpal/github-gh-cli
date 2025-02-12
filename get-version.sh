#!/bin/bash

set -euxo pipefail  # Ensures the script exits on errors and unset variables

# Function to parse JSON data using jq
parseData() {
    local jsonData="$1"
    if echo "$jsonData" | jq . >/dev/null 2>&1; then
        echo "$jsonData" | jq -c '[.[] | select(.prerelease == false) | {published_at, tag_name}]'
    else
        echo "Error: Failed to parse JSON data." >&2
        exit 1
    fi
}

# Function to get paginated data
getPaginatedData() {
    local url=$1
    local token=$2
    local data='[]'

    while :; do
        # Fetch data using curl
        response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $token" \
                          -H "X-GitHub-Api-Version: 2022-11-28" \
                          -H "Accept: application/vnd.github.v3+json" "$url")

        http_code="${response: -3}"  # Extract HTTP status code
        response_body="${response%???}"  # Extract body

        if [[ "$http_code" != "200" ]]; then
            echo "Error: Failed to fetch data from GitHub API (HTTP status: $http_code)." >&2
            echo "Response: $response_body" >&2
            exit 1
        fi

        # Parse the JSON data
        parsedData=$(parseData "$response_body")

        # Append parsed data to the data array
        data=$(echo "$data" "$parsedData" | jq -s 'add')

        # Check the link header for pagination
        linkHeader=$(curl -s -I -H "Authorization: Bearer $token" \
                             -H "X-GitHub-Api-Version: 2022-11-28" \
                             -H "Accept: application/vnd.github.v3+json" "$url" | grep -i 'link:')

        if [[ $linkHeader == *'rel="next"'* ]]; then
            # Extract the next URL from the link header using regex
            nextUrl=$(echo "$linkHeader" | grep -o '<[^>]*>; rel="next"' | sed 's/<\(.*\)>; rel="next"/\1/')
            url=$nextUrl
        else
            break
        fi
    done

    # Output the collected data
    echo "$data"
}

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 GITHUB_TOKEN"
    exit 1
fi

# Initial URL
initialUrl="https://api.github.com/repos/cli/cli/releases?per_page=100"
token="$1"
current_version="$(grep -Eo "ENV GITHUB_CLI_VERSION .+" debian/Dockerfile | cut -d' ' -f3)"

# Get the paginated data
data=$(getPaginatedData "$initialUrl" "$token")

# Sort the data by the published_at attribute in descending order
sortedData=$(echo "$data" | jq 'sort_by(.published_at) | reverse')

# Determine the next version.
tags=$(echo "$sortedData" | jq -r '.[] | .tag_name' | tr '\n' ' ')
next_version="$(echo "$tags" | (grep -Eo "(.*?) v$current_version( |$)" || true) | awk '{print $(NF-1)}' | cut -c2-)"

echo "$next_version"
