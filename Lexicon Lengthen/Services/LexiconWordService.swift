//
//  LexiconWordService.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/20/26.
//

import Foundation
import SwiftData

enum LexiconWordService {
    static func lexiconWordIDs(from entries: [UserLexiconEntry]) -> Set<Word.ID> {
        Set(entries.compactMap { $0.word?.id })
    }

    static func isInLexicon(_ word: Word, entries: [UserLexiconEntry]) -> Bool {
        entries.contains { entry in
            entry.word?.persistentModelID == word.persistentModelID
        }
    }

    static func removeFromLexicon(
        _ word: Word,
        entries: [UserLexiconEntry],
        in context: ModelContext
    ) {
        let wordID = word.persistentModelID.storeIdentifier ?? ""
        for entry in entries {
            if entry.word?.persistentModelID == word.persistentModelID {
                context.delete(entry)
                continue
            }
            if !wordID.isEmpty && entry.wordID == wordID {
                context.delete(entry)
            }
        }
        try? context.save()
    }

    static func deleteWord(
        _ word: Word,
        entries: [UserLexiconEntry],
        in context: ModelContext
    ) {
        removeFromLexicon(word, entries: entries, in: context)
        context.delete(word)
        try? context.save()
    }
}
