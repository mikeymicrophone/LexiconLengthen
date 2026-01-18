//
//  DatamuseLookupTests.swift
//  Lexicon LengthenTests
//
//  Created by Mike Schwab on 1/18/26.
//

import Foundation
import Testing
@testable import Lexicon_Lengthen

struct DatamuseLookupTests {

    @Test func datamuseLookupReturnsSuggestion() async throws {
        let suggestion = await PartOfSpeechResolver.shared.lookup(for: "example")
        #expect(
            suggestion.partOfSpeech != nil || suggestion.ipa != nil,
            "Expected Datamuse to return a part of speech or IPA for a common word."
        )
    }

}
