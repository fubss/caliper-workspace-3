# parse a statedb subcommand if used
if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "leveldb" ]]; then
      export STATEDBNAME=leveldb
      export FABRIC_VERSION=2.4.0-goleveldb
      shift
  fi
  if [[ "$key" == "rocksdb" ]]; then
      export STATEDBNAME="rocksdb"
      export FABRIC_VERSION="!!!!!!!!!!2.4.0-grocksdb"

      shift
  fi
  if [[ "$key" == "boltdb" ]]; then
      export STATEDBNAME=boltdb
      shift
  fi
fi

set -x

#../fabric-samples/test-network/network.sh down
(cd ../fabric-samples/test-network && exec ./network.sh down)
