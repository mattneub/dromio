import Foundation

/// Actions sent by AlbumsViewController to AlbumsProcessor.
enum AlbumsAction: Equatable {
    /// The user wants to see all albums; also called initially when the view controller is ready for its data.
    case allAlbums
    /// The user wants to see random albums.
    case randomAlbums
    /// The user wants to see the song list for the given album.
    case showAlbum(albumId: String)
    /// The user wants to see the artists.
    case artists
    /// The user would like to view the playlist.
    case showPlaylist
}
