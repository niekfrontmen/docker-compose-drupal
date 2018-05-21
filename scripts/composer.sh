#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Helper to execute Composer as a standalone docker container.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   composer.sh
#
# Depends on:
#  docker
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

# Short form: set -u
set -o nounset

# Exit immediately if a pipeline returns non-zero.
set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above.
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Allow the above trap be inherited by all functions in the script.
# Short form: set -E
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set IFS to just newline and tab at the start
SAFER_IFS=$'\n\t'
IFS="${SAFER_IFS}"

###############################################################################
# Environment
###############################################################################

# $_ME
#
# Set to the program's basename.
_ME=$(basename "${0}")

# $_SOURCE
#
# Set to the program's source.
_SOURCE="${BASH_SOURCE[0]}"

###############################################################################
# Die
###############################################################################

# _die()
#
# Usage:
#   _die printf "Error message. Variable: %s\n" "$0"
#
# A simple function for exiting with an error after executing the specified
# command. The command is expected to print a message and should typically
# be either `echo`, `printf`, or `cat`.
_die() {
  # Prefix die message with "cross mark (U+274C)", often displayed as a red x.
  printf "❌  "
  "${@}" 1>&2
  exit 1
}
# die()
#
# Usage:
#   die "Error message. Variable: $0"
#
# Exit with an error and print the specified message.
#
# This is a shortcut for the _die() function that simply echos the message.
die() {
  _die echo "${@}"
}

###############################################################################
# Help
###############################################################################

# _print_help()
#
# Usage:
#   _print_help
#
# Print the program help information.
_print_help() {
  cat <<HEREDOC
  ____   ____   ____                         _
 |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
 | | | | |     | | | | '__| | | | '_ \ / _  | |
 | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
 |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
                                |_|

Helper to execute Composer as a standalone docker container, see
https://getcomposer.org/doc/03-cli.md for commands details.
For require command it's recommended to use --ignore-platform-
and --no-scripts options.

Usage:
  ${_ME} [status | require | remove | outdated | ... ]
  ${_ME} -h | --help

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Program Variables
###############################################################################

_DRUPAL_ROOT="/drupal"
_BASE_SOURCE=$(pwd)
_BASE_SOURCE=${_BASE_SOURCE%/scripts}

# Check where this script is run to fix base path.
if [[ "${_SOURCE}" = ./${_ME} ]]
then
  _BASE_PATH="../"
elif [ "${_SOURCE}" = scripts/"${_ME}" ] || [ "${_SOURCE}" = ./scripts/"${_ME}" ]
then
  _BASE_PATH="./"
else
  die "This script must be run within DCD project. Invalid command : ${_SOURCE} $0"
fi

source "${_BASE_PATH}.env"

_DRUPAL_ROOT=$(echo "${_BASE_SOURCE}${HOST_WEB_ROOT}${_DRUPAL_ROOT}" | sed -e 's/\.//g')

_DOCKER=$(which docker)

tty=
tty -s && tty=--tty

###############################################################################
# Program Functions
###############################################################################

_check_dependencies() {

  if ! [ -x "$(command -v docker)" ]; then
    die "Docker is not installed. Please install to use this script.\n"
  fi

}

###############################################################################
# Main
###############################################################################

# _main()
#
# Usage:
#   _main [<options>] [<arguments>]
#
# Description:
#   Entry point for the program, handling basic option parsing and dispatching.
_main() {

  _check_dependencies

  # Avoid complex option parsing when only one program option is expected.
  if [[ "${1:-}" =~ ^-h|--help$  ]]
  then
    _print_help
  else
    $_DOCKER run \
      $tty \
      --interactive \
      --rm \
      --user "${LOCAL_UID}":"${LOCAL_GID}" \
      --volume /etc/passwd:/etc/passwd:ro \
      --volume /etc/group:/etc/group:ro \
      --volume "${_DRUPAL_ROOT}":/app \
        composer --working-dir=/app "$@"
  fi

}

# Call `_main` after everything has been defined.
_main "$@"