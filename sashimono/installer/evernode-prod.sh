#!/bin/bash
# Evernode host latest version installer

# Check jq command is installed.
if ! command -v jq &>/dev/null; then
    echo "jq command not found. Installing.."
    apt-get install -y jq >/dev/null
fi

# Check curl command is installed.
if ! command -v curl &>/dev/null; then
    echo "curl command not found. Installing.."
    apt-get install -y curl >/dev/null
fi

[ -z $VERSION ] && VERSION="latest"
repository="https://api.github.com/repos/EvernodeXRPL/evernode-resources/releases"

if [ "$VERSION" = "latest" ]; then
    release_data=$(curl -s "$repository/latest")
else
    release_data=$(curl -s $repository)
fi

# Check if the release is found.
[ -z "$release_data" ] || [ "$(echo $release_data | jq -r 'if type=="array" then "yes" else '.message' end') << "$realease_data"" = "Not Found" ] && echo "Sashimono $VERSION not found." && exit 1

# Fetch the release url
if [ "$VERSION" = "latest" ]; then
    VERSION=$(echo $release_data | jq -r '.tag_name')
    setup=$(echo $release_data | jq -r '.assets[] | select(.name == "setup.sh").browser_download_url')
else
    setup=$(echo $release_data | jq -r '.[] | select(.tag_name == '\"$VERSION\"') | .assets[] |  select(.name == "setup.sh").browser_download_url')
fi

# Check if the release is found.
[ -z "$setup" ] && echo "Sashimono $VERSION not found." && exit 1

echo "Found Sashimono $VERSION..."

# Exucute the setup
curl -fsSL $setup | cat | sudo NETWORK=${NETWORK:-mainnet} bash -s ${@}
