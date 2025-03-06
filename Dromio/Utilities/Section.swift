/// Simple value struct that encapsulates the notion of a table view section.
struct Section<T> {
    var name: String
    var rows: [T]
}
