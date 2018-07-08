#!/usr/bin/env bash
##———————————————————————————————————————————————————————————————————————————————
## © 2016-2017 Author: Konstantin Gredeskoul
## Ported from the licensed under the MIT license Project Pullulant, at
## https://github.com/kigster/pullulant
##———————————————————————————————————————————————————————————————————————————————

function lib::run::env() {

  export run_stdout=/tmp/bash-run.$$.stdout
  export run_stderr=/tmp/bash-run.$$.stderr

  export commands_ignored=${commands_ignored:-0}
  export commands_failed=${commands_failed:-0}
  export commands_completed=${commands_completed:-0}

  export command_exit_code=0
  export ignore_errors=${ignore_errors:-0}
}

function lib::run::cleanup() {
  rm -f ${run_stdout}
  rm -f ${run_stderr}
}

function run() {
  lib::run $@
}

# To print and not run, set ${opts_dryrun}
function lib::run() {
  local cmd="$*"

  lib::run::env

  if [[ -n "${opts_dryrun}" ]]; then
    [[ "${cmd}"  =~ "printf" ]]  && eval "${cmd} 2>${run_stderr}"
    [[ "${cmd}"  =~ "printf" ]]  || info "[opts_dryrun]  ${txtgrn}${cmd}${txtrst}\n"
  else
    lib::run::exec "${cmd}"
  fi

  return ${command_exit_code}
}

function lib::run::exec() {
  local cmd=$*

  # print the actual STDOUT if present, or nothing when captured
  printf "${txtblu}"

  set +e
  if [[ ${opts_verbose} ]]; then
    hr
    printf "❯❯ ${bldylw}%-50.50s  \n" "${cmd}"
    printf "${txtgrn}"
    eval "${cmd} 2>${run_stderr} | tee -a ${run_stdout}"
  else
    printf "❯❯ ${bldylw}%-50.50s ${bldblu} ⇨ " "${cmd}"
    eval "${cmd} 2>${run_stderr} 1>${run_stdout}"
  fi

  real_status=$?
  command_exit_code=${real_status}

  if [[ ${command_exit_code} == 0 ]];  then
    if [[ ${opts_verbose} ]]; then
      printf "${bldblu}❯❯ ${bldylw}%s" "${cmd}"
      ok:
    else
      ok:
    fi
    commands_completed=$(($commands_completed + 1))
  else
    not_ok:
    if [[ -n "${ignore_error}" ]];  then
      command_exit_code=0
      commands_ignored=$(($commands_ignored + 1))
    else
      commands_failed=$(($commands_failed + 1))
    fi
  fi

  if [[ ${command_exit_code} != 0 ]];  then
    stderr ${run_stderr}
  fi

  lib::run::cleanup

  return ${command_exit_code}
}
