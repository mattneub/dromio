import Foundation

/// Actions sent by ArtistsViewController to ArtistsProcessor.
enum ArtistsAction: Equatable {
    /// The user wants to see all artists; also called initially when the view controller is ready for its data.
    case allArtists
    /// The user wants to see composers.
    case composers
    /// The user wants to see the album list for the given artist.
    case showAlbums(artistId: String)
    /// The user would like to view the playlist.
    case showPlaylist
}
