import Foundation

/// Actions sent by AlbumsViewController to AlbumsProcessor.
enum AlbumsAction: Equatable {
    /// The user wants to see all albums.
    case allAlbums
    /// The user wants to see the artists.
    case artists
    /// Called by the view controller as soon as it's ready to receive data.
    case initialData
    /// The user wants to see random albums.
    case randomAlbums
    /// The user wants to see the server-editing screen.
    case server
    /// The user wants to see the song list for the given album.
    case showAlbum(albumId: String)
    /// The user would like to view the playlist.
    case showPlaylist
}
