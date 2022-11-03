#!/usr/bin/env bash
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
TMP_GIT_DIR="$ROOT/.git_tmp_repos"
CONTRACTS_MODULE_PATH="contracts_modules"

pre_check() {
 echo "Installing from Clarinet.json..."
 # check if file not exists
 if [ ! -f "$DIR/../Clarinet.json" ]; then
  echo "Clarity.json not found. abort..."
  exit 1
 fi

 # check if command jq is installed, if not, install jq
 if ! [ -x "$(command -v jq)" ]; then
  echo "jq not installed. Install it before continue. (brew install jq)..."
  exit 1
 fi
}

install_project() {
  project_name=${1//\"/}
  echo "Installing project...$project_name"
  commit=$(cat Clarinet.json | jq -cr ".dependencies.$project_name.commit")
  git_repo=$(cat Clarinet.json | jq -cr ".dependencies.$project_name.git")
  contracts_path=$(cat Clarinet.json | jq -cr ".dependencies.$project_name.contracts_path")

  echo "Installing from $git_repo, commit $commit, to $project_name"
  mkdir -p "$TMP_GIT_DIR"/"$project_name"


  echo git clone "$git_repo" "$TMP_GIT_DIR"/"$project_name"
  git clone "$git_repo" "$TMP_GIT_DIR"/"$project_name"
  pushd "$TMP_GIT_DIR"/"$project_name" > /dev/null
  echo git checkout "$commit"
  git checkout "$commit"
  popd > /dev/null

  mkdir -p "$ROOT/$CONTRACTS_MODULE_PATH"
  rm -rf "$ROOT/$CONTRACTS_MODULE_PATH/${project_name:?}"
  cp -r "$TMP_GIT_DIR"/"$project_name"/"$contracts_path" "$ROOT"/"$CONTRACTS_MODULE_PATH"/$project_name

  echo "cleaning..."
  rm -rf "$TMP_GIT_DIR"
  echo "installed $project_name"
}

install() {
  pre_check
  pushd "$DIR"/.. > /dev/null

  projects_str=$(cat Clarinet.json | jq -c ".dependencies | keys" | sed -e 's/\[//g' -e 's/\]//g' -e 's/\,/ /g')
  projects=($projects_str)

  for i in "${projects[@]}"; do
    install_project $i
  done

  echo installed all projects: $projects
}

clean() {
  rm -rf "$TMP_GIT_DIR"
  rm -rf "$ROOT/${CONTRACTS_MODULE_PATH:?}"
}

update() {
  project_name=$1
  branch=$2
  echo "Updating project...$project_name commit from branch head of [$branch]"

  git_repo=$(cat Clarinet.json | jq -cr ".dependencies.$project_name.git")
  contracts_path=$(cat Clarinet.json | jq -cr ".dependencies.$project_name.contracts_path")

  echo "Installing from $git_repo, to $project_name"
  mkdir -p "$TMP_GIT_DIR"/"$project_name"
  echo git clone "$git_repo" "$TMP_GIT_DIR"/"$project_name"
  git clone "$git_repo" "$TMP_GIT_DIR"/"$project_name"
  pushd "$TMP_GIT_DIR"/"$project_name" > /dev/null
  git checkout "$branch"
  current_commit=$(git show -s --format=%H)
  echo ------using commit------
  git log --format=%B -n 1 $(git log -1 --pretty=format:"%h")
  echo ------end commit------
  popd > /dev/null

  echo branch $branch has commit $current_commit
  cat <<< $(jq ".dependencies.$project_name.commit=\"$current_commit\"" Clarinet.json) > Clarinet.json

  echo "cleaning..."
  rm -rf "$TMP_GIT_DIR"
  echo "updated $project_name"
}

main() {
#   check if command is valid
  if [ "$1" == "install" ]; then
    install
  elif [ "$1" == "clean" ]; then
    clean
  elif [ "$1" == "update" ]; then
#    check if project and branch are provided
    if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
      echo "Usage: clarinet_manager.sh update <project> <branch>"
      exit 1
    fi
    update $2 $3
  else
    echo "Invalid command. Use: ./clarinet_manager.sh install | clean | update"
  fi
}

main $@