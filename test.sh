#!/usr/bin/env bash

set -e

# Helper for printing error.
echoerr() { printf "ERROR: %s\n" "$*" >&2; }

# $1 - Absolute path of an expected directory. 
check_dir_exists () {
	if [ ! -d $1 ]; then
		echoerr "expected $1 to be created"
		exit 1
	fi
}

# $1 - Absolute path of the source bundle manifests.
# $2 - Absolute path of the output bundle dir.
check_manifests_copied () {
	for filepath in $1/*.yaml; do
		[ -e "$filepath" ] || continue
		filename="$2/$(basename $filepath)"
		if [ ! -f "$filename" ]; then
			echoerr "expected $filename to be created"
			exit 1
		fi
	done
}

check_file_exists () {
	if [ ! -f $1 ]; then
		echoerr "expected $$1 to be created"
	fi
}

test_new_output_dir () {
	# Create a test operator bundle directory to be used as the output dir.
	TEST_OUTPUT_DIR=$PWD/testdata/test-operator
	mkdir -p $TEST_OUTPUT_DIR

	export MANIFESTS_DIR=$PWD/testdata/bundle/manifests
	export CHANNELS=stable
	export PACKAGE=test-operator
	export OUTPUT_DIR=$TEST_OUTPUT_DIR/0.0.2

	# Generate the bundle.
	./generate.sh

	# Check if the bundle directory is created.
	WANT_BUNDLE_DIR="$TEST_OUTPUT_DIR/0.0.2"
	check_dir_exists $WANT_BUNDLE_DIR

	# Check if all the manifest files were copied.
	check_manifests_copied $MANIFESTS_DIR $OUTPUT_DIR/manifests

	# Check if dockerfile was created with the right name.
	WANT_DOCKERFILE="$(dirname $OUTPUT_DIR)/bundle-$(basename $OUTPUT_DIR).Dockerfile"
	check_file_exists $WANT_DOCKERFILE

	# Cleanup.
	rm -rf $TEST_OUTPUT_DIR
}

# Install opm.
make opm
sudo cp bin/opm /usr/local/bin

# Run tests.
test_new_output_dir

