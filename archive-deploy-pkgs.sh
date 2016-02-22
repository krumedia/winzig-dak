#!/bin/bash
#
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
# Requires: zip
#

# Import library

. archive-lib.sh

deploy_archive()
{
  local archive_file=$(realpath $1)
  local changes_file=$(dirname $archive_file)/$(basename $archive_file archive)changes
  local section=$(basename $(dirname $archive_file))
  local package=`fetch_source_name < $archive_file`
  
  cd $(dirname $archive_file)

  local section=$(basename $(dirname $archive_file))
  local files=`fetch_files < $archive_file`

  for deployment in $deployments; do
    dest=$deployment_dir/$deployment/$section/$package
	dest_changes_file=$dest/$(basename $archive_file archive)changes
    mkdir -p $dest
    cp $archive_file $dest_changes_file
    pattern=$(eval echo \"\$deployment_regex_${deployment}\")
    for file in $files; do
      if echo $file | grep -q -P "$pattern"; then
        echo $file
		cp $file $dest
      else
	    sed -i "/$file/d" $dest_changes_file
      fi
    done
	sed -i "/Signed-By/d" $dest_changes_file
	sed -i "/From foo@bar/d" $dest_changes_file
	gpg --clearsign $dest_changes_file
	mv $dest_changes_file{.asc,}
	zip -q $dest/$(basename $archive_file archive)zip $dest/*
  done
}

main_pwd=$(pwd)
cd $accepted_dir

shopt -s nullglob

for archive_file in */*.archive; do
echo $archive_file
    deploy_archive "$archive_file"
done

cd $main_pwd