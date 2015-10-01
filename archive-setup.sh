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

. archive-lib.sh

create_apt_config ()
{
  cat > $apt_config <<-HERE
	Default {
	  Packages::Extensions	".deb";
	  Packages::Compress	". gzip bzip2";
	  Sources::Compress	". gzip bzip2";
	  MaxContentsChange	25000;
	};

	APT::FTPArchive::Release {
	  Version		"$archive_version";
	  Origin		"$archive_name";
	  Label			"$archive_url";
	}

	Dir {
	  ArchiveDir		"$archive_dir";
	  OverrideDir		"$indices_dir";
	  CacheDir		"$cache_dir";
	  FileListDir		"$cache_dir";
	};

	TreeDefault {
	  Directory		"pool-\$(ARCH)/";
	  SrcDirectory		"pool/";
	  FileList		"\$(DIST)_\$(SECTION)_\$(ARCH).list";
	};
	
HERE

  for suite in $suite_list; do
    cat >> $apt_config <<-HERE
	Tree "dists/$suite" {
	  Sections		"$(get_suite_sections $suite)";
	  Architectures		"$(get_suite_arches $suite)";
	};

HERE
	  touch ${indices_dir}/override.$suite.main
	  touch ${indices_dir}/override.$suite.main.src
	  touch ${indices_dir}/override.$suite.extra.main
  done
}

create_repo ()
{
  if [ ! -d $incoming_dir ]; then
    for section in $section_list; do
      mkdir -p $incoming_dir/${section}
    done
  fi

  for suite in $suite_list; do
    for section in $section_list; do
      for arch in $(get_suite_arches $suite); do
        if [ $arch = source ]; then
          path_dir=$dists_dir/$suite/$section/$arch
        else
          path_dir=$dists_dir/$suite/$section/binary-$arch
          mkdir -p $dists_dir/$suite/$section/debian-installer/binary-$arch
        fi
        mkdir -p $path_dir
        cat > $path_dir/Release <<-HERE
		Archive: $suite
		Version: $archive_version
		Component: $section
		Origin: $archive_name
		Label: $archive_url
		Architecture: $arch
	HERE
	# FIXME: hardcoded check
	if [ $suite = experimental ]; then
		echo "NotAutomatic: yes" >> $path_dir/Release
	fi
        files_owner_perms $path_dir/Release
      done
    done
  done

  mkdir -p $cache_dir/dists
  mkdir -p $cache_dir/changes
  mkdir -p $indices_dir

  mkdir -p $queue_dir
  mkdir -p $unchecked_dir
  mkdir -p $accepted_dir
  mkdir -p $byhand_dir

  mkdir -p $log_dir

  for d in $(get_pool_dirs); do
    mkdir -p $d
  done
}


create_repo
create_apt_config
