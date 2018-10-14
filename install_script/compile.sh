#/bin/bash

OSTYPE=`uname`

#Stop shell scripts if commands are returing non-zero value
#set -e

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in?page=1&tab=votes#tab-top


SOURCE="${BASH_SOURCE[0]}"

while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SOURCE="$(readlink "$SOURCE")"
[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
PARENTDIR="$(dirname "${DIR}")"
INSTALL_PATH="${PARENTDIR}/source"
ROOT="${PARENTDIR}/source"

NEMOH_FORTRAN="${ROOT}/NemohImproved/Nemoh"

echo "Root is" $ROOT

if [ "$OSTYPE" = "Linux" ];then
	echo "Installing to $ROOT"
    FORTRAN_BUILD="${ROOT}/NemohImproved/FortranBuild_Linux"

    echo "Building fortran to" "$FORTRAN_BUILD"
    mkdir -p "$FORTRAN_BUILD"  
    rm -rf "$FORTRAN_BUILD"/*  
    cd "$FORTRAN_BUILD"
    if [ -n "$1" ] && [ "$1" == "ifort" ]; then
        cho "Using Intel Fortran" 
        cmake -DCMAKE_Fortran_COMPILER="ifort" "$NEMOH_FORTRAN"        
    else
        echo "Using gfortran" 
        cmake -DCMAKE_Fortran_COMPILER="gfortran" "$NEMOH_FORTRAN"        	
    fi	
    make
    cp libnemoh.so "$INSTALL_PATH/openwarpgui/bundled/simulation/libs/"

	export LD_LIBRARY_PATH="$ROOT/openwarpgui/bundled/simulation/libs:$LD_LIBRARY_PATH"
	export LDFLAGS="-L$ROOT/openwarpgui/bundled/simulation/libs"

	cd "$ROOT/openwarpgui/nemoh"

	echo "Link Nemoh Fortran Library to Python"
	python setup.py cleanall
	python setup.py build_ext --inplace
	
	echo "OpenWarp Installation successfully completed"

elif [ "$OSTYPE"="Darwin" ];then
    FORTRAN_BUILD="${ROOT}/NemohImproved/FortranBuild_OSX"
	
	USERNAME=`id -un`

	echo "Make sure the dynamic version of quad-math library is not in the path"
	mv /usr/local/lib/gcc/4.9/libquadmath.0.dylib /usr/local/lib/gcc/4.9/disable_libquadmath.0.dylib
	mv /usr/local/lib/gcc/4.9/libquadmath.dylib /usr/local/lib/gcc/4.9/disable_libquadmath.dylib
	
    echo "Building fortran to" "$FORTRAN_BUILD"
    mkdir -p "$FORTRAN_BUILD"  
    rm -rf "$FORTRAN_BUILD"/*  
    cd "$FORTRAN_BUILD"
	cmake -DCMAKE_Fortran_COMPILER="gfortran" "$NEMOH_FORTRAN"
	make
	
	echo "Command to test the library path is correctly set "
	(test -e "$FORTRAN_BUILD/libnemoh.dylib" && echo ’Success’ ) || echo ’Error:Nemoh library not found’.
	
	
	cd ${ROOT}/openwarpgui/nemoh/

	echo "Link Nemoh Fortran Library to Python"
	python ${ROOT}/openwarpgui/nemoh/setup.py cleanall
    python ${ROOT}/openwarpgui/nemoh/setup.py build_ext --inplace
	
	# To know the currently configured path 
	otool -L ${ROOT}/openwarpgui/nemoh/solver_fortran.so
	
	chmod 777 ${ROOT}/openwarpgui/nemoh/solver_fortran.so
	# install_name_tool -change $Current $New
	install_name_tool -change "libnemoh.dylib" "$FORTRAN_BUILD/libnemoh.dylib" ${ROOT}/openwarpgui/nemoh/solver_fortran.so
	
	echo "OpenWarp Installationg Succesfully Completed"	
else
 	echo "This OS type is not supported!  "
fi
