
function setup::ruby::ruby-install() {
  local dir=$(pwd)
  cd /tmp
  run "wget -O ruby-install-0.6.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.6.1.tar.gz"
  run "tar -xzvf ruby-install-0.6.1.tar.gz"
  cd ruby-install-0.6.1/
  run "sudo make install"
  cd ${dir}
}

function setup::ruby::install() {
  local version=${1:-${def_ruby_version}}

  [[ -z $(ruby-install --help 2>/dev/null) ]] && setup::ruby::ruby-install

  run "ruby-install ruby ${version}"
}
