;-----macro defs-----------
;TEST        SET 1
;SHOWCELLS   SET 1
;DEBUG       SET 1
;MODONE      SET 1
;NOINT       SET 1

    INCDIR  "git/"
    INCLUDE "defs.i"
    INCLUDE "start.i"

;-----state defs-----------
wsizelog    equ 3               ; log2(wsize)
wsize       equ (1<<wsizelog)   ; window size (rows)
hsize       equ wsize*4         ; history window size
hsizel      equ (hsize/4)       ; history window size in dwords
pwidthlog   equ 3               ; log2(pwidth)
pwidth      equ (1<<pwidthlog)  ; pattern width
pwidthb     equ (pwidth/8)      ; pattern width (bytes)
pwidthbl    equ (pwidthlog-3)   ; log2(pwidthb)
psize       equ (pwidthb*pwidth); pattern size
psizel      equ (psize/4)       ; pattern size in dwords
psizelog    equ (pwidthbl+pwidthlog) ; log2(psize)
psizeb      equ (psize/32)      ; pattern size (packed)
sprwidthlog equ (pwidthlog+csizelog-3)
sprwidth    equ (1<<sprwidthlog)
sprwidthl   equ (sprwidth/4)
sprwidthw   equ (sprwidth/2)
sprsizelog  equ (sprwidthlog+csizelog+pwidthlog)
sprsize     equ (1<<sprsizelog)
sprsizel    equ (sprsize/4)
sprsizew    equ (sprsize/2)

;-----buffer defs----------
coff        equ (bplwidth-sprwidth)/2   ; modulo for patterns in bytes
coffw       equ (bplwidthw-sprwidthw)/2 ; modulo for patterns in words
tsizelog    equ 2
tsize       equ (1<<tsizelog)
wavsizelog  equ (tsizelog+6)            ; 6 = tabsizelog
wavsize     equ (1<<wavsizelog)
wavsizew    equ (wavsize/2)

;-----flag bits------------
F_STEP      equ 0               ; step screen next vblank
F_KEY       equ 1               ; key pressed
F_DATA      equ 2               ; data ready from PPT
F_DRAW      equ 4               ; match to draw next vblank
F_MATCH     equ 5               ; match found
F_ENV       equ 6               ; update envelopes

;------flag2 bits----------
G_PLAY      equ 0               ; play note next iter (delay?)
G_LDM       equ 1               ; modulate lead
G_RAND      equ 2               ; randomize next state
G_ONE       equ 3               ; init next state
G_MOD       equ 4               ; modulate next iter
G_ERR       equ 7

;-----sequencer defs-------
E_ATT       equ 1
E_DEC       equ 2
E_REL       equ 3

;-----color defs------------
ctablog     equ   3
ctabsize    equ   (1<<ctablog)
cskip       equ   height/ctabsize

;-----ppt defs-------------
pptb        equ   4             ; buffer element count
pptd        equ   3             ; data element count
pptn        equ   (pptb+pptd)   ; total element count

;-----entry point----------
;-----init playfield-------
    IFND DEBUG
    move.w  #$2200,_BPLCON0     ; two planes, composite
    move.w  #00,_BPLCON1        ; hscroll = 0
    move.w  #0,_BPL1MOD         ; mod for odd planes (bg)
    move.w  #0,_BPL1MOD         ; mod for even planes (bg)
    move.w  #$0038,_DDFSTRT     ; data-fetch start = $38/3Chi
    move.w  #$00D0,_DDFSTOP     ;            stop  = $D0/D4hi
    move.w  #$2100,_DIWHIGH     ; diw-high  = msb set for stop
    move.w  #$2C81,_DIWSTRT     ; diw-start = $2C81
    move.w  #$F4C1,_DIWSTOP     ; diw-stop  = $F4C1 (NTSC, PAL 2CC1)
    move.w  #$0111,_COLOR00     ; bg color (0) 
    move.w  #$0391,_COLOR01     ; fg color (1)
    move.w  #$0FFF,_COLOR02     ; fg color (2)
    move.w  #$0FFF,_COLOR03     ; fg color (3)
    move.w  #$0000,_BLTCON1     ; clear BLTCON1
    ENDC

;-----init rng-------------
    IFD TEST
    jsr     seed
    ENDC

;-----init buffers----------
    IFD TEST
    move.b  #1,state+16
    bset    #G_RAND,flags2
    ENDC
    move.w  #0,pattern
    move.w  pattern,d1
    jsr     loadpat
    jsr     loadscales

    IFD DEBUG
    lea     buf,a6
;   move.l  #$FFFEBFFE,(a6)+
;   move.l  #$8003E003,(a6)+
;   move.l  #$BFFA2FFA,(a6)+
;   move.l  #$E00EB80F,(a6)+
;   move.l  #$2FEBEBE9,(a6)+
    move.l  #%00000000000000000000011111110000,(a6)+
    move.l  #%00000000000000000000010000010000,(a6)+
    move.l  #%00000000000000000000010111010000,(a6)+
    move.l  #%00000000000000000000011101110000,(a6)+
    move.l  #%00000000000000000000000000000000,(a6)+
    move.l  #%00000000000000000000000000000000,(a6)+
    move.w  #0,bpos
    jsr     match
    move.w  mb1,d0
    sub.w   #1,d0
    lea     ldstate+2,a0
    move.w  d0,LDN(a0)
    bset    #0,LDT(a0)
    jsr     playlead
    bra     .exit
    ENDC

;-----init wavetables------
    jsr     initwav
    move.l  #_AUD0LC,a6         ; audio base
    move.l  #wavm0,d6
    move.l  d6,0(a6)            ; set first channels
    move.w  #TABSIZEW,4(a6)
    clr.w   6(a6)
    clr.w   8(a6) 
    move.l  #wavm1,d6          
    add.l   #AUDOFFSET,a6
    move.l  d6,0(a6)
    move.w  #TABSIZEW,4(a6)
    clr.w   6(a6)
    clr.w   8(a6)
    move.l  #wavm1,d6          
    add.l   #AUDOFFSET,a6       ; set second channels
    move.l  d6,0(a6)
    move.w  #TABSIZEW,4(a6)
    clr.w   6(a6)
    clr.w   8(a6)
    move.l  #wavm0,d6          
    add.l   #AUDOFFSET,a6
    move.l  d6,0(a6)
    move.w  #TABSIZEW,4(a6)
    clr.w   6(a6)
    clr.w   8(a6)

;-----init lead params-----
    lea     ldstate,a6
    move.w  #ldsize/4-1,d6
.initld:
    clr.l   (a6)+
    dbra    d6,.initld
    lea     ldstate,a6
    move.w  #80,LDI(a6)
    move.w  #90,LDV(a6)
    move.w  #12,LDA(a6)
    move.w  #28,LDD(a6)
    move.w  #24,LDS(a6)
    move.w  #1,LDR(a6)
    move.w  #1,LDO(a6)
    move.w  #1,MDR(a6)
    add.l   #2,a6
    move.w  #40,LDI(a6)
    move.w  #90,LDV(a6)
    move.w  #16,LDA(a6)
    move.w  #5,LDD(a6)
    move.w  #60,LDS(a6)
    move.w  #6,LDR(a6)
    move.w  #0,LDO(a6)
    move.w  #4,MDR(a6)
    move.b  #0,mode

;-----setup copper list----
    IFND DEBUG
    move.l  #bgpl,d0            ; set up bg pointer
    move.w  d0,copptrl
    swap    d0
    move.w  d0,copptrh
    move.l  #fgpl,d0            ; set up fg pointer
    move.w  d0,copptr2l
    swap    d0
    move.w  d0,copptr2h
    lea     coplist,a1          ; copper list position
    lea     ctab,a2             ; color table base
    move.w  #0,d0               ; color list index
    move.w  #$0001,d5           ; init wait position
    move.w  #cskip,d4           ; period in bit 8
    lsl.w   #8,d4
    move.w  #ctabsize-1,d6      ; loop counter
.clist:
    C_WAITR a1,d5,#$FF00        ; WAIT for next line
    move.w  (a2,d0.w),d3        ; load color
    C_MOVE  a1,COLOR01_,d3
    add.w   d4,d5               ; update WAIT position
    add.w   #2,d0               ; next color
    dbra    d6,.clist
    C_ENDL  a1                  ; end list
    move.l  #copstart,_COP1LCH 
    ENDC

;-----system setup---------
    IFND DEBUG
    waitr   a1,d0,d1,d2
    move.l  #CIAA,a5            ; CIA-A base
    move.l  #CIAB,a6            ; CIA-B base
    move.b  #$7F,CIAICR(a5)     ; clear CIA-A interrupts
    move.b  #$7F,CIAICR(a6)     ; clear CIA-B interrupts
    move.b  #$18,CIACRA(a5)     ; CIA-A TA: one-shot, KB input mode
    IFND TEST
    move.b  #$00,CIADDRB(a5)    ; CIA-A DDRB: ppt input
    and.b   #$F8,CIADDRA(a6)    ; CIA-B DDRA: ctl input (reset)
    or.b    #$07,CIAPRA(a6)	; CIA-B PRA: all ctl high
    ENDC
    IFD TEST
    and.b   #$80,CIACRB(a6)     ; CIA-B TB: continuous, pulse, PB6OFF
    or.b    #$10,CIACRB(a6)
    move.b  #(period&$FF),CIATBLO(a6) ; set CIA-B timer B period 
    move.b  #(period>>8),CIATBHI(a6)  ; ..for timer interrupt
    ENDC
    move.b  #(kbhs&$FF),CIATBLO(a5)   ; set CIA-A timer B period
    move.b  #(kbhs>>8),CIATBHI(a5)    ; .. for kb handshake
    move.l  #keyint,$68.w       ; install lvl2 handler (cia-a)
    move.l  #vblankint,$6C.w    ; install lvl3 handler
    IFD TEST
    move.l  #timerint,$78.w     ; install lvl6 handler (cia-b)
    move.b  #$88,CIAICR(a5)     ; enable CIA-A SP interrupt (keyboard)
    move.b  #$82,CIAICR(a6)     ; enable CIA-B TB interrupt
    move.w  #$E028,_INTENA      ; enable lvl2/3/6
    bset.b  #0,CIACRB(a6)       ; start CIA-B TB
    ENDC
    IFND TEST
    move.b  #$90,CIAICR(a5)     ; enable CIA-A FLG/SP interrupt (keyboard)
    move.w  #$C028,_INTENA      ; enable lvl2/3
    ENDC
    waitr   a1,d0,d1,d2
    move.w  _COPJMP1,d0         ; start copper
    move.w  #$0088,_ADKCON      ; clear mod bits
    move.w  #$7FFF,_DMACON      
    move.w  #$87CF,_DMACON      ; start DMA
    ENDC

;-----frame loop start-------
.mainloop:
    btst    #F_KEY,flags
    beq     .nokey
    bclr    #F_KEY,flags
    jsr     handlekb
.nokey:
    btst    #F_DATA,flags
    beq     .nodata
    bclr    #F_DATA,flags
;    add.l   #$10000,dbg
    IFND TEST
    move.b  pmod,d0
    jsr     modulate
    move.b  proot,d0
    jsr     chroot
    move.b  ppat,d0
    jsr     setpat
    ENDC
    jsr     match
    btst    #F_MATCH,flags
    beq     .nodata
    add.l   #$1,dbg
.nodata:
    btst    #F_ENV,flags
    beq     .noenv
    bclr    #F_ENV,flags
    jsr     doenv
.noenv:
    btst    #G_MOD,flags2
    beq     .nomod
    bclr    #G_MOD,flags2
    move.b  mode,d0
    add.b   #1,d0
    jsr     modulate
.nomod:
    btst    #G_LDM,flags2
    beq     .noldm
    bclr    #G_LDM,flags2
    jsr     modlead
.noldm
    btst    #G_PLAY,flags2
    beq     .notrig
    bclr    #G_PLAY,flags2
    jsr     playlead
.notrig:
    btst    #G_ERR,flags2
    beq     .endmain
    move.w  #$7FFF,_INTENA      ; turn off interrupts
.errlp
    btst    #6,$bfe001
    bne     .errlp
    bra     .exit
.endmain:
    btst    #6,$bfe001
    bne     .mainloop
;-----frame loop end---------
.exit:
    move.l  dbg,d6
    rts

;------interrupts----------
keyint:
    movem.l d1-d6/a0-a4,-(sp)
    move.w  _INTREQR,d0
    btst    #3,d0               ; PORTS handler
    beq     .exit
    move.l  #CIAA,a0
    move.l  #CIAB,a1
    IFND TEST
    btst.b  #4,CIAICR(a0)       ; test FLAG bit (ppt)
    bne     .ppt
    bra     .exit
    ENDC
    IFD TEST
    btst.b  #3,CIAICR(a0)       ; test SP bit (kb)
    beq     .exit
    move.b  CIASDR(a0),d6       ; load serial data
    or.b    #$01,CIACRB(a0)     ; start CIA-A TB (one shot)
    or.b    #$40,CIACRA(a0)     ; set output mode (handshake)
    not.b   d6                  ; decode key
    lsr.b   #1,d6
    bcs     .handshake
    and.w   #$7F,d6             ; test key value
    move.w  d6,key
    bset    #F_KEY,flags 
.handshake:
    moveq   #2,d6               ; busy wait for timer underflow
    and.b   CIAICR(a0),d6
    beq     .handshake
    and.b   #$BF,CIACRA(a0)     ; set input mode
    ENDC
    IFND TEST
    bra     .exit
.ppt:
;   add.l   #1,dbg
    move.b  ppos,d2             ; get count
    cmp.b   #pptb,d2            ; read buffer?
    bge     .pptd               ; no, read data
    lea     buf,a2
    move.w  bpos,d6
.w1 btst.b  #1,CIAPRA(a1)       ; busy wait valid low
    bne     .w1
    move.b  CIAPRB(a0),d0       ; load parallel data
    move.b  d0,(a2,d6.w)        ; store state
    bset.b  #1,CIAPRA(a1)       ; reset valid
    bset.b  #0,CIADDRA(a1)      ; set ack to output
    bclr.b  #0,CIAPRA(a1)       ; pull ack low
    add.w   #1,d6               ; increment position
    and.w   #$1F,d6             ; mod 4*window size
    move.w  d6,bpos             ; update position
    bra     .ppdone
.pptd:
    lea     pdata,a2            ; param address
    ext.w   d2                  ; to index
.w2 btst.b  #1,CIAPRA(a1)       ; busy wait valid low
    bne     .w2
    move.b  CIAPRB(a0),d0       ; load parallel data
    move.b  d0,(a2,d2.w)        ; store parameter
    bset.b  #1,CIAPRA(a1)       ; reset valid
    bset.b  #0,CIADDRA(a1)      ; set ack to output
    bclr.b  #0,CIAPRA(a1)       ; pull ack low
.ppdone:
    and.b   #$F8,CIADDRA(a1)    ; set all input (reset)
    or.b    #$7,CIAPRA(a1)      ; reset valid, ack to high
    add.b   #1,d2               ; increment 
    cmp.b   #pptn,d2            ; test
    blt     .nopp
    clr.b   d2                  ; reset
    bset    #F_STEP,flags       ; indicate step
    bset    #G_LDM,flags2       ; request env update
    btst    #F_MATCH,flags      ; match found on prev data?
    beq     .nomatch
    bclr    #F_MATCH,flags
    lea     ldstate,a0
    clr.w   d1
    move.w  mb0,d0
    move.w  d0,mx0
    clr.w   mb0
    subq.w  #1,d0 
    blt     .nomatch0
    move.w  d0,LDN(a0,d1.w)     ; set note
    bset    #0,LDT(a0,d1.w)     ; set trigger
    bset    #F_DRAW,flags       ; request pattern draw
    bset    #G_PLAY,flags2
.nomatch0:
    add.w   #2,d1
    move.w  mb1,d0
    move.w  d0,mx1
    clr.w   mb1
    subq.w  #1,d0 
    blt     .nomatch1
    move.w  d0,LDN(a0,d1.w)     ; set note
    bset    #0,LDT(a0,d1.w)     ; set trigger
    bset    #F_DRAW,flags       ; request pattern draw
    bset    #G_PLAY,flags2
.nomatch1:
.nomatch:
.nopp:
    move.b  d2,ppos             ; update position
    ENDC
.exit:
    move.w  #$4008,_INTREQ
    move.w  #$4008,_INTREQ
    movem.l (sp)+,d1-d6/a0-a4
    rte

vblankint:
    movem.l d0-d6/a0-a6,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #5,d0               ; VBLANK handler
    beq     .exit
    bset    #F_ENV,flags
    btst    #F_STEP,flags
    beq     .nostep
    bclr    #F_STEP,flags
   add.l #$1000,dbg
    bset    #F_DATA,flags       ; data ready for next match
    lea     bgpl,a0             ; get screen base
    move.w  coprpos,d5          ; get copper offset
    addmod  d5,width,bplsize    ; update start
    move.w  d5,coprpos
    IFND SHOWCELLS
    lea     bgpl,a2
    lea     (a2,d5.w),a1
    move.w  #8,d1
    jsr     clearpl
    add.l   #bplsize,a1
    jsr     clearpl
    ENDC
    lea     (a0,d5.w),a1        ; copper start
    move.l  a1,d6
    move.w  d6,copptrl          ; update copper pointers
    swap    d6
    move.w  d6,copptrh
    IFD SHOWCELLS
    lea     bgpl,a0             ; screen base for copy
    ELSE
    lea     bgpl0,a0
    ENDC
    move.w  bplpos,d4           ; offset for copy
    addmod  d4,width,bplsize    ; increment
    move.w  d4,d5
    add.w   #doff,d5
    lea     (a0,d5.w),a2        ; copy address
    IFD TEST
    IFD SHOWCELLS
    lea     cbuf,a0             ; source address
    move.l  a2,a1               ; copy address
    jsr     copystate           ; copy state
    lea     bgplhi,a0           ; screen base for render
    ENDC
    ELSE
    lea	    bgplhi0,a0
    ENDC
    move.w  d4,bplpos
    move.w  d4,d5 
    add.w   #doff,d5
    lea     (a0,d5.w),a3        ; render address
    IFD TEST
    IFD SHOWCELLS
    move.w  drawpos,d0
    jsr     drawstate           ; draw state
    move.l  a3,a1               ; render address
    lea     cbuf,a0             ; source address
    jsr     copystate
    ENDC
    ENDC
    lea     fgpl0,a1            ; get fg pointer
    jsr     clearrow            ; clear fg row
    btst    #F_DRAW,flags       ; match to render?
    beq     .nomatch
    bclr    #F_DRAW,flags
    add.l   #doff,a1            ; add offset
    move.l  a1,a4               ; stash
    IFD SHOWCELLS
    sub.l   #patoffset,a3       ; add bg offset
    sub.l   #patoffset,a2       ; add bg offset
    ENDC
    move.w  mx0,d0              ; load match index
    subq.w  #1,d0               ; adjust
    blt     .nomatch0
    add.w   #1,dbg
    move.w  #0,d1               ; select pattern 0
    move.l  a4,a1
    jsr     drawpat             ; draw pattern 0 (fg)
    move.l  a3,a1
    jsr     drawpat             ; draw pattern 0 (bg)
    clr.w   mx0                 ; reset index
.nomatch0:
    move.w  mx1,d0              ; load match index
    subq.w  #1,d0               ; adjust
    blt     .nomatch1
    move.w  #1,d1               ; select pattern 1
    move.l  a4,a1
    jsr     drawpat             ; draw pattern 1 (fg)
    move.l  a3,a1
    jsr     drawpat             ; draw pattern 1 (bg)
    clr.w   mx1                 ; reset index
.nomatch1: 
    move.l  a3,a0               ; bg address
    move.l  a2,a1               ; copy address
    jsr     copyrow
.nomatch:
.nostep:
.exit:
    move.w  #$0020,_INTREQ      ; clear INTREQ
    move.w  #$0020,_INTREQ      ; ... twice
    movem.l (sp)+,d0-d6/a0-a6
    rte

timerint:
    movem.l d0-d6/a0-a3,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    and.w   #$2000,d0           ; PORTS handler
    beq     .exit
    move.l  #CIAB,a0            ; CIA-B base
    btst    #1,CIAICR(a0)       ; timer interrupt
    beq     .exit
    add.b   #1,count            ; increment count mod countmod
    cmp.b   #countmod,count     ; check for mod divider
    bne     .nomod
    clr.b   count
.nomod:
    move.b  cpos,d0             ; increment mod position
    add.b   #1,d0
    and.b   #(csize-1),d0       ; mod and test 0
    move.b  d0,cpos
    cmp.b   #0,d0
    bne     .exit
    bset    #G_LDM,flags2       ; request env update
    bset    #F_STEP,flags       ; set step
    btst    #F_MATCH,flags      ; match found on prev data?
    beq     .nomatch
    bclr    #F_MATCH,flags
    lea     ldstate,a0
    clr.w   d2
    move.w  mb0,d0
    move.w  d0,mx0
    clr.w   mb0
    subq.w  #1,d0 
    blt     .nomatch0
    move.w  d0,LDN(a0,d2.w)     ; set note
    bset    #0,LDT(a0,d2.w)     ; set trigger
    bset    #F_DRAW,flags       ; request pattern draw
    bset    #G_PLAY,flags2
.nomatch0:
    add.w   #2,d2
    move.w  mb1,d0
    move.w  d0,mx1
    clr.w   mb1
    subq.w  #1,d0 
    blt     .nomatch1
    move.w  d0,LDN(a0,d2.w)     ; set note
    bset    #0,LDT(a0,d2.w)     ; set trigger
    bset    #F_DRAW,flags       ; request pattern draw
    bset    #G_PLAY,flags2
.nomatch1:
.nomatch:
    IFD TEST
    move.w  pos,drawpos
    jsr     nextstate
    ENDC
.exit:
    move.w  #$2000,_INTREQ      ; clear INTREQ
    move.w  #$2000,_INTREQ      ; ... twice
    movem.l (sp)+,d0-d6/a0-a3
    rte

;-----tables---------------
    INCDIR  "git/"
    INCLUDE "tablead.i"
    INCLUDE "scales.i"
    INCLUDE "pattern.i"

;------saves/system--------
    SECTION state,DATA_F
    CNOP    0,4
flags:
    dc.w    0                   ; state flags
flags2:
    dc.w    0                   ; state flags
key:
    dc.w    0                   ; last keypress
bpos:
    dc.w    0                   ; buffer position
pos:
    dc.w    0
ppos:
    dc.b    0                   ; ppt read position
pdata:
    dc.b    0, 0, 0, 0          ; padding
pmod:
    dc.b    0                   ; mode from ppt
proot:                  
    dc.b    0                   ; root from ppt
ppat:
    dc.b    0                   ; pattern from ppt
    EVEN
audtab:
    dc.w    0, AUDOFFSET*3, AUDOFFSET*1, AUDOFFSET*2

;-----system---------------
    SECTION saves,DATA
    CNOP    0,4
dbg:  
    dc.l    0
  
;-----locals---------------
    SECTION pos,DATA_F
    CNOP    0,4
bplpos:
    dc.w    0                   ; bitplane offset for render
coprpos:
    dc.w    0                   ; copper offset  
drawpos:
    dc.w    0                   ; horiz. position for patterns
    dc.w    0
    EVEN
cpos:
    dc.b    0                   ; scroll position mod 8
count:
    dc.b    0                   ; step counter

;-----wave buffers---------
    SECTION wave,BSS_C
    CNOP    0,4
wav0:
    ds.w    wavsizew
wav1:
    ds.w    wavsizew
wavm0:
    ds.w    wavsizew
wavm1:
    ds.w    wavsizew

;-----cell buffers---------
    SECTION cells,BSS_C
    CNOP    0,4
buf:
    ds.l    hsizel              ; state buffer 
    CNOP    0,4
spr0:
    ds.l    sprsizel            ; display pattern 0
spr1:
    ds.l    sprsizel            ; display pattern 1

;-----pattern data--------
    SECTION pattern,DATA_F
    CNOP    0,4
pat0:
    dc.l    0                   ; pattern address 0
pat1:
    dc.l    0                   ; pattern address 1
mask0:
    dc.l    0                   ; mask address 0
mask1:
    dc.l    0                   ; mask address 1
    CNOP    0,4
mbits0:
    dc.l    0                   ; match mask 0
mbits1:
    dc.l    0                   ; match masks 1
mx0:
    dc.w    0                   ; match index 0 (draw)
mx1:
    dc.w    0                   ; match index 1 (draw)
mb0:
    dc.w    0                   ; match index 0 (buffer)
mb1:
    dc.w    0                   ; match index 1 (buffer)

;-----cell state-----------
    IFD TEST
    SECTION amd,DATA
    CNOP    0,4
rule:
    dc.w    0
zeros:
    dc.b    0
    SECTION cstate,BSS
    CNOP    0,4
state:
    ds.b    stsize
newstate:
    ds.b    ncells
    ENDC 

;-----leads data-----------
    SECTION scales,DATA_f
    CNOP    0,4
scale:
    ds.w    sclen             ; scale lists
scoct:
    ds.w    sclen
    SECTION seq,DATA_F
    CNOP    0,4
ldstate:
ldnote:
    ds.w    2                 ; current notes
ldvoice:
    ds.w    2                 ; current voice
ldtrig:
    ds.w    2                 ; triggers
ldinit:
    ds.w    2                 ; init volumes
ldoct:
    ds.w    2                 ; octaves
ldvol:
    ds.w    2                 ; max volumes
ldatt:
    ds.w    2                 ; attack rates
lddec:
    ds.w    2                 ; decay rates
ldsus:
    ds.w    2                 ; 'sustain' level
ldrel:
    ds.w    2                 ; release rate
ldmp:
    ds.w    2                 ; mod position
ldmr:
    ds.w    2                 ; mod rate
ldparms:
ldenv:
    ds.w    2                 ; envelope states (voice 0)
    ds.w    2                 ; envelope states (voice 1)
ldlvl:
    ds.w    2                 ; level (voice 0)
    ds.w    2                 ; level (voice 1)
ldend:
    dc.w    0
ldsize      equ  (*-ldstate)

;-----ldstate addressing---
LDN         equ   (ldnote-ldstate)
LDC         equ   (ldvoice-ldstate)
LDT         equ   (ldtrig-ldstate)
LDO         equ   (ldoct-ldstate)
LDI         equ   (ldinit-ldstate)
LDV         equ   (ldvol-ldstate)
LDA         equ   (ldatt-ldstate)
LDD         equ   (lddec-ldstate)
LDS         equ   (ldsus-ldstate)
LDR         equ   (ldrel-ldstate)
LDE         equ   (ldenv-ldparms)
LDL         equ   (ldlvl-ldparms)
MDP         equ   (ldmp-ldstate)
MDR         equ   (ldmr-ldstate)

;-----copper lists---------
    SECTION cop,DATA_C
    CNOP    0,4
copstart:
    dc.w    BPL1PTL_
copptrl:  
    dc.w    0
    dc.w    BPL1PTH_
copptrh:
    dc.w    0
    dc.w    BPL2PTL_
copptr2l:  
    dc.w    0
    dc.w    BPL2PTH_
copptr2h:  
    dc.w    0
coplist:
    dcb.l   64, CL_END

;-----bitplanes------------
    SECTION planes,BSS_C
patoffset   equ width*(pwidth-1)
    CNOP    0,4
bgpl0:
    ds.b    (patoffset)
bgpl:
    ds.b    (bplsize-(patoffset))
bgplhi0:
    ds.b    (patoffset)
bgplhi:
    ds.b    bplsize
    CNOP    0,4
fgpl:
    ds.b    (bplsize-patoffset)
fgpl0:
    ds.b    (patoffset+width)

    IFD TEST
    CNOP    0,4
cbuf:
    ds.b    stwidth*csize     ; state display buffer
    ENDC

;-----color tables---------
    SECTION amd,DATA
    CNOP    0,4
ctab:
    dc.w    $0003
    dc.w    $0014
    dc.w    $0015
    dc.w    $0126
    dc.w    $0127
    dc.w    $0138
    dc.w    $0239
    dc.w    $024A

;-----functions------------
    SECTION funcs,CODE_F
   
;-----loadpat(d1)-------
; load patterns at index d1 into buffers spr0/1
; and set pointers.
    CNOP    0,4
loadpat:
    IFD TEST
    lea     rules,a1
    move.w  d1,d2
    lsl.w   #rulesl,d2
    move.b  (a1,d2.w),rule+1
    ENDC
    lea     patterns,a6
    lea     masks,a5
    lea     mmap,a4
    lea     invert,a3
    move.w  d1,d0
    lsl.w   #patsl,d1           ; form pattern index
    move.w  d0,d2               
    lsl.w   #invsl,d0           ; form invert index
    lsl.w   #mmapsl,d2          ; form map index
    move.w  (a4,d2.w),d3        ; load map offset for first pattern
    lea     (a6,d1.w),a1        ; pattern 0 address
    lea     (a5,d3.w),a2        ; mask 0 address
    move.l  a1,pat0
    move.l  a2,mask0
    lea     spr0,a2             ; first sprite
    move.w  #pwidth-1,d6        ; loop counter
.loada:
    move.b  (a6,d1.w),d4        ; load sprite line
    cmp.b   #0,(a3,d0.w)        ; test invert bit
    beq     .posa
    not.b   d4                  ; negate bits
.posa:
    move.b  (a5,d3.w),d5
    and.b   (a5,d3.w),d4        ; and with mask
    move.b  d4,.ptmp            ; stash 
    clr.w   d5                  ; line counter
    move.w  #pwidth-1,d5        ; loop counter/bit
.expa:
    clr.b   d4
    btst    d5,.ptmp            ; test pattern bit
    beq     .offa
    move.b  #$7E,d4
.offa:
    move.l  a2,a1               ; copy start address
    REPT csize-2
    add.l   #sprwidth,a1
    move.b  d4,(a1)
    ENDR
    add.l   #1,a2               ; next sprite column
    dbra    d5,.expa
    add.w   #1,d1               ; next pattern byte
    add.w   #1,d3               ; next mask byte
    add.l   #sprwidth*(csize-1),a2  ; next cell line
    dbra    d6,.loada
.startb:
    add.w   #2,d2               ; next map offset
    add.w   #1,d0               ; next invert bit
    move.w  (a4,d2.w),d3        ; load map offset for next pattern
    lea     (a6,d1.w),a1        ; pattern 1 address
    lea     (a5,d3.w),a2        ; mask 1 address
    move.l  a1,pat1
    move.l  a2,mask1
    lea     spr1,a2             ; first sprite
    move.w  #pwidth-1,d6        ; loop counter
.loadb:
    move.b  (a6,d1.w),d4        ; load sprite line
    cmp.b   #0,(a3,d0.w)        ; test invert bit
    beq     .posb
    not.b   d4                  ; negate bits
.posb:
    move.b  (a5,d3.w),d5
    and.b   (a5,d3.w),d4        ; and with mask
    move.b  d4,.ptmp            ; stash 
    clr.w   d5                  ; line counter
    move.w  #pwidth-1,d5        ; loop counter/bit
.expb:
    clr.b   d4
    btst    d5,.ptmp            ; test pattern bit
    beq     .offb
    move.b  #$7E,d4
.offb:
    move.l  a2,a1               ; copy start address
    REPT csize-2
    add.l   #sprwidth,a1
    move.b  d4,(a1)
    ENDR
    add.l   #1,a2               ; next sprite column
    dbra    d5,.expb
    add.w   #1,d1               ; next pattern byte
    add.w   #1,d3               ; next mask byte
    add.l   #sprwidth*(csize-1),a2  ; next cell line
    dbra    d6,.loadb
    rts
.ptmp dc.b  0,0

;-----loadscales()---------
; update the scales/leads for the current mode.
    CNOP    0,4
loadscales:
    lea     scales,a6         ; scale base
    lea     scale,a5          ; scale list
    lea     scoct,a1          ; octave list
    lea     ldstate,a4        ; param base
    lea     ptab4,a2          ; period table
    clr.w   d0                ; wave table
    move.b  mode,d5           ; get mode
    ext.w   d5 
    move.b  root,d1           ; root note
    ext.w   d1
    lsl.w   #ldlenlog,d5      ; get lead scale index
    lea     (a6,d5.w),a3      ; scale base
    move.b  (a3)+,d4          ; get scale length
    ext.w   d4
    move.w  #9,d3
    sub.w   d4,d3             ; get scale offset to centre
    move.w  #sclen-1,d6       ; loop counter
.copy:
    move.b  (a3,d3.w),d5      ; get scale note
    ext.w   d5
    add.w   d1,d5             ; add root
    lsl.w   #1,d5             ; form period index 
    move.w  (a2,d5.w),(a5)+   ; copy period
    move.w  d0,(a1)+          ; store octave
    add.w   #1,d3             ; increment mod length
    cmp.w   d4,d3
    bne     .nowrap
    clr.w   d3
    add.w   #1,d0             ; next wave table
    and.w   #$3,d0
.nowrap:
    dbra    d6,.copy
    rts

;-----modulate()---------
; set current key to value in d0.
    CNOP    0,4
modulate:
    cmp.b   mode,d0
    beq     .end
    cmp.b   #seqcnt,d0
    blt     .nowrap
    clr.b   d0
.nowrap:
    move.b  d0,mode
    jsr     loadscales
.end:
    rts
    
;-----incpat(d0)-----------
; adjust the current pattern
; by the amount in d0. write the pattern
; data to the sprite areas.
    CNOP    0,4
incpat:
    move.w  pattern,d1
    add.w   d0,d1 
    cmp.w   #0,d1
    bge     .pos
    add.w   #numpat,d1
.pos: 
    cmp.w   #numpat,d1
    blt     .inrange
    sub.w   #numpat,d1
.inrange:
    move.w  d1,pattern
    jsr     loadpat
    rts 

;-----setpat()----------------
; sets the pattern to the value in d0
    CNOP    0,4
setpat:
    ext.w   d0
    cmp.w   pattern,d0
    beq     .end
    cmp.w   #0,d0
    bge     .pos
    add.w   #numpat,d0
.pos: 
    cmp.w   #numpat,d0
    blt     .inrange
    sub.w   #numpat,d0
.inrange:
    move.w  d0,pattern
    move.w  d0,d1
    jsr     loadpat
.end:
    rts 

;-----matchdown()-------------
; match helper. check later rows for match and 
; set corresponding bit of mbits(0,1).
; d0 = pattern (0,1)
; a0 = pattern base
; a1 = mask base
; (a6,d5) = history row (preserve)
; a4, a5 = patterns (preserve)
; d6 = index + 7 (preserve)
; d2 = history data (preserve)
; saves d2-d6,a4-a6, kills d0-d1
    CNOP    0,4
matchdown:
    movem.l d2-d6,-(sp)         ; save regs
    move.w  d0,d3               ; save pattern index  
    move.w  #1,d0               ; next row
    add.w   #4,d5               ; next window row
    and.w   #$1C,d5             ; mod (8 rows * 4 bytes/row)
    neg.w   d6                  ; counter in [-31,0]
    add.w   #31,d6              ; counter in [0,31]
    moveq   #pwidth-2,d4        ; loop counter
.loop:
    move.l  (a6,d5.w),d1        ; get row
    ror.l   d6,d1               ; rotate into position
    and.b   (a1,d0.w),d1        ; apply mask
    cmp.b   (a0,d0.w),d1        ; compare
    bne.b   .exit
    add.w   #1,d0               ; next row
    add.w   #4,d5               ; next window row
    and.w   #$1C,d5             ; mod (8 rows * 4 bytes/row)
    dbra    d4,.loop 
.found:
    ; here d6 is is the number of rotate rights done
    ; the match position is (24 - d6) % 32
    ; or 32 - (24 - d6) = d6 + (32 - 24)
    neg.w   d6
    add.w   #56,d6
    and.w   #$1F,d6
    lea     mbits0,a1           ; get match base
    lsl.w   #2,d3               ; match offset (0,1)
    move.l  #1,d0
    lsl.l   d6,d0
    or.l    d0,(a1,d3.w)        ; set match bit
.exit:
    movem.l (sp)+,d2-d6         ; restore regs
    rts    
  
;-----match()--------------
; Match the current patterns against the buffer,
; setting mbits[0,1] appropriately.
; buffer/patterns are packed
    CNOP    0,4
match:
    lea     buf,a6              ; window base
    move.l  pat0,a4             ; pattern 0 base
    move.l  pat1,a5             ; pattern 1 base
    move.l  mask0,a2            ; mask 0 base
    move.l  mask1,a3            ; mask 1 base
    clr.l   mbits0              ; match set 0
    clr.l   mbits1              ; match set 1
    move.w  #31,d6              ; loop counter
    move.w  bpos,d5             ; window position
    move.l  (a6,d5.w),d2        ; load row
    move.b  (a2),d3             ; load mask 0 byte
    move.b  (a3),d4             ; load mask 1 byte
.loop:
    move.b  d2,d1               ; get next 8 bits
    and.b   d3,d1               ; apply mask 0
    cmp.b   (a4),d1
    bne.b   .nomatch0
    move.w  #0,d0               ; 
    move.l  a4,a0               ; pattern base
    move.l  a2,a1               ; mask base
    jsr     matchdown           ; check remainder
.nomatch0
    move.b  d2,d1               ; get next 8 bits
    and.b   d4,d1               ; apply mask 1
    cmp.b   (a5),d1             ; check
    bne.b   .nomatch1
    move.w  #1,d0
    move.l  a5,a0               ; pattern base
    move.l  a3,a1               ; mask base
    jsr     matchdown           ; check remainder
.nomatch1:
    ror.l   #1,d2               ; next position
    dbra    d6,.loop
    jsr     findmatch
    rts 

;-----findmatch()------------
; checks mbits0, mbits1 for a pattern
; match. Sets mx0,mx1 to the match index + 1 or
; 0 if no match was found.
    CNOP    0,4
findmatch:
    move.w  #15,d5              ; down counter
    move.w  #16,d6              ; up counter 
    lea     ldtrig,a6           ; trigger base
    lea     ldnote,a5           ; notes
.loop0:
    move.l  #1,d0
    lsl.l   d5,d0
    and.l   mbits0,d0
    bne     .found0
    move.l  #1,d0
    lsl.l   d6,d0
    and.l   mbits0,d0
    bne     .up0
    add.w   #1,d6
    dbra    d5,.loop0
    bra     .next
.up0:
    move.w  d6,d5
.found0:
    add.w   #1,d5
    move.w  d5,mb0
    bset    #F_MATCH,flags      ; match found
.next:
    move.w  #15,d5              ; down counter
    move.w  #16,d6              ; up counter 
.loop1:
    move.l  #1,d0
    lsl.l   d5,d0
    and.l   mbits1,d0
    bne     .found1
    move.l  #1,d0
    lsl.l   d6,d0
    and.l   mbits1,d0
    bne     .up1
    add.w   #1,d6
    dbra    d5,.loop1
    bra     .done
.up1:
    move.w  d6,d5
.found1:
    add.w   #1,d5
    move.w  d5,mb1
    bset    #F_MATCH,flags      ; match found
.done:
    rts

;-----drawpat(d0,d1,a1)------
; Render the pattern indicated by d1 at 
; to address a1 at offset d0.
; preserves d0,d1
    CNOP    0,4
drawpat:
    move.w  d0,d5
    move.w  d1,d6
    lea     (a1,d0.w),a1      ; dest pointer
    move.w  #0,d3             ; shift value
    move.w  a1,d4
    and.w   #1,d4             ; test for alignment
    cmp.w   #0,d4
    beq     .aligned
    move.w  #$8000,d3         ; align value in 12-15
.aligned:
    lea     spr0,a0           ; pattern base 
    cmp.w   #0,d1
    beq     .idx0
    lea     spr1,a0
.idx0:
    move.w  #sprwidthw,d0     ; word count
    move.w  #csize*pwidth,d1  ; height
    lsl.w   #6,d1             ; in bit pos 6
    or.w    #$0BFA,d3         ; set control bits
    waitblt
    move.l  a1,_BLTDPT        ; D address
    move.l  a1,_BLTCPT        ; C address
    move.l  a0,_BLTAPT        ; source pointer
    clr.w   _BLTAMOD          ; set A modulo
    move.w  #coff*2,_BLTDMOD  ; set D modulo
    move.w  #coff*2,_BLTCMOD  ; set C modulo
    move.w  d3,_BLTCON0       ; enable A,C,D, LF A + C (9)
    or.w    d1,d0             ; form blit size
    move.w  d0,_BLTSIZE       ; start blit
    move.w  d6,d1             ; restore regs
    move.w  d5,d0
    rts 

    CNOP    0,4
clearmem:
    waitblt
    move.l  a1,_BLTDPT
    clr.w   _BLTDMOD          ; set D modulo (0)
    move.w  #$0100,_BLTCON0   ; enable only D (clear)
    lsl.w   #6,d1             ; .. in pos 6
    or.w    d1,d0             ; form blit size
    move.w  d0,_BLTSIZE       ; start blit
    rts

;-----clearpl(a1)------------
; zero out the bit plane at a1 with height d1
    CNOP    0,4
clearpl:
    move.w  #bplwidthw,d0     ; word count
    bra     clearmem

;-----clearrow(a1)----------
; clear the pwidth*csize lines starting at
; the address in a1.
    CNOP    0,4
clearrow:
    move.w  #bplwidthw,d0     ; word count
    move.w  #csize*pwidth,d1  ; height
    bra     clearmem

;-----clearline(a1)------------
; zero out the line at a1.
    CNOP    0,4
clearline:
    move.w  #bplwidthw,d0     ; word count
    move.w  #csize,d1         ; height
    bra     clearmem
  
;-----handlekb()------------
; Process the key buffer.
    CNOP    0,4
handlekb:
    move.w  key,d6
    cmp.b   #$30,d6 
    bge.b   .row3
    cmp.b   #$20,d6
    bge.b   .row2
    cmp.b   #$10,d6
    bge.b   .row1
.row0:  
    subq.w  #1,d6
    lea     ldstate,a0
    move.w  #-1,d1              ; adjustment amount 
    move.w  #1,d0               ; test odd
    and.w   d6,d0
    beq     .even0
    neg.w   d1                  ; flip adj
.even0:
    and.w   #$6,d6              ; form param index
    move.w  LDO(a0,d6.w),d0     ; get value
    add.w   d1,d0               ; adjust
    cmp.w   #0,d0               ; clamp
    bgt     .pos0
    clr.w   d0
.pos0:
    and.w   #$3,d0
    move.w  d0,LDO(a0,d6.w)     ; new value
    bra     .done
.row1:
    lea     ldstate,a0
    bra     .adj
.row2:
    lea     ldstate+2,a0
    bra     .adj
.row3:
    and.b   #$F,d6
    cmp.b   #8,d6
    bge     .incpat
    and.w   #$03,d6
    cmp.b   #0,d6
    beq     .done
    cmp.b   #3,d6
    bgt     .done
    cmp.b   #3,d6
    bne     .setstate           ; 1,2 - set state
    IFD TEST
    bset    #G_MOD,flags2       ; 3 - modulate
    ENDC
    bra     .done 
.adj:
    move.w  #-1,d1              ; adjustment amount 
    move.w  #1,d0               ; test odd
    and.w   d6,d0
    beq     .even
    neg.w   d1                  ; flip adj
.even: 
    and.w   #$E,d6              ; form param index (>>1, <<2)
    cmp.w   #(5<<1),d6
    bge     .done
    lsl.w   #1,d6
    move.w  LDV(a0,d6.w),d0     ; get param (vol, att, dec, sus, rel)
    add.w   d1,d0               ; add adjustment
    cmp.w   #0,d0               ; clamp
    bgt     .pos
    clr.w   d0
.pos:
    and.w   #$7F,d0
    move.w  d0,LDV(a0,d6.w)     ; set new
    bra     .done
.setstate: 
    IFD TEST
    cmp.b   #1,d6
    beq.b   .reset1
.resetrand:
    bset    #G_RAND,flags2
    bra     .done
.reset1:
    bset    #G_ONE,flags2
    bra     .done
    ENDC
.incpat:
    move.w  #1,d0
    cmp.b   #9,d6
    bge     .inc
    neg.w   d0
.inc
    jsr     incpat
.done:
    rts

    CNOP    0,4
copymem:
    waitblt
    move.l  a1,_BLTDPT        ; set D pointer
    move.l  a0,_BLTAPT        ; set A pointer
    move.w  d2,_BLTDMOD       ; set D modulo 
    move.w  d3,_BLTAMOD       ; set A modulo
    move.w  #$09F0,_BLTCON0   ; enable A,D, LF A
    lsl.w   #6,d1             ; move height into position
    or.w    d1,d0             
    move.w  d0,_BLTSIZE       ; start the blit
    rts

;-----copystate()-------
; Copy the contents of the rendered state at a0
; into the display at address a1
    CNOP    0,4
copystate:
    move.w  #stwidthw,d0      ; word count
    move.w  #csize,d1         ; height
    move.w  #doff*2,d2     ; D modulo
    clr.w   d3                ; A modulo
    bra     copymem

;-----copyrow()---------
; Copies the psize-sized row at a0 into a1.
    CNOP    0,4
copyrow:
    move.w  #stwidthw,d0      ; word count
    move.w  #pwidth*csize,d1  ; height
    move.w  #doff*2,d2     ; D modulo
    move.w  d2,d3             ; A modulo
    bra     copymem

;-----wavcopy(a0,a1)--------
; copy wave data at a1 into a0.
    CNOP    0,4
wavcopy:
    waitblt
    move.l  a0,_BLTDPT        ; D address
    move.l  a1,_BLTAPT        ; C address
    clr.w   _BLTAMOD          ; set A modulo
    clr.w   _BLTDMOD          ; set D modulo
    move.w  #$09F0,_BLTCON0   ; enable A,D, LF A 
    move.w  #TABSIZEW,d0      ; word count
    or.w    #$40,d0           ; set height = 1
    move.w  d0,_BLTSIZE       ; start blit
    rts 

;-----wavint(a0,a1,a2)------
; interpolates between tables
; in a0,a1 into 8* table a2
    CNOP    0,4
wavint:
    lea     tabint,a3
    move.w  #tsize-1,d4
.interp:
    move.w  (a3)+,d0
    move.w  (a3)+,d1
    move.w  #TABSIZEB-1,d6
.tab:
    move.b  (a0)+,d2
    move.b  (a1)+,d3
    ext.w   d2
    ext.w   d3
    IFND NOINT
    lsl.w   d0,d2
    lsl.w   d1,d3
    add.w   d2,d3
    asr.w   #3,d3
    cmp.w   #-126,d3
    bgt     .hi
    move.w  #-126,d3
.hi:
    cmp.w   #127,d3 
    blt     .lo
    move.w  #127,d3
    ENDC
.lo:
    move.b  d3,(a2)+
.skip:   
    dbra    d6,.tab  
    dbra    d4,.interp
    rts
    EVEN
tabint:
    dc.w    3,0,2,1,1,2,0,3,1,2,2,1,3,0
    dc.w    3,0,2,1,1,2,0,3,1,2,2,1,3,0

;-----initwav()-------------
; initializes wav0/wav1
    CNOP    0,4
initwav:
    lea     asintab,a0
    lea     asintab,a1
    lea     wav0,a2
    jsr     wavint
    lea     sintab,a0
    lea     sqtab,a1
    lea     wav1,a2
    IFD MODONE
    lea wavm1,a2 
    ENDC
    jsr     wavint
    rts 

;-----doenv()----------------
; update all envelopes.
    CNOP    0,4
doenv:
    lea     audtab,a4
    move.l  #_AUD0LC,a3       ; audio base
    lea     ldstate,a2        ; param base
    lea     ldparms,a1        ; envelope/level  
    move.w  #3,d6             ; loop counter
.loop:
    move.w  LDE(a1),d4        ; env state
    move.w  LDL(a1),d3        ; level
    move.w  d4,d1
    cmp.w   #0,d4
    beq     .end
    cmp.w   #E_ATT,d4
    bne     .dec
    add.w   LDA(a2),d3
    cmp.w   LDV(a2),d3
    blt     .dec
    move.w  LDV(a2),d3
    move.w  #E_DEC,d1
.dec:
    cmp.w   #E_DEC,d4
    bne     .sus
    sub.w   LDD(a2),d3
    cmp.w   LDS(a2),d3
    bgt     .sus
    move.w  LDS(a2),d3
    move.w  #E_REL,d1
.sus:
    cmp.w   #E_REL,d4
    bne     .end
    sub.w   LDR(a2),d3
    cmp.w   #0,d3
    bge     .end
    clr.w   d3
    clr.w   d1
.end:
    move.w  (a4)+,d5
    move.w  d3,8(a3,d5.w)     ; set level
    move.w  d3,LDL(a1)        ; new level
    move.w  d1,LDE(a1)        ; new state
.done:
    add.l   #2,a1             ; next channel
    move.w  d6,d2
    and.w   #1,d2
    bne     .next
    add.l   #2,a2             ; next voice
.next:
    dbra    d6,.loop
    rts

;-----playlead()-------------
; trigger lead note(s).
    CNOP    0,4
playlead:
    move.l  #_AUD0LC,a6       ; audio base
    lea     ldstate,a5        ; param base
    lea     scale,a4          ; scale data
    lea     ldenv,a3          ; envelope state
    lea     scoct,a2
    lea     ldlvl,a1
    lea     audtab,a0
    move.l  #wavm0,d1
    move.w  #1,d6             ; loop counter
.loop:
    btst    #0,LDT(a5)        ; check trigger
    beq     .next             ; skip if none
    move.w  LDN(a5),d5        ; scale note
    lsl.w   #1,d5             ; to word offset
    move.w  (a4,d5.w),d4      ; period value
    move.w  LDO(a5),d2        ; get octave
    lsr.w   d2,d4             ; adjust period
    move.w  (a2,d5.w),d0      ; get wavetable
    lsl.w   #TABSIZELOG,d0    ; wavetable offset
    ext.l   d0
    add.l   d1,d0             ; form pointer
    move.w  LDC(a5),d3        ; get voice
    lsl.w   #1,d3             ; to offset
    move.w  LDI(a5),(a1,d3.w) ; set level
    move.w  #E_ATT,(a3,d3.w)  ; set env state
    move.w  (a0,d3.w),d3
    move.l  d0,(a6,d3.w)      ; set pointer
    move.w  d4,6(a6,d3.w)     ; set period
    eor.w   #1,LDC(a5)        ; toggle voice
    bclr    #0,LDT(a5)        ; clear trigger
.next:
    add.l   #2,a5             ; next channel
    add.l   #4,a3             ; ""
    add.l   #4,a1
    add.l   #4,a0
    add.l   #wavsize,d1       ; ""
    dbra    d6,.loop
    rts

;-----modlead()------------
; updates wavm0/wavm1 by pwm
modlead:
    lea     wavm0,a0            ; dest position
    lea     wav0,a1             ; source
    lea     modtab,a2           ; modulation
    lea     ldmp,a3             ; mod position
    lea     ldmr,a4             ; mod rate
    move.w  #TABSIZEW,d1
    or.w    #(4<<6),d1          ; 4 lines
    move.w  #1,d6               ; loop counter
    IFD MODONE
    clr.w d6 ; only mod first
    ENDC
.loop:
    waitblt
    move.w  #$0D30,_BLTCON0     ; set params (A,B,D), LF AB'
    clr.w   _BLTAMOD
    clr.w   _BLTDMOD
    move.w  #-TABSIZEB,_BLTBMOD
    move.l  a0,_BLTDPT          ; set dest
    move.l  a1,_BLTAPT          ; set A
    move.w  (a3),d3             ; mod position
    lea     (a2,d3.w),a5        ; B address
    move.l  a5,_BLTBPT          ; set B           
    move.w  d1,_BLTSIZE         ; start blit
    move.w  (a4)+,d4            ; mod rate
    add.w   d4,d3               ; update mod position
    and.w   #$7F,d3             ; mod table size
    move.w  d3,(a3)+
    add.l   #wavsize,a0         ; update pointers
    add.l   #wavsize,a1
    dbra    d6,.loop
    rts

;-----chroot()----------------
; update the root note to the new value in d0
; no effect if same
    CNOP    0,4
chroot:
    move.b  root,d1
    cmp.b   d0,d1
    beq     .done
    move.b  d0,root
    jsr     loadscales
.done:
    rts

    IFD TEST
;-----nextstate()----------
; Compute next cell state.
; uses a0-a2,d0-d6
    CNOP    0,4
nextstate:
    lea     state,a0          ; state address
    move.l  a0,a1
    move.w  pos,d0            ; current position 
    move.w  d0,d6
    incmod  d6,nstates
    move.w  d6,pos            ; save new position
    lsl.w   #stwidthlog,d0
    lsl.w   #stwidthlog,d6
    lea     (a0,d0.w),a0      ; current state
    btst    #G_RAND,flags2 
    beq     .norand
    bclr    #G_RAND,flags2
    jsr     randstate
    lea     newstate,a0
    bra     .noinit
.norand:
    btst    #G_ONE,flags2
    beq     .noinit
    bclr    #G_ONE,flags2
    jsr     initstate
    lea     newstate,a0
.noinit:
    move.w  rule,d3           ; rule
    lea     (a1,d6.w),a1      ; next state
    clr.l   d4                ; shift buffer
    move.b  stlast(a0),d0     ; s-1
    lsl.b   #2,d0
    or.b    d0,d4             ; add to buffer
    move.b  (a0)+,d0          ; s
    move.b  d0,d6             ; save first element in d6
    lsl.b   #1,d0
    or.b    d0,d4             ; add to buffer
    move.b  d4,d2             ; previous buffer in d2
    move.w  #ncells-1,d0      ; loop counter
.stloop:
    move.b  (a0)+,d1          ; next
    or.b    d1,d4 
    move    d3,d1             ; check rule bit
    lsr.b   d4,d1
    and.b   #1,d1
    move.b  d1,(a1)+          ; store new state
    move.b  d4,d2             ; previous buffer in d2
    lsl.b   #1,d4             ; advance bits
    and.b   #7,d4
    dbra    d0,.stloop
    or.b    d6,d4             ; last
    move    d3,d1             ; check rule bit
    lsr.b   d4,d1
    and.b   #1,d1
    move.b  d1,(a1)           ; store new state
    move.w  pos,d0
    jsr     pack
    rts

;-----pack()---------------
; pack state at d0 into packed as dword.
; uses d0-d2,d6,a6
    CNOP    0,4
pack:
    lea     state,a6          ; compute state address
    lsl.w   #stwidthlog,d0    
    move.w  #ncells-1,d6      ; loop counter
    move.l  #$80000000,d1     ; bit mask
    clr.l   d2                ; bit buffer
    clr.b   d3                ; set bit counter
.loop:
    cmp.b   #0,(a6,d0.w)      ; test byte
    beq.b   .next
    or.l    d1,d2             ; set bit
    move.b  #$FF,d3           ; set flag
.next:
    lsr.l   #1,d1             ; advance mask
    add.w   #1,d0             ; advance position
    dbra    d6,.loop
    lea     buf,a6
    move.w  bpos,d0           ; write position
    move.l  d2,(a6,d0.w)
    add.w   #4,d0             ; advance
    and.w   #$1F,d0           ; mod 4*window size
    move.w  d0,bpos
    add.b   #1,d3             ; count zeros
    add.b   d3,zeros
    cmp.b   #countz,zeros     ; test for dead state
    blt     .norand
    clr.b   zeros
    bset    #G_RAND,flags2
.norand:
    rts
    
;-----drawstate(d0)--------
; Render the cell state at position in d0
; to render buffer cbuf.
; uses a0-a1,d0-d3
    CNOP    0,4
drawstate:
    waitblt
    lea     state,a0          ; compute state addr
    lsl.w   #stwidthlog,d0
    add.l   d0,a0
    lea     stwidth+cbuf,a1   ; cell ptr
    move.w  #ncells-1,d0      ; loop counter
    move.l  #$7E000000,d1     ; bit pattern
    clr.l   d2                ; current word
.drawloop:
    cmp.b   #0,(a0)+          ; test current cell
    beq     .off 
    or.l    d1,d2             ; set bit 
.off: 
    lsr.l   #csize,d1         ; advance bit
    bne     .nxt
    move.l  #$7E000000,d1     ; reset pattern
    move.l  d2,(a1)+          ; store word
    clr.l   d2                ; clear current word
.nxt:
    dbra    d0,.drawloop
    move.w  #csize-3,d1       ; outer loop counter
.copyout:
    lea     stwidth+cbuf,a0
    move.w  #stwidthl-1,d0    ; inner loop counter
.copyloop:
    move.l  (a0)+,d2          ; copy by dwords
    move.l  d2,(a1)+
    dbra    d0,.copyloop
    dbra    d1,.copyout
    rts 
    
;-----seed()---------------
; Seed the prng
; uses d0-d2
    CNOP      0,4
seed:
    move.l    #$deadbeef,d0
    move.l    #$1234a1b2,d1
    move.w    #4,d2
.loop:
    swap      d0
    add.l     d1,d0
    add.l     d0,d1
    dbra      d2,.loop    
    movem.l   d0-d1,rng
    rts
;-----prng()--------------
; get a prn in d0
; uses d0-d2
prng:
    movem.l   rng,d0-d1
    swap      d0
    add.l     d1,d0
    add.l     d0,d1
    movem.l   d0-d1,rng
    rts
rng:
    ds.l      2 

;-----randstate()-----------
; randomize the current state
; uses a0,d0-d2
randstate:
    lea     newstate,a0
    move.w  #ncells-1,d2        ; loop counter
.randloop:
    jsr     prng
    move.b  d0,d1
    lsl.b   #3,d1
    or.b    d0,d1
    and.b   #1,d1
    move.b  d1,(a0)+
    dbra    d2,.randloop
    rts

;-----initstate()----------
; initialize the current state
; uses a0,d0
initstate:
    lea     newstate,a0
    move.l  #ncells/4-1,d0
.clearloop:
    clr.l   (a1)+
    dbra    d0,.clearloop
    move.b  #1,newstate+16
    rts
    ENDC

;------------------------------------------------------------------------------
    end
;------------------------------------------------------------------------------

