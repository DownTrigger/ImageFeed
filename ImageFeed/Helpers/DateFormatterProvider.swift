import Foundation

final class DateFormatterProvider {

    // MARK: - Public
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
