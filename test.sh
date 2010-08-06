#!/bin/sh
BASE_DIR=$(cd $(dirname $0) && pwd)
DATA_DIR=$BASE_DIR/data

for file in $DATA_DIR/* ; do
	echo "Source: $file"
	ruby keyphrase.rb $file
	echo
done
