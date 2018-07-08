#!/usr/bin/env bash

hdr1() {
  printf "${txtblk}${bakylw}\n$*${clr}\n${clr}"
}

hdr2() {
  printf "\n${bldylw}$*${clr}\n"
}

hdr() {
  hdr1 $@
}

ok() {
  printf " ${bldgrn} ✔︎ ${clr}"
}

not_ok() {
  printf " ${bldred} ✖ ${clr}"
}

stdout() {
  local file=$1
  printf "\n${txtblu}"
  if [[ -f ${file} ]]; then
    cat ${file}
  fi

  [[ -n ${file} ]] && printf "${clr}\n"
}

stderr() {
  local file=$1
  printf "\n${txtred}"

  if [[ -f ${file} ]]; then
    cat ${file}
  fi

  [[ -n ${file} ]] && printf "${clr}\n"
}

ok:() {
  ok
  echo
}

not_ok:() {
  not_ok
  echo
}

run() {
  local args=$*
  info " run [${bldylw}$*${clr}] "
  echo
  $args
}

warn() {
  printf "\n ⇨  ${txtylw}WARN:${clr} $*${clr}"
}

inf() {
  printf "\n ⇨  ${bldgrn}INFO:${clr} $*${clr}"
}

info() {
  inf $@
}

puts() {
  printf "\n ⇨  ${txtblu}$*${clr}"
}

err() {
  printf "\n ⇨  ${blderr}:${clr} $*${clr}"
}

error() {
  err $@
}

unalias hr 2>/dev/null

function hr() {
  wrap=${1:-true}
  local hrcolor=${bldblu}

  printf "${hrcolor}————————————————————————————————————————————————————————————${clr}"
  ( $wrap ) && printf "\n"
}

set +e
