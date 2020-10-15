# olm-bundle

[![Test](https://github.com/darkowlzz/olm-bundle/workflows/Test/badge.svg)](https://github.com/darkowlzz/olm-bundle/actions?query=workflow%3ATest)
[![Action in workflow](https://github.com/darkowlzz/olm-bundle/workflows/Action%20in%20workflow/badge.svg)](https://github.com/darkowlzz/olm-bundle/actions?query=workflow%3A%22Action+in+workflow%22)

Github Action to generate
[Operator Lifecycle Manager](olm.operatorframework.io/) bundle format
manifests.

olm-bundle can be used as github action or as an independent tool to help
generate the OLM versioned bundles.

When used as github action, it can be paired with
[peter-evans/create-pull-request](https://github.com/marketplace/actions/create-pull-request)
to create a pull request with the generated bundle changes.

## Usage

This action can be used in two ways based on the location of the source bundle
manifests (CSV and CRD files):

1. When the source bundle manifests is in the same repo, set the action input
   `manifestsDir` to the source bundle manifests dir path as shown below:

```yaml
on:
  workflow_dispatch:
    # Enable manual trigger for this action.
    inputs:
      version:
        description: Bundle version.
        required: true

jobs:
  generate-bundle:
    runs-on: ubuntu-latest
    name: Generate operator bundle
    steps:
      - uses: actions/checkout@v2
      - name: olm-bundle action
        id: bundle
        uses: darkowlzz/olm-bundle@master
        with:
          manifestsDir: bundle/manifests
          outputDir: my-operator/${{ github.event.inputs.version }}
          channels: stable,beta
          package: my-operator
      - name: bundle tree output
        run: echo "${{ steps.bundle.outputs.tree }}"
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v3.4.0
```

This will read the manifests from `manifestsDir` and write it to the
`outputDir` and create a pull request with the changes.

2. When the source bundle manifests is in a different repo, set the action
   inputs `operatorRepo`, `operatorBranch` and `operatorManifestsDir` as shown
   below:

```yaml
on:
  workflow_dispatch:
    # Enable manual trigger for this action.
    inputs:
      version:
        description: Bundle version.
        required: true

jobs:
  generate-bundle:
    runs-on: ubuntu-latest
    name: Generate operator bundle
    steps:
      - uses: actions/checkout@v2
      - name: olm-bundle action
        id: bundle
        uses: darkowlzz/olm-bundle@master
        with:
          outputDir: my-operator/${{ github.event.inputs.version }}
          channels: stable,beta
          package: my-operator
          operatorRepo: https://github.com/example/someoperator
          operatorBranch: devel
          operatorManifestsDir: bundle/manifests
      - name: bundle tree output
        run: echo "${{ steps.bundle.outputs.tree }}"
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v3.4.0
```

This will clone the operator repo that contains the bundle and extract the
bundle manifests, use it to generate the versioned bundle at `outputDir` and
create a pull request with the changes.

## Action inputs

| Name | Description | Example value |
| --- | --- | --- |
| `manifestsDir` | Directory containing all the CRDs and CSVs for a bundle. | `bundle/manifests` |
| `outputDir` | Bundle version directory. Created if not exists. | `my-operator/0.3.0` |
| `channels` | Channels of the bundle. Comma separated channel names. | `stable` |
| `defaultChannel` | Default bundle channel name (optional, `stable` by default). | `stable` |
| `package` | OLM package name. | `my-operator` |
| `operatorRepo` | Operator git repo that contains the OLM manifests. | `https://github.com/example/my-operator` |
| `operatorBranch` | Operator git repo branch. | `devel` |
| `operatorManifestsDir` | Manifests dir in the operator git repo. | `bundle/manifests` |
| `dockerfileLabels` | Path to a file containing extra Dockerfile labels |

## Action outputs

### `tree`

Tree view of the versioned bundle directory after the changes:

```console
testdata/memcached/0.0.2
|-- manifests
|   |-- cache.example.com_memcachedpeers.yaml
|   |-- cache.example.com_memcacheds.yaml
|   +-- memcached-operator.clusterserviceversion.yaml
+-- metadata
    +-- annotations.yaml

2 directories, 4 files
```

## Using without github actions

### Container image

olm-bundle can be used with the container image
`ghcr.io/darkowlzz/olm-bundle:test`.

```console
$ docker run --rm \
	-v $PWD:/github/workspace \
	-e OUTPUT_DIR=<package-name>/<bundle-version> \
	-e CHANNELS=<channel-name> \
	-e PACKAGE=<package-name> \
	-e OPERATOR_REPO=<operator-repo> \
	-e OPERATOR_BRANCH=<operator-branch> \
	-e OPERATOR_MANIFESTS_DIR=<operator-manifests-dir> \
	-u "$(shell id -u):$(shell id -g)" \
	ghcr.io/darkowlzz/olm-bundle:test
```

This will generate the versioned bundle in `OUTPUT_DIR` on the host.

**NOTE**: Mounting to the working directory to `/github/workspace` is required
because the container image is made to work in github actions environment.

### Script

To use olm-bundle directly on host using the `generate.sh` script, install
[`opm`](https://github.com/operator-framework/operator-registry) first. The
bundle generation depends on `opm`. Ensure that it's available in the $PATH.
Run:

```console
$ MANIFESTS_DIR=path/to/source/bundle \
	OUTPUT_DIR=my-operator/0.3.0 CHANNELS=stable PACKAGE=my-operator \
	generate.sh
```

This will generate the versioned bundle in `OUTPUT_DIR` on the host.
