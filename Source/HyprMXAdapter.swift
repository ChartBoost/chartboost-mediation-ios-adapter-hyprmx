// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import HyprMX

final class HyprMXAdapter: PartnerAdapter {

    private let AGE_RESTRICTED_USER_KEY = "com.chartboost.adapter.hyprmx.ageRestrictedUser"
    private let DISTRIBUTOR_ID_KEY = "distributor_id"
    private let GAMEID_STORAGE_KEY = "com.chartboost.adapter.hyprmx.game_id"
    // We track "has opted out" instead of "has opted in" because it makes the
    // three-valued (true, false, nil) truth table easier to read
    private var gdprOptOut: Bool? = nil
    private var ccpaOptOut: Bool? = nil

    private var initializationCompletion: ((Error?) -> Void)?

    // MARK: PartnerAdapter

    /// The version of the partner SDK.
    let partnerSDKVersion = HyprMX.versionString()

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.6.2.0.1"

    /// The partner's unique identifier.
    let partnerIdentifier = "hyprmx"

    /// The human-friendly partner name.
    let partnerDisplayName = "HyprMX"

    /// Ad storage managed by Chartboost Mediation SDK.
    let storage: PartnerAdapterStorage
    
    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        self.storage = storage
    }

    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        guard let distributorId = configuration.credentials[DISTRIBUTOR_ID_KEY] as? String else {
            let error = error(.initializationFailureInvalidCredentials, description: "The distributor id was invalid")
            log(.setUpFailed(error))
            completion(error)
            return
        }
        initializationCompletion = completion

        let gameID: String
        if let storedGameID = UserDefaults.standard.object(forKey: GAMEID_STORAGE_KEY) as? String {
            gameID = storedGameID
        } else {
            gameID = ProcessInfo.processInfo.globallyUniqueString
            UserDefaults.standard.set(gameID, forKey: GAMEID_STORAGE_KEY)
        }

        // UserDefaults.standard.bool defaults to false if key is not present
        let savedAgeRestrictedUserSetting = UserDefaults.standard.bool(forKey: AGE_RESTRICTED_USER_KEY)
        // HyprMX.initialize() uses WKWebView, which must only be used on the main thread
        DispatchQueue.main.async { [self] in
            // consentStatus will be updated by setGDPR & setCCPA after init
            HyprMX.initialize(withDistributorId: distributorId,
                              userId: gameID,
                              consentStatus: CONSENT_STATUS_UNKNOWN,
                              ageRestrictedUser: savedAgeRestrictedUserSetting,
                              initializationDelegate: self)
            // For information about these init options, see https://documentation.hyprmx.com/ios-hyprmx-sdk/#initialization-api
        }
    }

    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation( request: PreBidRequest, completion: @escaping ([String: String]?) -> Void ) {
        // HyprMX does not use a bidding token
        completion(nil)
    }

    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        if applies == true {
            switch status {
            case .granted:
                gdprOptOut = false
            case .denied:
                gdprOptOut = true
            case .unknown:
                gdprOptOut = nil
            @unknown default:
                gdprOptOut = nil
            }
        } else {
            // In the case of either a false or nil value of 'applies', we set gdprOptOut
            // to nil, because the GDPR status should not be taken into consideration
            gdprOptOut = nil
        }
        updateConsentState()
    }

    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        // We invert "has given consent" to "NOT has opted out" because the HyprConsent
        ccpaOptOut = !hasGivenConsent
        updateConsentState()
    }

    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        // We map the COPPA setting to HyprMX's ageRestrictedUser setting based on their description
        // of its intended use, for instance "If the user requires child-directed treatment under
        // applicable laws and policies, set this parameter to true."
        // More info at https://documentation.hyprmx.com/ios-hyprmx-sdk/#initialization-api
        UserDefaults.standard.set(isChildDirected, forKey: AGE_RESTRICTED_USER_KEY)
        log(.privacyUpdated(setting: "ageRestrictedUser", value: isChildDirected))
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread for banner ads.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        // Prevent multiple loads for the same partner placement, since the partner SDK cannot handle them.
        // Banner loads are allowed so a banner prefetch can happen during auto-refresh.
        // ChartboostMediationSDK 4.x does not support loading more than 2 banners with the same placement, and the partner may or may not support it.
        guard !storage.ads.contains(where: { $0.request.partnerPlacement == request.partnerPlacement })
            || request.format == .banner
        else {
            log("Failed to load ad for already loading placement \(request.partnerPlacement)")
            throw error(.loadFailureLoadInProgress)
        }
        
        switch request.format {
        case .banner:
            return HyprMXAdapterBannerAd(adapter: self, request: request, delegate: delegate)
        case .interstitial:
            return HyprMXAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case .rewarded:
            return HyprMXAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }

    /// HyprMX distills all privacy preferences into a single HyprConsentStatus value, so the we have to look at both the
    /// GDPR and CCPA settings whenever we receive an update.
    /// Details are available here https://documentation.hyprmx.com/ios-hyprmx-sdk/#quickstart-initializinghyprmx
    func determineConsentState() -> HyprConsentStatus {
        if gdprOptOut == true || ccpaOptOut == true {
            return CONSENT_DECLINED
        } else if gdprOptOut == false && ccpaOptOut != true {
            return CONSENT_GIVEN
        } else if gdprOptOut != true && ccpaOptOut == false {
            // At this point, the only gdprOptOut value we're still looking for is nil,
            // but the symmetry of the logic with the previous if-condition is clearer this way
            return CONSENT_GIVEN
        } else {
            return CONSENT_STATUS_UNKNOWN
        }
    }

    private func updateConsentState() {
        // To make unit testing possible, the consent state logic was broken out into a function
        // that returns a value. All updateConsentState needs to do is send that value to HyprMX

        // HyprMX only supports interaction from the Main Thread
        DispatchQueue.main.async { [self] in
            let consentState = determineConsentState()
            HyprMX.setConsentStatus(consentState)
            log(.privacyUpdated(setting: "HyprConsentStatus", value: consentState.description))
        }
    }
}

extension HyprMXAdapter: HyprMXInitializationDelegate {
    func initializationDidComplete() {
        log(.setUpSucceded)
        initializationCompletion?(nil)
        initializationCompletion = nil
    }

    func initializationFailed() {
        let error = error(.initializationFailureUnknown)
        log(.setUpFailed(error))
        initializationCompletion?(error)
        initializationCompletion = nil
    }
}

extension HyprConsentStatus {
    var description: String {
        switch self.rawValue {
        case 0:
            return "CONSENT_STATUS_UNKNOWN"
        case 1:
            return "CONSENT_GIVEN"
        case 2:
            return "CONSENT_DECLINED"
        default:
            return "undefined consent status"
        }
    }
}
