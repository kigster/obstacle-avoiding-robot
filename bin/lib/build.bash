#!/usr/bin/env bash

function build::cmake(){
  [[ -z $root ]] && root=$(pwd)
  if [[ ${1} == 'clean' ]]; then
    run "rm -rf build"
    return
  fi
  export ignore_errors=0
  run "mkdir -p build"
  cd build
  opts_verbose=true
  run "cmake .."
  run "make $*"
  opts_verbose=
  cd ${root}
}

function build() {
  build::cmake $@
}

function help() {
  if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
    puts "usage: $0 ${txtgrn} [ clean | upload | make-flags ]${clr}"
    echo
    puts "   eg: $0 setup"
    puts "   eg: $0 clean"
    echo
    puts "   ${txtpur}or, without arguments it runs setup and build:"
    puts "   eg: $0"
    echo
    echo
    exit 1
  fi
}
