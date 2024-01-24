import BitwardenSdk
import Foundation

// MARK: - SendListProcessor

/// The processor used to manage state and handle actions for the send tab list screen.
///
final class SendListProcessor: StateProcessor<SendListState, SendListAction, SendListEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasPasteboardService
        & HasSendRepository

    // MARK: Private properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SendRoute>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `SendListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SendRoute>,
        services: Services,
        state: SendListState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SendListEffect) async {
        switch effect {
        case .appeared:
            await streamSendList()
        case let .search(text):
            state.searchResults = await searchSends(for: text)
        case .refresh:
            await refresh()
        case let .sendListItemRow(effect):
            switch effect {
            case let .copyLinkPressed(sendView):
                guard let url = try? await services.sendRepository.shareURL(for: sendView) else { return }
                services.pasteboardService.copy(url.absoluteString)
                state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.sendLink))
            case let .deletePressed(sendView):
                let alert = Alert.confirmation(title: Localizations.areYouSureDeleteSend) { [weak self] in
                    await self?.deleteSend(sendView)
                }
                coordinator.showAlert(alert)
            case let .removePassword(sendView):
                let alert = Alert.confirmation(title: Localizations.areYouSureRemoveSendPassword) { [weak self] in
                    await self?.removePassword(sendView)
                }
                coordinator.showAlert(alert)
            case let .shareLinkPressed(sendView):
                guard let url = try? await services.sendRepository.shareURL(for: sendView) else { return }
                coordinator.navigate(to: .share(url: url))
            }
        }
    }

    override func receive(_ action: SendListAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem, context: self)
        case .clearInfoUrl:
            state.infoUrl = nil
        case .infoButtonPressed:
            state.infoUrl = ExternalLinksConstants.sendInfo
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .sendListItemRow(rowAction):
            switch rowAction {
            case let .editPressed(sendView):
                coordinator.navigate(to: .editItem(sendView), context: self)
            case let .sendListItemPressed(item):
                switch item.itemType {
                case let .send(sendView):
                    coordinator.navigate(to: .editItem(sendView), context: self)
                case .group:
                    // TODO: BIT-1412 Navigate to the group list screen
                    break
                }
            }
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private Methods

    /// Refreshes the user's vault, including sends.
    ///
    private func refresh() async {
        do {
            try await services.sendRepository.fetchSync(isManualRefresh: true)
        } catch {
            let alert = Alert.networkResponseError(error) { [weak self] in
                await self?.refresh()
            }
            coordinator.showAlert(alert)
        }
    }

    /// Deletes the provided send.
    ///
    /// - Parameter sendView: The send to delete.
    ///
    private func deleteSend(_ sendView: SendView) async {
        coordinator.showLoadingOverlay(title: Localizations.deleting)
        do {
            try await services.sendRepository.deleteSend(sendView)
            coordinator.hideLoadingOverlay()
            state.toast = Toast(text: Localizations.sendDeleted)
        } catch {
            let alert = Alert.networkResponseError(error) { [weak self] in
                await self?.deleteSend(sendView)
            }
            coordinator.hideLoadingOverlay()
            coordinator.showAlert(alert)
        }
    }

    /// Removes the password from the provided send.
    ///
    /// - Parameter sendView: The send to remove the password from.
    ///
    private func removePassword(_ sendView: SendView) async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.removingSendPassword))
        do {
            _ = try await services.sendRepository.removePassword(from: sendView)
            coordinator.hideLoadingOverlay()
            state.toast = Toast(text: Localizations.sendPasswordRemoved)
        } catch {
            let alert = Alert.networkResponseError(error) { [weak self] in
                await self?.removePassword(sendView)
            }
            coordinator.hideLoadingOverlay()
            coordinator.showAlert(alert)
        }
    }

    /// Stream the list of sends.
    ///
    private func streamSendList() async {
        do {
            for try await sections in try await services.sendRepository.sendListPublisher() {
                state.sections = sections
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Searches the sends using the provided string, and returns any matching results.
    ///
    /// - Parameter searchText: The string to use when searching the sends.
    /// - Returns: An array of `SendListItem`s. If no results can be found, an empty array will be
    ///   returned.
    ///
    private func searchSends(for searchText: String) async -> [SendListItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        do {
            let result = try await services.sendRepository.searchSendPublisher(searchText: searchText)
            for try await sends in result {
                return sends
            }
        } catch {
            services.errorReporter.log(error: error)
        }

        return []
    }
}

// MARK: - SendListProcessor:SendItemDelegate

extension SendListProcessor: SendItemDelegate {
    func sendItemCancelled() {
        coordinator.navigate(to: .dismiss())
    }

    func sendItemCompleted(with sendView: SendView) {
        Task {
            guard let url = try? await services.sendRepository.shareURL(for: sendView) else { return }
            coordinator.navigate(to: .dismiss(DismissAction(action: {
                self.coordinator.navigate(to: .share(url: url))
            })))
        }
    }

    func sendItemDeleted() {
        coordinator.navigate(to: .dismiss(nil))
        state.toast = Toast(text: Localizations.sendDeleted)
    }
}