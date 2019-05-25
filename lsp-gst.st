Eval [
    | reader writer |

    reader := (LSPReader new onStream: FileStream stdin).
    writer := (LSPWriter new onStream: FileStream stdout).
    [true] whileTrue: [
        reader nextMessage ifNotNil: [:message |
            | response |

            ('->', (message body asJSON), (String with: Character lf)) displayOn: (FileStream stderr).
            FileStream stderr flush.

            response := (MessageDispatcher dispatch: message body).

            ('<-', (response asJSON), (String with: Character lf)) displayOn: (FileStream stderr).
            FileStream stderr flush.

            writer respondTo: (message body) with: response.
        ].
    ]
]
