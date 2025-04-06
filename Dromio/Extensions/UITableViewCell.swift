import UIKit

extension UITableViewCell {
    /// Injected method that sets up the cell background configuration throughout the app.
    func configureBackground() {
        var backgroundConfiguration = UIBackgroundConfiguration.listCell()
        backgroundConfiguration.backgroundColorTransformer = UIConfigurationColorTransformer { [weak self] color in
            guard let self else { return .background }
            return if self.isSelected || self.isHighlighted {
                .systemGray3
            } else {
                .background
            }
        }
        self.backgroundConfiguration = backgroundConfiguration
    }
}
