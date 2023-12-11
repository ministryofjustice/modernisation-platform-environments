#!/bin/bash

LAMBDA_ZIP="lambda_function.zip"
SOURCE_DIR="./lambda/cw-xml-to-json"
BUILD_DIR="build"
VENV_DIR="venv"

echo "Creating virtual environment..."
python3 -m venv $VENV_DIR

echo "Activating virtual environment..."
# shellcheck disable=SC1091
source $VENV_DIR/bin/activate

echo "Installing requirements in virtual environment..."
pip install -r $SOURCE_DIR/requirements.txt

mkdir -p $BUILD_DIR
cp -r $VENV_DIR/lib/python3.*/site-packages/* $BUILD_DIR/

cp $SOURCE_DIR/*.py $BUILD_DIR/

cd $BUILD_DIR || exit 1

echo "Creating Lambda function package..."
zip -r ../$LAMBDA_ZIP ./*

deactivate
cd ..
rm -rf $VENV_DIR $BUILD_DIR

echo "Lambda package created: $LAMBDA_ZIP"
