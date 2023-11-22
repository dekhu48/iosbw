import BitwardenSdk

// MARK: - VaultListAction

/// Actions that can be processed by a `VaultListProcessor`.
enum VaultListAction: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// An item in the vault was pressed.
    case itemPressed(item: VaultListItem)

    /// The more button was pressed on an item in the vault.
    case morePressed(item: VaultListItem)

    /// A forwarded profile switcher action
    case profileSwitcherAction(ProfileSwitcherAction)

    /// An action to toggle the visibility of the profile switcher view.
    case requestedProfileSwitcher(visible: Bool)

    /// The text in the search bar was changed.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)
}