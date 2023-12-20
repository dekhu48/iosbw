import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AddEditSendItemViewTests

class AddEditSendItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect>!
    var subject: AddEditSendItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: AddEditSendItemState())
        subject = AddEditSendItemView(store: Store(processor: processor))
    }

    // MARK: Tests

    func test_deletionDateMenu_updated() throws {
        processor.state.isOptionsExpanded = true
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.deletionDate)
        try menuField.select(newValue: SendDeletionDateType.thirtyDays)
        XCTAssertEqual(processor.dispatchedActions.last, .deletionDateChanged(.thirtyDays))
    }

    func test_expirationDateMenu_updated() throws {
        processor.state.isOptionsExpanded = true
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.expirationDate)
        try menuField.select(newValue: SendExpirationDateType.thirtyDays)
        XCTAssertEqual(processor.dispatchedActions.last, .expirationDateChanged(.thirtyDays))
    }

    func test_maximumAccessCountStepper_updated() throws {
        processor.state.isOptionsExpanded = true
        processor.state.maximumAccessCount = 42
        let stepper = try subject.inspect().find(ViewType.Stepper.self, containing: Localizations.maximumAccessCount)

        try stepper.increment()
        XCTAssertEqual(processor.dispatchedActions.last, .maximumAccessCountChanged(43))

        try stepper.decrement()
        XCTAssertEqual(processor.dispatchedActions.last, .maximumAccessCountChanged(41))
    }

    func test_nameTextField_updated() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.name)
        try textField.inputBinding().wrappedValue = "Name"
        XCTAssertEqual(processor.dispatchedActions.last, .nameChanged("Name"))
    }

    func test_newPasswordTextField_updated() throws {
        processor.state.isOptionsExpanded = true
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.newPassword)
        try textField.inputBinding().wrappedValue = "password"
        XCTAssertEqual(processor.dispatchedActions.last, .passwordChanged("password"))
    }

    func test_notesTextField_updated() throws {
        processor.state.isOptionsExpanded = true
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.notes)
        try textField.inputBinding().wrappedValue = "Notes"
        XCTAssertEqual(processor.dispatchedActions.last, .notesChanged("Notes"))
    }

    func test_optionsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.options)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .optionsPressed)
    }

    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .savePressed)
    }

    func test_textTextField_updated() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.text)
        try textField.inputBinding().wrappedValue = "Text"
        XCTAssertEqual(processor.dispatchedActions.last, .textChanged("Text"))
    }

    func test_typePicker_updated() throws {
        let picker = try subject.inspect().find(picker: Localizations.type)
        try picker.select(value: SendType.file)
        XCTAssertEqual(processor.dispatchedActions.last, .typeChanged(.file))
    }

    // MARK: Snapshots

    func test_snapshot_text_empty() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_text_withValues() {
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.isHideTextByDefaultOn = true
        processor.state.isShareOnSaveOn = true
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_text_withOptions_empty() {
        processor.state.isOptionsExpanded = true
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_text_withOptions_withValues() {
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.isHideTextByDefaultOn = true
        processor.state.isShareOnSaveOn = true
        processor.state.deletionDate = .custom
        processor.state.customDeletionDate = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)
        processor.state.expirationDate = .custom
        processor.state.customExpirationDate = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)
        processor.state.maximumAccessCount = 42
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes"
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject, as: .tallPortrait)
    }
}