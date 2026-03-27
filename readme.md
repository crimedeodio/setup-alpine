automated alpine linux installation script with support for f2fs and limine.

# installation

in an alpine live boot, install `git` and `patch`
```
setup-interfaces -r # connect to the internet
setup-apkrepos -1 # setup apk repositories
apk add git patch
```

clone the repository
```
git clone https://codeberg.org/crimedeodio/setup-alpine.git
```

then, configure and run the script
```
cd setup-alpine
vi config.sh
sh setup-alpine.sh
```

# todo

* remove openrc