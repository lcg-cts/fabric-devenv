#!/usr/bin/env bash

set -o errexit
set -o pipefail

if [ -z $1 ]; then
  HLF_VERSION=1.4.1
else
  HLF_VERSION=$1
fi

CA_VERSION=$HLF_VERSION
THIRDPARTY_IMAGE_VERSION=0.4.15

if [ ${HLF_VERSION:0:4} = '2.0.' ]; then
  SAMPLE_BRANCH=master
else
  SAMPLE_BRANCH=v${HLF_VERSION}
fi

# Install NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] || curl --silent --show-error -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.3/install.sh | bash
. "$NVM_DIR/nvm.sh"

# Install node and npm
DEFAULT_NODE_VERSION=8.9.0
nvm which ${DEFAULT_NODE_VERSION} >/dev/null 2>&1 || nvm install ${DEFAULT_NODE_VERSION}

nvm use ${DEFAULT_NODE_VERSION}
nvm alias default ${DEFAULT_NODE_VERSION}
echo "default" > $HOME/.nvmrc

# Install a few useful node modules
npm ls -g yo >/dev/null 2>&1 || npm install -g yo
npm ls -g generator-fabric >/dev/null 2>&1 || npm install -g generator-fabric
npm ls -g hlf-cli >/dev/null 2>&1 || npm install -g hlf-cli

# Install Hyperledger Fabric binaries and docker images
if [ ! -d "$HOME/fabric" ]; then
  mkdir -p "$HOME/fabric"
  pushd "$HOME/fabric"
  sg docker "curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/be235fd3a236f792a525353d9f9586c8b0d4a61a/scripts/bootstrap.sh | bash -s -- $HLF_VERSION $CA_VERSION $THIRDPARTY_IMAGE_VERSION -s"
  popd
fi

# Set up Go workspace
if [ ! -d "$HOME/go/src" ]; then
  mkdir -p "$HOME/go/src"
fi

# Clone Hyperledger Fabric into Go workspace
if [ ! -d "$HOME/go/src/github.com/hyperledger/fabric" ]; then
  mkdir -p "$HOME/go/src/github.com/hyperledger"
  pushd "$HOME/go/src/github.com/hyperledger"
  git clone --branch v${HLF_VERSION} --depth 1 https://github.com/hyperledger/fabric.git
  popd
fi

# Clone Hyperledger Fabric Samples into Go workspace
if [ ! -d "$HOME/go/src/github.com/hyperledger/fabric-samples" ]; then
  mkdir -p "$HOME/go/src/github.com/hyperledger"
  pushd "$HOME/go/src/github.com/hyperledger"
  git clone --branch ${SAMPLE_BRANCH} --depth 1 https://github.com/hyperledger/fabric-samples.git
  popd
fi

# Add symlink to Fabric Samples
if [ ! -h "$HOME/fabric-samples" ]; then
  ln -s "$HOME/go/src/github.com/hyperledger/fabric-samples" "$HOME/fabric-samples"
fi

# Create a test network for Hyperledger Fabric
if [ ! -d "$HOME/test-network" ]; then
  mkdir -p "$HOME/test-network"
  pushd "$HOME/test-network"
  yo fabric:network -- --name test-network --dockerName testnetwork --orderer 7050 --peerRequest 7051 --peerChaincode 7052 --certificateAuthority 7054 --couchDB 7055 --logspout 7056
  popd
fi
