#!/usr/bin/env bash
set -eu
set -o pipefail

if ! ver=$(./openapi-generator-cli version | tail -1); then
  ver="4.3.1"  
  echo "Use default version ${ver} to validate"
fi

for entry in ./public/doc/openapi-3-v*.json
do
  OPENAPI_GENERATOR_VERSION=${ver} ./openapi-generator-cli validate -i "$entry"
done
