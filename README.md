# Music Library Organizer

A simple Swift script to organize my music library.

## Rationale

I use [Doppler](https://brushedtype.co/doppler/) as my music player. There is a lot to gain from listening to music
locally: no internet connection required, songs won't disappear out of no where, song information can be edited to be
perfect[^1], a simpler interface (usually), etc. While listening is the primary experience, organizing is (arguably)
just as important, as a poorly organized library will reflect when you want to find something.

Editing songs in a player is possible, but basic more often than not. In Doppler's case, you can edit some info, but
changes will only be saved to its internal database, and not the music files. For proper editing, I've been using
[Meta](https://www.nightbirdsevolve.com/meta/), which has useful tools like renaming and creating directories
from a pattern containing tag info. While this works, it requires supplying a pattern for the structure you want. This
works fine, but requires flipping between previously used patterns to match the most optimal pattern. If you're fine
with this, or don't mind a fairly verbose but "correct" file system structure (e.g. `~/Music/Local/Album Artist/Album/Disc #/Track Number. Title`),
then you don't need this. But if you're like me, and would like the folder structure to match the given music metadata,
then this may be for you!

[^1]: Compared to Spotify, where you can't edit anything, and Apple Music, where you can edit local songs, but songs
uploaded to the platform [may have their names munged](https://help.apple.com/itc/musicstyleguide/en.lproj/static.html#itc7436bdcd1)
to meet the standard.

## Installing

This is primarily intended to be used in conjuction with [Dropover](https://dropoverapp.com) and its [custom scripts](https://dropoverapp.com/kb/application-scripts)
functionality.

1. `git clone` this repository.
2. In `~/Library/Application Scripts/me.damir.dropover-mac`, create a file called `organize-into-music-library.swift`
3. On the first line of the file, paste the following: `#!/usr/bin/env swift`
4. From the cloned repository, copy the contents of `main.swift` into the new file *after* the line you just added.
5. From Dropover's Preferences, go `Advanced > Manage Custom Scripts`, hit the plus/add button, and select the file you
just created.

From this point, when you create a shelf, you should be able to hit the ellipses/more button, navigate to File Actions,
and select "Organize Into Music Library". Your music files should then be organized into the right location.

## Details

In a shelf containing tagged music files, the program reads the tagged information from each one and determines its
correct location (from my own convention). In execution, it means the following:
1. All music files are saved to `~/Media/Music`.
2. A music file containing the words "soundtrack" or "sound track" in its album name will use said album name as its folder
  - "Roar of the Abyss" from ["MADE IN ABYSS ORIGINAL SOUNDTRACK"](https://madeinabyss.fandom.com/wiki/Made_In_Abyss_Original_Soundtrack)
  would be organized to `~/Media/Music/MADE IN ABYSS ORIGINAL SOUNDTRACK`
3. If the above did not match, then a music file will use the artist and album (with preference given to the album
artist, and then the track artist), separated by a colon (-), as its folder.
  - "Yamborghini Dream" from Lil Uzi Vert's "Luv is Rage" will be organized to `~/Media/Music/Lil Uzi Vert - Luv is Rage`.
  If the album artist was not set, it would be organized to `~/Media/Music/Lil Uzi Vert feat. Young Thug - Luv is Rage`
  instead.
4. For the above case, if one of the two tags used is missing, the present tag will be used and the dash will be omitted.
  - Using the above example, if the album artist and artist were both missing, the file would then be organized to `~/Media/Music/Luv is Rage`.
  If it were the other way around, however (artist and album missing), it would've then been `~/Media/Music/Lil Uzi Vert`
5. If the music file is part of a multi-disc set (e.g. an album with 2 CDs), it will be saved in `~/Media/Music/.../Disc ...`,
where the second "..." corresponds to its disc number.
  - Michael Jackson's "Al Capone", which is part of "Bad", is from the second disc, so it'd be saved in `~/Media/Music/Michael Jackson - Bad/Disc 2`
  - sora tob sakana's "Dazzle" from their final album "deep blue" is only in the first disc, as the album is a
  single-disc release. As a result, it would be saved in `~/Media/Music/sora tob sakana - deep blue`. If the album has
  more than one disc, it would've then been saved in `~/Media/Music/sora tob sakana - deep blue/Disc 1`
6. Finally, the music file is saved as either its track number and title, or just its title.
  - "SO, I LOVE YOU" from Kingo Hamada's "midnight crusin'" is the third track, so it'd be saved as `~/Media/Music/Kingo Hamada - midnight crusin'/3. SO, I LOVE YOU YOU.[extension]`
