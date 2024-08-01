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
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)

        // HyprMX only supports interaction from the Main Thread. Unlike banner ads, Chartboost Mediation SDK
        // does not load rewarded ads on the main thread so we need to wrap this ourselves.
        DispatchQueue.main.async { [self] in
            // Construct a partner ad to be persisted for subsequent ad operations.
            if let ad = HyprMX.getPlacement(self.request.partnerPlacement) {
                self.ad = ad
                ad.expiredDelegate = self
                ad.loadAd { [weak self] success in
                    guard let self else { return }
                    if success {
                        self.log(.loadSucceeded)
                        completion(nil)
                    } else {
                        let loadError = self.error(.loadFailureUnknown)
                        self.log(.loadFailed(loadError))
                        completion(loadError)
                    }
                }
            } else {
                let loadError = error(.loadFailureUnknown)
                log(.loadFailed(loadError))
                completion(loadError)
            }
        }
    }

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)
        // Chartboost Mediation SDK already calls show() on the main thread so we don't need to wrap this
        guard let ad,
              ad.isAdAvailable else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(error)
            return
        }
        showCompletion = completion

        ad.showAd(from: viewController, delegate: self)
    }
}

extension HyprMXAdapterRewardedAd: HyprMXPlacementShowDelegate {
    // Called upon conclusion of any ad presentation attempt
    func adDidClose(placement: HyprMXPlacement, finished: Bool) {
        log(.didDismiss(error: nil))
        details["finished"] = String(finished)
        delegate?.didDismiss(self, error: nil) ?? log(.delegateUnavailable)
    }

    // Called immediately before attempting to present an ad.
    func adWillStart(placement: HyprMXPlacement) {
        log(.showSucceeded)
        showCompletion?(nil) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    // Called when user has earned a reward.
    func adDidReward(placement: HyprMXPlacement, rewardName: String?, rewardValue: Int) {
        log(.didReward)
        var details: [String: String] = [:]
        // Attempt to add "rewardName" key. Nothing will happen if rewardName is nil.
        details["rewardName"] = rewardName
        details["rewardValue"] = String(rewardValue)
        delegate?.didReward(self) ?? log(.delegateUnavailable)
    }

    // Called when an error occurs during ad presentation.
    func adDisplay(error: NSError, placement: HyprMXPlacement) {
        log(.showFailed(error))
        showCompletion?(error) ?? log(.showResultIgnored)
        showCompletion = nil
    }
}

extension HyprMXAdapterRewardedAd: HyprMXPlacementExpiredDelegate {
    // Called when ad loaded is no longer available for this placement.
    func adExpired(placement: HyprMXPlacement) {
        log(.didExpire)
        delegate?.didExpire(self) ?? log(.delegateUnavailable)
        showCompletion = nil
    }
}
