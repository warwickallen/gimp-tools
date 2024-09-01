; standardise-border.scm
;
; Makes the border of the image a standard width.
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

(define (script-fu-standardise-border img)
  (gimp-image-undo-group-start img)

  ; Increase the current border, in case the image goes too close to the edge
  (gimp-image-flatten img)
  (let*
    (
      (lyr_orig (car (gimp-image-get-active-layer img)))
      (name_lyr_orig (car (gimp-item-get-name lyr_orig)))
      (bkg_orig (car (gimp-context-get-background)))
      (wdt_orig (car (gimp-image-width img)))
      (hgh_orig (car (gimp-image-height img)))
      (wdt_new (* 1.04 wdt_orig))
      (hgh_new (* 1.04 hgh_orig))
      (off_x (/ (- wdt_new wdt_orig) 2))
      (off_y (/ (- hgh_new hgh_orig) 2))
      (blr_x (* 0.02 wdt_orig))
      (blr_y (* 0.02 hgh_orig))
      (blr (/ (+ blr_x blr_y (max blr_x blr_y)) 3))
    )
    (define (get-new-layer-name postfix)
      (string-append name_lyr_orig " standardise-border " postfix)
    )
    (gimp-context-set-background '(0 0 0))
    (gimp-image-resize
      img
      (+ wdt_new)
      (+ hgh_new)
      off_x off_y
    )
    (gimp-image-flatten img)
    (let*
      (
        (lyr_blr (car (gimp-layer-new-from-drawable (car (gimp-image-get-active-layer img)) img)))
        (smpl_thrshld_orig (car (gimp-context-get-sample-threshold)))
      )
      (gimp-drawable-set-name lyr_blr (get-new-layer-name "blurred"))
      (gimp-image-insert-layer img lyr_blr 0 -1)
      (plug-in-gauss RUN-NONINTERACTIVE img lyr_blr blr blr 1) ; for the last param: 0 = IIR, 1 = RLE
      (gimp-context-set-sample-threshold 0.05)
      (gimp-image-select-contiguous-color img CHANNEL-OP-REPLACE lyr_blr 0 0)
      (gimp-context-set-sample-threshold smpl_thrshld_orig)
      (gimp-image-remove-layer img lyr_blr)
    )
    (gimp-selection-invert img)
    (let*
      (
        (sel_bounds (gimp-selection-bounds img))
        (sel_x1 (car (cdr    sel_bounds)))
        (sel_y1 (car (cddr   sel_bounds)))
        (sel_x2 (car (cdddr  sel_bounds)))
        (sel_y2 (car (cddddr sel_bounds)))
        (sel_wdt (- sel_x2 sel_x1))
        (sel_hgh (- sel_y2 sel_y1))
      )
      (gimp-crop img sel_wdt sel_hgh sel_x1 sel_y1)
    )
    (gimp-selection-none img)

    (gimp-context-set-background bkg_orig)
  )

  (gimp-image-undo-group-end img)
  (gimp-displays-flush)
)

(script-fu-register
  "script-fu-standardise-border"
  "Standardise Border"
  "Makes the border of the image a standard width."
  "Warwick Allen"
  "Copyright (c) 2024 Warwick Allen, MIT licence"
  "August 2014"
  "*"
  SF-IMAGE    "Image"    0
  SF-DRAWABLE "Drawable" 0
)

(script-fu-menu-register
  "script-fu-standardise-border"
  "<Image>/Image"
)
