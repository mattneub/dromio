import UIKit

/// Class that functions as data source and delegate for AlbumViewController table view.
@MainActor
final class AlbumDataSourceDelegate: NSObject, DataSourceDelegate, UITableViewDelegate {

    /// Processor to whom we can send action messages.
    weak var processor: (any Receiver<AlbumAction>)?

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

    func present(_ state: AlbumState) {
        if data != state.songs {
            data = state.songs
            Task {
                await updateTableView()
            }
        }
    }


    // MARK: - Table view contents

    /// Data to be displayed by the table view.
    var data = [SubsonicSong]()

    /// Type of the diffable data source.
    typealias Datasource = UITableViewDiffableDataSource<String, String>

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
        guard let song = data.first(where: { $0.id == identifier }) else {
            return nil
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = song.title
        cell.contentConfiguration = configuration
        return cell
    }

    /// Method called by `present` to bring the table into line with the data.
    func updateTableView() async {
        var snapshot = datasource.snapshot()
        snapshot.deleteAllItems() // despite the name, this deletes the section too
        snapshot.appendSections(["Dummy"])
        snapshot.appendItems(data.map {$0.id})
        await datasource.apply(snapshot, animatingDifferences: false)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let identifier = datasource.itemIdentifier(for: indexPath) else {
            return
        }
        guard let song = data.first(where: { $0.id == identifier }) else {
            return
        }
        Task {
            await processor?.receive(.tapped(song))
        }
    }
}
