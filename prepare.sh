#!/bin/sh

build=no
if [ ! -z "$1" ]; then
	branch="$1"
	build=yes
fi

static=yes
post=""

[ "$2" = "dynamic" ] && static=no
[ "$2" = "static" ] && static=yes

mkdir -p build
	
if [ "$static" = "yes" ]; then
	# needed for static hidapi
	export OCAMLPARAM="_,cclib=-framework,cclib=CoreFoundation,cclib=-framework,cclib=IOKit"
	post="-static"

	if [ ! -f "$(brew --prefix hidapi)/lib/libhidapi.a" ]; then
		cd build
		git clone https://github.com/libusb/hidapi.git
		cd hidapi
		mkdir _build
		cmake -S . -B _build -DHIDAPI_BUILD_HIDTEST=ON -DBUILD_SHARED_LIBS=OFF
		cmake --build _build
		cp _build/src/mac/libhidapi.a $(brew --prefix hidapi)/lib
		cd ../..
	fi
fi

libs="NONE"
if [ -f libraries ]; then
	libs=`cat libraries`
fi

tezosdir="build/tezos"

arch=`uname -m`	
rel=`uname -r`
tmpdir=$(mktemp -d octez-node-staging-dir-XXXXX)
mkdir -p $tmpdir/bin $tmpdir/share/octez 
cp -pR LaunchDaemons/*plist $tmpdir/share/octez

# Hack from Claude to prefer static libraries
#
if [ "$libs" != "NONE" ] && [ "$static" = "yes" ]; then
	stash=~/_stash
	mkdir $stash
	for d in $libs; do
		mkdir -p $stash/$d
		  mv $(brew --prefix $d)/lib/*.dylib $stash/$d   # then build, then move back
	done
fi


if [ $build = yes ]; then
	echo "Building branch $branch"
	if [ ! -d "$tezosdir" ]; then
		git clone git@gitlab.com:tezos/tezos.git $tezosdir
	fi

	rm -rf $tezosdir/_opam
	(cd $tezosdir && git checkout ${branch})
	(cd $tezosdir && eval `opam env` && make clean)
	(cd $tezosdir && make build-deps && eval `opam env` && make release)
fi
_vers=$(cd $tezosdir && eval `opam env` && dune exec octez-version 2>/dev/null)
vers=$(echo "$_vers" | sed -e 's/Octez //' -e 's/(.*$//' -e 's/(build.*$//'  -e 's/\~//' -e 's/^\+//' -e 's/^[[:blank:]]//' -e 's/[[:blank:]]$//')
target=octez-macos-$rel-$arch-$vers$post.tgz

# Put the dynamic libraries back then
#
if [ "$libs" != "NONE" ] && [ "$static" = "yes" ]; then
	for d in $libs; do
	  mv $stash/$d/*.dylib $(brew --prefix $d)/lib/   # then build, then move back
	  rmdir $stash/$d
	done
	rmdir $stash
fi

echo "Packaging up version $vers"

if [ -f "$tezosdir/octez-node" ]; then

	echo "Copying files"
	cp -pR $tezosdir/octez-* $tmpdir/bin
	rm -f $tmpdir/bin/octez-accuser-* $tmpdir/bin/octez-baker-*
	cp -pR $tezosdir/_opam/share/zcash-params $tmpdir/share
	cd $tmpdir
	echo "Making archive"
	tar zvcf ../$target --owner root --group wheel .
	cd ..
	ls -l $target
fi
rm -rf $tmpdir
	
