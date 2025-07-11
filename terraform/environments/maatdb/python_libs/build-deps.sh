#!/usr/bin/env bash

# exit on errors
set -e

echo "requests" > requirements.txt

# colours!
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK_SIGN="\\e[1;32m\\xE2\\x9C\\x94\\e[0m"

echo -e "[I]${RED} Building your docker image... ${NC}"
docker buildx build --platform linux/amd64 --load -t lambda-builder .
echo -e "[I]${RED} Running docker and building dependencies... ${NC}"
docker run --rm -ti --name lambda -v "${PWD}":/app lambda-builder
echo -e "[${CHECK_SIGN}]${RED} Your lambda layer with dependencies is ready! ${NC}"