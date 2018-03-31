#!/bin/bash
set -o pipefail
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
> errors.txt
> run.log
GHA2DB_PROJECT=spire IDB_DB=spire PG_DB=spire GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=spire IDB_DB=spire PG_DB=spire GHA2DB_LOCAL=1 ./gha2db 2017-09-28 0 today now 'spiffe' 'spire' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=spire IDB_DB=spire PG_DB=spire GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
./spire/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
./spire/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
./spire/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=spire PG_DB=spire ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=spire PG_DB=spire GHA2DB_LOCAL=1 ./pdb_vars || exit 8
./devel/ro_user_grants.sh spire || exit 9
echo "All done. You should run ./spire/reinit.sh script now."
