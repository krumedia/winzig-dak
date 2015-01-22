winzig-dak - Partial and lightweight reimplementation of dak forked from mini-dak

Introduction
------------

This is winzig-dak a fork of mini-dak.

Both a partial and lightweight reimplementation of dak
(Debian Archive Kit) in shell script and with no database
dependencies, "designed" to host small Debian repositories.

So the main purpose of mini-dak is to run a slave archive for new
Debian ports, taking all sources from the master archive. Source uploads
to the slave archive are supposed to be modifications and porting fixes
for the new architectures.

winzig-dak uses this leightweight implementation, but can be used to share
packages in addition to the official repositories.

mini-dak source repository
-----------------

  <http://git.hadrons.org/?p=debian/mini-dak.git>
  <git://git.hadrons.org/git/debian/mini-dak.git>

Setup
-----

Download the sources, and put them for example in '/srv/ftp.foo.org/bin',
create a user for it (optional), edit archive.conf and run archive-setup.
Depending on the configured functionality or what parts of mini-dak are
used, you will need some additional software, listed by: «grep Requires: *».
Install the cronjob. Enjoy.


TODO
----

* delete stuff used to download/mirror upstream archives
* delete hacks for unreleased
* create a dokumentation
* debianize / make debian-package
* much more …
