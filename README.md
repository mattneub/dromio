This is **Dromio**, a new dedicated Navidrome client for iPhone. It does not support any other type of Subsonic server — it is Navidrome-only.

Dromio is very small and simple (it occupies just 2MB of your iPhone’s storage), and takes a minimalist attitude towards letting you select and play your music, supplying very few screens. It is oriented particularly towards Classical music buffs, fully displaying long track titles and artist information, and supporting tagging for Composer and Year.

**Requirements:** Dromio requires iOS 18 and a Navidrome server running  the “BFR” (0.55.0) or later. You will need to have `Subsonic.ArtistParticipations` set to `true` in your configuration; otherwise, Dromio’s artist and composer support will not work.

Dromio was inspired by the Navidrome “BFR”. I started writing it when the “BFR” was [released for testing](https://github.com/navidrome/navidrome/discussions/3676). It is oriented towards the way I tag and organize my Classical music collection, and the way I listen to music. In short, it is the sort of Subsonic client that I personally have always wanted but never found. I wrote it for me. If Dromio’s prejudices don’t suit you, don’t use Dromio!

### A Minimalist Navidrome Client

Dromio takes a minimalist attitude:

- There is no “database” stored on disk. Dromio works by talking to the Navidrome server, not by making a database and consulting the database. Navidrome _is_ the database. You never need to “update” Dromio’s copy of the database; it doesn’t have any database.
- The vast majority of OpenSubsonic endpoints are unsupported.
- There is no admin (e.g. creation of users), because you can do that with Navidrome’s web interface.
- There is no creation and storage of named playlists.
- “Foo-foo” features like favorites, play counts, genres and so forth are unsupported. 
- No artwork is fetched or displayed.

Dromio fetches and displays only the following information, and only when you ask for that information:

* Albums and their songs.
* Random albums and their songs.
* Artists and their albums (and those albums’ songs).
* Composers and their albums (and those albums’ songs).

### Full Display

Some screenshots will illustrate Dromio’s full display of the information that it does fetch — album title and artist; track title, artist, composer, year, and duration:

![IMG_1947](https://github.com/user-attachments/assets/5e6d48ad-7e57-4803-b385-8777e88aa649)

![IMG_1948](https://github.com/user-attachments/assets/d5faf534-9345-47f3-8162-b58b4cce549d)

### How to Use

Launch the app. The first time, you will be asked to enter your Navidrome server information. You are then taken to the list of Albums.

The “page-turn” button at the top left lets you switch between All Albums, Random Albums, Artists, and Composers. (You can also return to the app’s initial screen to manage the app’s list of Navidrome servers.)

If you are on the Artists or Composers screen, tap an Artist or Composer to see the Albums in which they participate.

If you are on an Albums screen, tap an Album to see the tracks on that albums.

If you are on an Album Tracks screen, tap a track to append it to the Queue. _Nothing will appear to happen_ at this point.

But, on any screen, tap the “list” button at the top right to see the Queue. The tracks that you have tapped are here! On the Queue screen, tap a track to begin listening to the Queue, starting with the track you tapped. Download progress is displayed; a downloaded track is fully marked in yellow.

### About the Queue Screen

The Queue screen is not yet editable, so all you can do at this point is play the queue you’ve created in the order you’ve appended to it, or just delete the queue and start over. An editable queue will come in a future version of the app.

Once Dromio has started playing, the currently playing track is marked with a “note” icon in the Queue, and the “playpause” button is enabled, allowing you to pause and resume play. You can get more details about what is playing by using the iPhone’s built-in Now Playing Info center (in, for example, the Control Center).

The “x” button at the top right clears the queue and erases the downloads. It also navigates back out of the Queue screen, because if the queue is empty, there is nothing you can do in this screen.

In this screenshot, the first track has been tapped; it is playing and has finished downloading. The second track is in the middle of downloading. The third and fourth tracks are not yet downloaded.

![IMG_1949](https://github.com/user-attachments/assets/348e11f2-160a-4bad-92e2-58fdfb122044)

### Future Directions

Dromio is now working satisfactorily; otherwise, I would not be releasing it. I have a few future features in mind:

* The Queue needs to be editable: we need to be able to rearrange the tracks or delete individual tracks.
* In the Queue, it would be nice to be able to ask to see a track displayed within its album.
* In the Queue, in Jukebox Mode, the only operative commands are `clear` and `start` — you can start playing the queue, and you can kill the whole queue, and that’s all. It would be nice to make the playpause button operative in Jukebox Mode so that the playing can be paused and resumed.
* In the Queue, we are not scrobbling when a track is played. This means that a played track’s album is not being added to Navidrome’s list of recent albums. It would be nice to scrobble.
