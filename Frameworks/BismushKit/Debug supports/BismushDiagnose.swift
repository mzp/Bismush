//
//  Diagnose.swift
//  Bismush
//
//  Created by mzp on 3/22/22.
//

import Metal

enum BismushDiagnose {
    #if os(macOS)
        static func locationName(_ location: MTLDeviceLocation) -> String {
            switch location {
            case .builtIn:
                return "built in"
            case .external:
                return "external"
            case .slot:
                return "slot"
            default:
                return "unknown"
            }
        }
    #endif

    // swiftlint:disable cyclomatic_complexity
    static func gpuFamilyName(_ family: MTLGPUFamily) -> String {
        switch family {
        case .common1:
            return "Common 1"
        case .common2:
            return "Common 2"
        case .common3:
            return "Common 3"
        case .apple1:
            return "Apple 1"
        case .apple2:
            return "Apple 2"
        case .apple3:
            return "Apple 3"
        case .apple4:
            return "Apple 4"
        case .apple5:
            return "Apple 5"
        case .apple6:
            return "Apple 6"
        case .apple7:
            return "Apple 7"
        case .apple8:
            return "Apple 8"
        case .mac2:
            return "mac 2"
        case .macCatalyst1:
            return "mac Catalyst 1"
        case .macCatalyst2:
            return "mac Catalyst 2"
        default:
            if #available(iOS 16, macOS 13, *) {
                if family == .metal3 {
                    return "metal3"
                }
            }
            return "unknown"
        }
    }

    // swiftlint:enable cyclomatic_complexity

    // swiftlint:disable function_body_length
    static func record(device: MTLDevice) {
        var diagnose = [String]()
        let macGPUFamily = [
            MTLGPUFamily.mac2,
        ].first(where: { device.supportsFamily($0) })
        let appleGPUFamily = [
            MTLGPUFamily.apple7,
            .apple6,
            .apple5,
            .apple4,
            .apple3,
            .apple2,
            .apple1,
        ].first(where: device.supportsFamily)
        let commonGPUFamily = [
            MTLGPUFamily.common3,
            .common2,
            .common1,
        ].first(where: device.supportsFamily)
        let metalFamily: MTLGPUFamily?
        if #available(iOS 16, macOS 13, *) {
            metalFamily = [
                MTLGPUFamily.metal3,
            ].first(where: device.supportsFamily)
        } else {
            metalFamily = nil
        }

        let families = [
            macGPUFamily,
            appleGPUFamily,
            commonGPUFamily,
            metalFamily,
        ].compactMap { family -> String? in
            if let family = family {
                return Self.gpuFamilyName(family)
            } else {
                return nil
            }
        }

        // basic device info
        diagnose.append("register id: \(device.registryID)")

        #if os(macOS)
            diagnose.append("location: \(locationName(device.location))")

            // device status
            if device.isRemovable {
                diagnose.append("removable")
            }
            if device.isHeadless {
                diagnose.append("headless")
            }
            if device.isLowPower {
                diagnose.append("low power")
            }
            // device spec
            diagnose.append("max transfer rate: \(device.maxTransferRate)")
        #endif

        diagnose.append("max buffer length: \(device.maxBufferLength)")
        diagnose.append("max threadgroup memory length: \(device.maxThreadgroupMemoryLength)")
        diagnose.append("max threads per threadgroup: \(device.maxThreadsPerThreadgroup)")
        diagnose.append("max arugment buffer sample count: \(device.maxArgumentBufferSamplerCount)")

        if device.hasUnifiedMemory {
            diagnose.append("unified memory")
        }

        // supported feautres
        diagnose.append("families: \(families.joined(separator: ", "))")

        // especially, we interested in these features
        if device.supportsRaytracing {
            diagnose.append("ray tracing")
        }

        if device.supports32BitMSAA {
            diagnose.append("msaa")
        } else {
            diagnose.append("no msaa")
        }

        BismushLogger.metal.info("Use \(device.name) (\(diagnose.joined(separator: "; ")))")
    }
    // swiftlint:enable function_body_length
}
