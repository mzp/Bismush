//
//  BismushError.swift
//  Bismush
//
//  Created by mzp on 7/2/22.
//

import Foundation
protocol BismushError: Error {}
struct UnsupportedError: BismushError {}
struct InvalidContextError: BismushError {}
