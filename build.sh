#!/bin/sh 
# git clone http://github.com/kstephens/neko-build

_prereqs() {
  if [ -d /opt/local ]
    sudo port install autoconf bison ruby gdbm readline
  else
    sudo apt-get install autoconf bison ruby libgdbm-dev libreadline-dev
  fi
}

_clone() {
   (
   cd $base_dir
   [ -d ruby ]      || git clone git@github.com:kstephens/ruby.git
   [ -d rubyspec ]  || git clone http://github.com/rubyspec/rubyspec
   [ -d smal ]      || git clone git@github.com:kstephens/smal.git
   [ -d integrity ] || git clone https://github.com/integrity/integrity.git
   ) || exit $?
}

_update() {
   (
   cd $base_dir
   for f in ruby rubyspec smal integrity
   do
     (cd $d && git pull) || exit $?
   done
   ) || exit $?
}

_build() {
  (
  cd $base_dir/ruby
  export CFLAGS='-O2'
  if [ -d /opt/local ]
  then
    export CFLAGS="$CFLAGS -I/opt/local/include" LDFLAGS='-L/opt/local/lib'
  fi
  [ -f ./configure ] || autoconf
  ./configure --prefix="$ruby_prefix"
  make clean
  make
  make test
  ) || exit $?
}

_get_ruby_branch() {
if [ -z "$ruby_branch" ]
then
  if [ -d "$base_dir/ruby" ]
  then
    ruby_branch="$(basename "$(sed -e 's@ref: @@' $base_dir/ruby/.git/HEAD)")"
    mkdir -p $base_dir/build/ruby
    ruby_prefix="$(cd $base_dir/build && mkdir -p ruby/$ruby_branch && cd -P ruby/$ruby_branch && /bin/pwd)"
    # exec 2>&1 > "$base_dir/ruby/build.log"
  fi
fi
}

set -x
#alias cd='builtin cd'
base_dir="$(cd -P "$(dirname "$0")/.." && /bin/pwd)"

set -e
while [ $# -gt 0 ]
do
  action="$1"; shift
  _get_ruby_branch
  "_${action}" || exit $?
done

echo "OK"
exit 0
