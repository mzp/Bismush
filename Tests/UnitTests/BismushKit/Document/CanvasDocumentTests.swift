//
//  CanvasDocumentTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by Hiro Mizuno on 6/11/22.
//

import CoreGraphics
import SwiftUI
import XCTest
@testable import BismushKit

class CanvasDocumentTests: XCTestCase {
    private let RFC3339DateFormatter: DateFormatter = {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HHmmssZZZZZ"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return RFC3339DateFormatter
    }()

    private var document: CanvasDocument!

    override func setUpWithError() throws {
        try super.setUpWithError()

        document = try CanvasDocument()

        draw(points: [
            .init(x: 0, y: 0),
            .init(x: 100, y: 100),
            .init(x: 200, y: 200),
            .init(x: 300, y: 300),
            .init(x: 400, y: 400),
        ])
    }

    private func draw(points: [Point<ViewCoordinate>]) {
        let brush = Brush(document: document)
        brush.viewSize = .init(width: 800, height: 800)
        for point in points {
            brush.add(
                pressurePoint: .init(point: point, pressure: 1)
            )
        }
        brush.commit()

        let commandQueue = MTLCreateSystemDefaultDevice()!.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func XCTAssertNotEqualSnapshot(_ lhs: CanvasDocumentSnapshot, _ rhs: CanvasDocumentSnapshot) {
        XCTAssertNotEqual(lhs, rhs)
    }

    private func attach(name: String = "snapshot", snapshot: CanvasDocumentSnapshot) {
        XCTContext.runActivity(named: "Dump snapshot: \(name)") { activity in
            for (id, texture) in snapshot.textures {
                for (index, image) in texture.inspectImages().enumerated() {
                    #if os(macOS)
                        let attachment = XCTAttachment(
                            image: NSImage(
                                cgImage: image,
                                size: NSSize(width: image.width, height: image.height)
                            )
                        )
                    #else
                        let attachment = XCTAttachment(image: UIImage(cgImage: image))
                    #endif

                    attachment.name = "\(name)-\(id)-\(index).png"
                    activity.add(attachment)
                }
            }
        }
    }

    func testPersist() throws {
        let snapshot = try snapshot(document: document)
        let file = try document.flieWrapper(
            snapshot: snapshot,
            container: FileWrapper(directoryWithFileWrappers: [:])
        )

        let timestamp = RFC3339DateFormatter.string(from: Date())
        let fileURL = URL(filePath: NSTemporaryDirectory()).appending(component: "\(timestamp).bismush")
        try file.write(to: fileURL, originalContentsURL: nil)
        BismushLogger.testing.info("Saved in \(fileURL)")

        let documentFromFile = try CanvasDocument(file: FileWrapper(url: fileURL))
        let snapshotFromFile = try self.snapshot(document: documentFromFile)
        attach(name: "original", snapshot: snapshot)
        attach(name: "from file", snapshot: snapshotFromFile)
        XCTAssertEqual(snapshot, snapshotFromFile)
    }

    func testRestore() throws {
        let snapshotBeforeEdit = try snapshot(document: document)
        draw(points: [
            .init(x: 800, y: 0),
            .init(x: 700, y: 100),
            .init(x: 600, y: 200),
            .init(x: 500, y: 300),
            .init(x: 400, y: 400),
            .init(x: 300, y: 300),
        ])
        let snapshotAfterEdit = try snapshot(document: document)
        attach(name: "before", snapshot: snapshotBeforeEdit)
        attach(name: "after", snapshot: snapshotAfterEdit)
        XCTAssertNotEqual(snapshotBeforeEdit, snapshotAfterEdit)

        document.restore(snapshot: snapshotBeforeEdit)
        let snapshotAfterRestore1 = try snapshot(document: document)
        attach(name: "restore 1", snapshot: snapshotAfterRestore1)
        XCTAssertEqual(snapshotBeforeEdit, snapshotAfterRestore1)

        document.restore(snapshot: snapshotAfterEdit)
        let snapshotAfterRestore2 = try snapshot(document: document)
        attach(name: "restore 2", snapshot: snapshotAfterRestore2)
        XCTAssertEqual(snapshotAfterEdit, snapshotAfterRestore2)
    }

    func testHealth() throws {
        let modifiedSnapshot = try snapshot(document: .sample)
        let vanillaSnapshot = try snapshot(document: .empty)
        attach(snapshot: modifiedSnapshot)
        XCTAssertTrue(vanillaSnapshot != modifiedSnapshot)
    }

    private func snapshot(document: CanvasDocument) throws -> CanvasDocumentSnapshot {
        try document.snapshot(contentType: .canvas)
    }
}
