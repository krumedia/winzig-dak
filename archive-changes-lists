#!/bin/bash
#
# Copyright © 2003, 2004, 2005 Guillem Jover <guillem@debian.org>
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

#
# Main
#

echo_time "-> Collecting .changes files lists..."
for arch in $(get_archive_arches); do
  echo_time " -> Collecting .changes files list... [$arch]"
  find $(get_pool_dir_arch $arch) -name '*.changes' | changes_canonic | \
    sort > $cache_dir/changes_$arch.list
done

echo_time "-> Done."
