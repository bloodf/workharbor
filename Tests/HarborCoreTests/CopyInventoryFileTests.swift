import XCTest
@testable import HarborCore

final class CopyInventoryFileTests: XCTestCase {
    var directory: URL!
    var file: URL { directory.appendingPathComponent("copies.json") }
    var store: CopyInventoryFile { CopyInventoryFile(file: file) }
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }
    func testFirstUseAllowsMissingEmptyInventoryOnly() throws {
        XCTAssertNil(try store.validatedBytes(expected: [:], mustExist: false))
        XCTAssertThrowsError(try store.validatedBytes(expected: [:], mustExist: true))
        XCTAssertThrowsError(try store.validatedBytes(expected: ["m":"old"], mustExist: false))
    }
    func testUnreadableFileAndCorruptOrWrongSchemaNeverBecomeEmptyInventory() throws {
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        XCTAssertThrowsError(try store.validatedBytes(expected: [:], mustExist: false))
        try FileManager.default.removeItem(at: file)
        for text in ["not-json", "[]", "{\"m\":null}", "{\"m\":4}"] {
            try Data(text.utf8).write(to: file)
            XCTAssertThrowsError(try store.validatedBytes(expected: [:], mustExist: false))
        }
    }
    func testRemovedOrExternallyChangedInventoryBlocks() throws {
        try Data("{\"m\":\"old\"}".utf8).write(to: file)
        XCTAssertNotNil(try store.validatedBytes(expected: ["m":"old"], mustExist: true))
        try Data("{\"m\":\"external\"}".utf8).write(to: file)
        XCTAssertThrowsError(try store.validatedBytes(expected: ["m":"old"], mustExist: true))
        try FileManager.default.removeItem(at: file)
        XCTAssertThrowsError(try store.validatedBytes(expected: ["m":"old"], mustExist: true))
    }
    func testReconnectPreservesExactBytesAndEveryPreviousBackup() throws {
        let first = Data("{ \"m\" : \"old\", \"untouched\" : \"id\" }\n".utf8)
        try first.write(to: file)
        let backup1 = try store.reconnect(expectedBytes: first, repaired: ["m":"new","untouched":"id"])
        XCTAssertEqual(try Data(contentsOf: backup1), first)
        let second = try Data(contentsOf: file)
        let backup2 = try store.reconnect(expectedBytes: second, repaired: ["m":"newer","untouched":"id"])
        XCTAssertNotEqual(backup1, backup2)
        XCTAssertEqual(try Data(contentsOf: backup1), first)
        XCTAssertEqual(try Data(contentsOf: backup2), second)
        XCTAssertEqual(try JSONDecoder().decode([String:String].self, from: Data(contentsOf:file)), ["m":"newer","untouched":"id"])
        for backup in [backup1,backup2] {
            XCTAssertEqual((try FileManager.default.attributesOfItem(atPath:backup.path)[.posixPermissions] as? NSNumber)?.intValue,0o600)
        }
    }
    func testStaleBytesCannotOverwriteExternalEditOrCreateBackup() throws {
        let old=Data("{\"m\":\"old\"}".utf8), changed=Data("{\"m\":\"external\"}".utf8)
        try changed.write(to:file)
        XCTAssertThrowsError(try store.reconnect(expectedBytes:old,repaired:["m":"replacement"]))
        XCTAssertEqual(try Data(contentsOf:file),changed)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:directory.path),["copies.json"])
    }
}
