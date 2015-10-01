winzig-dak - Partial and lightweight reimplementation of dak forked from mini-dak

Introduction
------------

This is winzig-dak, a fork of mini-dak.

Both are partial and leightweight reimplementation of dak
(Debian Archive Kit) in shell script and with no database
dependencies, "designed" to host small Debian repositories.

So the main purpose of mini-dak is to run a slave archive for new
Debian ports, taking all sources from the master archive. Source uploads
to the slave archive are supposed to be modifications and porting fixes
for the new architectures.

winzig-dak uses this leightweight implementation, but can be used to share
packages in addition to the official repositories.

mini-dak source repository
--------------------------

  <http://git.hadrons.org/?p=debian/mini-dak.git>
  <git://git.hadrons.org/git/debian/mini-dak.git>

Setup
-----

Download the sources, and put them for example in '/srv/ftp.foo.org/bin',
create a user for it (optional), edit archive.conf and run archive-setup.
Depending on the configured functionality or what parts of mini-dak are
used, you will need some additional software, listed by: «grep Requires: *».
Enjoy.

License
-------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

TODO
----
* Allow upload to others sections than main
  (archive-lib.sh#195,#211)
* try to understand and then delete hacks for unreleased/experimental
* debianize / make debian-package
* give ability to delete a package with a specific version
* is it necessary to deploy the *.changes (they are not doing that in the
  official repositories)
* generate human readable information about available packages
  (one XML file for every package, so we can use xslt (?))
* generate symlinks for dist-aliases
* clone only specific versions

KNOWN BUGS
----------

* Packages with a suite-alias are accepted and copied to the pool, but they
  don’t appear in dists/…/Contents
