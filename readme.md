alpine linux with f2fs, limine and nitro-init.

# installation

in an alpine live boot, install `git` and `patch`
```
setup-interfaces -r # connect to the internet
setup-apkrepos -1 # setup apk repositories
apk add git patch
```

clone the repository
```
https://codeberg.org/crimedeodio/setup-alpine.git
```

then, configure and run the script
```
cd setup-alpine
vi setup-alpine.sh
sh setup-alpine.sh
```

# todo

* fix hostname
* shutdown, restart
* more services (eiwd, ssh, bluetooth)
* modular service selection in the script
* remove openrc
... basically everything related to the init system