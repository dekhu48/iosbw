import BitwardenResources
import SwiftUI
import XCTest

@testable import AuthenticatorShared

class SettingsCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: SettingsCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        module = MockAppModule()
        stackNavigator = MockStackNavigator()

        subject = SettingsCoordinator(
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        module = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.alert` has the stack navigator present the alert.
    @MainActor
    func test_navigateTo_alert() throws {
        let alert = Alert.defaultAlert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.genericErrorMessage
        )
        subject.showAlert(alert)

        XCTAssertEqual(stackNavigator.alerts, [alert])
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.exportItems` presents the export vault view.
    @MainActor
    func test_navigateTo_exportVault() throws {
        subject.navigate(to: .exportItems)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<ExportItemsView>)
    }

    /// `navigate(to:)` with `.selectLanguage()` presents the select language view.
    @MainActor
    func test_navigateTo_selectLanguage() throws {
        subject.navigate(to: .selectLanguage(currentLanguage: .default))

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<SelectLanguageView>)
    }

    /// `navigate(to:)` with `.settings` pushes the settings view onto the stack navigator.
    @MainActor
    func test_navigateTo_settings() throws {
        subject.navigate(to: .settings)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is SettingsView)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    @MainActor
    func test_show_hide_loadingOverlay() throws {
        stackNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(stackNavigator.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` navigates to the settings view.
    @MainActor
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.last?.view is SettingsView)
    }
}
