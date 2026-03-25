alpine linux with f2fs and limine

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

then, run the script
```
cd setup-alpine
sh setup-alpine.sh
```

# todo

* replace `openrc` with `nitro-init`
* make it more automated, just edit the options in the script and run it