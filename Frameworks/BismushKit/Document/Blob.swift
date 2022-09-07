//
//  Blob.swift
//  Bismush
//
//  Created by Hiro Mizuno on 9/5/22.
//

import Foundation

protocol DataManager {
    func store(id: String, data: Data)
    func load(id: String) -> Data
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
        if let manager = decoder.userInfo[Self.dataManager] as? DataManager {
            self.data = manager.load(id: id) as NSData
        } else {
            self.data = NSData()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        if let manager = encoder.userInfo[Self.dataManager] as? DataManager {
            manager.store(id: id, data: data as Data)
        }
    }

    static func == (lhs: Blob, rhs: Blob) -> Bool {
        lhs.id == rhs.id
    }

    static var dataManager: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "dataManager")!
    }
}
