import XCTest
@testable import HarborCore
final class SettingsMigrationTests:XCTestCase {
    func testLegacyCalendarIdentityAndUnknownFieldsSurviveSave() throws {
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:folder)}
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let file=folder.appendingPathComponent("settings.json"),installation=UUID(),ruleID=UUID()
        let legacy:[String:Any] = ["installationID":installation.uuidString,"rules":[["id":ruleID.uuidString,"sourceID":"a","destinationID":"b","mode":"Ocupado → trabalho","beforeMinutes":15,"afterMinutes":15]],"profiles":[["legacy":"preserve"]],"ai":["endpoint":"https://example.invalid"]]
        try JSONSerialization.data(withJSONObject:legacy).write(to:file)
        let store=SettingsStore(file:file);var settings=try store.load()
        XCTAssertEqual(settings.installationID,installation);XCTAssertEqual(settings.rules.first?.id,ruleID)
        settings.language="es";try store.save(settings)
        let saved=try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
        XCTAssertNotNil(saved["profiles"]);XCTAssertNotNil(saved["ai"])
        XCTAssertEqual(try store.load().rules.first?.mode,.busy)
        XCTAssertTrue(FileManager.default.fileExists(atPath:folder.appendingPathComponent("settings-before-calendar-only.json").path))
    }
}
