#####################################################################
# Init
#####################################################################

export BUILDKITE_API_ENDPOINT="https://api.buildkite.com"

function buildkite-del () {
  local PTH=""

  if [[ -n "${1}" ]]; then
    PTH="/${1}"
  fi

  curl --request DELETE \
       --silent \
       --header 'Accept: application/json' \
       --header "Authorization: Bearer ${BUILDKITE_TOKEN}" \
       "${BUILDKITE_API_ENDPOINT}${PTH}"
}

function buildkite-get () {
  local PTH="" #${1:-""}
  local QRY="" #${2:-""}

  if [[ -n "${1}" ]]; then
    PTH="/${1}"
  fi

  if [[ -n "${2}" ]]; then
    QRY="?${2}"
  fi

  curl --request GET \
       --silent \
       --header 'Accept: application/json' \
       --header "Authorization: Bearer ${BUILDKITE_TOKEN}" \
       "${BUILDKITE_API_ENDPOINT}${PTH}${QRY}"
}

function buildkite-post () {
  local PTH=${1:-""}
  local DTA=${2:-"{}"}

  if [[ -n "${1}" ]]; then
    PTH="/${1}"
  fi

  curl --request POST \
       --silent \
       --header 'Content-type: application/json' \
       --header 'Accept: application/json' \
       --header "Authorization: Bearer ${BUILDKITE_TOKEN}" \
       --data $DTA \
       "${BUILDKITE_API_ENDPOINT}${PTH}"
}

function buildkite () {
  [[ $# -gt 0 ]] || {
    _buildkite::help
    return 1
  }

  local command="$1"
  shift

  (( $+functions[_buildkite::$command] )) || {
    _buildkite::help
    return 1
  }

  _buildkite::$command "$@"
}

function _buildkite {
  local -a cmds subcmds
  cmds=(
    'help:Usage information'
    'init:Initialisation information'
    'pipeline:Manage pipelines'
  )

  if (( CURRENT == 2 )); then
    _describe 'command' cmds
  elif (( CURRENT == 3 )); then
    case "$words[2]" in
      pipeline) subcmds=(
        'list:list all the pipelines'
        )
        _describe 'command' subcmds ;;
    esac
  fi

  return 0
}

compdef _buildkite buildkite

function _buildkite::help {
    cat <<EOF
Usage: buildkite <command> [options]

Available commands:

  pipeline

EOF
}

function _buildkite::init {
  echo "============================================="
  echo "Create a new access id and key pair and export\n  BUILDKITE_ORG=<organisation_slug>\n  BUILDKITE_TOKEN=<generated_token>"
  echo "============================================="
  open "https://buildkite.com/user/api-access-tokens"
}

#####################################################################
# User
#####################################################################

function _buildkite::pipeline () {
  (( $# > 0 && $+functions[_buildkite::pipeline::$1] )) || {
    cat <<EOF
Usage: buildkite pipeline <command> [options]

Available commands:

  list

EOF
    return 1
  }

  local command="$1"
  shift

  _buildkite::pipeline::$command "$@"
}

function _buildkite::pipeline::list () {
  buildkite-get "v2/organizations/${BUILDKITE_ORG}/pipelines"
}
