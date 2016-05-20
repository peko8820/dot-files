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
;;     emacs --load "./build.el"


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

  ;; Just link the entire directory instead of copying the snippets:
  (ms/mksymlink  "${dot-files-src}/snippets"
                 "${ms/emacs-directory}/snippets")

  ;; Just link the entire directory instead of copying the snippets:
  (ms/mksymlink  "${dot-files-src}/templates/"
                 "${ms/emacs-directory}/templates")

  ;; Some Elisp files are just symlinked instead of tangled...
  (ms/mksymlinks "${dot-files-src}/bin/[a-z]*"
                 "${HOME}/bin")

  ;; Yeah, this makes me snicker every time I see it. I have not yet created the folder inside the source directory, though
  ;; (ms/mksymlink  "${dot-files-src}/vimrc" "${HOME}/.vimrc")

  ;; All of the .el files I've eithe tangled or linked should be comp'd:
  ;; (mapc 'byte-compile-file
  ;;       (ms/get-files "${ms/emacs-directory}/elisp/*.el" t))

  (message "Finished building dot-files- Resetting Emacs.")
  (require 'init-main (ms/get-path "${user-emacs-directory}elisp/init-main.el")))

(defun ms/tangle-file (file)
  "Given an 'org-mode' FILE, tangle the source code."
  (interactive "fOrg File: ")
  (find-file file)   ;;  (expand-file-name file \"$DIR\")
  (org-babel-tangle)
  (kill-buffer))


(defun ms/tangle-files (path)
  "Given a directory, PATH, of 'org-mode' files, tangle source code out of all literate programming files."
  (interactive "D")
  (mapc 'ms/tangle-file (ms/get-files path)))


(defun ms/get-dot-files ()
  "Pull and build latest from the Github repository.  Load the resulting Lisp code."
  (interactive)
  (let ((git-results
         (shell-command (concat "cd " dot-files-src "; git pull"))))
    (if (not (= git-results 0))
        (message "Can't pull the goodness. Pull from git by hand.")
      (load-file (concat dot-files-src "/emacs.d/shell-script-funcs.el"))
      (load-file (concat dot-files-src "/build.el"))
      (require 'init-main))))

(ms/build-dot-files)  ;; Do it

(provide 'dot-files)
;;; build.el ends here
