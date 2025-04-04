This is **Dromio**, a dedicated Navidrome client for iPhone. It does not support any other type of Subsonic server — it is Navidrome-only.

Dromio is very small and simple, typically occupying just 2MB of your iPhone’s storage. It adopts a minimalist attitude, supplying very few screens: its goal is to help you survey, select, and play your music — and that’s all. It is oriented particularly towards Classical music collections, fully displaying long track titles and artist information, and supporting tagging for Composer and Year. Unlike some Subsonic clients, playback of multiple tracks is gapless.

**Requirements:** Dromio requires iOS 18 and a Navidrome server running  the “BFR” (0.55.0) or later. You will need to have `Subsonic.ArtistParticipations` set to `true` in your configuration; otherwise, Dromio’s artist and composer support will not work.

Dromio was inspired by the Navidrome “BFR”. I started writing it when the “BFR” was [released for testing](https://github.com/navidrome/navidrome/discussions/3676). It is oriented towards the way I tag and organize my Classical music collection, and the way I listen to music. In short, it is the sort of Subsonic client that I personally have always wanted but never found. I wrote it for me. If Dromio’s prejudices don’t suit you, don’t use Dromio!

### A Minimalist Navidrome Client

Dromio takes a minimalist attitude, with no waste of your time, your space, or your attention:

- There is no account administration (e.g. creation of users), because you can do that with Navidrome’s web interface.
- There is no creation and storage of named playlists.
- Secondary features like favorites, play counts, genres and so forth are unsupported. 
- No artwork is fetched or displayed.

Most important, there is no “database” stored on disk. Dromio works by talking to the Navidrome server, not by creating a database and consulting that database. Navidrome _is_ the database. You never need to “update” Dromio’s copy of the database; there is no such copy.

Unlike some Subsonic clients, Dromio lets you store credentials for multiple accounts on multiple servers. There is no difficulty or delay switching servers, because no track information has been stored.

Dromio displays the following information:

* Albums and their tracks.
* Random albums and their tracks.
* Artists and their albums (and those albums’ tracks).
* Composers and their albums (and those albums’ tracks).
* The current queue (tracks to be played, or currently playing).

Albums, artists, and composers are properly alphabetized, and searchable. Album tracks are searchable.

No information is fetched from the server unless you ask for it by navigating to that screen.

### Full Display

Titles and artists can be lengthy, especially for Classical music. Unlike many Subsonic clients, Dromio _does not truncate this information._ Dromio provides a _full_ display of the information that it fetches — album title and artist; track title, artist, composer, year, and duration:

![Simulator Screenshot - iPhone SE (3rd generation) - 2025-04-04 at 07 55 17](https://github.com/user-attachments/assets/b8d4c1d1-75c8-4525-8674-14acc759b526)

![Simulator Screenshot - iPhone SE (3rd generation) - 2025-04-04 at 07 55 37](https://github.com/user-attachments/assets/fbceae18-fff2-481d-a9c9-62a14dbc7311)

### How to Use

Launch the app. The first time, you will be asked to enter your Navidrome server information. You are then taken to the list of Albums.

The “page-turn” button at the top left lets you switch between All Albums, Random Albums, Artists, and Composers. You can also use it to return to the app’s initial screen to manage the app’s list of Navidrome servers.

Dromio’s behavior is simple and intuitive:

* If you are on the Artists or Composers screen, tap an Artist or Composer to see the Albums in which they participate.

* If you are on an Albums screen, tap an Album to see the tracks on that albums.

* If you are on an Album Tracks screen, tap a track to append it to the Queue.

   _Nothing will appear to happen_ at this point. But now, on any screen, tap the “list” button at the top right, to see the Queue. The tracks that you have tapped are here! Now you can tap a track to start listening.

### About the Queue Screen

On the Queue screen, tap a track to begin listening to the Queue, starting with the track you tapped. 

* Download progress is displayed; a downloaded track is fully marked in yellow.

* Once Dromio has started playing, the currently playing track is marked with a “note” icon in the Queue, and the “playpause” button is enabled, allowing you to pause and resume play. 

In this screenshot, the first track has been tapped; it is playing and has finished downloading. The second track has also been downloaded. The third track is in the middle of downloading. The fourth track is not yet downloaded.

![Simulator Screenshot - iPhone SE (3rd generation) - 2025-04-04 at 07 57 32](https://github.com/user-attachments/assets/5b2d75ff-c584-4222-83af-e7788d3c321f)

Apart from the “playpause” button, Dromio has no “player” interface. If you want “player” interface, use the iPhone’s built-in Now Playing Info center (in, for example, the Control Center).

The “scissors” button at the top left makes the queue editable. You can delete a track from the queue, and you can rearrange the order or tracks. While you are editing, the “scissors” changes to a “checkmark”; tap the “checkmark” when you are done editing.

The “x” button at the top right clears the queue and erases the downloads. It also navigates back out of the Queue screen, because if the queue is empty, there is nothing you can do in this screen.

### Future Directions

Dromio is working satisfactorily; otherwise, I would not be releasing it. I have a few future features in mind:

* In the Queue, it would be nice to be able to ask to see a track displayed within its album.

* In the Queue, in Jukebox Mode, the only operative commands are `clear` and `start` — you can start playing the queue, and you can kill the whole queue, and that’s all. It would be nice to make the playpause button operative in Jukebox Mode so that the playing can be paused and resumed.

If you have other suggestions, or if you find any issues, please use the Issues page.
