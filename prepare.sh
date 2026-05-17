#!/bin/sh

build=no
if [ ! -z "$1" ]; then
	branch="$1"
	build=yes
fi

arch=`uname -m`	
rel=`uname -r`
tmpdir=$(mktemp -d octez-node-staging-dir-XXXXX)
mkdir -p $tmpdir/bin $tmpdir/share/octez 
cp -pR LaunchDaemons/*plist $tmpdir/share/octez

if [ $build = yes ]; then
	echo "Building branch $branch"
	(cd ../tezos && git checkout ${branch})
	(cd ../tezos && eval `opam env` && make clean)
	(cd ../tezos && make build-deps && eval `opam env` && make release)
fi
_vers=$(cd ../tezos && eval `opam env` && dune exec octez-version 2>/dev/null)
vers=$(echo "$_vers" | sed -e 's/Octez //' -e 's/(.*$//' -e 's/(build.*$//'  -e 's/\~//' -e 's/^\+//' -e 's/^[[:blank:]]//' -e 's/[[:blank:]]$//')
target=octez-macos-$rel-$arch-$vers.tgz

echo "Packaging up version $vers"

if [ -f "../tezos/octez-node" ]; then

	echo "Copying files"
	cp -pR ../tezos/octez-* $tmpdir/bin
	rm -f $tmpdir/bin/octez-accuser-* $tmpdir/bin/octez-baker-*
	cp -pR ../tezos/_opam/share/zcash-params $tmpdir/share
	cd $tmpdir
	echo "Making archive"
	tar zvcf ../$target --owner root --group wheel .
	cd ..
	ls -l $target
fi
rm -rf $tmpdir
	
