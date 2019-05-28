Object subclass: InitializeHandler [
    InitializeHandler class >> handle: params [

        (params at: 'workspaceFolders' ifAbsent: [{}]) do: [:folder |
            Workspace singleton folders add: folder.
        ].

        ^HandlerResponse from: {
            'capabilities' -> (Dictionary from: {
                'textDocumentSync' -> (Dictionary from: {
                    'openClose' -> true.
                    'change' -> 1.
                }).
            }).
        }.
    ]
]

Object subclass: HandlerResponse [
    HandlerResponse class >> from: anAssociationArray [
        ^Dictionary from: {
            'response' -> (Dictionary from: anAssociationArray).
            'notifications' -> {}.
        }.
    ]

    HandlerResponse class >> from: anAssociationArray with: notifications [
        ^Dictionary from: {
            'response' -> (Dictionary from: anAssociationArray).
            'notifications' -> notifications.
        }.
    ]

    HandlerResponse class >> with: notifications [
        ^Dictionary from: {
            'response' -> nil.
            'notifications' -> notifications.
        }.
    ]

    HandlerResponse class >> none [
        ^Dictionary from: {
            'response' -> nil.
            'notifications' -> {}.
        }.
    ]
]

Object subclass: ShutdownHandler [
    ShutdownHandler class >> handle: params [
        ^HandlerResponse none.
    ]
]

Object subclass: TextDocumentOpenHandler [
    TextDocumentOpenHandler class >> handle: params [
        Workspace singleton documents at: ((params at: 'textDocument') at: 'uri') put: (Dictionary from: {
            'text' -> ((params at: 'textDocument') at: 'text').
            'version' -> ((params at: 'textDocument') at: 'version').
        }).
        ^HandlerResponse none.
    ]
]

Object subclass: TextDocumentChangeHandler [
    TextDocumentChangeHandler class >> handle: params [
        | doc |
        doc := Workspace singleton documents at: ((params at: 'textDocument') at: 'uri').
        ((doc at: 'version') < ((params at: 'textDocument') at: 'version')) ifTrue: [
            | errors |


            doc at: 'text' put: (((params at: 'contentChanges') at: 1) at: 'text').
            doc at: 'version' put: ((params at: 'textDocument') at: 'version').
            errors := (ParserService errors: (doc at: 'text')) collect: [:lineAndMsg |
                | line message |

                line := lineAndMsg at: 1.
                message := lineAndMsg at: 2.

                Dictionary from: {
                    'range' -> (Dictionary from: {
                        'start' -> (Dictionary from: {'line' -> line. 'character' -> 0.}).
                        'end' -> (Dictionary from: {'line' -> (line + 1). 'character' -> 0.}).
                    }).
                    'severity' -> 1.
                    'source' -> 'gst'.
                    'message' -> message.
                }.
            ].

            ^HandlerResponse with: {(Dictionary from: {
                'method' -> 'textDocument/publishDiagnostics'.
                'params' -> (Dictionary from: {
                    'uri' -> ((params at: 'textDocument') at: 'uri').
                    'diagnostics' -> errors.
                 }).
            })}.
        ].
    ]
]

Object subclass: TextDocumentSaveHandler [
    TextDocumentSaveHandler class >> handle: params [
        " | old new | "
        " new := params at: 'textDocument'. "
        " old := Workspace singleton documents at: (new at: 'uri'). "
        " ((old at: 'version') < (new at: 'version')) ifTrue: [ "
        "     | errors | "
        "     old put: (Dictionary from: { "
        "         'text' -> (new at: 'text'). "
        "         'version' -> (new at: 'version'). "
        "     }). "
        " ]. "
        ^HandlerResponse none.
    ]
]

Object subclass: CompletionHandler [
    CompletionHandler class >> handle: params [
        ^(Array with: (Dictionary from: {
            'label' -> 'hi'.
        })).
    ]
]

Object subclass: MessageDispatcher [
    dispatch := Dictionary from: {
        'initialize' -> InitializeHandler.
        'shutdown' -> ShutdownHandler.
        'textDocument/didOpen' -> TextDocumentOpenHandler.
        'textDocument/didChange' -> TextDocumentChangeHandler.
        'textDocument/didSave' -> TextDocumentSaveHandler.
    }.

    MessageDispatcher class >> dispatch: message [
        ^(dispatch at: (message at: 'method') ifAbsent: [
            ('lsp-gst: message not understood: ', (message at: 'method'), (String with: Character lf)) displayOn: (FileStream stderr).
            ^HandlerResponse none.
        ]) handle: (message at: 'params')
    ]
]
