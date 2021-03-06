#!/usr/bin/env bash

set -e

# This scripts helps generate an OLM bundle for a given set of CRDs and CSV
# files for a given bundle version. Once the bundle version is populated in the
# right directory structure, it then renames the generated Dockerfile to a
# version specific name - bundle-VERSION.Dockerfile. This Dockerfile can then
# be used to build bundle image for a specific version.
#
# MANIFESTS_DIR - Directory containing all the CRDs and CSVs for a bundle.
# OUTPUT_DIR - Bundle version directory. Created if not exists.
# CHANNELS - Channels of the bundle. Comma separated channel names.
# PACKAGE - OLM package name.
# DEFAULT_CHANNEL - Default channel name (optional).
# DOCKERFILE_LABELS_FILE - Path to a file containing extra Dockerfile labels.
#
# If MANIFESTS_DIR is not provided, OPERATOR_REPO, OPERATOR_BRANCH and
# OPERATOR_MANIFESTS_DIR can be provided for cloning and extracting the metadata
# files from an operator git repo.
#
# This results in the bundle directory of the following structure:
#       <packageName>
#	├── 2.1.0
#	│   ├── manifests
#	│   │   ├── operatorname.v2.1.0.clusterserviceversion.yaml
#	│   │   ├── someresource.crd.yaml
#	│   │   └── otherresource.crd.yaml
#	│   └── metadata
#	│       └── annotations.yaml
#	├── 2.2.0
#	│   ├── manifests
#	│   │   ├── operatorname.v2.2.0.clusterserviceversion.yaml
#	│   │   ├── someresource.crd.yaml
#	│   │   └── otherresource.crd.yaml
#	│   └── metadata
#	│       └── annotations.yaml
#	├── bundle-2.1.0.Dockerfile
#	└── bundle-2.2.0.Dockerfile
#
# Example command:
# $ MANIFESTS_DIR=/home/user/go/src/github.com/darkowlzz/bundle \
# 	OUTPUT_DIR=my-operator/2.1.0 CHANNELS=stable PACKAGE=my-operator \
# 	generate.sh

# Disable cleanup by default to avoid unexpected data deletion. This is only
# enabled automatically when MANIFESTS_DIR is not used and OPERATOR_REPO is
# provided to clone the repo and extract the manifests.
CLEANUP=false

if [ -z "$MANIFESTS_DIR" ]; then
	echo "No MANIFESTS_DIR specified, trying to extract bundle from git repo..."

	if [ -z "$OPERATOR_REPO" ]; then
		echo "Error: OPERATOR_REPO must be set"
		exit 1
	fi

	if [ -z "$OPERATOR_BRANCH" ]; then
		echo "Error: OPERATOR_BRANCH must be set"
		exit 1
	fi

	if [ -z "$OPERATOR_MANIFESTS_DIR" ]; then
		echo "Error: OPERATOR_MANIFESTS_DIR must be set"
		exit 1
	fi

	# Clone repo, copy the bundle dir from the repo into a bundle dir out
	# of the repo and delete the repo. Set MANIFESTS_DIR to bundle
	CLONE_DIR="operator"
	git clone $OPERATOR_REPO $CLONE_DIR --depth=1 --branch $OPERATOR_BRANCH
	cp -r "$CLONE_DIR/$OPERATOR_MANIFESTS_DIR" manifests
	rm -rf $CLONE_DIR
	MANIFESTS_DIR=$(pwd)/manifests
	CLEANUP=true
fi

if [ -z "$MANIFESTS_DIR" ]; then
	echo "Error: MANIFESTS_DIR must be set"
	exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
	echo "Error: OUTPUT_DIR must be set"
	exit 1
fi

if [ -z "$CHANNELS" ]; then
	echo "Error: CHANNELS must be set"
	exit 1
fi

if [ -z "$PACKAGE" ]; then
	echo "Error: PACKAGE must be set"
	exit 1
fi

# If no default channel is set, use stable.
if [ -z "$DEFAULT_CHANNEL" ]; then
	DEFAULT_CHANNEL=stable
fi

# If MANIFESTS_DIR is not absolute path, prepend PWD to make it absolute.
if [[ ! "$MANIFESTS_DIR" = /* ]]; then
	MANIFESTS_DIR=$(pwd)/$MANIFESTS_DIR
fi

# If DOCKERFILE_LABELS_FILE is provided and is not absolute path, prepend PWD.
if [[ ! -z "$DOCKERFILE_LABELS_FILE" ]] && [[ ! "$DOCKERFILE_LABELS_FILE" = /* ]] ; then
	DOCKERFILE_LABELS_FILE=$(pwd)/$DOCKERFILE_LABELS_FILE
fi

VERSION="$(basename $OUTPUT_DIR)"
BUNDLE_DIR="$(dirname $OUTPUT_DIR)"
DOCKERFILE_PATH="bundle-$VERSION.Dockerfile"

# Get into the bundle dir and generate the bundle.
pushd $BUNDLE_DIR
	echo "Generating bundle at $OUTPUT_DIR ..."
	opm alpha bundle generate -d $MANIFESTS_DIR -u $VERSION \
		--channels $CHANNELS \
		--package $PACKAGE \
		--default $DEFAULT_CHANNEL
	echo "Renaming bundle.Dockerfile to $DOCKERFILE_PATH"
	mv bundle.Dockerfile $DOCKERFILE_PATH
	# Append the dockerfile labels file content to the generated
	# dockerfile.
	if [ ! -z "$DOCKERFILE_LABELS_FILE" ]; then
		cat $DOCKERFILE_LABELS_FILE >> $DOCKERFILE_PATH
	fi
popd

# Print tree output as the action output.
# NOTE: tree output includes backtick which causes error when printed using
# echo. To avoid unexpected errors due to backticks, replace backtick and
# similar special symbols with alternatives.
t=$(tree $OUTPUT_DIR | sed 's/├/\+/g; s/─/-/g; s/└/\\/g; s/`/+/g')
# NOTE: Github action truncates multi-line outputs. Escape the newline
# characters.
# Refer: https://github.community/t/set-output-truncates-multiline-strings/16852/3
t="${t//'%'/'%25'}"
t="${t//$'\n'/'%0A'}"
t="${t//$'\r'/'%0D'}"
echo -e "::set-output name=tree::$t"

# Cleanup.
if [ "$CLEANUP" = true ]; then
	rm -rf $MANIFESTS_DIR
fi
