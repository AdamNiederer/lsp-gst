"
Copyright (c) 2017, PlasticHeart
Licensed under the BSD-2-Clause.
"

OrderedCollection extend [
    removeLast: n [
        | result |
        <category: 'removing'>
        result := self class new.
        n timesRepeat: [result addFirst: self removeLast].
        ^result
    ]
]


ReadStream extend [
    LR_ACTION := #(
        #(  3   0   4   0   0   0   0   0)
        #(  0   0   0   0   0   0   0 255)
        #(  3   6   4   0   0   0   8   0)
        #(  3   0   4  11   0   0   8   0)
        #(  0  13   0   0  14   0   0   0)
        #(  0  -2   0  -2  -2  -2   0  -2)
        #(  0  -5   0   0  -5   0   0   0)
        #(  0  -9   0  -9  -9  -9   0   0)
        #(  0 -10   0 -10 -10 -10   0   0)
        #(  0   0   0  15  16   0   0   0)
        #(  0  -4   0  -4  -4  -4   0  -4)
        #(  0   0   0   0   0  17   0   0)
        #(  0  -1   0  -1  -1  -1   0  -1)
        #(  3   0   4   0   0   0   8   0)
        #(  0  -3   0  -3  -3  -3   0  -3)
        #(  3   0   4   0   0   0   8   0)
        #(  3   0   4   0   0   0   8   0)
        #(  0  -6   0   0  -6   0   0   0)
        #(  0   0   0   0   0  21   0   0)
        #(  0   0   0  -7  -7   0   0   0)
        #(  3   0   4   0   0   0   8   0)
        #(  0   0   0  -8  -8   0   0   0)
    ).

    LR_GOTO := #(
        #( 2  0  9  9  0  0  0  0  0  0  0  0  0  9  0  9  9  0  0  0  9  0)
        #( 0  0  5  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0)
        #( 0  0  0 10  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0)
        #( 0  0  7 12  0  0  0  0  0  0  0  0  0 18  0 19 20  0  0  0 22  0)
    ).

    LR_REDUCE := {
        3->[:t | 1->(t at: 2) value].
        2->[:t | 1->OrderedCollection new].
        3->[:t | 1->(t at: 2) value].
        2->[:t | 1->Dictionary new].
        1->[:t | 2->(OrderedCollection with: (t at: 1) value)].
        3->[:t |
            | a |
            (a := (t at: 1) value) add: (t at: 3) value.
            2->a
        ].
        3->[:t |
            | k |
            ((k := (t at: 1) value) isMemberOf: String) ifFalse: [
                self error: 'unexpected token ''%1''' % {k}
            ].
            3->(Dictionary from: {k->(t at: 3) value})
        ].
        5->[:t |
            | d k |
            ((k := (t at: 3) value) isMemberOf: String) ifFalse: [
                self error: 'unexpected token ''%1''' % {k}
            ].
            (d := (t at: 1) value) at: k put: (t at: 5) value.
            3->d
        ].
        1->[:t | 4->(t at: 1) value].
        1->[:t | 4->(t at: 1) value]
    }.

    nextJSON [
        | stack token action pos reduce result goto |
        <category: 'converting'>
        stack := OrderedCollection with: 1->nil.
        [
            self skipSeparators.
            pos := self position.
            token := self nextJSONToken.
            action := (LR_ACTION at: stack last key) at: token key.
            action = 255 ifTrue: [^stack removeLast value].
            action = 0 ifTrue: [
                self error: 'unexpected token ''%1''' % {token}
            ].
            action > 0 ifTrue: [
                stack add: action->token value.
            ] ifFalse: [
                self position: pos.
                reduce := LR_REDUCE at: action abs.
                result := reduce value value: (stack removeLast: reduce key).
                goto := (LR_GOTO at: result key) at: stack last key.
                stack add: (goto->result value)
            ]
        ] repeat
    ]

    nextJSONToken [
        | c i |
        <category: 'private'>
        c := self peek.
        c ifNil: [^8->nil].
        i := '[]{},:' indexOf: c.
        i > 0 ifTrue: [self skip: 1. ^i->c].
        c = $n ifTrue: [self skip: 4. ^7->nil].
        c = $t ifTrue: [self skip: 4. ^7->true].
        c = $f ifTrue: [self skip: 5. ^7->false].
        c = $<16r22> ifTrue: [^7->self nextJSONStringToken].
        ^7->(Float readFrom: self)
    ]

    nextJSONStringToken [
        | c |
        <category: 'private'>
        (c := self next) = $<16r22> ifFalse: [
            self error: 'unexpected token ''%1''' % {c}
        ].
        ^String streamContents: [:stream |
            [self peek = $<16r22>] whileFalse: [
                stream nextPut: self nextJSONCharacterToken
            ].
            self skip: 1
        ]
    ]

    nextJSONCharacterToken [
        <category: 'private'>
        | c |
        (c := self peek) = $<16r5C> ifTrue: [
            ^self nextJSONEscapedCharacterToken
        ].
        (((c between: $<16r20> and: $<16r21>) or: [
            c between: $<16r23> and: $<16r5B>
        ]) or: [c between: $<16r5D> and: $<16rFF>]) ifTrue: [^self next].
        self error: 'unexpected token ''%1''' % {c}
    ]

    nextJSONEscapedCharacterToken [
        <category: 'private'>
        | c |
        (c := self next) = $<16r5C> ifFalse: [
            self error: 'unexpected token ''%1''' % {c}
        ].
        c := self next.
        c = $<16r22> ifTrue: [^$<16r22>].
        c = $<16r5C> ifTrue: [^$<16r5C>].
        c = $<16r2F> ifTrue: [^$<16r2F>].
        c = $b ifTrue: [^$<16r08>].
        c = $f ifTrue: [^$<16r0C>].
        c = $n ifTrue: [^$<16r0A>].
        c = $r ifTrue: [^$<16r0D>].
        c = $t ifTrue: [^$<16r09>].
        c = $u ifTrue: [
            ^Character codePoint: (
                Integer readFrom: (self next: 4) readStream radix: 16
            )
        ].
        self error: 'unexpected token %1' % {c}
    ]
]


Object extend [
    printJSONOn: aStream [
        <category: 'printing'>
        self subclassResponsibility
    ]

    asJSON [
        <category: 'converting'>
        | stream |
        stream := WriteStream on: String new.
        self printJSONOn: stream.
        ^stream contents
    ]
]


UndefinedObject extend [
    printJSONOn: aStream [
        <category: 'printing'>
        aStream nextPutAll: 'null'
    ]
]


Boolean extend [
    printJSONOn: aStream [
        <category: 'printing'>
        aStream nextPutAll: self displayString
    ]
]


Number extend [
    printJSONOn: aStream [
        <category: 'printing'>
        self asFloat displayOn: aStream
    ]
]


Float extend [
    printJSONOn: aStream [
        <category: 'printing'>
        aStream nextPutAll: (
            self displayString copyReplacing: self exponentLetter withObject: $e
        )
    ]
]


Integer extend [
    printJSONOn: aStream [
        <category: 'printing'>
        self displayOn: aStream
    ]
]


SequenceableCollection extend [
    printJSONOn: aStream [
        <category: 'printing'>
        aStream nextPut: $[.
        self doWithIndex: [:x :i |
            i > 1 ifTrue: [aStream nextPutAll: ', '].
            x printJSONOn: aStream
        ].
        aStream nextPut: $]
    ]
]


CharacterArray extend [
    printJSONOn: aStream [
        <category: 'printing'>
        aStream nextPut: $<16r22>.
        self asString do: [:c | c printJSONOn: aStream].
        aStream nextPut: $<16r22>
    ]
]


Character extend [
    printJSONOn: aStream [
        <category: 'printing'>
                (((self between: $<16r20> and: $<16r21>) or: [
                        self between: $<16r23> and: $<16r5B>
                ]) or: [
                        self between: $<16r5D> and: $<16rFF>
                ]) ifTrue: [^aStream nextPut: self].
                aStream nextPut: $<16r5C>.
                (((self = $<16r22>) or: [
                        self = $<16r5C>
                ]) or: [
                        self = $<16r2F>
                ]) ifTrue: [^aStream nextPut: self].
                self = $<16r08> ifTrue: [^aStream nextPut: $b].
                self = $<16r0C> ifTrue: [^aStream nextPut: $f].
                self = $<16r0A> ifTrue: [^aStream nextPut: $n].
                self = $<16r0D> ifTrue: [^aStream nextPut: $r].
                self = $<16r09> ifTrue: [^aStream nextPut: $t].
                aStream nextPutAll: 'u' , (
            self codePoint printPaddedWith: $0 to: 4 base: 16
        )
    ]
]


Dictionary extend [
    printJSONOn: aStream [
        <category: 'printing'>
        | sep |
        sep := false.
        aStream nextPut: ${.
        self keysAndValuesDo: [:k :v |
           sep ifTrue: [aStream nextPutAll: ', '].
           k printJSONOn: aStream.
           aStream nextPutAll: ': '.
           v printJSONOn: aStream.
           sep := true
        ].
        aStream nextPut: $}
    ]
]
