// Copyright 2023-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import HyprMX

/// The Chartboost Mediation HyprMX adapter rewarded ad.
final class HyprMXAdapterRewardedAd: HyprMXAdapterAd, PartnerFullscreenAd {

    /// The HyprMXSDK ad instance.
    var ad: HyprMXPlacement?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.loadStarted)
        loadCompletion = completion

        // HyprMX only supports interaction from the Main Thread. Unlike banner ads, Chartboost Mediation SDK
        // does not load rewarded ads on the main thread so we need to wrap this ourselves.
        DispatchQueue.main.async { [self] in
            // Construct a partner ad to be persisted for subsequent ad operations.
            if let ad = HyprMX.getPlacement(self.request.partnerPlacement) {
                self.ad = ad
                ad.placementDelegate = self
                ad.loadAd()
            } else {
                let loadError = error(.loadFailureUnknown)
                log(.loadFailed(loadError))
                completion(.failure(loadError))
                loadCompletion = nil
            }
        }
    }

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.showStarted)
        // Chartboost Mediation SDK already calls show() on the main thread so we don't need to wrap this
        guard let ad = ad,
              ad.isAdAvailable() else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(.failure(error))
            return
        }
        showCompletion = completion

        ad.showAd(from: viewController)
    }
}

extension HyprMXAdapterRewardedAd: HyprMXPlacementDelegate {
    // Called in response to loadAd when there is an ad to show.
    func adAvailable(for placement: HyprMXPlacement) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    // Called in response to loadAd when there's no ad to show.
    func adNotAvailable(for placement: HyprMXPlacement) {
        let loadError = error(.loadFailureNoFill)
        log(.loadFailed(loadError))
        loadCompletion?(.failure(loadError)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    // Called when ad loaded is no longer available for this placement.
    func adExpired(for placement: HyprMXPlacement) {
        log(.didExpire)
        delegate?.didExpire(self, details: [:]) ?? log(.delegateUnavailable)
        showCompletion = nil
    }

    // Called upon conclusion of any ad presentation attempt
    func adDidClose(for placement: HyprMXPlacement, didFinishAd finished: Bool) {
        log(.didDismiss(error: nil))
        let details = ["finished": String(finished)]
        delegate?.didDismiss(self, details: details, error: nil)  ?? log(.delegateUnavailable)
    }

    // Called when user has earned a reward.
    func adDidReward(for placement: HyprMXPlacement, rewardName: String?, rewardValue: Int) {
        log(.didReward)
        var details: [String: String] = [:]
        // Attempt to add "rewardName" key. Nothing will happen if rewardName is nil.
        details["rewardName"] = rewardName
        details["rewardValue"] = String(rewardValue)
        delegate?.didReward(self, details: details) ?? log(.delegateUnavailable)
    }

    // Called immediately before attempting to present an ad.
    func adWillStart(for placement: HyprMXPlacement) {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    // Called when an error occurs during ad presentation.
    func adDisplayError(_ error: Error, placement: HyprMXPlacement) {
        log(.showFailed(error))
        showCompletion?(.failure(error)) ?? log(.showResultIgnored)
        showCompletion = nil
    }
}
