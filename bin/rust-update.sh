#!/bin/bash

if wget -O - https://static.rust-lang.org/dist/channel-rust-nightly.toml | grep rustfmt-preview > /dev/null
then
	rustup update nightly
else
	echo "Current nightly build not good" >&2
	exit 1
fi
