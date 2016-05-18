;;; shell-script-funcs --- Utility functions for shell script conversions

;;; Commentary:

;; A collection of functions helpful in attempting to translate shell
;; scripts into Elisp scripts.

(require 'em-glob)

;;; Code:

(defun ms/substring-replace (old-str new-str beg end)
  "Return a new string where a subsection of OLD-STR has been replaced with NEW-STR beginning at position BEG and ending at END."
   (concat (substring old-str 0 beg) new-str (substring old-str end)))


(defun ms/getvar (var-name)
  "Return value of a variable or environment variable specified by VAR-NAME."
  (or (getenv var-name) (eval (read var-name))))

(defun ms/substr-variables (str)
  "Replace shell-like '$VAR' and '${variables}' in STR with the equivalent environment variables or Elisp variables.  For instance: $HOME/.emacs.d could return /home/howard/.emacs.d -- Keep in mind that this is just a string, it does not do any validation to see if any files exist."

  ;; This function recursively calls this function with more and more
  ;; embedded variables substituted out, until no more variables are
  ;; found, and then it returns the results.
  ;;
  ;; Begin by checking to see if the string starts with ~ ...
  (if (string-prefix-p "~/" str)
      (ms/substr-variables
       (concat (getenv "HOME") (substring str 1)))

    ;; Variables can either be simple $BLAH or ${some-larger}...
    (let ((s (or (string-match "${\\([^ }]*\\)}" str)
                 (string-match "$\\([A-z_]*\\)" str)))
          (e (match-end 0)))
      (if (not s)             ; No $ matches?
          str                 ; Then just return the string.
        (ms/substr-variables  ; Recursively call with first var sub'd
         (ms/substring-replace str (ms/getvar (match-string 1 str)) s e))))))

;; (ms/substr-variables "$HOME/.emacs.d/elisp/*.el")
;; (ms/substr-variables "~/.emacs.d/elisp/*.el")
;; (ms/substr-variables "${user-emacs-directory}elisp/*.el")

(defun ms/get-files (path &optional full)
  "Return list of files that match the glob pattern, PATH.  Allowing shell-like variable substitution from the environment, like $HOME, or from variables defined by `setq'.  If FULL is specified, return absolute pathnames for each file."
  (let ((subbed-path (ms/substr-variables path)))
    (condition-case nil
        (directory-files (file-name-directory subbed-path)
                         full
                         (eshell-glob-regexp
                          (file-name-nondirectory subbed-path)))
      (error '()))))

;; (ms/get-files "$HOME/.emacs.d/elisp/*.el")
;; => ("init-blog.el" "init-client.el" "init-clojure.el" ...)

;; (ms/get-files "$HOME/.emacs.d/elisp/*.el" t)
;; => ("/home/howard/.emacs.d/elisp/init-blog.el" "/home/howard/.emacs.d/elisp/init-client.el" ...)

;; (ms/get-files "${user-emacs-directory}/elisp/*.el")
;; => ("init-blog.el" "init-client.el" "init-clojure.el" ...)

;; (ms/get-files "/foo/bar/*")  => nil

(defun ms/has-org-tag-p (file tag)
  (let ((reg (concat "^#\\+TAGS:.* " tag "\\b")))
    (with-temp-buffer
      (insert-file-contents file)
      (re-search-forward reg nil t 1))))

(defun ms/get-org-files (path tag &optional full)
  "Return list of `org-mode' files in PATH that match the TAG section.
If FULL is specified, return absolute pathnames for each file."
  (filter (lambda (file) (ms/has-org-tag-p file tag)) (ms/get-files path full)))

;; (ms/get-org-files "~/website/Presentations/*.org" "presentation" t)

(defun ms/get-path (path &rest extra)
  "Return a file specification based on PATH.  We should expand this function so that glob patterns work when specifying the parent, but shouldn't worry about matching any particular file.  All EXTRA parameters are appended separated with / characters."
  (let ((file-parts (cons (ms/substr-variables path) extra)))
    (mapconcat 'identity file-parts "/")))

;; (ms/get-path "/home/bar") ;=> "/home/bar"
;; (ms/get-path "$HOME/.emacs.d/elisp/*.el") ;=> "/home/howard/.emacs.d/elisp/*.el"
;; (ms/get-path "/foo/bar" "baz")
;;
;; (let ((blah "blah-blah") )
;;   (ms/get-path "/home/${blah}/flubber")) ;=> /home/blah-blah/flubber
;;
;; (let ((blah "blah-blah") )
;;   (ms/get-path "/home/flubber" blah)) ;=> /home/flubber/blah-blah

;; ----------------------------------------------------------------------

;; The following functions are basic "shell" like functions that take
;; a path that refers to files. This allows us to not have to call
;; (ms/get-files) directly.

(defun ms/mkdir (path)
  "Create a directory specified by PATH, which can contain embedded environment variables and Emacs variables, e.g. '$HOME/Work/foobar'."
  (make-directory (ms/get-path path) t))


(defun ms/mksymlink (orig link)
  "Create symbolic link to ORIG.  If LINK is an existing link, it is deleted first.  LINK could also refer to a directory.  Note: Both parameters are strings that can accept embedded environment and Lisp variables, e.g. '$HOME/Work/foo.el' and '${user-emacs-directory}/elisp/bar.el' ."
  (let ((orig-file (ms/get-path orig))
        (link-file (ms/get-path link)))

    (if (not (file-symlink-p link-file))
        (make-symbolic-link orig-file link-file t))))

(defun ms/mksymlinks (files dest)
  "Create an absolute symbolic link for each file specified in FILES into the directory, DEST (where each link will have the same name).  Both parameters can be specified with glob patterns and embedded environment and Emacs variables, e.g. '$HOME/.emacs.d/*.el'."
  (mapc (lambda (file) (ms/mksymlink file dest)) (ms/get-files files t)))


(defun ms/mkdirs (path)
  "Create one or more directories specified by PATH, which can contain embedded environment variables and Emacs variables, e.g. '$HOME/Work/foobar'."
  (mapc (lambda (dir) (make-directory dir t)) (ms/get-files path)))

(defun ms/copy-files (from to files)
  "Copy some files FROM a directory TO another directory, where FILES is a list of names."
  (mapcar (lambda (file)
            (copy-file (ms/get-path from file)
                       (ms/get-path to) t))     files))

(provide 'shell-script-funcs)
;;; shell-script-funcs ends here
