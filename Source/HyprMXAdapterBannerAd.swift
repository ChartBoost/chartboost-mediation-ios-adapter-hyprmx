// Copyright 2023-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import HyprMX

/// The Chartboost Mediation HyprMX adapter banner ad.
final class HyprMXAdapterBannerAd: HyprMXAdapterAd, PartnerBannerAd {
    /// The partner banner ad view to display.
    var view: UIView?

    /// The loaded partner ad banner size.
    var size: PartnerBannerSize?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.loadStarted)
        guard let requestedSize = request.bannerSize,
              let loadedSize = BannerSize.largestStandardFixedSizeThatFits(in: requestedSize)?.size else {
            let loadError = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(loadError))
            completion(.failure(loadError))
            return
        }
        size = PartnerBannerSize(size: loadedSize, type: .fixed)

        // Chartboost Mediation SDK already calls banner load() on the main thread so we don't need to wrap this
        let ad = HyprMXBannerView(placementName: request.partnerPlacement, adSize: loadedSize)
        view = ad
        ad.placementDelegate = self
        ad.loadAd { [weak self] success in
            guard let self else { return }
            if success {
                self.log(.loadSucceeded)
                completion(.success([:]))
            } else {
                let loadError = self.error(.loadFailureUnknown)
                self.log(.loadFailed(loadError))
                completion(.failure(loadError))
            }
        }
    }
}

/// These delegate method  descriptions are taken from HyprMX's documentation https://documentation.hyprmx.com/ios-hyprmx-sdk/banner-ads
/// Note the ambiguity between the name 'adDidOpen' and the description saying "... WILL open a full-screen modal"
extension HyprMXAdapterBannerAd: HyprMXBannerDelegate {
    // Called when a banner click will open a full-screen modal
    func adDidOpen(_ bannerView: HyprMXBannerView) {
        log(.delegateCallIgnored)
    }

    // Called when a full-screen modal has been closed
    func adDidClose(_ bannerView: HyprMXBannerView) {
        log(.delegateCallIgnored)
    }

    // Called when the user clicks on the bannerView
    func adWasClicked(_ bannerView: HyprMXBannerView) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    // Called when a banner click will open another application
    func adWillLeaveApplication(_ bannerView: HyprMXBannerView) {
        log(.delegateCallIgnored)
    }
}
