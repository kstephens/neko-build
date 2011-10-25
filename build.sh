#!/bin/sh 
# git clone http://github.com/kstephens/neko-build

run() {
 cmd="$*"
 echo "+ $@"
 "$@"
}

repos="ruby mspec rubyspec smal integrity"
ruby_origin="git@github.com:kstephens/ruby.git"
mspec_origin="http://github.com/rubyspec/mspec.git"
rubyspec_origin="http://github.com/rubyspec/rubyspec.git"
smal_origin="git@github.com:kstephens/smal.git"
integrity_origin="http://github.com/integrity/integrity.git"
ruby_branch="trunk-mem-api"
DEFAULT_branch="master"

get_repo_info() {
  repo="$1"
  eval origin="\$${repo}_origin"
  eval branch="\$${repo}_branch"
  branch="${branch:-$DEFAULT_branch}"
}

git_clone() {
  get_repo_info "$1"
  [ -d "$repo" -a -d "$repo/.git" ] || run git clone "$origin" "$repo"
}

get_ruby_info() {
if [ -z "$ruby_branch_current" ]
then
  if [ -d "$base_dir/ruby" ]
  then
    ruby_branch_current="$(basename "$(sed -e 's@ref: @@' $base_dir/ruby/.git/HEAD)")"
    mkdir -p $base_dir/build/ruby
    ruby_prefix="$(cd $base_dir/build && mkdir -p ruby/$ruby_branch_current && cd -P ruby/$ruby_branch_current && /bin/pwd)"
    # exec 2>&1 > "$base_dir/ruby/build.log"
  fi
fi
}

####################################
# Actions
#

_selfupdate() {
  run git pull && set -- && "$0" "$@"
}

_prereqs() {
  if [ -d /opt/local ]
  then
    run sudo port install autoconf bison ruby gdbm readline openssl zlib yaml libffi # ??? libyaml-dev
  else
    run sudo apt-get install autoconf bison ruby libgdbm-dev libreadline-dev libssl-dev zlib1g-dev libyaml-dev libffi-dev
  fi
}

_clone() {
   (
   cd $base_dir
   for repo in $repos
   do
     git_clone "$repo"
   done
   ) || exit $?
}

_update() {
   (
   cd $base_dir
   for repo in $repos
   do
     get_repo_info "$repo"
     (
       run cd "$repo"
       run git checkout "$branch" || 
       (
	 run git fetch origin
         run git branch --track "$branch" origin/"$branch"
         run git checkout "$branch"
       ) || exit $?
       run git pull origin "$branch"
     ) || exit $?
   done
   ) || exit $?
}

_configure() {
  get_ruby_info
  (
  cd $base_dir
  run cd ruby
  export CFLAGS='-O2'
  if [ -d /opt/local ]
  then
    export CFLAGS="$CFLAGS -I/opt/local/include" LDFLAGS='-L/opt/local/lib'
  fi
  [ -f ./configure ] || run autoconf
  run ./configure --prefix="$ruby_prefix"
  run make clean
  )
}

_clean() {
  (
  cd $base_dir
  run cd ruby
  run make clean
  )
}

_build() {
  (
  cd $base_dir
  run cd ruby
  run make # make ruby to avoid building rdocs.
  run make install
  ) || exit $?
}

_test() {
  (
  cd $base_dir
  run cd ruby
  run make test
  run make test-all
  ) || exit $?
}

_rubyspec() {
  (
  cd $base_dir
  run cd rubyspec
  PATH="$base_dir/mspec/bin:$PATH"
  PATH="$base_dir/ruby/bin:$PATH"
  run mspec -t "$ruby_prefix/bin/ruby"
  ) || exit $?
}

_setup() {
  prereqs
  clone
}

_help() {
 cat <<EOF
actions:

selfupdate - updates this script via git pull
prereqs    - install system prerequisites
clone      - git clone repos
update     - git pull repos
configure  - ./configure Ruby.
clean      - Clean ruby.
build      - Build ruby.
test       - Run basic ruby test.
rubyspec   - Run rubyspec tests using mspec.

EOF
}

# set -x
#alias cd='builtin cd'
base_dir="$(cd -P "$(dirname "$0")/.." && /bin/pwd)"

set -e
while [ $# -gt 0 ]
do
  action="$1"; shift
  get_ruby_info
  "_${action}" || exit $?
done

echo "OK"
exit 0
