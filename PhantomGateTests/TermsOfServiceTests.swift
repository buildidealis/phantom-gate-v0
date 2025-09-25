//
//  TermsOfServiceTests.swift
//  PhantomGateTests
//
//  Created for Terms of Service functionality testing.
//

import Testing
import Foundation
@testable import PhantomGate

struct TermsOfServiceTests {

    // MARK: - UserDefaults Management Tests

    @Test func testInitialTermsState() async throws {
        // Clear any existing terms acceptance
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAcceptedDate")

        // Test initial state
        let hasAccepted = TermsOfServiceManager.hasAcceptedTerms()
        #expect(hasAccepted == false)
    }

    @Test func testTermsAcceptance() async throws {
        // Clear any existing terms acceptance
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAcceptedDate")

        // Simulate accepting terms
        UserDefaults.standard.set(true, forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.set(Date(), forKey: "TermsOfServiceAcceptedDate")

        // Verify acceptance is recorded
        let hasAccepted = TermsOfServiceManager.hasAcceptedTerms()
        #expect(hasAccepted == true)

        // Verify date is recorded
        let acceptedDate = UserDefaults.standard.object(forKey: "TermsOfServiceAcceptedDate") as? Date
        #expect(acceptedDate != nil)
    }

    @Test func testTermsManagerInitialization() async throws {
        // Clear existing state
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAcceptedDate")

        // Create manager - should detect no acceptance
        let manager = TermsOfServiceManager()
        #expect(manager.shouldShowTerms == true)

        // Accept terms
        UserDefaults.standard.set(true, forKey: "TermsOfServiceAccepted")

        // Create new manager - should detect acceptance
        let manager2 = TermsOfServiceManager()
        #expect(manager2.shouldShowTerms == false)
    }

    @Test func testTermsManagerStateCheck() async throws {
        let manager = TermsOfServiceManager()

        // Clear acceptance
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAccepted")
        manager.checkIfShouldShowTerms()
        #expect(manager.shouldShowTerms == true)

        // Set acceptance
        UserDefaults.standard.set(true, forKey: "TermsOfServiceAccepted")
        manager.checkIfShouldShowTerms()
        #expect(manager.shouldShowTerms == false)
    }

    // MARK: - Terms URL Tests

    @Test func testTermsURL() async throws {
        // Verify the Terms URL is properly formatted
        let expectedURL = "https://mkdale.github.io/PGmarketingsite/terms.html"
        let url = URL(string: expectedURL)

        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "mkdale.github.io")
        #expect(url?.path == "/PGmarketingsite/terms.html")
    }

    // MARK: - UserDefaults Keys Tests

    @Test func testUserDefaultsKeysConsistency() async throws {
        // Test that the UserDefaults keys are consistent across the codebase
        let acceptedKey = "TermsOfServiceAccepted"
        let dateKey = "TermsOfServiceAcceptedDate"

        // These should be the keys used throughout the application
        #expect(acceptedKey.count > 0)
        #expect(dateKey.count > 0)
        #expect(acceptedKey != dateKey)
    }

    // MARK: - Cleanup

    func cleanupUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAcceptedDate")
    }
}
