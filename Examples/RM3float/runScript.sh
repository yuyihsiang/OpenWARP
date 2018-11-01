#! /bin/bash
# [Topcoder]
# This script consists of Test-case from 7 to 11 
#exec >> automated_test2.log

# Enable set -e to stop script in case of exception 
#set -e
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in?page=1&tab=votes#tab-top
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

INSTALL_PATH="/Users/yyu/Documents/GitHub/OpenWARP/source"
ROOT="$DIR"

export LD_LIBRARY_PATH="$INSTALL_PATH/openwarpgui/bundled/simulation/libs:$LD_LIBRARY_PATH"
export LDFLAGS="-L$INSTALL_PATH/openwarpgui/bundled/simulation/libs"
export PYTOHNPATH="$INSTALL_PATH"
export OMP_NUM_THREADS=3

mkdir -p ~/OpenWarpFiles/temp
mkdir -p ~/OpenWarpFiles/user_data

echo "------------------------"
echo "-->Starting Nemoh Runs-"
echo "------------------------"

rm db.hdf5
rm -rf results
cd "$INSTALL_PATH"
python "$INSTALL_PATH/openwarpgui/openwarp_cli.py" "$DIR/Nemoh.json"
echo "--> Nemoh run finished successfully"
