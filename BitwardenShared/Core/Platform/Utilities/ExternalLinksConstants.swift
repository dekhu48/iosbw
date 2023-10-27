import Foundation

// MARK: - ExternalLinksConstants

/// Links that are used throughout the app.
///
enum ExternalLinksConstants {
    // MARK: Properties

    /// A markdown link to Bitwarden's privacy policy.
    static let privacyPolicy = URL(string: "https://bitwarden.com/privacy/")!

    /// A markdown link to Bitwarden's help page about protecting individual items.
    static let protectIndividualItems = URL(
        string: "https://bitwarden.com/help/managing-items/#protect-individual-items"
    )!

    /// A markdown link to Bitwarden's terms of service.
    static let termsOfService = URL(string: "https://bitwarden.com/terms/")!
}