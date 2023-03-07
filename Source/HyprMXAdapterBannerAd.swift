// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import HyprMX

/// The Chartboost Mediation HyprMX adapter banner ad.
final class HyprMXAdapterBannerAd: HyprMXAdapterAd, PartnerAd {

    /// The HyprMXSDK ad instance.
//    var ad: HyprMXPlacement?
    var ad: HyprMXBannerView?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        self.loadCompletion = completion

        // TODO: Validate ad size? https://documentation.hyprmx.com/ios-hyprmx-sdk/banner-ads
        guard let size = self.request.size else {
            let loadError = ChartboostMediationError(code: .loadFailureInvalidBannerSize)
            log(.loadFailed(loadError))
            completion(.failure(loadError))
            return
        }

        ad = HyprMXBannerView.init(placementName: self.request.partnerPlacement, adSize: size)

        // TODO: *show* the banner ad
    }

    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }

}

extension HyprMXAdapterBannerAd: HyprMXPlacementDelegate {
    // Called in response to loadAd when there is an ad to show.
    func adAvailable(for placement: HyprMXPlacement) {
        log(PartnerAdLogEvent.loadSucceeded)
        self.loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
    }

    // Called in response to loadAd when there's no ad to show.
    func adNotAvailable(for placement: HyprMXPlacement) {
        let loadError = ChartboostMediationError(code: .loadFailureUnknown)
        log(.loadFailed(loadError))
        self.loadCompletion?(.failure(loadError)) ?? log(.loadResultIgnored)
    }

    // Called when ad loaded is no longer available for this placement.
    func adExpired(for placement: HyprMXPlacement) {
        log(.didExpire)
        self.delegate?.didExpire(self, details: [:]) ?? self.log(.delegateUnavailable)
    }

    // Called upon conclusion of any ad presentation attempt
    func adDidClose(for placement: HyprMXPlacement, didFinishAd finished: Bool) {
        log(.didDismiss(error: nil))
        let details = ["finished": String(finished)]
        self.delegate?.didDismiss(self, details: details, error: nil)  ?? self.log(.delegateUnavailable)
    }

    // Called immediately before attempting to present an ad.
    func adWillStart(for placement: HyprMXPlacement) {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
    }

    // Called when an error occurs during ad presentation.
    func adDisplayError(_ error: Error, placement: HyprMXPlacement) {
        log(.showFailed(error))
    }
}
