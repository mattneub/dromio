import Foundation

/// Messages to the server processor from its presenter.
enum ServerAction: Equatable {
    /// The value of the given text field changed to the given text.
    case textFieldChanged(Field, String)

    /// The value of the scheme segmented control changed to the given scheme.
    case schemeChanged(Scheme)

    /// The user tapped the Done button
    case done

    /// The four text fields.
    enum Field {
        case host
        case port
        case username
        case password
    }

    /// The two values of the segmented control.
    enum Scheme {
        case http
        case https
    }
}
