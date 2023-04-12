// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import HyprMX

/// The Chartboost Mediation HyprMX adapter banner ad.
final class HyprMXAdapterBannerAd: HyprMXAdapterAd, PartnerAd {
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        loadCompletion = completion

        guard let size = request.size else {
            let loadError = ChartboostMediationError(code: .loadFailureInvalidBannerSize)
            log(.loadFailed(loadError))
            completion(.failure(loadError))
            loadCompletion = nil
            return
        }

        // Chartboost Mediation SDK already calls banner load() on the main thread so we don't need to wrap this
//        let ad = HyprMXBannerView.init(placementName: request.partnerPlacement, adSize: size)
        let ad = HyprMXBannerView.init(placementName: "banner_320_50", adSize: size) // Usefull for testing until dashboard placements are working
        inlineView = ad
        ad.placementDelegate = self
        ad.loadAd()
    }

    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }

}

/// These delegate method  descriptions are taken from HyprMX's documentation https://documentation.hyprmx.com/ios-hyprmx-sdk/banner-ads
/// Note the ambiguity between the name 'adDidOpen' and the description saying "... WILL open a full-screen modal"
extension HyprMXAdapterBannerAd: HyprMXBannerDelegate {
    // Called in response to loadAd when an ad was loaded
    func adDidLoad(_ bannerView: HyprMXBannerView) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    // Called in response to loadAd when there was an error loading an ad
    func adFailed(toLoad bannerView: HyprMXBannerView, error: Error) {
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    // Called when a banner click will open a full-screen modal
    func adDidOpen(_ bannerView: HyprMXBannerView) {
        log(.showSucceeded)
    }

    // Called when a full-screen modal has been closed
    func adDidClose(_ bannerView: HyprMXBannerView) {
        log(.delegateCallIgnored)
    }

    // Called when the user clicks on the bannerView
    func adWasClicked(_ bannerView: HyprMXBannerView) {
        log(.didClick(error: nil))
    }

    // Called when a banner click will open another application
    func adWillLeaveApplication(_ bannerView: HyprMXBannerView) {
        log(.delegateCallIgnored)
    }
}
