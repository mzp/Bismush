//
//  Blob.swift
//  Bismush
//
//  Created by Hiro Mizuno on 9/5/22.
//

import Combine
import Foundation

protocol BlobStore {
    func store(id: String, data: NSData) throws
}

protocol BlobLoader {
    func load(id: String) throws -> NSData
}

struct Blob: Equatable, Hashable, Codable {
    var id: String
    var data: NSData

    init(id: String = UUID().uuidString, data: NSData) {
        self.id = id
        self.data = data
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        id = try container.decode(String.self)
        if let manager = decoder.userInfo[Self.decoderKey] as? BlobLoader {
            data = try manager.load(id: id)
        } else {
            data = NSData()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        if let manager = encoder.userInfo[Self.encoderKey] as? BlobStore {
            try manager.store(id: id, data: data)
        }
    }

    static func == (lhs: Blob, rhs: Blob) -> Bool {
        lhs.id == rhs.id
    }

    static var encoderKey: CodingUserInfoKey {
        CodingUserInfoKey(rawValue: "jp.mzp.bismush.encoder")!
    }

    static var decoderKey: CodingUserInfoKey {
        CodingUserInfoKey(rawValue: "jp.mzp.bismush.decoder")!
    }
}

protocol CustomizableCoder {
    var userInfo: [CodingUserInfoKey: Any] { get set }
}

extension JSONEncoder: CustomizableCoder {}
extension JSONDecoder: CustomizableCoder {}
extension PropertyListEncoder: CustomizableCoder {}
extension PropertyListDecoder: CustomizableCoder {}

class BlobEncoder<T: TopLevelEncoder & CustomizableCoder>: TopLevelEncoder, BlobStore {
    typealias Output = T.Output
    private var fileWrapper: FileWrapper
    private var encoder: T

    init(fileWrapper: FileWrapper, encoder: T) {
        self.fileWrapper = fileWrapper
        self.encoder = encoder
    }

    func encode<T>(_ value: T) throws -> Output where T: Encodable {
        encoder.userInfo[Blob.encoderKey] = self
        return try encoder.encode(value)
    }

    func store(id: String, data: NSData) throws {
        fileWrapper.addRegularFile(
            withContents: data as Data,
            preferredFilename: "\(id).data"
        )
    }
}

class BlobDecoder<T: TopLevelDecoder & CustomizableCoder>: TopLevelDecoder {
    typealias Input = T.Input
    private var fileWrapper: FileWrapper
    private var decoder: T

    init(fileWrapper: FileWrapper, decoder: T) {
        self.fileWrapper = fileWrapper
        self.decoder = decoder
    }

    func decode<T>(_ type: T.Type, from: Input) throws -> T where T: Decodable {
        decoder.userInfo[Blob.decoderKey] = self
        return try decoder.decode(type, from: from)
    }

    func load(id: String) throws -> NSData {
        guard let data = fileWrapper.fileWrappers?["\(id).data"]?.regularFileContents else {
            throw InvalidFileFormatError()
        }
        return data as NSData
    }
}
