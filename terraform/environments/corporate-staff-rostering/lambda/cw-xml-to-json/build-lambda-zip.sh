#!/usr/bin/env bash

# This script must be executed with the Lambda's
# python source directory in lambda/ as the working
# directory ($PWD).
# The ZIP file must be committed in that same directory.

readonly LOG_FILE=lambda-build-$(date "+%Y%m%dT%H%M%S").log

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>"$LOG_FILE" 2>&1

readonly SOURCE_DIR="."
readonly LAMBDA_ZIP="deployment_package.zip"
readonly BUILD_DIR="build"
readonly VENV_DIR="venv"

msg() {
	echo "$@" >&3
}

dependencies=(
	"python3"
	"zip"
)

for cmd in "${dependencies[@]}"; do
	if ! command -v "$cmd" &>/dev/null; then
		msg "Error: Required command '$cmd' is not available."
		exit 1
	fi
done

msg "Creating virtual environment..."
python3 -m venv $VENV_DIR

msg "Activating virtual environment..."
# shellcheck disable=SC1091
source $VENV_DIR/bin/activate

mkdir -p $BUILD_DIR

msg "Downloading requirements..."
pip install --requirement "$SOURCE_DIR/requirements.txt" --target $BUILD_DIR

msg "Copying source files..."
cp "$SOURCE_DIR/requirements.txt" $BUILD_DIR/
cp "$SOURCE_DIR"/*.py $BUILD_DIR/

msg "Creating ZIP file..."
(cd $BUILD_DIR && zip --recurse-paths ../$LAMBDA_ZIP ./*)

msg "Cleaning up..."
deactivate
rm -rf $BUILD_DIR $VENV_DIR

msg
msg "Lambda package created: $LAMBDA_ZIP"
msg "Full log: $LOG_FILE"
