# photo-unfucker

Importing photos sucks. I used to use iPhoto, which does dupe detection, organizes by exif dates and all sorts of other things.

Apple can go fuck theirselves. iPhotos is salty garbage. Using iPhotos on a network share is just downright ludicrous. 

Instead, this dodgy little (completely untested) ruby script is clearly more trustworthy. 

## Setup 

```
# Install brew stuff
brew bundle

# Install ruby stuff
bundle install
```

## Usage

Point it at a folder full of your pictures like this but READ THE WHOLE README BEFORE YOU RUN THIS OR SO HELP ME!

``` shell
IMPORT_PATH=/Users/psturgeon/Pictures/import/ ruby rename.rb
```

This will **move files out of the import folder** (using actual `mv`) and into a new structure like this:

```
2018/2018-12/2018-12-01 23:59:59.jpg
```

The output folder will be `./export` unless you provide `EXPORT_PATH` too.

It has duplicate detection with checksums, and it'll even try to help you out when EXIF dates are missing:

![](https://user-images.githubusercontent.com/67381/38002713-d6aa89fa-3201-11e8-9ca2-622d218d3e8b.png)

![](https://user-images.githubusercontent.com/67381/38002700-c3df292a-3201-11e8-9c03-9e10731e1b16.png)

This probably only works on OSX, who knows. 👋🏻
