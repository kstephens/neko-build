#!/bin/sh 
set -x
#alias cd='builtin cd'
base_dir="$(cd -P "$(dirname "$0")/.." && /bin/pwd)"
export CFLAGS='-O2'
if [ -d /opt/local ]
then
  export CFLAGS="$CFLAGS -I/opt/local/include" LDFLAGS='-L/opt/local/lib'
fi
branch="$(basename "$(sed -e 's@ref: @@' $base_dir/ruby/.git/HEAD)")"
mkdir -p $base_dir/build/ruby
prefix="$(cd $base_dir/build && mkdir -p ruby/$branch && cd -P ruby/$branch && /bin/pwd)"
set -e
(
cd $base_dir/ruby
echo ./configure --prefix="${prefix}"
echo make clean
echo make
)

