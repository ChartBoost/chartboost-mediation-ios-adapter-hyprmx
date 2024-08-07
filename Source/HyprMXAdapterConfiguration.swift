// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import HyprMX

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class HyprMXAdapterConfiguration: NSObject, PartnerAdapterConfiguration {
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        HyprMX.versionString()
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the 
    /// last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.
    /// <Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.6.4.0.0"

    /// The partner's unique identifier.
    @objc public static let partnerID = "hyprmx"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "HyprMX"

    /// Flag that can optionally be set to change the log level of the HyprMX SDK.
    @objc public static var logLevel: HYPRLogLevel = HYPRLogLevelError {
        didSet {
            HyprMX.setLogLevel(logLevel)
            log("Log level set to \(logLevel)")
        }
    }

    /// Use to manually set the consent status on the HyprMX SDK.
    /// This is generally unnecessary as the Mediation SDK will set the consent status automatically based on the latest consent info.
    @objc public static func setConsentStatusOverride(_ status: HyprConsentStatus) {
        // HyprMX only supports interaction from the Main Thread
        DispatchQueue.main.async { [self] in
            isConsentStatusOverridden = true
            HyprMX.setConsentStatus(status)
            log("Consent status override set to \(status)")
        }
    }

    /// Internal flag that indicates if the consent status has been overridden by the publisher.
    private(set) static var isConsentStatusOverridden = false
}
