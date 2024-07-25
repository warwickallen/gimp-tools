; extract-from-green-background.scm
; Makes the green border of the current layer transparent.
;
; This is used for images (of, for example, artworks) that have been
; photographed on a green background.
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

(define (script-fu-extract-from-green-background img drawable)
  (gimp-image-undo-group-start img)
  (gimp-selection-none img)

  ; Add a green border, in case the image goes too close to the edge, which
  ; prevents the select-by-colour operation working as required
  (gimp-image-flatten img)
  (let*
    (
      (lyr_orig (car (gimp-image-get-active-layer img)))
      (name_lyr_orig (car (gimp-item-get-name lyr_orig)))
      (bkg_orig (car (gimp-context-get-background)))
      (wdt_orig (car (gimp-image-width img)))
      (hgh_orig (car (gimp-image-height img)))
      (off_x 25)
      (off_y 25)
    )
    (define (get-new-layer-name postfix)
      (string-append name_lyr_orig " extract-from-green-background " postfix)
    )
    (gimp-context-set-background '(0 255 0))
    (gimp-image-resize
      img
      (+ (* 2 off_x) wdt_orig)
      (+ (* 2 off_y) hgh_orig)
      off_x off_y
    )
    (gimp-image-flatten img)
    (gimp-context-set-background bkg_orig)

    ; Create two layers representing the green component
    ; disable red channel
    (gimp-image-set-component-visible img 0 FALSE)
    ; disable blue channel
    (gimp-image-set-component-visible img 2 FALSE)
    (let*
      (
        (name_lyr_new (get-new-layer-name "g #1"))
        (lyr_g1 (car (gimp-layer-new-from-visible img img name_lyr_new)))
      )
      (gimp-image-insert-layer img lyr_g1 0 -1)
      ; enable red channel
      (gimp-image-set-component-visible img 0 TRUE)
      ; enable blue channel
      (gimp-image-set-component-visible img 2 TRUE)
      (gimp-drawable-desaturate lyr_g1 3)
      (gimp-item-set-visible lyr_g1 FALSE)
      (let*
        (
          (lyr_g2 (car (gimp-layer-copy lyr_g1 FALSE)))
        )
        (gimp-image-insert-layer img lyr_g2 0 -1)

        ; Create one layer representing the red component
        ; disable green channel
        (gimp-image-set-component-visible img 1 FALSE)
        ; disable blue channel
        (gimp-image-set-component-visible img 2 FALSE)
        (set!
          name_lyr_new (get-new-layer-name "r")
        )
        (let*
          (
            (lyr_r (car (gimp-layer-new-from-visible img img name_lyr_new)))
          )
          (gimp-image-insert-layer img lyr_r 0 -1)
          ; enable green channel
          (gimp-image-set-component-visible img 1 TRUE)
          ; enable blue channel
          (gimp-image-set-component-visible img 2 TRUE)
          (gimp-drawable-desaturate lyr_r 3)
          (gimp-item-set-visible lyr_r FALSE)

          ; Create one layer representing the blue component
          ; disable red channel
          (gimp-image-set-component-visible img 0 FALSE)
          ; disable green channel
          (gimp-image-set-component-visible img 1 FALSE)
          (set!
            name_lyr_new (get-new-layer-name "b")
          )
          (let*
            (
              (lyr_b (car (gimp-layer-new-from-visible img img name_lyr_new)))
            )
            (gimp-image-insert-layer img lyr_b 0 -1)
            ; enable red channel
            (gimp-image-set-component-visible img 0 TRUE)
            ; enable green channel
            (gimp-image-set-component-visible img 1 TRUE)
            (gimp-drawable-desaturate lyr_b 3)
            (gimp-item-set-visible lyr_b FALSE)

            ; Combine so to emphasise where there is a lot of green compared
            ; with the other colours
            (gimp-image-raise-layer img lyr_g2)
            (gimp-image-raise-layer img lyr_g2)
            (gimp-image-raise-layer img lyr_g1)
            (gimp-layer-set-mode lyr_g2 41) ; divide
            (gimp-layer-set-mode lyr_g1 41) ; divide
            (gimp-item-set-visible lyr_g2 TRUE)
            (gimp-item-set-visible lyr_b TRUE)
            (gimp-item-set-visible lyr_g1 TRUE)
            (gimp-item-set-visible lyr_r TRUE)
            (let*
              (
                (lyr_g2b (car (gimp-image-merge-down img lyr_g2 0)))
                (lyr_g1r (car (gimp-image-merge-down img lyr_g1 0)))
              )
              (plug-in-c-astretch 1 img lyr_g2b)
              (plug-in-c-astretch 1 img lyr_g1r)
              (gimp-layer-set-mode lyr_g2b 30) ; multiply
              (let*
                (
                  (lyr_g2bg1r (car (gimp-image-merge-down img lyr_g2b 0)))
                  (left off_x)
                  (right (+ wdt_orig (- off_x 1)))
                  (top off_y)
                  (bottom (+ hgh_orig (- off_y 1)))
                )
                (plug-in-c-astretch 1 img lyr_g2bg1r)
                (gimp-selection-none img)
                (for-each
                  (lambda (coords_)
                    (let * (
                        (coords (car (cdr coords_)))
                      )
                      (gimp-image-select-contiguous-color
                        img 0 ; 0 = add to selection
                        lyr_g2bg1r
                        (eval (car coords))
                        (eval (car (cdr coords)))
                      )
                    )
                  )
                  '(
                    '(0 0)
                    '(left  top   )
                    '(right top   )
                    '(right bottom)
                    '(left  bottom)
                    '((+ left  5) (+ top    5))
                    '((- right 5) (+ top    5))
                    '((- right 5) (- bottom 5))
                    '((+ left  5) (- bottom 5))
                  )
                )
                (gimp-image-remove-layer img lyr_g2bg1r)
                (let*
                  (
                    (res_x_px_per_mm
                      (/ (car (gimp-image-get-resolution img)) 25.4)
                    )
                  )
                  ; grow selection by 1.5 mm
                  (gimp-selection-grow img (* 1.5 res_x_px_per_mm))
                  ; feather selection by 0.025 mm
                  (gimp-selection-feather img (* 0.025 res_x_px_per_mm))
                )
                (gimp-selection-invert img)
                (set!
                  lyr_orig (car (gimp-image-get-active-layer img))
                )
                (let *
                  (
                    ; create a layer mask from the current selection
                    (msk (car (gimp-layer-create-mask lyr_orig 4)))
                  )
                  (gimp-layer-add-mask lyr_orig msk)
                )
                (gimp-layer-set-apply-mask lyr_orig TRUE)
                (let *
                  (
                    (lyr_back
                      (car
                        (gimp-layer-new
                          img
                          (car (gimp-image-width img))
                          (car (gimp-image-height img))
                          0 (get-new-layer-name "back") 100 28
                        )
                      )
                    )
                    (pos_lyr_orig
                      (car (gimp-image-get-layer-position img lyr_orig))
                    )
                  )
                  (gimp-image-insert-layer img lyr_back -1 (+ 1 pos_lyr_orig))
                )
              )
              (gimp-image-flatten img)
              (gimp-item-set-name
                (car (gimp-image-get-active-layer img))
                name_lyr_orig
              )
            )
          )
        )
      )
    )
    (set!
      lyr_orig (car (gimp-image-get-active-layer img))
    )
    (gimp-image-resize img wdt_orig hgh_orig (- off_x) (- off_y))
    (gimp-layer-resize-to-image-size lyr_orig)
  )
  (gimp-selection-none img)

  (gimp-image-undo-group-end img)
  (gimp-displays-flush)
)

(script-fu-register "script-fu-extract-from-green-background"
  _"Extract from Green Background"
  _"Makes the green border of the current layer transparent."
  "Warwick Allen"
  "Copyright (c) 2024 Warwick Allen, MIT licence"
  "July 2014"
  "*"
  SF-IMAGE    "Image"    0
  SF-DRAWABLE "Drawable" 0
)

(script-fu-menu-register "script-fu-extract-from-green-background"
                         "<Image>/Colors/Auto")
