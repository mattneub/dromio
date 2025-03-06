import UIKit

/// Class that functions as data source and delegate for AlbumsViewController table view.
@MainActor
final class AlbumsDataSourceDelegate: NSObject, DataSourceDelegate, UITableViewDelegate {

    /// Processor to whom we can send action messages.
    weak var processor: (any Receiver<AlbumsAction>)?

    weak var tableView: UITableView?

    /// Reuse identifier for the table view cells we will be creating.
    private let reuseIdentifier = "reuseIdentifier"

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        Task {
            // We're going to use a diffable data source. Register the cell type, make the
            // diffable data source, and set the table view's dataSource and delegate.
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
            datasource = await createDataSource(tableView: tableView)
            tableView.dataSource = datasource
            tableView.delegate = self
        }
    }

    func present(_ state: AlbumsState) {
        Task {
            await updateTableView(data: state.albums)
        }
    }


    // MARK: - Table view contents

    /// Data to be displayed by the table view.
    var data = [SubsonicAlbum]()

    /// Type of the diffable data source.
    typealias Datasource = MyTableViewDiffableDataSource

    /// Retain the diffable data source.
    var datasource: Datasource!

    /// Create the data source and populate it with its initial snapshot. Called by our initializer.
    /// - Parameter tableView: The table view.
    /// - Returns: The data source.
    /// 
    func createDataSource(tableView: UITableView) async -> Datasource {
        let datasource = Datasource(tableView: tableView) { [unowned self] tableView, indexPath, identifier in
            return cellProvider(tableView, indexPath, identifier)
        }
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections(["Dummy"])
        snapshot.appendItems([])
        await datasource.apply(snapshot, animatingDifferences: false)
        return datasource
    }

    /// Cell provider function of the diffable data source.
    /// - Returns: A populated cell.
    ///
    func cellProvider(_ tableView: UITableView, _ indexPath: IndexPath, _ identifier: String) -> UITableViewCell? {
        guard let album = data.first(where: { $0.id == identifier }) else {
            return nil
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.contentConfiguration = AlbumsCellContentConfiguration(album: album)
        return cell
    }

    /// Method called by `present` to bring the table into line with the data.
    func updateTableView(data: [SubsonicAlbum]) async {
        let data = data.sorted
        self.data = data
        // clump the data into sections so we know how to apply sections to the datasource
        let dictionary = Dictionary(grouping: data) {
            var firstLetter = String($0.sortName!.prefix(1)) // sortName guaranteed after `sorted`
            if !("a"..."z").contains(firstLetter) {
                firstLetter = "#" // clump all non-letter names at the front under "#"
            }
            return firstLetter
        }
        let sections = Array(dictionary).sorted { $0.key < $1.key }.map {
            Section(name: $0.key, rows: $0.value)
        }
        // all set, now just deal those sections and their items right into the snapshot, in order;
        // we do not actually need another copy of the list of sections, so just throw it away afterwards
        var snapshot = datasource.snapshot()
        snapshot.deleteAllItems() // despite the name, this deletes the section(s) too
        for section in sections {
            snapshot.appendSections([section.name])
            snapshot.appendItems(section.rows.map {$0.id})
        }
        await datasource.apply(snapshot, animatingDifferences: false)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Task {
            guard let id = datasource.itemIdentifier(for: indexPath) else { return }
            await processor?.receive(.showAlbum(albumId: id))
        }
    }

}

final class MyTableViewDiffableDataSource: UITableViewDiffableDataSource<String, String> {
    override func sectionIndexTitles(for _: UITableView) -> [String]? {
        return snapshot().sectionIdentifiers.map { $0.uppercased() }
    }
}
