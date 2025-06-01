# sneezy-webtools

This project currently houses the sneezy-webmap tool, with plans for additional related tools.

The webmap app has two parts:
1. `map_gen.py` and related scripts, with generates the map.svg and assocated json data files, which are used in
2. the vue frontend, which provides the user interface for interrogating the map.


## Setting up python and running the map generator
This python side of this project is built on python 3.11.  To install the project dependencies run 
```
pip install --no-cache-dir -r /src/requirements.txt
```
 from the root directory.

Change directories to `src/` and run 
```
python map_gen.py
```

This will generate `src/assets/map.svg`, `src/assets/rooms.json` and `src/assets/zones.json`

Note: the final webpage uses an optimized version of this svg generated with the node `svgo` module.  If you don't want to bother with this you can just copy the unoptomized version (it isn't a big difference): 
```
cp assets/map.svg assets/optimized-map.svg
```

## Setting up node and running vite
The webpage itself uses the Vue frontend and is built using vite.

Install node:
```
apt-get update && apt-get install -y curl inotify-tools procps
apt-get install -y nodejs
```

Install the node packages from package.json:
```
npm install
```

Optionally if you want to use the svg optimizer:
```
npm install -g svgo
npx svgo assets/map.svg -o assets/optimized-map.svg
```

Now you can build the project in vite:
```
npm run build
```

This will output the files in `/dist`