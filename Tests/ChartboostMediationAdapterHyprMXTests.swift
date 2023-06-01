//
//  ChartboostMediationAdapterHyprMXTests.swift
//  HeliumCanaryTests
//
//  Created by Alexander Rice on 3/28/23.
//

import ChartboostMediationSDK
@testable import ChartboostMediationAdapterHyprMX
import HyprMX
import XCTest

final class ChartboostMediationAdapterHyprMXTests: XCTestCase {

    var adapter: HyprMXAdapter!

    override func setUpWithError() throws {
        let storage = MockStorage(ads: [])
        adapter = HyprMXAdapter(storage: storage)
    }

    override func tearDownWithError() throws {
        adapter = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let version = HyprMX.versionString()
        XCTAssertNotNil(version)
    }

    func testUninitializedReturnsUnknown() throws {
        let status = adapter.determineConsentState()
         XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRNilUnknown() throws {
        adapter.setGDPR(applies: nil, status: .unknown)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRNilUnknownCCPAFalse() throws {
        adapter.setGDPR(applies: nil, status: .unknown)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRNilUnknownCCPATrue() throws {
        adapter.setGDPR(applies: nil, status: .unknown)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRNilDenied() throws {
        adapter.setGDPR(applies: nil, status: .denied)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRNilDeniedCCPAFalse() throws {
        adapter.setGDPR(applies: nil, status: .denied)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRNilDeniedCCPATrue() throws {
        adapter.setGDPR(applies: nil, status: .denied)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRNilGranted() throws {
        adapter.setGDPR(applies: nil, status: .granted)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRNilGrantedCCPAFalse() throws {
        adapter.setGDPR(applies: nil, status: .granted)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRNilGrantedCCPATrue() throws {
        adapter.setGDPR(applies: nil, status: .granted)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRFalseUnknown() throws {
        adapter.setGDPR(applies: false, status: .unknown)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRFalseUnknownCCPAFalse() throws {
        adapter.setGDPR(applies: false, status: .unknown)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRFalseUnknownCCPATrue() throws {
        adapter.setGDPR(applies: false, status: .unknown)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRFalseDenied() throws {
        adapter.setGDPR(applies: false, status: .denied)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRFalseDeniedCCPAFalse() throws {
        adapter.setGDPR(applies: false, status: .denied)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRFalseDeniedCCPATrue() throws {
        adapter.setGDPR(applies: false, status: .denied)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRFalseGranted() throws {
        adapter.setGDPR(applies: false, status: .granted)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRFalseGrantedCCPAFalse() throws {
        adapter.setGDPR(applies: false, status: .granted)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRFalseGrantedCCPATrue() throws {
        adapter.setGDPR(applies: false, status: .granted)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRTrueUnknown() throws {
        adapter.setGDPR(applies: true, status: .unknown)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_STATUS_UNKNOWN)
    }

    func testGDPRTrueUnknownCCPAFalse() throws {
        adapter.setGDPR(applies: true, status: .unknown)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRTrueUnknownCCPATrue() throws {
        adapter.setGDPR(applies: true, status: .unknown)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRTrueDenied() throws {
        adapter.setGDPR(applies: true, status: .denied)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRTrueDeniedCCPAFalse() throws {
        adapter.setGDPR(applies: true, status: .denied)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRTrueDeniedCCPATrue() throws {
        adapter.setGDPR(applies: true, status: .denied)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRTrueGranted() throws {
        adapter.setGDPR(applies: true, status: .granted)
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }

    func testGDPRTrueGrantedCCPAFalse() throws {
        adapter.setGDPR(applies: true, status: .granted)
        adapter.setCCPA(hasGivenConsent: false, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_DECLINED)
    }

    func testGDPRTrueGrantedCCPATrue() throws {
        adapter.setGDPR(applies: true, status: .granted)
        adapter.setCCPA(hasGivenConsent: true, privacyString: "")
        let status = adapter.determineConsentState()
        XCTAssertEqual(status, CONSENT_GIVEN)
    }


}

class MockStorage: PartnerAdapterStorage {
    var ads: [PartnerAd]
    init(ads: [PartnerAd]) {
        self.ads = ads
    }
}
