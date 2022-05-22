## Parse mode
if [[ $# -lt 1 ]] ; then
  echo "Usage (lowcase): ./start.sh statedbname"
  exit 0
fi

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
fi

set -x

#../fabric-samples/test-network/network.sh up createChannel
(cd ../fabric-samples/test-network && exec ./network.sh up createChannel)

#-ccp path is relative to directory fabric-samples/test-network
#(cd ../fabric-samples/test-network && exec ./network.sh deployCC -ccn fixed-asset -ccp ../../caliper-workspace-2/smart-contract/node -ccl javascript)
(cd ../fabric-samples/test-network && exec ./network.sh deployCC -ccn fixed-asset -ccp ../../caliper-workspace-3/smart-contract/go -ccl go)