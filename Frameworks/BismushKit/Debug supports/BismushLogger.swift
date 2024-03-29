//
//  BismushLogger.swift
//  Bismush
//
//  Created by mzp on 3/16/22.
//

import Foundation
import os

public enum BismushLogger {
    public static let desktop = Logger(subsystem: "jp.mzp.bismush", category: "desktop")
    public static let dev = Logger(subsystem: "jp.mzp.bismush", category: "dev")
    public static let drawing = Logger(subsystem: "jp.mzp.bismush", category: "drawing")
    public static let event = Logger(subsystem: "jp.mzp.bismush", category: "event")
    public static let file = Logger(subsystem: "jp.mzp.bismush", category: "file")
    public static let metal = Logger(subsystem: "jp.mzp.bismush", category: "metal")
    public static let mobile = Logger(subsystem: "jp.mzp.bismush", category: "mobile")
    public static let testing = Logger(subsystem: "jp.mzp.bismush", category: "testing")
    public static let texture = Logger(subsystem: "jp.mzp.bismush", category: "texture")
}
