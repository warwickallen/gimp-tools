; average-layers.scm
;
; Averages all the layers.
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

(define (script-fu-average-layers img)
  (gimp-image-undo-group-start img)

  (let*
    (
      (lyrs (gimp-image-get-layers img))
      (n (car lyrs))
    )
    (letrec
      (
        (f1 (lambda (i)
          (display i)
          (newline)
          (let*
            (
              (lyr (vector-ref (car (cdr lyrs)) i))
            )
            (gimp-layer-set-mode lyr 0) ; normal (legacy) mode
            (gimp-layer-set-opacity lyr (/ 100 (- n i)))
          )
          (cond
            ((> i 0) (f1 (- i 1)))
          )
        ))
      )
      (f1 (- n 1))
    )
  )
  (gimp-image-flatten img)
  (gimp-layer-set-mode
    (car (gimp-image-get-active-layer img))
    28 ; normal (default) mode
  )

  (gimp-image-undo-group-end img)
  (gimp-displays-flush)
)

(script-fu-register
  "script-fu-average-layers"
  _"Average Layers"
  _"Averages all the layers."
  "Warwick Allen"
  "Copyright (c) 2024 Warwick Allen, MIT licence"
  "July 2014"
  "*"
  SF-IMAGE    "Image"    0
)

(script-fu-menu-register
  "script-fu-average-layers"
  "<Image>/Layer"
)
