import Foundation
import os.activity

// Bridging Obj-C variabled defined as c-macroses. See `activity.h` header.
// swiftlint:disable identifier_name line_length
private let OS_ACTIVITY_NONE = unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "_os_activity_none"), to: OS_os_activity.self)
private let OS_ACTIVITY_CURRENT = unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "_os_activity_current"), to: OS_os_activity.self)
// swiftlint:enable identifier_name line_length

public struct Activity {
    private let activity: OS_os_activity!

    public init(_ description: String, dso: UnsafeRawPointer? = #dsohandle, options: Options = []) {
        var description = description
        activity = description.withUTF8 {
            if let dso = UnsafeMutableRawPointer(mutating: dso), let address = $0.baseAddress {
                let str = UnsafeRawPointer(address).assumingMemoryBound(to: Int8.self)
                let flag = os_activity_flag_t(rawValue: options.rawValue)
                return _os_activity_create(dso, str, OS_ACTIVITY_CURRENT, flag)
            } else {
                return nil
            }
        }
    }

    public init(_ description: String, dso: UnsafeRawPointer? = #dsohandle, parent: Activity, options: Options = []) {
        let parentActivity: OS_os_activity = parent.activity != nil ? parent.activity : OS_ACTIVITY_CURRENT
        var description = description
        activity = description.withUTF8 {
            if let dso = UnsafeMutableRawPointer(mutating: dso), let address = $0.baseAddress {
                let str = UnsafeRawPointer(address).assumingMemoryBound(to: Int8.self)
                return _os_activity_create(dso, str, parentActivity, os_activity_flag_t(rawValue: options.rawValue))
            } else {
                return nil
            }
        }
    }

    private init(_ activity: OS_os_activity) {
        self.activity = activity
    }
}

public extension Activity {
    static var nothing: Activity {
        Activity(OS_ACTIVITY_NONE)
    }

    static var current: Activity {
        Activity(OS_ACTIVITY_CURRENT)
    }

    static func initiate(_ description: String, dso: UnsafeRawPointer? = #dsohandle, options: Options = [],
                         execute body: @convention(block) () -> Void)
    {
        var description = description
        description.withUTF8 {
            if let dso = UnsafeMutableRawPointer(mutating: dso), let address = $0.baseAddress {
                let str = UnsafeRawPointer(address).assumingMemoryBound(to: Int8.self)
                _os_activity_initiate(dso, str, os_activity_flag_t(rawValue: options.rawValue), body)
            }
        }
    }

    func apply(execute body: @convention(block) () -> Void) {
        if activity != nil {
            os_activity_apply(activity, body)
        }
    }

    func enter() -> Scope {
        var scope = Scope()
        if activity != nil {
            os_activity_scope_enter(activity, &scope.state)
        }
        return scope
    }

    /**
     * Label an activity that is auto-generated by AppKit/UIKit with a name that is
     * useful for debugging macro-level user actions.  The API should be called
     * early within the scope of the IBAction and before any sub-activities are
     * created.
     * This API can only be called once and only on the activity created by AppKit/UIKit.
     */
    static func labelUserAction(_ description: StaticString, dso: UnsafeRawPointer? = #dsohandle) {
        description.withUTF8Buffer {
            if let dso = UnsafeMutableRawPointer(mutating: dso), let address = $0.baseAddress {
                let str = UnsafeRawPointer(address).assumingMemoryBound(to: Int8.self)
                _os_activity_label_useraction(dso, str)
            }
        }
    }
}

public extension Activity {
    struct Options: OptionSet {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let `default` = Options(rawValue: OS_ACTIVITY_FLAG_DEFAULT.rawValue)
        public static let detached = Options(rawValue: OS_ACTIVITY_FLAG_DETACHED.rawValue)
        public static let ifNonePresent = Options(rawValue: OS_ACTIVITY_FLAG_IF_NONE_PRESENT.rawValue)
    }

    struct Scope {
        fileprivate var state = os_activity_scope_state_s()

        public mutating func leave() {
            os_activity_scope_leave(&state)
        }
    }
}
