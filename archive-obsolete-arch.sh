#!/bin/bash
#
# Copyright © 2004 Guillem Jover <guillem@debian.org>
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

. archive-lib

target_arch=$1

dir=$dists_dir/unstable/main
target_arch_dir=$obsolete_dir/$target_arch

echo "-> Obsoleting arch: $target_arch"

cat $cache_dir/$target_arch.list | while read file
do
  echo " -> Obsoleting: $file"
  target_dir=`dirname $file`
  mkdir -p $target_arch_dir/$target_dir
  mv $pool_dir/$file $target_arch_dir/$target_dir
done

echo " done."
