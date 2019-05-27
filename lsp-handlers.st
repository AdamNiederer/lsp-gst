Object subclass: InitializeHandler [
    InitializeHandler class >> handle: params [

        (params at: 'workspaceFolders' ifAbsent: [{}]) do: [:folder |
            Workspace singleton folders add: folder.
        ].

        ^Dictionary from: {
            'capabilities' -> (Dictionary from: {
                'textDocumentSync' -> (Dictionary from: {
                    'openClose' -> true.
                    'change' -> 1.
                }).
            }).
        }.
    ]
]

Object subclass: ShutdownHandler [
    ShutdownHandler class >> handle: params [
        ^nil.
    ]
]

Object subclass: TextDocumentOpenHandler [
    TextDocumentOpenHandler class >> handle: params [
        Workspace singleton documents at: ((params at: 'textDocument') at: 'uri') put: (Dictionary from: {
            'text' -> ((params at: 'textDocument') at: 'text').
            'version' -> ((params at: 'textDocument') at: 'version').
        }).
        ^nil.
    ]
]

Object subclass: TextDocumentChangeHandler [
    TextDocumentChangeHandler class >> handle: params [
        | docParams |
        docParams := params at: 'textDocument'.
        ((params at: 'version') > (docParams at: 'version')) ifTrue: [
            Workspace singleton documents at: (docParams at: 'uri') put: (Dictionary from: {
                'text' -> (docParams at: 'text').
                'version' -> (docParams at: 'version').
            }).
        ].
        ^nil.
    ]
]

Object subclass: TextDocumentSaveHandler [
    TextDocumentSaveHandler class >> handle: params [
        | docParams |
        docParams := params at: 'textDocument'.
        ((params at: 'version') > (docParams at: 'version')) ifTrue: [
            Workspace singleton documents at: (docParams at: 'uri') put: (Dictionary from: {
                'text' -> (docParams at: 'text').
                'version' -> (docParams at: 'version').
            }).
        ].
        ^nil.
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
            ('lsp-gst: message not understood: ', (message at: 'method')) displayOn: (FileStream stderr).
            ^nil.
        ]) handle: (message at: 'params')
    ]
]
