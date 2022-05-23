#!/bin/bash
# This script will run caliper benchmarks to compare leveldb as a HLF statedb with SPECIFIED statedb.
# Benchamrks that will be run by INDEX:
#   0 - empty-contract-1of.yaml
#   1 - get-asset.yaml
#   2 - create-asset.yaml
#     - delete-asset.yaml //was deleted because there is no method in golang-cheincode
#   3 - mixed-range-query-pagination.yaml
#   4 - get-asset-batch.yaml
#   5 - create-asset-batch.yaml
#
# ------------------------------------------------------
# Algorithm:
# ------------------------------------------------------
# 1.* (can be ommited initially) Check that desired containers with set database exist. Check that they are not duplicated. if no: do not continue.
#
# 2. Create a catalog for HTML results (the name must be unique)
# 3. Start a loop for INDEX:
#   3.1 do for SPECIFIED statedb 
#       check that fabric is not run
#       3.1.1 run HLF with SPECIFIED statedb from docker images (start.sh)
#       3.1.2 run INDEXed caliper benchmark saving all cmd output into a file!!!!!   
#       3.1.3 check that "report.html" exist, if not - TODO: decide. stop script?
#       3.1.4 put "report.html" to created catalog on step 2
#       3.1.5 rename "report.html" to "report_benchmarkName_SPECIFIEDdb.html"
#       3.1.6 stop HLF
#   3.2 then straightaway do the same for leveldb statedb:
#       3.2.1 run HLF with leveldb statedb from docker images (start.sh)
#       3.2.2 run INDEXed caliper benchmark saving all cmd output into a file!!!!!  
#       3.2.3 check that "report.html" exist, if not - TODO: decide. stop script?
#       3.2.4 put "report.html" to created catalog on step 2
#       3.2.5 rename "report.html" to "report_benchmarkName_leveldb.html"
#       3.2.6 stop HLF
#
# ------------------------------------------------------
# Code:
# ------------------------------------------------------

CALIPER_BENCHMARKS_TO_RUN="create-asset-batch delete-asset" #"empty-contract-1of get-asset create-asset mixed-range-query-pagination get-asset-batch create-asset-batch"
SupportedDBs="rocksdb boltdb (all compares to leveldb)"
LEVELDB="leveldb"

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
  elif [[ "$key" == "rocksdb" ]]; then
      export STATEDBNAME=rocksdb
      shift
  elif [[ "$key" == "boltdb" ]]; then
      export STATEDBNAME=boltdb
      shift
  else
    echo "not existing statedbname, use from the list: ${SupportedDBs}"
    exit 0
  fi
fi

DIRNAME="bench_${STATEDBNAME}_"`date +"%Y%m%d_%H%M%S"`
mkdir $DIRNAME

#some checks
#       check that fabric is not run
if [[ $(docker ps | grep hyperledger) ]]; then
    echo "alive fabric containers detected. Please stop them to start this batch of caliper benchmarks."
    exit 1
fi
#       check that prometheus is run
if ! [[ $(docker ps | grep prometheus) ]]; then
    echo "prometheus container wasn't detected. Please run it to start this batch of caliper benchmarks."
    exit 1
fi

#checks that images with fabric-leveldb and fabric-STATEDBNAME exist
#TODO this
#check that STATEDBNAME images exist
if ! [[ $(docker images | grep 2.4.0-${STATEDBNAME}) ]]; then
    echo "no fabric-${STATEDBNAME} images detected. Please assemble fabric with ${STATEDBNAME} as a state database and make sure that images named with format 2.4.0-${STATEDBNAME}"
    exit 1
fi
#check that leveldb images exist
if ! [[ $(docker images | grep 2.4.0-leveldb) ]]; then
    echo "no fabric-${LEVELDB} images detected. Please assemble fabric with ${LEVELDB} as a state database and make sure that images named with format 2.4.0-${LEVELDB}"
    exit 1
fi

# 3. Start a loop for INDEX:
#   3.1 do for SPECIFIED statedb 

for BENCH in ${CALIPER_BENCHMARKS_TO_RUN}
do
    # FOR STATEDBNAME:

    echo "Running fabric network..."
    START_NETWORK_TIME=$(date '+%H%M%S')
    set -x
    #       3.1.1 run HLF with SPECIFIED statedb from docker images (start.sh)
    ./start.sh ${STATEDBNAME} >& "./$DIRNAME/${BENCH}_${STATEDBNAME}_output_${START_NETWORK_TIME}.txt"
    #       3.1.2 run INDEXed caliper benchmark saving all cmd output into a file!!!!!
    { set +x; } 2>/dev/null
    echo ""
    echo "===================================="
    echo "===================================="
    echo "Running $BENCH.yaml..."
    echo "===================================="
    echo "===================================="
    echo ""
    START_BENCH_TIME=$(date '+%H:%M:%S')
    echo "Benchamrk started at ${START_BENCH_TIME}:" >> "./$DIRNAME/${BENCH}_${STATEDBNAME}_output_${START_NETWORK_TIME}.txt"
    set -x
    npx caliper launch manager --caliper-workspace . \
    --caliper-networkconfig ./fabric-api-solo-node.yaml \
    --caliper-benchconfig ./benchmarks/$BENCH.yaml  \
    --caliper-flow-only-test --caliper-fabric-gateway-enabled >> "./$DIRNAME/${BENCH}_${STATEDBNAME}_output_${START_NETWORK_TIME}.txt"
    { set +x; } 2>/dev/null

#       3.1.3 check that "report.html" exist, if not - echo & continue loop
    if ! [[ $(ls | grep report.html) ]]; then
        echo ""
        echo "WARNING! report.html was not created after benchmark ${BENCH}.yaml"
        echo ""
        continue
    fi

    #       3.1.4 put "report.html" to created catalog on step 2
    #       3.1.5 rename "report.html" to "report_benchmarkName_SPECIFIEDdb.html"
    FINISH_BENCH_TIME=$(date '+%H%M%S')
    cp report.html "./$DIRNAME/report_${BENCH}_${STATEDBNAME}_${FINISH_BENCH_TIME}.html"
    rm report.html
    #       3.1.6 stop HLF
    echo "Stopping fabric network..."
    ./end.sh ${STATEDBNAME} >> "./$DIRNAME/${BENCH}_${STATEDBNAME}_output_${START_NETWORK_TIME}.txt"

    #==============================================================================================
    #==============================================================================================
    #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    #==============================================================================================
    #==============================================================================================
    #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    #==============================================================================================
    #==============================================================================================
    #   3.2 then straightaway do the same for leveldb statedb:
    #FOR LEVELDB DO THE SAME:
    echo "Running fabric network..."
    START_NETWORK_TIME=$(date '+%H%M%S')
    set -x
    #       3.2.1 run HLF with leveldb statedb from docker images (start.sh)
    ./start.sh ${LEVELDB} >& "./$DIRNAME/${BENCH}_${LEVELDB}_output_${START_NETWORK_TIME}.txt"
    #       3.2.2 run INDEXed caliper benchmark saving all cmd output into a file!!!!!  
    { set +x; } 2>/dev/null
    echo ""
    echo "===================================="
    echo "===================================="
    echo "Running $BENCH.yaml..."
    echo "===================================="
    echo "===================================="
    echo ""
    START_BENCH_TIME=$(date '+%H:%M:%S')
    echo "Benchamrk started at ${START_BENCH_TIME}:" >> "./$DIRNAME/${BENCH}_${LEVELDB}_output_${START_NETWORK_TIME}.txt"
    set -x
    npx caliper launch manager --caliper-workspace . \
    --caliper-networkconfig ./fabric-api-solo-node.yaml \
    --caliper-benchconfig ./benchmarks/$BENCH.yaml  \
    --caliper-flow-only-test --caliper-fabric-gateway-enabled >> "./$DIRNAME/${BENCH}_${LEVELDB}_output_${START_NETWORK_TIME}.txt"
    { set +x; } 2>/dev/null

    #       3.2.3 check that "report.html" exist, if not - TODO: decide. stop script?
    if ! [[ $(ls | grep report.html) ]]; then
        echo ""
        echo "WARNING! report.html was not created after benchmark ${BENCH}.yaml"
        echo ""
        continue
    fi

    #       3.2.4 put "report.html" to created catalog on step 2
    #       3.2.5 rename "report.html" to "report_benchmarkName_leveldb.html"
    FINISH_BENCH_TIME=$(date '+%H%M%S')
    cp report.html "./$DIRNAME/report_${BENCH}_${LEVELDB}_${FINISH_BENCH_TIME}.html"
    rm report.html
    #       3.2.6 stop HLF
    echo "Stopping fabric network..."
    ./end.sh ${LEVELDB} >> "./$DIRNAME/${BENCH}_${LEVELDB}_output_${START_NETWORK_TIME}.txt"
done   
