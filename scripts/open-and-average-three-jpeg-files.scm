; open-and-average-three-jpeg-files.scm
;
; This script is used to load three files that have been taken using a Panasonic
; camera with auto-bracketing enabled.  This produces three files with
; sequentially-numbered file names of the form "P#######.JPG" (the hash symbols
; representing numbers).
;
; The script does the following steps:
;   - Prompts the user for a valid integer input.
;   - Calculates the file names based on the input number.
;   - Opens the specified images as layers.
;   - Scales the image by 200%.
;   - Calls the script-fu-average-layers function.
;   - Removes the alpha channel from the resulting layer.
;   - Save the Gimp file using a composite file name.
;
; The directory where the photo files are stored and the five most significant
; digits of the photo file number are hard-coded in this script.
;
; MIT License
;
; Copyright (c) 2024 Warwick Allen
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

(define (script-fu-open-and-average-three-jpeg-files n)
  (let*
    (
      (base-file-number 1000000)

      ; Check if input is valid
      (valid-input (and (integer? n) (< n 100000) (> n 0)))
    )
    (if (not valid-input)
      (begin
        (gimp-message
          "Invalid input! Please enter a positive integer less than 100,000."
        )
        (quit)
      )

      (let*
        (
          (image-directory (string-append
            (getenv "userprofile") ; Warning! This is Windows-specific
            "\\Pictures\\DCIM\\10"
            (substring (number->string n) 0 1)
            "_PANA\\"
          ))
          ; Calculate file numbers
          (a (+ base-file-number 0 n))
          (b (+ base-file-number 1 n))
          (c (+ base-file-number 2 n))

          ; File names
          (file-a (string-append "P" (number->string a) ".JPG"))
          (file-b (string-append "P" (number->string b) ".JPG"))
          (file-c (string-append "P" (number->string c) ".JPG"))
          (image-name-head (substring file-a 0 8))
          (image-name-tail (substring file-c 5 8))
          (image-name (string-append image-name-head "–" image-name-tail))

          ; Open the first file as a new image
          (img (car (gimp-file-load RUN-NONINTERACTIVE
            (string-append image-directory file-a)
            file-a
          )))
          (drawable-a (car (gimp-image-get-active-layer img)))
          ; Open the other two files as layers
          (drawable-b (car (gimp-file-load-layer RUN-NONINTERACTIVE img
            (string-append image-directory file-b)
          )))
          (drawable-c (car (gimp-file-load-layer RUN-NONINTERACTIVE img
            (string-append image-directory file-c)
          )))
        )

        ; Make sure "undo" continues to work
        (gimp-image-undo-group-start img)

        ; Add layers to image
        (gimp-image-add-layer img drawable-b 1)
        (gimp-image-add-layer img drawable-c 2)

        ; Scale image by 200%
        (
          gimp-image-scale-full img
          (* 2 (car (gimp-image-width img)))
          (* 2 (car (gimp-image-height img)))
          INTERPOLATION-LANCZOS
        )

        ; Execute script-fu-average-layers
        (script-fu-average-layers img)

        (let*
          (
            (active-layer (car (gimp-image-get-active-layer img)))
            (xcf-name (string-append image-name ".xcf"))
          )

          ; Remove alpha channel from active layer
          (when (gimp-drawable-has-alpha active-layer)
            (gimp-layer-flatten active-layer)
          )

          ; Rename the layer
          (gimp-layer-set-name active-layer image-name)

          ; Rename the image
          (gimp-image-set-filename
            img
            (string-append image-directory xcf-name)
          )

          ; Display the result
          (gimp-display-new img)

          ; Save the Gimp image file
          (gimp-file-save RUN-NONINTERACTIVE
            img
            active-layer
            (string-append image-directory xcf-name)
            xcf-name
          )

        (gimp-image-undo-group-end img)
        )
      )
    )
  )
  (gimp-displays-flush)
)

(script-fu-register
  "script-fu-open-and-average-three-jpeg-files"         ; Function name
  "Open and Average Three JPEG Files"                   ; Menu label
  "Process three images as specified"                   ; Description
  "Warwick Allen"                                       ; Author
  "Copyright (c) 2024 Warwick Allen, MIT licence"       ; Copyright
  "July 2014"                                           ; Creation date
  "None"                                                ; Image types
  SF-ADJUSTMENT                                         ; Input parameter
  "Enter the final five digits of the photo file number (you may leave off leading zeroes)"
  '(0 0 99999 1 1 0 SF-SPINNER)
)

(script-fu-menu-register
  "script-fu-open-and-average-three-jpeg-files"
  "<Image>/File/Custom"
)
