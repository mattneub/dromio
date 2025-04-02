enum AlbumsEffect {
    /// Scroll the table view to the top, hiding the search bar if there is one
    case scrollToZero
    /// Ensure that the search controller exists and is configured.
    case setUpSearcher
    /// Remove the search bar and search controller.
    case tearDownSearcher
}
