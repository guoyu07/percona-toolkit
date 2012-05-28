#!/usr/bin/env perl

BEGIN {
   die "The PERCONA_TOOLKIT_BRANCH environment variable is not set.\n"
      unless $ENV{PERCONA_TOOLKIT_BRANCH} && -d $ENV{PERCONA_TOOLKIT_BRANCH};
   unshift @INC, "$ENV{PERCONA_TOOLKIT_BRANCH}/lib";
};

use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More tests => 1;

use PerconaTest;
use Sandbox;
require "$trunk/bin/pt-deadlock-logger";

# #############################################################################
# https://bugs.launchpad.net/percona-toolkit/+bug/903443
# pt-deadlock-logger crashes on MySQL 5.5
# #############################################################################

my $innodb_status_sample = <<'EOS';
=====================================
070915 15:34:37 INNODB MONITOR OUTPUT
=====================================
Per second averages calculated from the last 24 seconds
------------------------
LATEST DETECTED DEADLOCK
------------------------
111212 22:52:42
*** (1) TRANSACTION:
TRANSACTION 3405, ACTIVE 161 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 376, 3 row lock(s), undo log entries 2
MySQL thread id 19, OS thread handle 0x7fac301e4700, query id 180 localhost root Updating
update a set movie_id=96 where id =2
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 0 page no 307 n bits 72 index `PRIMARY` of table `test`.`a` trx id 3405 lock_mode X locks rec but not gap waiting
Record lock, heap no 3 PHYSICAL RECORD: n_fields 6; compact format; info bits 0
 0: len 4; hex 80000002; asc ;;
 1: len 6; hex 000000003404; asc 4 ;;
 2: len 7; hex 040000163b2515; asc ;% ;;
 3: len 4; hex 80000063; asc c;;
 4: len 1; hex 01; asc ;;
 5: len 8; hex 8000124a7c1acb8c; asc J| ;;

*** (2) TRANSACTION:
TRANSACTION 3404, ACTIVE 1026 sec starting index read
mysql tables in use 1, locked 1
3 lock struct(s), heap size 376, 2 row lock(s), undo log entries 1
MySQL thread id 18, OS thread handle 0x7fac30225700, query id 181 localhost root Updating
update a set movie_id=98 where id =4
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 0 page no 307 n bits 72 index `PRIMARY` of table `test`.`a` trx id 3404 lock_mode X locks rec but not gap
Record lock, heap no 3 PHYSICAL RECORD: n_fields 6; compact format; info bits 0
 0: len 4; hex 80000002; asc ;;
 1: len 6; hex 000000003404; asc 4 ;;
 2: len 7; hex 040000163b2515; asc ;% ;;
 3: len 4; hex 80000063; asc c;;
 4: len 1; hex 01; asc ;;
 5: len 8; hex 8000124a7c1acb8c; asc J| ;;

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 0 page no 307 n bits 72 index `PRIMARY` of table `test`.`a` trx id 3404 lock_mode X locks rec but not gap waiting
Record lock, heap no 5 PHYSICAL RECORD: n_fields 6; compact format; info bits 0
 0: len 4; hex 80000004; asc ;;
 1: len 6; hex 000000003405; asc 4 ;;
 2: len 7; hex 0500000e7017e8; asc p ;;
 3: len 4; hex 80000062; asc b;;
 4: len 1; hex 01; asc ;;
 5: len 8; hex 8000124a7c1acbb6; asc J| ;;

*** WE ROLL BACK TRANSACTION (2)
END OF INNODB MONITOR OUTPUT
============================
EOS

is_deeply(
   pt_deadlock_logger::parse_deadlocks($innodb_status_sample),
   {
      '1' => {
          db => '',
          hostname => 'localhost',
          id => 1,
          idx => '',
          ip => '',
          lock_mode => '',
          lock_type => '',
          query => 'update a set movie_id=96 where id =2',
          server => '',
          tbl => '',
          thread => '19',
          ts => '2011-12-12T22:52:42',
          txn_id => 0,
          txn_time => '161',
          user => 'root',
          victim => 0,
          wait_hold => 'w'
      },
      '2' => {
          db => '',
          hostname => 'localhost',
          id => 2,
          idx => '',
          ip => '',
          lock_mode => '',
          lock_type => '',
          query => 'update a set movie_id=98 where id =4',
          server => '',
          tbl => '',
          thread => '18',
          ts => '2011-12-12T22:52:42',
          txn_id => 0,
          txn_time => '1026',
          user => 'root',
          victim => 1,
          wait_hold => 'w'
      }
   },
   "Bug 903443: pt-deadlock-logger parses the thread id incorrectly for MySQL 5.5",
);

# #############################################################################
# Done.
# #############################################################################
exit;
