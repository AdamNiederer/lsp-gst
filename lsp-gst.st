Eval [
    | reader writer |

    reader := (LSPReader new onStream: FileStream stdin).
    writer := (LSPWriter new onStream: FileStream stdout).
    [true] whileTrue: [
        reader nextMessage ifNotNil: [:message |
            | response |

            (((message body includesKey: 'id') ifTrue: ['-R>'] ifFalse: ['-N>']), (message body asJSON), (String with: Character lf)) displayOn: (FileStream stderr).
            FileStream stderr flush.

            [response := (MessageDispatcher dispatch: message body)]
                on: Error
                do: [].

            (message body includesKey: 'id') ifTrue: [
                ('<R-', ((response at: 'response') asJSON), (String with: Character lf)) displayOn: (FileStream stderr).
                FileStream stderr flush.
            ].

            writer respondTo: (message body) with: (response at: 'response').

            (response at: 'notifications') do: [:notification |
                ('<N-', ((response at: 'response') asJSON), (String with: Character lf)) displayOn: (FileStream stderr).
                writer notify: (notification at: 'method') with: (notification at: 'params').
            ].
        ].
    ]
]
