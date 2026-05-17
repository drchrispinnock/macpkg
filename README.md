# MacOS

1. Untar in /usr/local (or somewhere appropriate for your installation).

cd /usr/local
sudo tar zxvf ~/octez-macos-25.5.0-arm64-24.4.tgz

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

4. Copy the launchctl script to LaunchDaemons. This will mean the node will
run on boot.

```
sudo cp /usr/local/share/octez/com.tezos.octez-node.service.plist \
	/Library/LaunchDaemons
```

5. Optionally - run it now (or reboot)
```
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tezos.octez-node.service.plist
```


