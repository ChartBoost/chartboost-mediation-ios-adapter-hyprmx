// Copyright 2023-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import HyprMX

final class HyprMXAdapter: PartnerAdapter {

    private let DISTRIBUTOR_ID_KEY = "distributor_id"
    private let GAMEID_STORAGE_KEY = "com.chartboost.adapter.hyprmx.game_id"
    private var initializationCompletion: ((Result<PartnerDetails, Error>) -> Void)?

    // MARK: PartnerAdapter

    /// The adapter configuration type that contains adapter and partner info.
    /// It may also be used to expose custom partner SDK options to the publisher.
    var configuration: PartnerAdapterConfiguration.Type { HyprMXAdapterConfiguration.self }

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
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.setUpStarted)
        guard let distributorId = configuration.credentials[DISTRIBUTOR_ID_KEY] as? String else {
            let error = error(.initializationFailureInvalidCredentials, description: "The distributor id was invalid")
            log(.setUpFailed(error))
            completion(.failure(error))
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
        // HyprMX.initialize() uses WKWebView, which must only be used on the main thread
        DispatchQueue.main.async { [self] in
            HyprMX.setLogLevel(HYPRLogLevelDebug)
            
            // consentStatus will be updated by setConsents() after init
            HyprMX.initialize(
                withDistributorId: distributorId,
                userId: gameID,
                consentStatus: consentStatus(from: configuration.consents),
                ageRestrictedUser: configuration.isUserUnderage,
                initializationDelegate: self
            )
            // For information about these init options, see https://documentation.hyprmx.com/ios-hyprmx-sdk/#initialization-api
        }
    }

    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation( request: PartnerAdPreBidRequest, completion: @escaping (Result<[String: String], Error>) -> Void ) {
        // HyprMX does not use a bidding token
        log(.fetchBidderInfoNotSupported)
        completion(.success([:]))
    }

    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        // Ignore if the consent status has been directly set by publisher via the configuration class.
        guard !HyprMXAdapterConfiguration.isConsentStatusOverriden else {
            return
        }
        guard modifiedKeys.contains(configuration.partnerID)
                || modifiedKeys.contains(ConsentKeys.gdprConsentGiven)
                || modifiedKeys.contains(ConsentKeys.ccpaOptIn)
        else {
            return
        }
        // HyprMX only supports interaction from the Main Thread
        DispatchQueue.main.async { [self] in
            let consentStatus = consentStatus(from: consents)
            HyprMX.setConsentStatus(consentStatus)
            log(.privacyUpdated(setting: "HyprConsentStatus", value: consentStatus.description))
        }
    }

    /// Indicates that the user is underage signal has changed.
    /// - parameter isUserUnderage: `true` if the user is underage as determined by the publisher, `false` otherwise.
    func setIsUserUnderage(_ isUserUnderage: Bool) {
        // HyprMX has requested that we simply default to "true" at init.
    }

    /// HyprMX distills all privacy preferences into a single HyprConsentStatus value, so the we have to look at both the
    /// GDPR and CCPA settings whenever we receive an update.
    /// Details are available here https://documentation.hyprmx.com/ios-hyprmx-sdk/#quickstart-initializinghyprmx
    private func consentStatus(from consents: [ConsentKey: ConsentValue]) -> HyprConsentStatus {
        // Determine GDPR status
        let gdprOptOut: Bool?
        let consent = consents[configuration.partnerID] ?? consents[ConsentKeys.gdprConsentGiven]
        switch consent {
        case ConsentValues.granted:
            gdprOptOut = false
        case ConsentValues.denied:
            gdprOptOut = true
        default:
            gdprOptOut = nil
        }
        // Determine CCPA status
        let ccpaOptOut: Bool?
        switch consents[ConsentKeys.ccpaOptIn] {
        case ConsentValues.granted:
            ccpaOptOut = false
        case ConsentValues.denied:
            ccpaOptOut = true
        default:
            ccpaOptOut = nil
        }
        // Determine general status
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

    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        // Multiple banner loads are allowed so a banner prefetch can happen during auto-refresh.
        // ChartboostMediationSDK 5.x does not support loading more than 2 banners with the same placement, and the partner may or may not support it.
        HyprMXAdapterBannerAd(adapter: self, request: request, delegate: delegate)
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        // Prevent multiple loads for the same partner placement, since the partner SDK cannot handle them.
        guard !storage.ads.contains(where: { $0.request.partnerPlacement == request.partnerPlacement }) else {
            log(.skippedLoadForAlreadyLoadingPlacement(request))
            throw error(.loadFailureLoadInProgress)
        }
        
        switch request.format {
        case PartnerAdFormats.interstitial:
            return HyprMXAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case PartnerAdFormats.rewarded:
            return HyprMXAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
}

extension HyprMXAdapter: HyprMXInitializationDelegate {
    func initializationDidComplete() {
        log(.setUpSucceded)
        initializationCompletion?(.success([:]))
        initializationCompletion = nil
    }

    func initializationFailed() {
        let error = error(.initializationFailureUnknown)
        log(.setUpFailed(error))
        initializationCompletion?(.failure(error))
        initializationCompletion = nil
    }
}

extension HyprConsentStatus {
    var description: String {
        switch self {
        case CONSENT_STATUS_UNKNOWN:
            return "CONSENT_STATUS_UNKNOWN"
        case CONSENT_GIVEN:
            return "CONSENT_GIVEN"
        case CONSENT_DECLINED:
            return "CONSENT_DECLINED"
        default:
            return "undefined consent status"
        }
    }
}
