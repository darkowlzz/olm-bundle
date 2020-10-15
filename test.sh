#!/usr/bin/env bash

set -e

YQ="./bin/yq"

# Helper for printing error.
echoerr() {
	printf "ERROR: %s\n" "$*" >&2;
	exit 1
}

# $1 - Absolute path of an expected directory. 
check_dir_exists () {
	if [ ! -d $1 ]; then
		echoerr "expected $1 to be created"
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
		fi
	done
}

# $1 - Absolute path of the output bundle dir.
check_annotations () {
	annotationsFile="$1/metadata/annotations.yaml"

	# Read the values from the annotations file. Check the attribues that
	# are passed to OPM, if they have the expected value.
	GOT_CHANNELS=$($YQ r $annotationsFile annotations[operators.operatorframework.io.bundle.channels.v1])
	GOT_DEFAULT_CHANNEL=$($YQ r $annotationsFile annotations[operators.operatorframework.io.bundle.channel.default.v1])
	GOT_PACKAGE=$($YQ r $annotationsFile annotations[operators.operatorframework.io.bundle.package.v1])
	GOT_MANIFESTS=$($YQ r $annotationsFile annotations[operators.operatorframework.io.bundle.manifests.v1])
	# Got and want manifests. Get the basename only.
	GM=$(basename $GOT_MANIFESTS)
	WM=$(basename $MANIFESTS_DIR)

	if [ "$GOT_CHANNELS" != "$CHANNELS" ]; then
		echoerr "expected channels to be $CHANNELS, got $GOT_CHANNELS"
	fi
	if [ "$GOT_DEFAULT_CHANNEL" != "$DEFAULT_CHANNEL" ]; then
		echoerr "expected default channel to be $DEFAULT_CHANNEL, got $GOT_DEFAULT_CHANNEL"
	fi
	if [ "$GOT_PACKAGE" != "$PACKAGE" ]; then
		echoerr "expected package to be $PACKAGE, got $GOT_PACKAGE"
	fi
	if [ "$GM" != "$WM" ]; then
		echoerr "expected manifests to be $WM, got $GM"
	fi
}

# $1 - DOCKERFILE_LABELS_FILE - path to a file containing dockerfile labels.
# $2 - Generated dockerfile.
check_labels_exists () {
	if ! cat $1 | grep -f $2; then
		echoerr "expected Dockerfile labels in $1 not found in the generated bundle Dockerfile $2"
	fi
}

check_file_exists () {
	if [ ! -f $1 ]; then
		echoerr "expected $$1 to be created"
	fi
}

test_new_output_dir () {
	echo "== Test if a bundle can be created in an empty bundle directory"

	# Create a test operator bundle directory to be used as the output dir.
	TEST_OUTPUT_DIR=$PWD/testdata/test-operator
	mkdir -p $TEST_OUTPUT_DIR

	export MANIFESTS_DIR=$PWD/testdata/bundle/manifests
	export CHANNELS=stable
	export DEFAULT_CHANNEL=stable
	export PACKAGE=test-operator
	export OUTPUT_DIR=$TEST_OUTPUT_DIR/0.0.2
	export DOCKERFILE_LABELS_FILE=testdata/common-labels.txt

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

	# Check if the annotations are as expected.
	check_annotations $OUTPUT_DIR

	# Check if the Dockerfile labels are appended.
	check_labels_exists $DOCKERFILE_LABELS_FILE $WANT_DOCKERFILE

	# Cleanup.
	rm -rf $TEST_OUTPUT_DIR

	unset MANIFESTS_DIR CHANNELS DEFAULT_CHANNEL PACKAGE OUTPUT_DIR \
		DOCKERFILE_LABELS_FILE
}

test_add_new_bundle () {
	echo "== Test if a bundle can be added to an existing bundle directory"

	# Existing bundle directory.
	TEST_OUTPUT_DIR=$PWD/testdata/memcached

	export MANIFESTS_DIR=$PWD/testdata/bundle/manifests
	export CHANNELS=stable
	export DEFAULT_CHANNEL=stable
	export PACKAGE=memcached
	export OUTPUT_DIR=$TEST_OUTPUT_DIR/0.0.2
	export DOCKERFILE_LABELS_FILE=$PWD/testdata/common-labels.txt

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

	# Check if the annotations are as expected.
	check_annotations $OUTPUT_DIR

	# Check if the Dockerfile labels are appended.
	check_labels_exists $DOCKERFILE_LABELS_FILE $WANT_DOCKERFILE

	# Cleanup.
	rm -rf $OUTPUT_DIR
	rm $WANT_DOCKERFILE

	unset MANIFESTS_DIR CHANNELS DEFAULT_CHANNEL PACKAGE OUTPUT_DIR \
		DOCKERFILE_LABELS_FILE
}

# Install opm and yq.
make opm
sudo cp bin/opm /usr/local/bin
sudo cp bin/yq /usr/local/bin

# Run tests.
test_new_output_dir
test_add_new_bundle
