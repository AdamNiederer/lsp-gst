Object subclass: ParserService [
    ParserService class >> errors: aString [
        | errors |

        errors := Set new.

        [STInST.STEvaluationDriver
             new parseSmalltalk: aString
                 with: STInST.STFileInParser
                 onError: [:msg :line |
                     errors add: {line. msg.}.
                 ].
        ] on: Exception do: [].

        ^Array withAll: errors.
    ]
]
