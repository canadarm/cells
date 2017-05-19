;-----waitr(a,d0,d1,d2)----
; uses given ar,dr1,dr2,dr3
waitr       MACRO
    IFND DEBUG
    move.w  #$CA,\2             ; $138 PAL, $CB NTSC
    move.l  #$1ff00,\4
    lsl.l   #8,\2
    and.l   \4,\2
    lea     $dff004,\1
.waitr\@:
    move.l  (\1),\3
    and.l   \4,\3
    cmp.l   \3,\2
    bne.s   .waitr\@
    ENDC
    ENDM

;-----waitb()--------------
; FIXME - this seems to hang in some cases?
waitb       MACRO
    IFND DEBUG
    move.w  #$7FFF,_DMACON
    move.w  #DMAF_ALLN,_DMACON
    tst     _DMACONR            ; for compatibility - prime DMACONR
.waitb\@
    btst    #6,_DMACONR
	  bne.s   .waitb\@
    move.w  #$7FFF,_DMACON
    move.w  #DMAF_ALL,_DMACON
    ENDC
    ENDM

;-----waitblit()-----------
; alternate blitter wait?
waitblt     MACRO
    IFND DEBUG
    btst.b  #6,_DMACONR
.waitblt\@
    btst.b  #6,_DMACONR
    bne     .waitblt\@
    ENDC
    ENDM

;-----setblt(a)------------
; uses given ar
; uses/sets bltset variable
setblt      MACRO
    lea     bltset(pc),\1
    btst    #1,(\1)
    beq     .setblt\@
    rts
.setblt\@:
    move.l  #-1,_BLTAFWM        ; set word mask for source a = 1s
    move.w  #$8000,_BLTADAT
    move.w  #$FFFF,_BLTBDAT    
    move.w  #bplwidth,_BLTCMOD 
    move.w  #bplwidth,_BLTDMOD
    move.w  #$F,(\1)
    ENDM

