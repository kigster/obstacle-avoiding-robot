
function setup::git() {
  if [[ -d ${dep_dir} ]]; then
    cd ${dep_dir}
    run "git pull --rebase"
    cd - >/dev/null
  else
    run "git clone ${dep_url} ${dep_dir}"
  fi
}

function setup::symlinks() {
  for file in $(ls -1 ${dep_dir}/cmake); do
    cd cmake
    rm -rf ${file}
    run "ln -nfs ./.arduino-cmake/cmake/$file"
    cd - > /dev/null
  done
}

function setup::install::arli() {
  local ruby_version=$(ruby --version 2>/dev/null | awk '{print $2}')

  if [[ -z ${ruby_version} || ! ${ruby_version} =~ '2.' ]]; then
    info "Installing Ruby ${def_ruby_ver}"
    setup::ruby::install "${def_ruby_ver}"
  fi

  if [[ -z $(gem list | egrep '^arli ') ]] ; then
    if [[ $(which gem) =~ '/usr/' ]]; then
      info "Please enter your password to install arli gem with sudo:"
      run "sudo gem install arli --no-rdoc --no-ri"
    else
      run "gem install arli --no-rdoc --no-ri"
    fi
  fi
}

function setup() {
  setup::install::arli
  setup::git
  setup::symlinks
}
