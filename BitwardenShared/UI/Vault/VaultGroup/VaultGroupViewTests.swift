import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupViewTests

class VaultGroupViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultGroupState, VaultGroupAction, VaultGroupEffect>!
    var subject: VaultGroupView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: VaultGroupState())
        subject = VaultGroupView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add an item button dispatches the `.addItemPressed` action.
    func test_addAnItemButton_tap() throws {
        processor.state.items = []
        let button = try subject.inspect().find(button: Localizations.addAnItem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping a vault item dispatches the `.itemPressed` action.
    func test_vaultItem_tap() throws {
        let item = VaultListItem.fixture(cipherListView: .fixture(name: "Item", subTitle: ""))
        processor.state.items = [item]
        let button = try subject.inspect().find(button: "Item")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item))
    }

    /// Tapping the more button on a vault item dispatches the `.morePressed` action.
    func test_vaultItemMoreButton_tap() throws {
        let item = VaultListItem.fixture()
        processor.state.items = [item]
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.more)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed(item))
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        processor.state.items = []
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_oneItem() {
        processor.state.items = [
            .fixture(),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_multipleItems() {
        processor.state.items = [
            .fixture(cipherListView: .fixture(id: "1")),
            .fixture(cipherListView: .fixture(
                id: "2",
                name: "An extra long name that should take up more than one line",
                subTitle: "An equally long subtitle that should also take up more than one line"
            )),
            .fixture(cipherListView: .fixture(id: "3")),
            .fixture(cipherListView: .fixture(id: "4")),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}