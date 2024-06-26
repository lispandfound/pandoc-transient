;;; pandoc.el --- transient.el interface to the pandoc utility.  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Jake Faulkner

;; Author: Jake Faulkner <jakefaulkn@gmail.com>
;; Keywords: tools, files

;;; Code:

(require 'transient)
(require 's)

(defgroup pandoc-transient nil
  "transient.el interface to the pandoc utility."
  :group 'tools)

(defcustom pandoc-transient-input-mode-alist
  '((bibtex-mode . "biblatex")
    (creole-mode . "creole")
    (csv-mode . "csv")
    (djot-mode . "djot") ;; https://codeberg.org/crmsnbleyd/djot-mode
    (dokuwiki-mode . "dokuwiki")
    (nov-mode . "epub") ;; nov-mode for handling EPUB files
    (html-mode . "html")
    (json-mode . "json")
    (latex-mode . "latex")
    (markdown-mode . "markdown")
    (mediawiki-mode . "mediawiki")
    (man-mode . "man")
    (org-mode . "org")
    (rst-mode . "rst")
    (textile-mode . "textile"))
  "An association list mapping input modes to pandoc input formats."
  :type 'sexp
  :group 'pandoc-transient)

(defcustom pandoc-transient-default-output-format
  "pdf"
  "The default file format to convert to"
  :type 'string
  :group 'pandoc-transient)

(defcustom pandoc-transient-default-output-file-extension
  "pdf"
  "The default file extension to append to output file"
  :type 'string
  :group 'pandoc-transient)

(defcustom pandoc-transient-executable
  "pandoc"
  "The pandoc executable location"
  :type 'string
  :group 'pandoc-transient)


(transient-define-argument pandoc-transient--input-formats ()
  "Set the pandoc input format"
  :argument "--from="
  :class 'transient-option
  :choices
  '("bibtex"
    "biblatex"
    "bits"
    "commonmark"
    "commonmark_x"
    "creole"
    "csljson"
    "csv"
    "tsv"
    "djot"
    "docbook"
    "docx"
    "dokuwiki"
    "endnotexml"
    "epub"
    "fb2"
    "gfm"
    "haddock"
    "html"
    "ipynb"
    "jats"
    "jira"
    "json"
    "latex"
    "markdown"
    "markdown_mmd"
    "markdown_phpextra"
    "markdown_strict"
    "mediawiki"
    "man"
    "muse"
    "native"
    "odt"
    "opml"
    "org"
    "ris"
    "rtf"
    "rst"
    "t2t"
    "textile"
    "tikiwiki"
    "twiki"
    "typst"
    "vimwiki")
  :init-value (lambda (obj)
                (oset obj value (alist-get major-mode pandoc-transient-input-mode-alist))))


(transient-define-argument pandoc-transient--output-formats ()
  "Set the pandoc output format"
  :argument "--to="
  :class 'transient-option
  :choices
  '("asciidoc"
    "asciidoc_legacy"
    "asciidoctor"
    "beamer"
    "bibtex"
    "biblatex"
    "chunkedhtml"
    "commonmark"
    "commonmark_x"
    "context"
    "csljson"
    "djot"
    "docbook"
    "docbook5"
    "docx"
    "dokuwiki"
    "epub"
    "epub2"
    "fb2"
    "gfm"
    "haddock"
    "html"
    "html4"
    "icml"
    "ipynb"
    "jats_archiving"
    "jats_articleauthoring"
    "jats_publishing"
    "jats"
    "jira"
    "json"
    "latex"
    "man"
    "markdown"
    "markdown_mmd"
    "markdown_phpextra"
    "markdown_strict"
    "markua"
    "mediawiki"
    "ms"
    "muse"
    "native"
    "odt"
    "opml"
    "opendocument"
    "org"
    "pdf"
    "plain"
    "pptx"
    "rst"
    "rtf"
    "texinfo"
    "textile"
    "slideous"
    "slidy"
    "dzslides"
    "revealjs"
    "s5"
    "tei"
    "typst"
    "xwiki"
    "zimwiki"))


(transient-define-argument pandoc-transient--pdf-engine ()
  "Set the pandoc PDF engine."
  :argument "--pdf-engine="
  :class 'transient-option
  :choices  '("pdflatex" "lualatex" "latexmk" "tectonic" "wkhtmltopdf" "weasyprint"))


(transient-define-prefix pandoc-interface ()
  "Convert files with pandoc"
  ["Pandoc Options"
   ("ps" "Standalone file generation (i.e. with <head> or LaTeX preamble)" "-s"
    :init-value (lambda (obj) (oset obj value "-s")))
   ("pd" "Output DPI" "--dpi="  "Output DPI: " :reader transient-read-number-N+)
   ("pt" "table of contents" "--toc")]
  ["PDF Output Options"
   ("pe" "PDF Engine to use" pandoc-transient--pdf-engine)
   ("bc" "Process citations" "--citeproc")
   ("bl" "Use biblatex" "--biblatex")
   ("bb" "Set bibliography" "--bibliography=" :reader transient-read-existing-file)]
  ["Input/Output"
   ("f" "From Format" pandoc-transient--input-formats :always-read t)
   ("t" "To Format" pandoc-transient--output-formats
    :init-value (lambda (obj) (oset obj value pandoc-transient-default-output-format)) :always-read t)
   ("o" "Output File" "--output="
    :reader transient-read-file 
    :init-value (lambda (obj) (oset obj value (concat (file-name-sans-extension (buffer-file-name)) (s-concat "." pandoc-transient-default-output-file-extension))))
    :always-read t)]
  ["Command"
   ("<return>" "Convert this file (C-u to prompt for file)." pandoc-transient--convert-this-file :transient nil)
   ("q" "Quit" transient-quit-all)])

(transient-define-suffix pandoc-transient--convert-this-file (the-prefix-arg)
  "Convert this file, using pandoc. If supplied with a prefix argument, prompt for input file."
  :transient 'transient--do-call
  (interactive "P")
  (let ((args (transient-args (oref transient-current-prefix command)))
        (input-file-path (if the-prefix-arg (read-file-name "Input File: ") (buffer-file-name))))
    (async-shell-command (s-concat pandoc-transient-executable " " (s-join " " (cons input-file-path args))))))

;;;###autoload
(defun pandoc-convert-transient ()
  "Convert files with pandoc."
  (interactive)
  (pandoc-interface))

(provide 'pandoc-transient)

;;; pandoc-transient.el ends here
