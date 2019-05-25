Object subclass: LSPMessage [
    | message |
    from: string [
        message := string.
    ]

    headers [
        ^(message =~ '^(.+)\r\n\r\n') at: 1
    ]

    body [
        ^((message =~ '^(.+?)\r\n\r\n(.+)') at: 2) readStream nextJSON
    ]
]

Object subclass: LSPReader [
    | stream |
    onStream: s [
        stream := s.
    ]

    nextMessage [
        | ret |

        ret := ''.
        [ret ~ '\r\n\r\n'] whileFalse: [
            ret := ret, (stream next ifNotNil: [:x | x asString]).
        ].

        (ret =~ 'Content-Length: (\d+)') ifMatched: [:match |
            | bytesRead |

            bytesRead := 0.
            [bytesRead < (match at: 1) asInteger] whileTrue: [
                ret := ret, (stream next ifNotNil: [:x |
                    bytesRead := bytesRead + 1.
                    x asString.
                ]).
            ].
            ^LSPMessage new from: ret.
        ].
        ^nil.
    ]
]

Object subclass: LSPWriter [
    | stream |
    onStream: s [
        stream := s.
    ]

    writeMessage: aDictionary [
        | body |
        body := aDictionary asJSON.
        (('Content-Length: ',
              (body size asString),
              (String with: Character cr),
              (String with: Character lf),
              (String with: Character cr),
              (String with: Character lf)),
             (body))
            displayOn: stream.
        stream flush.
    ]

    respondTo: message with: params [
        (message includesKey: 'id') ifTrue: [
            self writeMessage: (Dictionary from: {
                'jsonrpc' -> '2.0'.
                'id' -> (message at: 'id').
                'result' -> params.
            }).
        ].
    ]

    notify: method with: params [
        self writeMessage: (Dictionary from: {
            'jsonrpc' -> '2.0'.
            'method' -> method.
            'params' -> params.
        }).
    ]
]
