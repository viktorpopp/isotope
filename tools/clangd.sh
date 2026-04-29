#!/usr/bin/env bash

# Generate a clangd configuration

echo "CompileFlags:" > .clangd
echo "  Add:" >> .clangd

OUTPUT="$(pwd)"
echo "    - -I${OUTPUT}/lib" >> .clangd
