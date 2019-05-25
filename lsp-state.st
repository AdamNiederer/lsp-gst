Object subclass: Workspace [
    | folders documents |

    init [
        folders := Set new.
        documents := Dictionary new.
    ]

    folders [ ^folders. ]
    documents [ ^documents. ]

    singleton := Workspace new init.
    Workspace class >> singleton [ ^singleton. ]
]
