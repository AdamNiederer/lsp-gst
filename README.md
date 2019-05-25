# lsp-gst

The latest in a long series of profoundly useless projects from yours truly.

## Supported Operations

- `initialize`
- `shutdown`
- `textDocument/didOpen`
- Multi-workspace support

## Dependencies

`lsp-gst` depends on the following packages:

- An included version of [`gst-json`](https://github.com/plhx/gst-json), modified to use String rather than UnicodeString
- [`I18N`](https://github.com/gnu-smalltalk/smalltalk/tree/master/packages/i18n)
- [`STInST`](https://github.com/gnu-smalltalk/smalltalk/tree/master/packages/stinst)

And provides the following namespaces:

- `LSP.GST` - The primary namespace for GST-related LSP functions

## Building & Installation

### Build

First, ensure you have `I18N` and `STInSt` available (`STInST` is often left out
of distributions' GNU Smalltalk packages). Then, run the following commands to
generate and run a fresh `lsp-gst` image:

```sh
$ gst-package -t . package.xml
$ gst-load -iI lsp-gst.im lsp-gst
```

The language server protocol is now listening on stdin.

### Use

Assuming you are using Emacs' [`lsp-mode`](https://github.com/emacs-lsp/lsp-mode), with
[`smalltalk-mode`](https://github.com/gnu-smalltalk/smalltalk/blob/master/smalltalk-mode.el)
from the official gnu-smalltalk repo. `lsp-gst` currently operates on stdio, but
should be trivially modifiable to run on a proper socket in the future. A
reasonable smalltalk setup for Emacs would be:

```emacs-lisp
(load-file "path/to/smalltalk-mode.el")
(add-to-list 'auto-mode-alist '("\\.st" . smalltalk-mode))

(require 'lsp)
(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection '("gst-load" "-iI" "path/to/lsp-gst.im" "lsp-gst"))
                  :major-modes '(smalltalk-mode)
                  :priority -1
                  :server-id 'gst-ls))

(with-eval-after-load 'smalltalk-mode
  (add-hook 'smalltalk-mode-hook #'lsp))
```

`gst-lsp` should activate and connect when you open a Smalltalk file.

## Licenses

- `lib/json.st`: Copyright 2017 PlasticHeart; BSD-2-Clause.
- All other source code: Copyright 2019 Adam Niederer; AGPLv3+
