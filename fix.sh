
stash=~/_stash
for d in `cat libraries`; do
  mv $stash/$d/*.dylib $(brew --prefix $d)/lib/   # then build, then move back
  rmdir $stash/$d

done
rmdir $stash
