import UIKit

/// Class that functions as data source and delegate for ArtistsViewController table view.
@MainActor
final class ArtistsDataSourceDelegate: NSObject, DataSourceDelegateSearcher, UITableViewDelegate {

    /// Processor to whom we can send action messages.
    weak var processor: (any Receiver<ArtistsAction>)?

    weak var tableView: UITableView?

    /// Reuse identifier for the table view cells we will be creating.
    private let reuseIdentifier = "reuseIdentifier"

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        // We're going to use a diffable data source. Register the cell type, make the
        // diffable data source, and set the table view's dataSource and delegate.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        datasource = createDataSource(tableView: tableView)
        tableView.dataSource = datasource
        tableView.delegate = self
    }

    func present(_ state: ArtistsState) {
        datasource?.listType = state.listType
        Task {
            await updateTableView(data: state.artists)
        }
    }

    // MARK: - Table view contents

    /// Data to be displayed by the table view.
    var data = [SubsonicArtist]()

    /// A copy of the data that we can restore after a search.
    var originalData = [SubsonicArtist]()

    /// Type of the diffable data source.
    typealias Datasource = MyArtistsTableViewDiffableDataSource

    /// Retain the diffable data source.
    var datasource: Datasource!

    /// Create the data source and populate it with its initial snapshot. Called by our initializer.
    /// - Parameter tableView: The table view.
    /// - Returns: The data source.
    /// 
    func createDataSource(tableView: UITableView) -> Datasource {
        let datasource = Datasource(tableView: tableView) { [unowned self] tableView, indexPath, identifier in
            return cellProvider(tableView, indexPath, identifier)
        }
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections(["Dummy"])
        snapshot.appendItems([])
        datasource.apply(snapshot, animatingDifferences: false)
        return datasource
    }

    /// Cell provider function of the diffable data source.
    /// - Returns: A populated cell.
    ///
    func cellProvider(_ tableView: UITableView, _ indexPath: IndexPath, _ identifier: String) -> UITableViewCell? {
        guard let artist = data.first(where: { $0.id == identifier }) else {
            return nil
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.contentConfiguration = ArtistsCellContentConfiguration(artist: artist)
        return cell
    }

    /// Method called by `present` to bring the table into line with the data.
    func updateTableView(data: [SubsonicArtist]) async {
        var sections = [Section(name: "dummy", rows: [SubsonicArtist]())]
        self.data = data
        switch datasource?.listType {
        case .allArtists, .composers:
            // sort the data
            let data = data.sorted
            self.data = data
            // clump the data into sections by first letter
            let dictionary = Dictionary(grouping: data) {
                var firstLetter = String($0.sortName!.prefix(1)) // sortName guaranteed after `sorted`
                if !("a"..."z").contains(firstLetter) {
                    firstLetter = "#" // clump all non-letter names at the front under "#"
                }
                return firstLetter
            }
            sections = Array(dictionary).sorted { $0.key < $1.key }.map {
                Section(name: $0.key, rows: $0.value)
            }
        case .none: break
        }
        // "deal" the sections and their items right into the snapshot, in order;
        // we do not actually need to retain the section info independently so just throw it away
        var snapshot = datasource.snapshot()
        snapshot.deleteAllItems() // despite the name, this deletes the section(s) too
        for section in sections {
            snapshot.appendSections([section.name])
            snapshot.appendItems(section.rows.map {$0.id})
        }
        await datasource.apply(snapshot, animatingDifferences: false)
        UIView.performWithoutAnimation {
            self.tableView?.beginUpdates()
            self.tableView?.endUpdates()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Task {
            guard let id = datasource.itemIdentifier(for: indexPath) else { return }
            await processor?.receive(.showAlbums(artistId: id))
        }
    }

    // MARK: Searching

    // Quite tricky, because we get calls to this method not just when the user types in the
    // search bar but also when the user _taps_ in the search bar and when the user or the app
    // cancels searching.
    func updateSearchResults(for searchController: UISearchController) {
        if let update = searchController.searchBar.text, !update.isEmpty {
            let filteredData = originalData.filter {
                $0.name.range(of: update, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
            data = filteredData
        } else {
            if !originalData.isEmpty {
                data = originalData
            }
        }
        Task {
            await updateTableView(data: data)
        }
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        originalData = data
        datasource.searching = true
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        datasource.searching = false
        tableView?.reloadSectionIndexTitles()
    }
}

final class MyArtistsTableViewDiffableDataSource: UITableViewDiffableDataSource<String, String> {
    var listType: ArtistsState.ListType = .allArtists
    var searching: Bool = false

    override func sectionIndexTitles(for _: UITableView) -> [String]? {
        if snapshot().itemIdentifiers.isEmpty {
            return nil
        }
        if searching {
            return nil
        }
        switch listType {
        case .allArtists, .composers:
            return snapshot().sectionIdentifiers.map { $0.uppercased() }
        }
    }
}
