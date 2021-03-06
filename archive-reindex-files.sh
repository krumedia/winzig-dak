#!/bin/bash
#
# Copyright © 2003-2007 Guillem Jover <guillem@debian.org>
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

#
# Main
#

echo_time "-> Regenerating file lists..."
for arch in $(get_archive_arches); do
  echo_time " -> Regenerating file list.. [$arch]"
  cat $cache_dir/changes_$arch.list | while read package suite section arch version path; do
    archive_file=`changes_strip < $path`
    basedir=$(poolize_package_name ${package} ${section})
    files=`echo "$archive_file" | fetch_files`
    filepaths=`echo "$files" | sed -e "s:^ *:$basedir/:"`

    echo "$filepaths" | grep "_\($arch\|all\)\.deb" \
      >> $cache_dir/dists/${suite}_${section}_$arch.list.new
    echo "$filepaths" | grep "_\($arch\|all\)\.udeb" \
      >> $cache_dir/dists/${suite}_${section}_$arch.di.list.new
  done
done

echo_time '-> Merging mirrored files into suite file lists ...'
for listname in ${cache_dir}/dists/*-mirror*.list; do
  suite=$(basename ${listname} .list | cut -d'_' -f 1)
  section=$(basename ${listname} .list | cut -d'_' -f 2)
  arch=$(basename ${listname} .list | cut -d'_' -f 3)
  grep '\.deb$' $listname \
    >> $cache_dir/dists/${suite%-mirror}_${section}_${arch}.list.new
  grep '\.udeb$' $listname \
    >> $cache_dir/dists/${suite%-mirror}_${section}_${arch}.di.list.new
done

echo_time '-> Merging arch:all files into suite file lists ...'
# FIXME: Hardcoded suite
for suite in $suite_list; do
  for arch in $(filter_real_arches $(get_suite_arches $suite)); do
    for section in ${section_list}; do
      grep '\.deb$' $cache_dir/dists/${suite}_${section}_all.list.new \
        >> $cache_dir/dists/${suite}_${section}_$arch.list.new
      grep '\.udeb$' $cache_dir/dists/${suite}_${section}_all.list.new \
        >> $cache_dir/dists/${suite}_${section}_$arch.di.list.new
    done
  done
done

echo_time "-> Moving new file lists into place..."
for suite in $suite_list; do
  for arch in $(get_suite_arches $suite); do
    for section in ${section_list}; do
      touch $cache_dir/dists/${suite}_${section}_$arch.list.new
      mv -f $cache_dir/dists/${suite}_${section}_$arch.list.new \
            $cache_dir/dists/${suite}_${section}_$arch.list
      touch $cache_dir/dists/${suite}_${section}_$arch.di.list.new
      mv -f $cache_dir/dists/${suite}_${section}_$arch.di.list.new \
            $cache_dir/dists/${suite}_${section}_$arch.di.list
    done
  done
done

echo_time "-> Done."
