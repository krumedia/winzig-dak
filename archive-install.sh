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

#
# Requires: apt-utils
#

# Import library

. archive-lib.sh

# file output

pool_install ()
{
  local archive_file=$(realpath $1)
  local changes_file=$(dirname $archive_file)/$(basename $archive_file archive)changes
  local section=$(basename $(dirname $archive_file))
  local package=`fetch_source_name < $archive_file`
  local arch=`fetch_single_arch < $archive_file`
  local dest_dir=`poolize_arch_name $package $arch $section`
  
  cd $(dirname $archive_file)

  if [ ! -d "$dest_dir" ]; then
    mkdir -p $dest_dir
  fi

  if archive_move $archive_file $dest_dir; then

    mkdir -p ${cache_dir}/changes/${section}
    mv -f $changes_file ${cache_dir}/changes/${section}

    log install "install_success ${archive_file##*/}"
    cd $OLDPWD
    return 0
  else
    script_error "$?"
    log install "install_failed ${archive_file##*/}"
    cd $OLDPWD
    return 1
  fi
}

# message output

script_error ()
{
  # FIXME: message should be nicer than that
  log install "$1" | echo mail -s "Error in `basename $0`" $archive_maint
}

#
# Main
#

main_pwd=$(pwd)
cd $accepted_dir

shopt -s nullglob

for archive_file in */*.archive; do
    pool_install "$archive_file"
    rm $archive_file

    INSTALLED=yes
done

cd $main_pwd

if [ "$INSTALLED" = "yes" ]; then
  ./archive-changes-lists.sh
  ./archive-reindex-files.sh
  ./archive-reindex-meta.sh
fi
