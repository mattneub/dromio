import Foundation

/// Actions sent by AlbumsViewController to AlbumsProcessor.
enum AlbumsAction: Equatable {
    /// The view controller is ready for its data.
    case initialData
    /// The user wants to see the song list for the given album.
    case showAlbum(albumId: String)
    /// The user would like to view the playlist.
    case showPlaylist
}
