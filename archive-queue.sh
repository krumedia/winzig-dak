#!/bin/bash
#
# Copyright © 2003 Robert Millan <rmh@debian.org>
# Copyright © 2003-2005, 2007 Guillem Jover <guillem@debian.org>
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

set -e

. archive-lib.sh

######
# data validation functions

verify_symlink_attack ()
{
  local changes_file=$1

  if [ -L $changes_file ]; then
    return 1
  else
    return 0
  fi
}

verify_size ()
{
  local changes_file=$1
  local changes_size=`stat -c "%s" $changes_file`

  if [ $changes_size -gt 100000 ]; then
    return 1
  else
    return 0
  fi
}

verify_gpg_signature ()
{
  local changes_file=$1
  local archive_file=$2
  local verify_result="`gpg $archive_keyrings --no-tty --status-fd=2 --verify $changes_file 2>&1`"

  if wrong=`echo "$verify_result" | grep '^\[GNUPG:\] BADSIG '`; then
    return 1
  elif good=`echo "$verify_result" | grep '^\[GNUPG:\] GOODSIG '`; then
    local signed_by="`echo "$good" | cut -d\  -f4-`"
    changes_strip < $changes_file \
      | formail -a"Signed-By: $signed_by" > $archive_file
    return 0
  else
    return 1
  fi
}

verify_dpkg_signature ()
{
  local archive_file=$1
  local section=$(basename $(dirname $archive_file))
  local files=`fetch_secure_files $section < $archive_file $section | grep '\.u\?deb$'`

  if [ "$use_dpkg_sig" != yes ]; then
    return 0
  fi

  for f in $files; do
    verify_result="`dpkg-sig --verify-role builder $f 2>&1`"

    if good=`echo "$verify_result" | grep '^GOODSIG '`; then
      :
    else
      return 1
    fi
  done

  return 0
}

verify_md5sums ()
{
  local archive_file=$1
  local section=$(basename $(dirname $archive_file))
  local md5sum=md5sum.textutils

  if ! which $md5sum >/dev/null; then
    md5sum=md5sum
  fi

  if fetch_md5sums $section < $archive_file | $md5sum -c >& /dev/null; then
    return 0
  else
    return 1
  fi
}

verify_suite ()
{
  local archive_file=$1
  local target_suite=`fetch_field "Distribution" < $archive_file`
  local c_target_suite=`canonic_suite $target_suite`

  for suite in $suite_list; do
    if [ "`canonic_suite $suite`" = "$c_target_suite" ]; then
      return 0
    fi
  done

  return 1
}

verify_arch ()
{
  local archive_file=$1
  local target_arches=`fetch_field "Architecture" < $archive_file`
  local suite=`fetch_field "Distribution" < $archive_file`

  for arch in $target_arches; do
    if ! valid_arch $suite $arch; then
      return 1
    fi
  done

  return 0
}

verify_section ()
{
  local archive_file=$1
  local target_section=$(basename $(dirname $archive_file))

  for section in $section_list; do
    if [ "$section" = "$target_section" ]; then
      return 0
    fi
  done

  return 1
}

verify_multiarch_changes ()
{
  local archive_file=$1
  local target_arches=`fetch_field "Architecture" < $archive_file`
  local multiarch=`filter_real_arches $target_arches | wc -w`

  if [ $multiarch -gt 1 ]; then
    return 1
  elif [ "$multipool" = "yes" ] && [ $multiarch -eq 0 ]; then
    # This will happen when a pure arch:all .changes has been uploaded,
    # but because it lacks a normal arch we don't know in which pool to
    # put the arch:all packages.
    return 1
  else
    return 0
  fi
}

# file output

queue_accepted ()
{
  local changes_file=$1
  local archive_file=$2
  local signer=$3
  local section=$(basename $(dirname $archive_file))
  local files=`fetch_secure_files < $archive_file`
  local files_install="$files $changes_file $archive_file"

  files_owner_perms $files_install

  mkdir -p $accepted_dir/$section
  if mv $files_install $accepted_dir/$section; then
    log queue "mv_accepted_success ${archive_file##*/}"
    notice_accepted $changes_file "$section" "$files" "$signer"
    return 0
  else
    script_error "queue_accepted" "$?"
    log queue "mv_accepted_failed ${archive_file##*/}"
    return 1
  fi
}

queue_rejected ()
{
  local outcome=$1
  local changes_file=$2
  local section=$3
  local archive_file=$4
  local signer=$5
  local files=

  if [ "$signer" ]; then
    files="`fetch_secure_files < $archive_file` $changes_file $archive_file"
  else
    files=$changes_file
  fi

  if rm $files; then
    log queue "rm_rejected_success ${archive_file##*/}"
    notice_rejected $changes_file $section "$outcome" "$signer"
    return 0
  else
    script_error "queue_rejected" "$?"
    log queue "rm_rejected_failed ${archive_file##*/}"
    return 1
  fi
}

# message output

notice_rejected ()
{
  local changes_file=${1##*/}
  local section=$2
  local outcome=$3
  local signer=$4

  ( cat <<-HERE
Uploader: $signer
Host: `hostname -f`
Rejected: $changes_file
Section: $section
Reason: $outcome
HERE
  ) | msg_queue "$changes_file REJECTED" "$signer"
}


notice_accepted ()
{
  local changes_file=${1##*/}
  local section=$2
  local files=$3
  local signer=$4

  ( cat <<-HERE
Uploader: $signer
Host: `hostname -f`
Accepted: $changes_file
Section: $section
Files:
$files
HERE
  ) | msg_queue "$changes_file ACCEPTED" "$signer"
}

script_error ()
{
  # echo "$@" | mail -s "Error in `basename $0` ($1): $2" $archive_maint
  log queue "Error in `basename $0` ($1): $2"
}

#
# main
#

cd $incoming_dir

shopt -s nullglob

for full_changes_file in {,*/}*.changes; do

  changes_file=$(basename $full_changes_file)
  subdir=$(dirname $full_changes_file)
  section=$subdir
  
  # fallback
  if [ "$section" = "." ]; then
    section="main"
  fi

  cd $incoming_dir/$subdir

  if ! fuser $changes_file; then
    mkdir -p $unchecked_dir/$section
    mv -f $changes_file $unchecked_dir/$section/$changes_file

    changes_file=$unchecked_dir/$section/$changes_file
    archive_file=$unchecked_dir/$section/$(basename $changes_file changes)archive

    if ! verify_symlink_attack $changes_file; then
      queue_rejected "error-symlink-attack" $changes_file $section
      continue
    fi

    if ! verify_size $changes_file; then
      queue_rejected "toobig-changes-file" $changes_file $section
      continue
    fi

    if ! verify_gpg_signature $changes_file $archive_file; then
      queue_rejected "wrong-signature" $changes_file $section
      continue
    fi

    signer=`fetch_field "Signed-By" < $archive_file`

    if ! verify_dpkg_signature $archive_file; then
      queue_rejected "wrong-dpkg-signature" $changes_file $section $archive_file "$signer"
      continue
    fi

    # Move the .archive contents to unchecked

    mkdir -p $unchecked_dir/$section
    if archive_move secure "$archive_file" "$unchecked_dir/$section"; then
      log queue "mv_unchecked_success ${archive_file##*/}"
    else
      log queue "mv_unchecked_failed ${archive_file##*/}"
      continue
    fi

    cd $unchecked_dir/$section

    if ! verify_md5sums $archive_file; then
      queue_rejected "wrong-md5sums" $changes_file $section $archive_file "$signer"
      continue
    fi

    if ! verify_suite $archive_file; then
      queue_rejected "wrong-suite" $changes_file $section $archive_file "$signer"
      continue
    fi

    if ! verify_arch $archive_file; then
      queue_rejected "wrong-arch" $changes_file $section $archive_file "$signer"
      continue
    fi

    if ! verify_section $archive_file; then
      queue_rejected "wrong-section" $changes_file $section $archive_file "$signer"
      continue
    fi

    if ! verify_multiarch_changes $archive_file; then
      queue_rejected "wrong-multiarch-changes" $changes_file $section $archive_file "$signer"
      continue
    fi

    queue_accepted $changes_file $archive_file "$signer"
  fi
done

cd - >/dev/null
