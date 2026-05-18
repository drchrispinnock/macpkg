# Makeshift Octez MacOS binaries

0. Get a tar (or build Octez yourself)

Go to [packages.tzinit.org/macos](https://packages.tzinit.org/macos).

1. Untar in /usr/local (or somewhere appropriate for your installation).

```
cd /usr/local
sudo tar zxvf ~/octez-macos-25.5.0-arm64-24.4.tgz
```

You might get an error about changing permissions on bin or share - you can
ignore it.

2. Setup a tezos user and group

```
sudo dseditgroup -o create tezos
sudo sysadminctl -addUser tezos -fullName Tezos
sudo dscl . -create /Groups/tezos GroupMembership tezos
```

3. Setup the node

```
sudo su - tezos
/usr/local/bin/octez-node config init \
	--network https://teztnets.com/tallinnnet \
	--history rolling \
	--rpc-addr 127.0.0.1 --net-addr 0.0.0.0
wget https://snapshots.tzinit.org/tallinnnet/rolling
/usr/local/bin/octez-node snapshot import rolling
rm -f rolling
exit
```

4. Copy the relevant launchctl scripts to LaunchDaemons. This will mean the node will
run on boot.

```
sudo cp /usr/local/share/octez/octez-{node,baker,dal-node}.service.plist \
	/Library/LaunchDaemons
```

5. Optionally - run it now (or reboot)
```
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tezos.octez-node.service.plist
```

6. Set up your baker keys (on production, do something more secure than this please!)

```
$ sudo su - tezos
$ octez-client gen keys baker --sig bls
$ octez-client show address baker
Hash: tz4UMrWz3z6NiABPSBPQF1arLf5oUvqmnVcM
Public Key: BLpk1vnS47n9jBTqHkB52Zaoj1SXanmTpR93MwZ58Nh4zRJecmrxc6TbqgqMN9N5UVy4Ex1aw2AF
$ exit
```

7. Set up the DAL node using the baker address. If you are using consensus keys, use the master baker key.

```
sudo su - tezos
octez-dal-node config init --attester-profile=tz4UMrWz3z6NiABPSBPQF1arLf5oUvqmnVcM
exit
```

8. Run the DAL node

```
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tezos.octez-dal-node.service.plist
```

9. Fund the baking key and stake

10. Edit /Library/LaunchDaemons/com.tezos.octez-baker.service.plist, search for SETME and set the liquidity baking vote. On a test network, you can just use 'pass' without any thought. Research and vote how you want on mainnet.

11. Run the Baker

```
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tezos.octez-baker.service.plist
```

12. If you feel like being a good citizen, run the accuser

```
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tezos.octez-accuser.service.plist
```


The daemons/services will start on boot.  However be aware - you will need your mac to automatically login on startup for it to work without your attention.
