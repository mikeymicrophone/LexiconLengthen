//
//  DeleteWordConfirmationView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/20/26.
//

import SwiftUI

struct DeleteWordConfirmationView: View {
    let word: Word
    let onDelete: (Word) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            VStack(alignment: .leading, spacing: 16) {
                Text("Delete this word from the device?")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text(word.spellingText)
                        .font(.title3.weight(.semibold))
                    Text(word.partOfSpeech)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("This removes the word, its definitions, and pronunciations from this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Delete", role: .destructive) {
                        onDelete(word)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(maxWidth: 320)
            .shadow(radius: 16)
            .padding()
        }
    }
}
