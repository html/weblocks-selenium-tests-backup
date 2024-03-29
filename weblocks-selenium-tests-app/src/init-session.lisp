
(in-package :weblocks-selenium-tests-app)
(defvar *demo-actions* nil)

(defun get-upload-directory ()
  (merge-pathnames 
    (make-pathname :directory '(:relative "upload"))
    (compute-webapp-public-files-path (weblocks:get-webapp 'weblocks-selenium-tests-app))))

(defun file-field-demonstration-action (&rest args)
  (do-page 
    (make-quickform 
      (defview 
        nil 
        (:caption "File form field demo" :type form :persistp nil :enctype "multipart/form-data" :use-ajax-p nil)
        (file 
          :present-as file-upload 
          :parse-as (file-upload 
                      :upload-directory (get-upload-directory)
                      :file-name :unique))))))

(defun dialog-demonstration-action (&rest args)
  (let* ((widget))
    (setf widget (make-instance 'composite 
                                :widgets 
                                (list 
                                  "Some dialog content"
                                  (lambda (&rest args)
                                    (render-link (lambda (&rest args)
                                                   (answer widget t))
                                                 "Close dialog")))))
    (do-dialog "Dialog title" widget)))

(defun navigation-demonstration-action (&rest args)
  (let ((widget)
        (navigation))
    (setf navigation (make-navigation 
                       "toplevel-nav"
                       (list "First pane" (make-widget "First pane value") nil)
                       (list "Second pane" (make-widget "Second pane value") "second-pane")
                       (list "Third pane (first nested pane)" 
                             (make-navigation 
                               "second-level-nav-1"
                               (list "First nested pane" (make-widget "First nested pane") nil)
                               (list "Second nested pane" (make-widget "Second nested pane") "second-nested-pane")
                               (list "Third nested pane (with 2-level nesting)" 
                                     (make-navigation 
                                       "third-level-nav" 
                                       (list "First nested pane" (make-widget "First nested pane") nil)
                                       (list "Second nested pane" (make-widget "Second nested pane") "second-nested-pane"))
                                     "third-nested-pane")) "third-pane")
                       (list "Fourth pane (second nested pane)" 
                             (make-navigation 
                               "second-level-nav-2"
                               (list "First nested pane" (make-widget "First nested pane"))
                               (list "Second nested pane" (make-widget "Second nested pane") "second-nested-pane")) "fourth-pane")
                       (list "Fifth pane" (make-widget "Fifth pane") "fifth-pane")
                       (list "Sixth pane (third nested pane)" 
                             (make-navigation 
                               "second-level-nav-3"
                               (list "First nested pane" (make-widget "First nested pane"))
                               (list "Second nested pane" (make-widget "Second nested pane") "second-nested-pane")) "sixth-pane")))
    (setf widget 
          (make-instance 'composite 
                         :widgets (list 
                                    navigation
                                    (lambda (&rest args)
                                      (with-html 
                                        (:div :style "clear:both"
                                          (render-link (lambda (&rest args)
                                                     (answer widget t)) "back")))))))
    (do-page widget)))

(defun define-demo-action (link-name action &key (prototype-engine-p t) (jquery-engine-p t))
  "Used to add action to demo list, 
   :prototype-engine-p and :jquery-engine-p keys 
   are responsive for displaying action in one or both demo applications"
  (push (list link-name action prototype-engine-p jquery-engine-p) *demo-actions*))

(define-demo-action "File field form presentation" #'file-field-demonstration-action :jquery-engine-p nil)
(define-demo-action "Dialog sample" #'dialog-demonstration-action :jquery-engine-p nil)
(define-demo-action "Navigation sample" #'navigation-demonstration-action)

;; Define callback function to initialize new sessions
(defun init-user-session-prototype (root)
  (setf (widget-children root)
        (list (lambda (&rest args)
                (with-html
                  (:ul
                    (loop for (link-title action display-for-prototype display-for-jquery) in (reverse *demo-actions*)
                          if display-for-prototype
                          do
                          (cl-who:htm (:li (render-link action link-title))))))))))

(defun init-user-session-jquery (root)
  (setf (widget-children root)
        (list (lambda (&rest args)
                (with-html
                  (:ul
                    (loop for (link-title action display-for-prototype display-for-jquery) in (reverse *demo-actions*) 
                          if display-for-jquery
                          do
                          (cl-who:htm (:li (render-link action link-title))))))))))

(defun render-apps-list ()
  (let* ((uri-path (request-uri-path))
         (urls (mapcar #'weblocks::weblocks-webapp-prefix weblocks::*active-webapps*))
         (apps (copy-list weblocks::*active-webapps*)))
    (when (find uri-path urls :test #'string=)
      (flet ((current-webapp-p (i)
               (string= 
                 (string-right-trim "/" (weblocks::weblocks-webapp-prefix i)) 
                 (string-right-trim "/" uri-path))))
        (with-html 
        (:div :style "position:fixed;top:20px;right:20px;background:white;border:3px solid #001D23;text-align:left;"
         (:ul :style "padding:10px 30px;margin:0;"
           (loop for i in (sort apps #'string> :key #'weblocks::weblocks-webapp-description) do 
                 (cl-who:htm 
                   (:li (:a :style (format nil "font-size: 15px;text-decoration:none;~A" (if (current-webapp-p i) "font-weight:bold;" "")) :href (weblocks::weblocks-webapp-prefix i) 
                         (str (weblocks::weblocks-webapp-description i)))))))))))))

(defmethod render-page-body :after ((app weblocks-selenium-tests-app) body-string)
  (render-apps-list))

(defmethod render-page-body :after ((app weblocks-with-jquery-selenium-tests-app) body-string)
  (render-apps-list))

