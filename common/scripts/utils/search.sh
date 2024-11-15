#!/usr/local/bin/bash

set -e

search() {
	open -a "Firefox" "$*"
}

google() {
	google="https://www.google.com/search?q="
	search "$google$*"
}

github() {
	github="https://github.com/search?q="
	search "$github$*&type=repositories"
}


help() {
	cat <<-_EOF_
		Browser Search Utils 🌏

		search [command|args] :
			-gt --github search repositories
			-go --google search content
			-h  --help for help information

		Requirement :
		browser: by default brave
	_EOF_
}

if [ "$1" == "-gt" ] || [ "$1" == "--github" ]; then
	github "${@:2}"
	exit
elif [ "$1" == "-go" ] || [ "$1" == "--google" ]; then
	google "${@:2}"
	exit
elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	help "${@:2}"
	exit
elif [ -n "$1" ]; then
	echo "search not found 🙅"
	echo "search --help for information 💁"
	exit
else
	echo "search not found 🙅"
	echo "search --help for information 💁"
fi