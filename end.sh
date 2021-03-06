# parse a statedb subcommand if used
if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "leveldb" ]]; then
      export STATEDBNAME=leveldb
      shift
  fi
  if [[ "$key" == "rocksdb" ]]; then
      export STATEDBNAME=rocksdb
      shift
  fi
  if [[ "$key" == "boltdb" ]]; then
      export STATEDBNAME=boltdb
      shift
  fi
  if [[ "$key" == "badgerdb" ]]; then
      export STATEDBNAME=badgerdb
      shift
  fi
fi

set -x

#../fabric-samples/test-network/network.sh down
(cd ../fabric-samples/test-network && exec ./network.sh down)
