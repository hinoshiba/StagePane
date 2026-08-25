import Foundation
import XCTest
@testable import StagePaneCore

final class ReviewPromptPolicyTests: XCTestCase {
    func testSuccessfulSessionRequiresAUsefulCleanRun() {
        XCTAssertFalse(ReviewPromptPolicy.qualifiesAsSuccessfulSession(
            duration: 59,
            needsAttention: false,
            reachedPreview: true
        ))
        XCTAssertFalse(ReviewPromptPolicy.qualifiesAsSuccessfulSession(
            duration: 120,
            needsAttention: true,
            reachedPreview: true
        ))
        XCTAssertFalse(ReviewPromptPolicy.qualifiesAsSuccessfulSession(
            duration: 120,
            needsAttention: false,
            reachedPreview: false
        ))
        XCTAssertTrue(ReviewPromptPolicy.qualifiesAsSuccessfulSession(
            duration: 60,
            needsAttention: false,
            reachedPreview: true
        ))
    }

    func testRequiresRepeatedSuccessAndTimeToLearnTheApp() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let experiencedSince = now.addingTimeInterval(-ReviewPromptPolicy.minimumExperience)

        XCTAssertFalse(ReviewPromptPolicy.shouldRequestReview(
            successfulSessionCount: 2,
            firstSuccessfulSessionDate: experiencedSince,
            lastRequestedVersion: nil,
            currentVersion: "1.0",
            now: now
        ))
        XCTAssertFalse(ReviewPromptPolicy.shouldRequestReview(
            successfulSessionCount: 3,
            firstSuccessfulSessionDate: now.addingTimeInterval(-60),
            lastRequestedVersion: nil,
            currentVersion: "1.0",
            now: now
        ))
        XCTAssertTrue(ReviewPromptPolicy.shouldRequestReview(
            successfulSessionCount: 3,
            firstSuccessfulSessionDate: experiencedSince,
            lastRequestedVersion: nil,
            currentVersion: "1.0",
            now: now
        ))
    }

    func testRequestsAtMostOncePerMarketingVersion() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let experiencedSince = now.addingTimeInterval(-ReviewPromptPolicy.minimumExperience)

        XCTAssertFalse(ReviewPromptPolicy.shouldRequestReview(
            successfulSessionCount: 12,
            firstSuccessfulSessionDate: experiencedSince,
            lastRequestedVersion: "1.0",
            currentVersion: "1.0",
            now: now
        ))
        XCTAssertTrue(ReviewPromptPolicy.shouldRequestReview(
            successfulSessionCount: 12,
            firstSuccessfulSessionDate: experiencedSince,
            lastRequestedVersion: "1.0",
            currentVersion: "1.1",
            now: now
        ))
    }
}
