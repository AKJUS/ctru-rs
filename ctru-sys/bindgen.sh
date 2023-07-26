#!/usr/bin/env bash

set -euo pipefail

echo "Determining libctru version..."
pacman=dkp-pacman
if ! command -v $pacman &>/dev/null; then
    pacman=pacman
    if ! command -v $pacman &>/dev/null; then
        echo >&2 "ERROR: Unable to automatically determine libctru version!"
        exit 1
    fi
fi

LIBCTRU_VERSION="$($pacman -Qi libctru | grep Version | cut -d: -f 2 | tr -d ' ')"

CTRU_SYS_VERSION="$(
    printf '%s' "$LIBCTRU_VERSION" |
    cut -d- -f1 |
    sed -E 's/^([0-9]+)\.([0-9.]+)$/\1\2/'
)"

echo "Generating bindings.rs..."
cargo run --package bindgen-ctru-sys > src/bindings.rs

echo "Formatting generated files..."
cargo fmt --all

echo "Compiling static inline wrappers..."
arm-none-eabi-gcc -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft \
    -I${DEVKITPRO}/libctru/include \
    -I${DEVKITPRO}/libctru/include/3ds \
    -O -c -o extern.o /tmp/bindgen/extern.c
arm-none-eabi-ar -rcs libextern.a extern.o
rm extern.o


echo "Generated bindings for ctru-sys version \"${CTRU_SYS_VERSION}.x+${LIBCTRU_VERSION}\""
