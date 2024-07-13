
export BUILDKITE_API_ENDPOINT="https://api.buildkite.com"
export BUILDKITE_API_DEBUG=0

function buildkite-curl-flags () {
  case "${BUILDKITE_API_DEBUG}" in
    0) echo "--silent" ;;
    1) echo "--verbose --trace-ascii /dev/stderr" ;;
  esac
}

function buildkite-stream () {
  jq -cn --stream 'fromstream(1|truncate_stream(inputs))'
}

function buildkite-fields () {
  local QUERY=""
  for FIELD in "${@}"; do
    QUERY="$QUERY \"${FIELD}\"  : .${FIELD},"
  done
  jq -r "{ ${QUERY} }"
}

function buildkite-token () {
  echo -n "${BUILDKITE_TOKEN}"
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

  curl $(buildkite-curl-flags)\
       --request GET \
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

  curl $(buildkite-curl-flags)\
       --request POST \
       --header 'Content-type: application/json' \
       --header 'Accept: application/json' \
       --header "Authorization: Bearer ${BUILDKITE_TOKEN}" \
       --data $DTA \
       "${BUILDKITE_API_ENDPOINT}${PTH}"
}

function buildkite-pipeline-show () {
  buildkite pipeline list | jq -r '.[] | "\(.slug):\(.name)"'
}

function buildkite-build-show () {
  buildkite build list $1 | jq -r '.[] | "\(.number):\(.message | split("\n")[:1] | .[] )"'
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
    'debug:Enable debugging curl commands'
    'init:Initialisation information'
    'pipeline:Manage pipelines'
    'build:Manage builds'
  )

  if (( CURRENT == 2 )); then
    _describe 'command' cmds
  elif (( CURRENT == 3 )); then
    case "$words[2]" in
      pipeline) subcmds=(
        'list:List all the pipelines'
        'show:Show a pipeline'
        )
        _describe 'command' subcmds ;;
      build) subcmds=(
        'list:List builds for a pipeline'
        'show:Show a build for a pipeline'
        'trigger:Trigger a build for a pipeline'
        )
        _describe 'command' subcmds ;;
    esac
  elif (( CURRENT == 4 )); then
      case "${words[1]}-${words[2]}-${words[3]}" in
          buildkite-pipeline-show)
            subcmds=("${(@f)$(buildkite-pipeline-show)}")
            _describe 'command' subcmds ;;
          buildkite-build-list)
            subcmds=("${(@f)$(buildkite-pipeline-show)}")
            _describe 'command' subcmds ;;
          buildkite-build-show)
            subcmds=("${(@f)$(buildkite-pipeline-show)}")
            _describe 'command' subcmds ;;
          buildkite-build-trigger)
            subcmds=("${(@f)$(buildkite-pipeline-show)}")
            _describe 'command' subcmds ;;
      esac
  elif (( CURRENT == 5 )); then
      case "${words[1]}-${words[2]}-${words[3]}" in
          buildkite-build-show)
            subcmds=("${(@f)$(buildkite-build-show ${words[4]})}")
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
  build

EOF
}

#####################################################################
# Init
#####################################################################

function _buildkite::init {

  if [ -n "${BUILDKITE_API_ENDPOINT}" ] && [ -n "${BUILDKITE_TOKEN}" ]; then
    echo "============================================="
    echo "BUILDKITE_API_ENDPOINT ..... ${BUILDKITE_API_ENDPOINT}"
    echo "BUILDKITE_ORG .............. ${BUILDKITE_ORG}"
    echo "BUILDKITE_TOKEN ............ ${BUILDKITE_TOKEN:0:4}***${BUILDKITE_TOKEN:${#BUILDKITE_TOKEN}-4}"
    echo "============================================="
  else
    echo "============================================="
    echo "Create a new access id and key pair and export;"
    echo "BUILDKITE_ORG=<organisation_slug>"
    echo "BUILDKITE_TOKEN=<generated_token>"
    echo "============================================="
    open "https://buildkite.com/user/api-access-tokens"
  fi
}

#####################################################################
# Debug
#####################################################################

function _buildkite::debug () {
  export BUILDKITE_API_DEBUG=$((1-BUILDKITE_API_DEBUG))
  echo "================================================================"
  echo "Toggle the buildkite api curl debug to [${BUILDKITE_API_DEBUG}]"
  echo "================================================================"
}

#####################################################################
# Pipeline
#####################################################################

function _buildkite::pipeline () {
  (( $# > 0 && $+functions[_buildkite::pipeline::$1] )) || {
    cat <<EOF
Usage: buildkite pipeline <command> [options]

Available commands:

  list
  show [pipeline]

EOF
    return 1
  }

  local command="$1"
  shift

  _buildkite::pipeline::$command "$@"
}

function _buildkite::pipeline::list () {
  buildkite-get "v2/organizations/${BUILDKITE_ORG}/pipelines?page=1&per_page=100"
}

function _buildkite::pipeline::show () {
  buildkite-get "v2/organizations/${BUILDKITE_ORG}/pipelines/${1:-"unknown"}"
}

#####################################################################
# Build
#####################################################################

function _buildkite::build () {
  (( $# > 0 && $+functions[_buildkite::build::$1] )) || {
    cat <<EOF
Usage: buildkite build <command> [options]

Available commands:

  list    [pipeline]
  show    [pipeline] [build]
  trigger [pipeline] <branch>

EOF
    return 1
  }

  local command="$1"
  shift

  _buildkite::build::$command "$@"
}

function _buildkite::build::list () {
  buildkite-get "v2/organizations/${BUILDKITE_ORG}/pipelines/${1:-"unknown"}/builds?page=1&per_page=10"
}

function _buildkite::build::show () {
  buildkite-get "v2/organizations/${BUILDKITE_ORG}/pipelines/${1:-"unknown"}/builds/${2:-"1"}"
}

function _buildkite::build::trigger () {
  local DATA="{ \"commit\": \"HEAD\", \"branch\": \"${2:-"master"}\" }"
  buildkite-post "v2/organizations/${BUILDKITE_ORG}/pipelines/${1:-"unknown"}/builds" "${DATA}"
}
