// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import HyprMX

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class HyprMXAdapterConfiguration: NSObject {

    /// The version of the partner SDK.
    @objc static var partnerSDKVersion: String {
        HyprMX.versionString()
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc static let adapterVersion = "4.6.3.0.0"

    /// The partner's unique identifier.
    @objc static let partnerID = "hyprmx"

    /// The human-friendly partner name.
    @objc static let partnerDisplayName = "HyprMX"
}
