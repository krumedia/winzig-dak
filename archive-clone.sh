#!/bin/bash
#
# Copyright © 2015 Matthias Blümel <bluemel@krumedia.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

#
# Requires: wget
#

# Import library

. archive-lib.sh

# TODO: move to rsync instead of wget

if [ ! -e clone.list ]; then
	exit 0
fi

rm $cache_dir/mirror_*.list

cat clone.list | while read suite arch package; do
	dest_dir=$(poolize_arch_name $package $arch)
	if [ ! -d "$dest_dir" ]; then 
		mkdir -p $dest_dir
	fi
	
	source_dir=${debian_archive}pool/$(poolize_arch_name_relative $package $arch)
	wget -e robots=off -nH --cut-dirs=5 -c -r --no-parent ${source_dir} -P $dest_dir -R "index.html*"
	
	find $dest_dir -type f | sort >> $cache_dir/mirror_${suite}_${arch}.list
	
done

./archive-reindex-files.sh
./archive-reindex-meta.sh
