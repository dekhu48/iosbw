import SwiftUI

// MARK: - VaultListProcessor

/// The processor used to manage state and handle actions for the vault list screen.
///
final class VaultListProcessor: StateProcessor<VaultListState, VaultListAction, VaultListEffect> {
    // MARK: Types

    typealias Services = HasVaultRepository
        & HasAuthRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `VaultListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute>,
        services: Services,
        state: VaultListState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultListEffect) async {
        switch effect {
        case .appeared:
            await refreshVault()
            for await value in services.vaultRepository.vaultListPublisher() {
                state.loadingState = .data(value)
            }
        case let .profileSwitcher(profileEffect):
            switch profileEffect {
            case let .rowAppeared(rowType):
                guard state.profileSwitcherState.shouldSetAccessibilityFocus(for: rowType) == true else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.state.profileSwitcherState.hasSetAccessibilityFocus = true
                }
            }
        case .refreshAccountProfiles:
            await refreshProfileState()
        case .refreshVault:
            await refreshVault()
        }
    }

    override func receive(_ action: VaultListAction) {
        switch action {
        case .addItemPressed:
            setProfileSwitcher(visible: false)
            coordinator.navigate(to: .addItem())
        case let .itemPressed(item):
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id))
            case let .group(group, _):
                coordinator.navigate(to: .group(group))
            }
        case .morePressed:
            // TODO: BIT-375 Show item actions
            break
        case let .profileSwitcherAction(profileAction):
            switch profileAction {
            case .accountPressed:
                // TODO: BIT-124 Switch account
                setProfileSwitcher(visible: false)
            case .addAccountPressed:
                addAccount()
            case .backgroundPressed:
                setProfileSwitcher(visible: false)
            case let .scrollOffsetChanged(newOffset):
                state.profileSwitcherState.scrollOffset = newOffset
            }
        case let .requestedProfileSwitcher(visible: isVisible):
            setProfileSwitcher(visible: isVisible)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else { return }
            state.profileSwitcherState.isVisible = !isSearching
        case let .searchTextChanged(newValue):
            state.searchText = newValue
            state.searchResults = searchVault(for: newValue)
        }
    }

    // MARK: - Private Methods

    /// Navigates to login to initiate the add account flow.
    ///
    private func addAccount() {
        coordinator.navigate(to: .addAccount)
    }

    /// Configures a profile switcher state with the current account and alternates.
    ///
    /// - Returns: A current ProfileSwitcherState, if available.
    ///
    private func refreshProfileState() async {
        var accounts = [ProfileSwitcherItem]()
        var activeAccount: ProfileSwitcherItem?
        do {
            accounts = try await services.authRepository.getAccounts()
            activeAccount = try? await services.authRepository.getActiveAccount()

            state.profileSwitcherState = ProfileSwitcherState(
                accounts: accounts,
                activeAccountId: activeAccount?.userId,
                isVisible: state.profileSwitcherState.isVisible
            )
        } catch {
            services.errorReporter.log(error: error)
            state.profileSwitcherState = ProfileSwitcherState(accounts: [], activeAccountId: nil, isVisible: false)
        }
    }

    /// Refreshes the vault's contents.
    ///
    private func refreshVault() async {
        do {
            try await services.vaultRepository.fetchSync()
        } catch {
            // TODO: BIT-1034 Add an error alert
            print(error)
        }
    }

    /// Searches the vault using the provided string, and returns any matching results.
    ///
    /// - Parameter searchText: The string to use when searching the vault.
    /// - Returns: An array of `VaultListItem`s. If no results can be found, an empty array will be returned.
    ///
    private func searchVault(for searchText: String) -> [VaultListItem] {
        // TODO: BIT-628 Actually search the vault for the provided string.
        if "example".contains(searchText.lowercased()) {
            return [
                VaultListItem(cipherListView: .init(
                    id: "1",
                    organizationId: nil,
                    folderId: nil,
                    collectionIds: [],
                    name: "Example",
                    subTitle: "email@example.com",
                    type: .login,
                    favorite: true,
                    reprompt: .none,
                    edit: false,
                    viewPassword: true,
                    attachments: 0,
                    creationDate: Date(),
                    deletedDate: nil,
                    revisionDate: Date()
                ))!,
            ]
        } else {
            return []
        }
    }

    /// Sets the visibility of the profiles view and updates accessbility focus
    /// - Parameter visible: the intended visibility of the view
    private func setProfileSwitcher(visible: Bool) {
        if !visible {
            state.profileSwitcherState.hasSetAccessibilityFocus = false
        }
        state.profileSwitcherState.isVisible = visible
    }
}