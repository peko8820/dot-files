;;; build -- Set up all the dot-files for updating emacs system configurations

;;; Commentary:

;; I took most of this code from Howard Adams' git-repo and modified
;; it to my needs.  The script is used to build/tangle all my Emacs
;; support environmental dot-files.
;;
;; We should be able to execute this as a shell script-like thing
;; ... and we don't mind starting a new instance.  To run the script
;; use the git bash terminal (if you need to suffer through windows)
;; or regular terminal use something like this:
;;
;;     Emacs --load "./build.el"


;;; Code:

(require 'org)                          ; The org-mode goodness
(require 'ob)                           ; org-mode export system
(require 'ob-tangle)                    ; org-mode tangling process


;; Special functions for doing script are not in a loadable location
;; yet
(defvar script-funcs-src (concat (file-name-directory
                                  (buffer-file-name))
                                 "elisp/shell-script-funcs.el"))
(require 'shell-script-funcs script-funcs-src)

;; Need to get the directory to my 'dot-files' source code. While
;; developing, we just evaluate this buffer, so 'buffer-file-name' is
;; out friend. If we load this file instead, we need to use
;; 'load-file-name':
(defconst dot-files-src (if load-file-name (file-name-directory
                                            load-file-name)
                            (file-name-directory (buffer-file-name))))
(defconst ms/emacs-directory (concat (getenv "HOME") "/.emacs.d"))


;; Where all of the *.el files will live and play:
(defconst dest-elisp-dir (ms/get-path "${ms/emacs-directory}/elisp"))


;; The Script Part... here we do all the building and compilation
;; work.
(defun ms/build-dot-files ()
  "Compile and deploy 'init files' in this directory."
  (interactive)

  ;; Initially create some of the destination directories
  (ms/mkdir "$HOME/.oh-my-zsh/themes")
  (ms/mkdir "${ms/emacs-directory}/elisp")

  (ms/tangle-files "${dot-files-src}/*.org")

   ;; Some Elisp files are just symlinked instead of tangled...
  (ms/mksymlinks "${dot-files-src}/elisp/*.el"
                 "${ms/emacs-directory}/elisp")
  )



(provide 'dot-files)
;;; build.el ends here
