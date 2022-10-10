//
//  BlobTests.swift
//  Bismush
//
//  Created by Hiro Mizuno on 10/9/22.
//

import Foundation
import XCTest
@testable import BismushKit

class BlobTests: XCTestCase {
    struct Entry: Codable, Equatable {
        var name: String
        var blob: Blob
    }
    private var entry: Entry!
    private var fileWrapper: FileWrapper!

    override func setUpWithError() throws {
        let url = URL(
            filePath: NSTemporaryDirectory()
        ).appending(
                path: UUID().uuidString
            )
       try FileManager.default.createDirectory(
        at: url,
        withIntermediateDirectories: true
       )
        fileWrapper = try FileWrapper(
            url: url
        )

        entry = Entry(
            name: "foo",
            blob: Blob(data: "bar".data(using: .utf8)! as NSData)
        )
    }

    func testEncoderDecoder() throws {
        let encoder = BlobEncoder(
            fileWrapper: fileWrapper,
            encoder: JSONEncoder()
        )
        let data = try encoder.encode(entry)

        let decoder = BlobDecoder(
            fileWrapper: fileWrapper,
            decoder: JSONDecoder()
        )
        let entry2 = try decoder.decode(Entry.self, from: data)
        XCTAssertEqual(entry, entry2)
    }
}
