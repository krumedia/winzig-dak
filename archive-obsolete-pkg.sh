#!/bin/bash
#
# Copyright © 2004-2007 Guillem Jover <guillem@debian.org>
# Copyright © 2015 Matthias Blümel <blaimi@blaimi.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Import library

. archive-lib.sh

echo "-> Obsoleting packages:"

shopt -s nullglob

# the arguments have the form: arch pkgname...

arch=$1
shift

obsolete_pkg_arch ()
{
  arch=$1
  pkg=$2

  srcdir=`poolize_arch_name $pkg $arch`
  dstdir=$obsolete_dir/`date -I`/$pkg

  if [ -d $srcdir ]; then
    cd $srcdir
  else
    echo " -> warning: package '$pkg' does not exist"
    return
  fi

  changes=`ls $pkg*.changes | sort -n`
  echo " -> full list:"
  echo "$changes"

  for changes_file in $changes; do
    srcfiles=`changes_strip < $changes_file | fetch_files`

    echo "  -> $changes_file"
    echo "$srcfiles"
    echo

    echo "  -> confirm obsolescence? [y|n]"
    read

    if [ "$REPLY" = y ]; then
      echo "  -> proceeding ..."
      mkdir -p $dstdir
      mv $changes_file $srcfiles $dstdir
    fi
  done
}

for pkg do
  echo " -> package: '$pkg'"

  if [ "$arch" = any ]; then
    for a in $(get_archive_arches); do
      obsolete_pkg_arch $a $pkg
    done
  else
    obsolete_pkg_arch $arch $pkg
  fi
done

echo " -> Done."
