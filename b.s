    JUMPPTR init
    INCDIR  "git/"
    INCLUDE "wmacro.i"
    INCLUDE "hwdefs.i"
    INCDIR  "Include/"
    INCLUDE "exec/exec_lib.i"
    INCLUDE "exec/nodes.i"
;-----macro defs-----------
TEST        SET 1
;DEBUG       SET 1

;-----screen defs----------
width       equ 320             ; plane width
height      equ 200             ; plane height (NTSC)
size        equ width*height    ; plane size (bits)
bplwidth    equ width/8         ; width in bytes
bplsize     equ bplwidth*height ; size in bytes
bplsizel    equ bplsize/4       ; size in dwords
bplwidthw   equ bplwidth/2      ; width in words
bplwidthl   equ bplwidth/4      ; width in dwords

;-----state defs-----------
ncellslog   equ 5
ncells      equ (1<<ncellslog)  ; cell count
ncellsl     equ (ncells/4)      ; cell count (dwords)
csizelog    equ 3               ; log2(csize)
csize       equ (1<<csizelog)   ; cell size (bits)
csizeb      equ (csize/8)       ; cell size (bytes)
nstates     equ height/csize    ; number of states
stwidth     equ ncells*csizeb   ; state size in bytes
stwidthlog  equ (ncellslog+(csizelog-3))
stlast      equ stwidth-1       ; last state offset
stwidthw    equ stwidth/2       ; state size in words
stwidthl    equ stwidth/4       ; state size in dwords
stsize      equ stwidth*nstates ; total state size
stsizel     equ stsize/4        ; total state size in dwords
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
bsize       equ stwidth*csize           ; render buffer size
bsizel      equ bsize/4                 ; render buffer size in dwords
coff        equ (bplwidth-sprwidth)/2   ; modulo for patterns in bytes
coffw       equ (bplwidthw-sprwidthw)/2 ; modulo for patterns in words
celloff     equ (bplwidth-stwidth)/2    ; cell offset in bytes
celloffw    equ (bplwidthw-stwidthw)/2  ; cell offset in words

;-----flag bits------------
F_STEP      equ 0               ; step screen next vblank
F_KEY       equ 1               ; key pressed
F_DATA      equ 2               ; data on LPT
F_MATCH0    equ 3               ; match on pat0
F_MATCH1    equ 4               ; match on pat1
F_MATCH     equ 5               ; match on either
F_MOD       equ 6
F_ENV       equ 7               ; update envelopes
F_PLAY      equ 8               ; play next interval
F_ERR       equ 10              ; error exit

;-----sequencer defs-------
E_ATT       equ 0
E_DEC       equ 1
E_SUS       equ 2
E_REL       equ 3
E_MASK      equ 4
F_NOTEON    equ 7

;-----timing defs----------
; one tick = 1.396825ms (clock interval is 279.365 nanoseconds)
; .715909 Mhz NTSC; .709379 Mhz PAL
; PAL 7093,79 ~ 7094 = 10ms   | NTSC 7159,09 ~ 7159 = 10ms
; 120 bpm = 32dq/s ~ 22371 (NTSC)
; 60hz ~ 11934 (NTSC)
period      equ 14800           ; timer interrupt period
kbhs        equ 95              ; keyboard handshake duration - 02 clocks
countmod    equ 64              ; 16th notes between mode transition

;-----color defs------------
ctablog     equ   3
ctabsize    equ   (1<<ctablog)
cskip       equ   height/ctabsize

;-----entry point----------
; most of the CIA saving is trying
; to allow asmone to recover after close.
; however, this is only a convenience issue..
    SECTION amc,CODE
    CNOP    0,4
init:
    movem.l d1-d6/a0-a6,-(sp)
    move.w  _DMACONR,d1         ; save control regs
    move.w  _INTENAR,d2   
    move.w  _INTREQR,d3
    move.w  _ADKCONR,d4
    movem.l d1-d4,-(sp)
    move.l  #CIAB,a6            ; save CIA-B regs
    move.b  CIACRA(a6),d2
    move.b  CIACRB(a6),d3
    move.b  CIAICR(a6),d4
    move.b  CIATBLO(a6),d5
    move.b  CIATBHI(a6),d6
    movem.l d2-d6,-(sp)
    move.l  #CIAA,a6            ; save CIA-A regs
    move.b  CIACRA(a6),d1
    move.b  CIAICR(a6),d2
    move.b  CIATBLO(a6),d3
    move.b  CIATBHI(a6),d4
    movem.l d1-d4,-(sp)
    move.l  4.w,a6              ; get execbase
    clr.l   d0                  ; start lib calls
    move.l  #gfxname,a1     
    jsr     -552(a6)            ; openlibrary()
    move.l  d0,gfxbase          ; save result = gfxbase
    move.l  d0,a6
    move.l  34(a6),d1           ; save viewport
    move.l  38(a6),d2           ; save copper ptr
    movem.l d1-d2,-(sp)
    IFND DEBUG
    move.l  #0,a1               ; graceful exit prep
    jsr     -222(a6)            ; LoadView
    jsr     -270(a6)            ; WaitTOF (x2)
    jsr     -270(a6)      
    jsr     -456(a6)            ; OwnBlitter
    jsr     -228(a6)            ; WaitBlit - yes, _after_ own
    move.l  4.w,a6              ; execbase
    jsr     -132(a6)            ; Forbid MT
    ENDC
    
;-----init playfield-------
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

;-----init bitplanes-------
    IFND DEBUG
    lea     bgpl,a0             ; bitplane address
    move.l  #bplsizel*2-1,d0    ; loop counter
.initbpl:
    clr.l   (a0)+
    dbra    d0,.initbpl
    ENDC
    move.l  #0,bplpos

;-----init buffers----------
    IFND DEBUG
    lea     spr0,a0             ; state buffer addr
    move.l  #sprsizel*2-1,d0    ; loop counter
.initspr:
    clr.l   (a0)+ 
    dbra    d0,.initspr
    lea     buf,a0
    move.w  #hsize-1,d6
.buflp:
    move.b  #$80,(a0)+ 
    dbra    d6,.buflp
    ENDC
    IFD TEST
    lea     state,a0            ; cell state address
    move.l  #stsizel-1,d0       ; loop counter
.initstate:
    clr.l   (a0)+
    dbra    d0,.initstate
    lea     state,a0
    move.b  #1,16(a0)
    ENDC
    clr.w   d0
    jsr     setpat

;-----init wavetables------
    jsr     initwav
    move.l  #_AUD0LC,a6         ; audio base
    move.l  #wav0,d6
    move.l  d6,0(a6)            ; set first channels
    move.w  #TABSIZE,4(a6)
    clr.w   8(a6)
    add.l   #AUDOFFSET,a6
    move.l  d6,0(a6)
    move.w  #TABSIZE,4(a6)
    clr.w   8(a6)
    move.l  #wav1,d6          
    add.l   #AUDOFFSET,a6       ; set second channels
    move.l  d6,0(a6)
    move.w  #TABSIZE,4(a6)
    clr.w   8(a6)
    add.l   #AUDOFFSET,a6
    move.l  d6,0(a6)
    move.w  #TABSIZE,4(a6)
    clr.w   8(a6)

;-----init rng-------------
    jsr     seed

;-----setup copper list----
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
    IFND DEBUG
    move.l  #copstart,_COP1LCH 
    ENDC

;-----install ints---------
    move.l  $68.w,d0            ; save lvl2 handler
    move.l  d0,savelvl2
    move.l  $6C.w,d0            ; save lvl3 handler
    move.l  d0,savelvl3
    move.l  $78.w,d0            ; save lvl6 handler
    move.l  d0,savelvl6

;-----system setup---------
    IFND DEBUG
    waitr   a1,d0,d1,d2
    move.w  #$7fff,_INTENA      ; disable all bits in INTENA
    move.w  #$6028,_INTREQ      ; clear pending lvl2/3/6 
    move.w  #$6028,_INTREQ      ; ... twice
    move.l  #CIAA,a5            ; CIA-A base
    move.l  #CIAB,a6            ; CIA-B base
    move.b  #$7F,CIAICR(a5)     ; clear CIA-A interrupts
    move.b  #$7F,CIAICR(a6)     ; clear CIA-B interrupts
    and.b   #$18,CIACRA(a5)     ; CIA-A TA: one-shot, KB input mode
    and.b   #$C0,CIACRA(a6)     ; CIA-B TB: continuous, pulse, PB6OFF
    move.b  #(period&$FF),CIATBLO(a6) ; set CIA-B timer B period 
    move.b  #(period>>8),CIATBHI(a6)  ; ..for timer interrupt
    move.b  #(kbhs&$FF),CIATBLO(a5)   ; set CIA-A timer B period
    move.b  #(kbhs>>8),CIATBHI(a5)    ; .. for kb handshake
    move.l  #keyint,$68.w       ; install lvl2 handler (cia-a)
    move.l  #vblankint,$6C.w    ; install lvl3 handler
    move.l  #timerint,$78.w     ; install lvl6 handler (cia-b)
    move.b  #$88,CIAICR(a5)     ; enable CIA-A FLG/SP interrupt (keyboard) (was 9 for FLG)
    move.b  #$82,CIAICR(a6)     ; enable CIA-B TB interrupt
    move.w  #$E028,_INTENA      ; enable lvl2/3/6
    waitr   a1,d0,d1,d2
    bset.b  #0,CIACRB(a6)       ; start CIA-B TB
    move.w  _COPJMP1,d0         ; start copper
    move.w  #$8000,_ADKCON      ; clear mod bits
    move.w  #$7FFF,_DMACON      
    move.w  #DMAF_ALLA,_DMACON  ; start DMA
    ENDC

;-----frame loop start-------
.mainloop:
;   btst    #F_PLAY,flags
;   beq     .notrig
;   bclr    #F_PLAY,flags
;   jsr     playlead
.notrig:
    btst    #F_KEY,flags
    beq     .nokey
    bclr    #F_KEY,flags
    jsr     handlekb
.nokey:
    btst    #F_MOD,flags
    beq     .nomod
    bclr    #F_MOD,flags
;   jsr     modulate
.nomod
    btst    #F_DATA,flags
    beq     .nodata
    bclr    #F_DATA,flags
    jsr     match
.nodata:
.endmain:
    btst    #6,$bfe001
    bne     .mainloop
;-----frame loop end---------

;-----exit code------------
.exit:
    IFND DEBUG
    move.w  #$7FFF,_INTENA      ; turn off interrupts
    move.l  #CIAA,a5
    move.l  #CIAB,a6
    bclr.b  #0,CIACRB(a6)       ; stop timer
    move.b  #$7F,CIAICR(a6)     ; clear CIA-B interrupts
    move.b  #$7F,CIAICR(a5)     ; clear CIA-A interrupts
    ENDIF
    movem.l (sp)+,d1-d2         ; pop saved copper,view
    movem.l (sp)+,d3-d6         ; pop CIA-A regs
    IFND DEBUG
    or.b    #$80,d3             ; write bit
    move.b  d3,CIACRA(a5)
    or.b    #$80,d4
    move.b  d4,CIAICR(a5)
    move.b  d5,CIATBLO(a5)
    move.b  d6,CIATBHI(a5)
    ENDC
    movem.l (sp)+,d5-d6         ; pop CIA-B timer regs
    IFND DEBUG
    move.b  d5,CIATBLO(a6)
    move.b  d6,CIATBHI(a6)
    ENDC
    movem.l (sp)+,d3-d5         ; pop CIA-B control regs
    IFND DEBUG
    or.b    #$80,d3             ; write bit
    move.b  d3,CIACRA(a6)
    or.b    #$80,d4 
    move.b  d4,CIACRB(a6)
    or.b    #$80,d5
    move.b  d5,CIAICR(a6)
    ENDC
    movem.l (sp)+,d3-d6         ; pop saved system control regs
    IFND DEBUG
    or.w    #$8000,d3           ; write bit
    move.w  #$7FFF,_DMACON  
    move.w  d3,_DMACON
    or.w    #$8000,d4
    move.w  #$7FFF,_INTENA      ; disable ints before resotre
    move.l  savelvl2,d0         ; restore lvl2 handler
    move.l  d0,$68.w
    move.l  savelvl3,d0         ; restore lvl3 handler
    move.l  d0,$6C.w
    move.l  savelvl6,d0         ; restore lvl6 handler
    move.l  d0,$78.w
    move.w  d4,_INTENA          ; restore interrupts
    move.w  #$7FFF,_INTREQ      ; clear pending
    move.w  #$7FFF,_INTREQ
    or.w    #$8000,d5
    move.w  d5,_INTREQ          ; restore reqs
    or.w    #$8000,d6
    move.w  #$7FFF,_ADKCON
    move.w  d6,_ADKCON
    move.l  d2,_COP1LCH         ; restore copper
    move.l  gfxbase,a6          ; get gfxbase
    move.l  d1,a1               ; saved view
    jsr     -222(a6)            ; LoadView
    jsr     -270(a6)            ; WaitTOF (x2)
    jsr     -228(a6)            ; WaitBlit
    jsr     -462(a6)            ; Disown
    ENDC
    move.l  4.w,a6              ; get execbase
    move.l  gfxbase,a1          ; gfx ptr
    jsr     -414(a6)            ; closelibrary
    IFND DEBUG
    jsr     -132(a6)            ; permit MT
    ENDC
.return:
.xx:
    movem.l (sp)+,d1-d6/a0-a6
    move.w  mx0,d0
    move.l  #state,d1
    move.w  bpos,d2
    move.w  pos,d3
    rts

;------interrupts----------
keyint:
    movem.l d6/a0-a2,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #3,d0               ; PORTS handler
    beq     .exit
    move.l  #CIAA,a0            ; CIA-A base
    btst    #3,CIAICR(a0)       ; test SP bit (???)
    beq     .exit
    IFND TEST
    lea     buf,a2
    move.w  bpos,d6
    move.l  #CIAB,a1            ; CIAB base
    move.b  CIAPRB(a0),d0       ; load parallel data
    move.b  d0,(a2,d6.w)        ; store state
    move.w  #$8010,CIAICR(a0)   ; set FLAG bit (handshake)
    add.w   #1,d6               ; increment position
    and.w   #$1F,d6             ; mod 4*window size
    and.w   #$3,d6              ; test for full line
    cmp.b   #0,d6
    bne.b   .notline
    bset    #F_DATA,flags       ; set data bit
.notline:
    move.w  d6,bpos             ; update position
    ENDC
    IFD TEST
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
.exit:
    move.w  #$4008,_INTREQ
    move.w  #$4008,_INTREQ
    movem.l (sp)+,d6/a0-a2
    rte

vblankint:
    movem.l d1-d6/a0-a3,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #5,d0               ; VBLANK handler
    beq     .exit
    btst    #F_STEP,flags
    beq     .nostep
    bclr    #F_STEP,flags
    move.w  coprpos,d5          ; get copper offset
    addmod  d5,width,bplsize    ; update start
    move.w  d5,coprpos
    lea     bgpl,a0
    lea     (a0,d5.w),a1        ; copper start
    move.l  a1,d6
    move.w  d6,copptrl          ; update copper pointers
    swap    d6
    move.w  d6,copptrh
    lea     bgpl,a0             ; screen base for copy
    move.w  bplpos,d4           ; offset for copy
;   cmp.l   #0,d4               ; clear on reset
;   bne.b   .noclearlo
;   lea     bgpl,a1
;   jsr     clearpl
.noclearlo:
    move.w  d4,d5
    add.w   #celloff,d5
    lea     (a0,d5.w),a2        ; copy address
    IFD TEST
    lea     cbuf,a0             ; source address
    move.l  a2,a1               ; copy address
    jsr     copystate           ; copy state
    ENDC
    lea     bgplhi,a0           ; screen base for render
    addmod  d4,width,bplsize    ; increment
    move.w  d4,bplpos
;   cmp.l   #0,d4               ; clear on reset
;   bne.b   .noclearhi
;   lea     bgplhi,a1
;   jsr     clearpl
.noclearhi:
    move.w  d4,d5 
    add.w   #celloff,d5
    lea     (a0,d5.w),a3        ; render address
    IFD TEST
    move.w  drawpos,d0          ; state position
    jsr     drawstate           ; draw state
    move.l  a3,a1               ; render address
    lea     cbuf,a0             ; source address
    jsr     copystate
    ENDC
    lea     fgpl0,a1            ; get fg pointer
    jsr     clearrow            ; clear fg row
.nostep:
    btst    #F_MATCH,flags
    beq     .nomatch1
    bclr    #F_MATCH,flags
    lea     fgpl0,a1            ; get fg pointer
    add.l   #celloff,a1
    btst    #F_MATCH0,flags     ; test for match on 0
    beq     .nomatch0
    move.w  mx0,d0              ; load match index
    move.w  #0,d1               ; select pattern 0
    jsr     drawpat             ; draw pattern 0 (fg)
;   move.l  a2,a1
;   jsr     drawpat             ; draw pattern 0 (copy)
;   move.l  a3,a1
;   jsr     drawpat             ; draw pattern 0 (bg)
.nomatch0:
    btst    #F_MATCH1,flags     ; test for match on 1
    beq     .nomatch1
    move.w  mx1,d0              ; load match index
    move.w  #1,d1               ; select pattern 1
    jsr     drawpat             ; draw pattern 1 (fg)
;   move.l  a2,a1
;   jsr     drawpat             ; draw pattern 1 (copy)
;   move.l  a3,a1 
;   jsr     drawpat             ; draw pattern 1 (bg)
.nomatch1: 
.exit:
    move.w  #$4020,_INTREQ      ; clear INTREQ
    move.w  #$4020,_INTREQ      ; ... twice
    movem.l (sp)+,d1-d6/a0-a3
    rte

timerint:
    move.l  a0,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #13,d0              ; PORTS handler
    beq     .exit
    move.l  #CIAB,a0            ; CIA-B base
    btst    #1,CIAICR(a0)
    beq     .exit
    bset    #F_ENV,flags        ; request env update
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
    bne.b   .exit
    bset    #F_STEP,flags
    IFD TEST
    move.w  pos,drawpos         ; set draw position
    jsr     nextstate
    ENDC
.exit:
    move.w  #$6000,_INTREQ      ; clear INTREQ
    move.w  #$6000,_INTREQ      ; ... twice
    move.l  (sp)+,a0
    rte

;-----tables---------------
    INCDIR  "git/"
    INCLUDE "tablead.i"
    INCLUDE "scales.i"
    INCLUDE "pattern.i"

;------saves/system--------
    SECTION amd,DATA
    CNOP    0,4
flags:
    dc.w    0                   ; state flags
key:
    dc.w    0                   ; last keypress
bpos:
    dc.w    0                   ; buffer position
pos:
    dc.w    0
savelvl2:
    dc.l    0                   ; saved lvl2 handler
savelvl3:
    dc.l    0                   ; saved lvl3 handler
savelvl6:
    dc.l    0                   ; saved lvl6 handler
gfxbase:
    dc.l    0
gfxname:
    dc.b    "graphics.library",0
  
;-----locals---------------
    SECTION amd,DATA
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
    SECTION amdc,DATA_C
    CNOP    0,4
wav0:
    ds.w    TABSIZE
wav1:
    ds.w    TABSIZE

;-----cell buffers---------
    SECTION amdc,DATA_C
    CNOP    0,4
buf:
    ds.l    hsizel              ; state buffer 
    CNOP    0,4
spr0:
    ds.l    sprsizel            ; display pattern 0
spr1:
    ds.l    sprsizel            ; display pattern 1

    SECTION amd,DATA
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
    dc.w    0
mx1:
    dc.w    0
dbg:
    dc.l    0
dbg2:
    dc.l    0
dbgm:
    dc.w    0
dbgb:
    dc.w    0
dbgp:
    dc.w    0
dbgf:
    dc.l    0,0,0,0,0,0,0,0
ptmp:
    dc.b    0

;-----cell state-----------
    IFD TEST
    SECTION amd,DATA
    CNOP    0,4
rule:
    dc.w    0
    CNOP    0,4
state:
    ds.b    stsize
    ENDC 

;-----leads data-----------
    SECTION amd,DATA
    CNOP    0,4
scale:
    ds.b    sclen*2           ; scale lists
    CNOP    0,4
ldstate:
ldnote:
    ds.b    2                 ; current notes
ldvoice:
    ds.b    2                 ; current voice
ldtrig:
    ds.b    2                 ; triggers
ldoct:
    ds.b    2                 ; octaves
ldvol:
    ds.b    2                 ; max volumes
ldatt:
    ds.b    2                 ; attack rates
lddec:
    ds.b    2                 ; decay rates
ldsus:
    ds.b    2                 ; sustain level
ldrel:
    ds.b    2                 ; release times
ldmod:
    ds.b    2                 ; mod position
ldparms:
ldenv:
    ds.b    2                 ; envelope states (voice 0)
    ds.b    2                 ; envelope states (voice 1)
ldlvl:
    ds.b    2                 ; current levels (voice 0)
    ds.b    2                 ; current levels (voice 1)
ldsize      equ  (*-ldstate)

;-----ldstate addressing---
LDN         equ   (ldnote-ldstate)
LDC         equ   (ldvoice-ldstate)
LDT         equ   (ldtrig-ldstate)
LDO         equ   (ldoct-ldstate)
LDV         equ   (ldvol-ldstate)
LDA         equ   (ldatt-ldstate)
LDD         equ   (lddec-ldstate)
LDS         equ   (ldsus-ldstate)
LDR         equ   (ldrel-ldstate)
LDM         equ   (ldmod-ldstate)
LDE         equ   (ldenv-ldparms)
LDL         equ   (ldlvl-ldparms)

;-----copper lists---------
    SECTION amdc,DATA_C
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
    SECTION ambss,BSS_C
    CNOP    0,4
bgpl:
    ds.b    bplsize-width*pwidth
bgplhi0:
    ds.b    width*pwidth
bgplhi:
    ds.b    bplsize
    CNOP    0,4
fgpl:
    ds.b    bplsize-width*(pwidth-2)
fgpl0:
    ds.b    width*(pwidth+2)
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
ctabfg:
    dc.w    $0FFF
    dc.w    $0CCC
    dc.w    $0AAA
    dc.w    $0777
    dc.w    $0333
    dc.w    $0111
    dc.w    $0000
    dc.w    $0000
cposfg:
    dc.w    0

;-----functions------------
    SECTION amc,CODE
   
;-----loadpat(d1)-------
; load patterns at index d1 into buffers spr0/1
; and set pointers.
    CNOP    0,4
loadpat:
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
    move.b  d4,ptmp             ; stash 
    clr.w   d5                  ; line counter
    move.w  #pwidth-1,d5        ; loop counter/bit
.expa:
    clr.b   d4
    btst    d5,ptmp             ; test pattern bit
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
    move.w  (a4,d2.w),d3        ; load map offset for first pattern
    lea     (a6,d1.w),a1        ; pattern 0 address
    lea     (a5,d3.w),a2        ; mask 0 address
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
    move.b  d4,ptmp             ; stash 
    clr.w   d5                  ; line counter
    move.w  #pwidth-1,d5        ; loop counter/bit
.expb:
    clr.b   d4
    btst    d5,ptmp             ; test pattern bit
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

;-----loadscales()---------
; update the scales/leads for the current mode.
    CNOP    0,4
loadscales:
    lea     scales,a6         ; scale base
    lea     scale,a5          ; scale data
    lea     ldstate,a4        ; param base
    clr.l   d5
    clr.w   d4
    clr.w   d3
    move.b  mode,d5           ; get mode
    lsl.w   #seqlenlog,d5     ; get scale index
    add.l   d5,a6             ; scale base    
    move.w  #1,d6             ; loop counter
.loop:
    move.l  a6,a3             ; copy
    move.b  (a3)+,d3          ; get scale length
    move.w  #8,d4
    sub.w   d3,d4             ; get offset to centre
    move.w  #sclen-1,d2       ; loop counter
.copy
    move.b  (a3,d4),(a5)+     ; copy scale note
    add.w   #1,d4             ; increment mod length
    cmp.w   d3,d4
    blt     .nowrap
    clr.w   d4
.nowrap:
    dbra    d2,.copy
    dbra    d6,.loop
    rts

;-----modulate()---------
; modulate current key
; TODO: rewrite to take mode index from PPT
    CNOP    0,4
modulate:
    move.b  mode,d6           ; current mode
    add.b   #1,d6
    cmp.b   #seqcnt,d6
    blt     .nowrap
    clr.b   d6
.nowrap
    move.b  d6,mode
    jsr     loadscales
    rts
    
;-----setpat(d0)-----------
; adjust the current pattern
; by the amount in d0. write the pattern
; data to the sprite areas.
    CNOP    0,4
setpat:
    move.w  pattern,d1
    add.b   d0,d1 
    cmp.w   #0,d1
    bge     .pos
    add.w   #numpat,d1
.pos: 
    cmp.w   #numpat,d1
    blt     .inrange
    sub.w   #numpat,d1
.inrange:
    IFD TEST
    move.w  d1,d2
    lsl.w   #rulesl,d2
    lea     rules,a1
    clr.w   d3
    move.b  (a1,d2.w),d3
    move.w  d3,rule
    ENDC
    move.w  d1,pattern
    jsr     loadpat
    rts 

;-----matchdown()-------------
; match helper. check later rows for match and 
; set corresponding bit of mbits(0,1).
; d0 = pattern (0,1)
; (a6,d5) = history row (preserve)
; a4, a5 = patterns (preserve)
; d6 = index + 7 (preserve)
; d2 = history data (preserve)
; saves d2-d6,a4-a6, kills d0-d1,a2-a3
    CNOP    0,4
matchdown:
    movem.l d3-d6,-(sp)         ; save regs
    move.w  d0,d3               ; save pattern index   
    move.l  mask0,a3            ; mask base
    move.l  pat0,a2             ; pattern base
    lsl.w   #psizelog,d0        ; pattern/mask offset (0,1)
    add.w   #1,d0               ; next row
    add.w   #4,d5               ; next window row
    and.w   #$1C,d5             ; mod (8 rows * 4 bytes/row)
    neg.w   d6                  ; counter in [-31,0]
    add.w   #31,d6              ; counter in [0,31]
    moveq   #pwidth-2,d4        ; loop counter
.loop:
    move.l  (a6,d5.w),d1        ; get row
    ror.l   d6,d1               ; rotate into position
    and.b   (a3,d0.w),d1        ; apply mask
    cmp.b   (a2,d0.w),d1        ; compare
    bne.b   .exit
    add.w   #1,d0               ; next row
    add.w   #4,d5               ; next window row
    and.w   #$1C,d5             ; mod (8 rows * 4 bytes/row)
    dbra    d4,.loop 
.found:
    ; here d6 is is the number of rotate rights done
    ; the match position is (24 - d6) % 32
    neg.w   d6
    add.w   #24,d6
    and.w   #$1F,d6
    lea     mbits0,a2           ; get match base
    lsl.w   #2,d3               ; match offset (0,1)
    move.l  #1,d0
;   move.l  #$80000000,d0
;   lsr.l   d6,d0
    move.l  #1,d0
    lsl.l   d6,d0
    or.l    d0,(a2,d3.w)        ; set match bit
.exit:
    movem.l (sp)+,d3-d6         ; restore regs
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
    cmp.b   (a4),d1             ; check
    bne.b   .nomatch0
    moveq   #0,d0
    jsr     matchdown           ; check remainder
.nomatch0
    move.b  d2,d1               ; get next 8 bits
    and.b   d4,d1               ; apply mask 1
    cmp.b   (a5),d1             ; check
    bne.b   .nomatch1           
    moveq   #1,d0
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
    bclr    #F_MATCH0,flags     ; clear bits
    bclr    #F_MATCH1,flags
.loop0:
    moveq   #1,d0
    lsl.l   d5,d0
    and.l   mbits0,d0
    cmp.l   #0,d0
    bne     .down0
    moveq   #1,d0
    lsl.l   d6,d0
    and.l   mbits0,d0
    cmp.l   #0,d0
    bne     .up0
    add.w   #1,d6
    dbra    d5,.loop0
    bra     .next
.down0:
    move.w  d5,mx0
    bset    #F_MATCH0,flags
    bset    #F_MATCH,flags
    bset    #F_PLAY,flags
    move.b  #1,0(a6)
    bra     .next
.up0:
    move.w  d6,mx0
    bset    #F_MATCH0,flags
    bset    #F_MATCH,flags
    bset    #F_PLAY,flags
    move.b  #1,0(a6)
.next:
    move.w  #15,d5              ; down counter
    move.w  #16,d6              ; up counter 
.loop1:
    moveq   #1,d0
    lsl.l   d5,d0
    and.l   mbits1,d0
    cmp.l   #0,d0
    bne     .down1
    moveq   #1,d0
    lsl.l   d5,d0
    and.l   mbits1,d0
    cmp.l   #0,d0
    bne     .up1
    add.w   #1,d6
    dbra    d5,.loop1
    bra     .done
.down1:
    move.w  d5,mx1
    bset    #F_MATCH1,flags
    bset    #F_MATCH,flags
    bset    #F_PLAY,flags
    move.b  #1,1(a6)
    bra     .done
.up1:
    move.w  d6,mx1
    bset    #F_MATCH1,flags
    bset    #F_MATCH,flags
    bset    #F_PLAY,flags
    move.b  #1,1(a6)
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
    lea     (a1,d0.w),a2      ; dest pointer
    move.w  #0,d3             ; shift value
    and.w   #1,d0             ; test for alignment
    cmp.w   #0,d0
    beq     .aligned
    move.w  #$8000,d3         ; align value in 12-15
.aligned:
    lea     spr0,a0           ; pattern base 
    cmp.w   #0,d1
    beq     .idx0
    lea     spr1,a0
.idx0:
    waitblt
    move.l  a2,_BLTDPT        ; D address
    move.l  a2,_BLTCPT        ; C address
    move.l  a0,_BLTAPT        ; source pointer
    clr.w   _BLTAMOD          ; set A modulo
    move.w  #coff*2,_BLTDMOD  ; set D modulo
    move.w  #coff*2,_BLTCMOD  ; set C modulo
    or.w    #$0BFA,d3         ; set control bits
    move.w  d3,_BLTCON0       ; enable A,C,D, LF A + C (9)
    move.w  #sprwidthw,d0     ; word count
    move.w  #csize*pwidth,d1  ; height
    lsl.w   #6,d1             ; in bit pos 6
    or.w    d1,d0             ; form blit size
    move.w  d0,_BLTSIZE       ; start blit
    move.w  d6,d1             ; restore regs
    move.w  d5,d0
    rts 

;-----clearrow(a1)----------
; clear the pwidth*csize lines starting at
; the address in a1.
    CNOP    0,4
clearrow:
    waitblt
    move.l  a1,_BLTDPT        ; dest ptr
    clr.w   _BLTDMOD          ; set D modulo (0)
    move.w  #$0100,_BLTCON0   ; enable only D (clear)
    move.w  #bplwidthw,d0     ; word count
    move.w  #csize*pwidth,d1  ; height
    lsl.w   #6,d1             ; .. in pos 6
    or.w    d1,d0             ; form blit size
    move.w  d0,_BLTSIZE       ; start blit
    rts

;-----clearpl(a1)------------
; zero out the bit plane at a1.
    CNOP    0,4
clearpl:
    waitblt
    move.l  a1,_BLTDPT
    clr.w   _BLTDMOD          ; set D modulo (0)
    move.w  #$0100,_BLTCON0   ; enable only D (clear)
    move.w  #bplwidthw,d0     ; word count
    move.w  #height,d1        ; height
    lsl.w   #6,d1             ; .. in pos 6
    or.w    d1,d0             ; form blit size
    move.w  d0,_BLTSIZE       ; start blit
    rts
  
;-----handlekb()------------
; Process the key buffer.
    CNOP    0,4
handlekb:
    move.w  key,d6
    cmp.b   #$30,d6 
    bge.b   .row3
    bra     .done
.row3:
    and.b   #$0F,d6
    cmp.b   #8,d6
    bge     .setpat
    and.w   #$03,d6
    cmp.b   #0,d6
    beq     .done
    cmp.b   #3,d6
    bgt     .done
    cmp.b   #3,d6
    bne     .setstate           ; 1,2 - set state
    bset    #F_MOD,flags        ; 3 - modulate
    bra     .done 
.setstate: 
    IFD TEST
    lea     state,a1
    move.w  pos,d4              ; get current position
    lsl.w   #stwidthlog,d4      ; ..
    move.w  #(ncells/4)-1,d5    ; loop counter
.clear:
    clr.l   (a1,d4.w)
    addq    #4,d4
    dbra    d5,.clear
    cmp.b   #1,d6
    beq.b   .reset1
.resetrand:
    move.w  pos,d4              ; get current position
    lsl.w   #stwidthlog,d4      ; ..
    move.w  #ncells-1,d5        ; loop counter
.randloop:
    jsr     prng
    move.b  d0,d6
    lsl.b   #3,d6
    or.b    d0,d6
    and.b   #1,d6
    move.b  d6,(a1,d4.w)
    addq    #1,d4
    dbra    d5,.randloop
    bra     .done
.reset1:
    move.w  pos,d4              ; get current position
    lsl.w   #stwidthlog,d4      ; ..
    add.w   #(ncells/2),d4
    move.b  #1,(a1,d4.w)
    bra     .done
    ENDC
.setpat:
    move.w  #1,d0
    cmp.b   #9,d6
    bge     .inc
    neg.w   d0
.inc
    jsr     setpat
    bra     .done
.done:
    bclr    #F_KEY,flags
    rts

    IFD TEST
;-----nextstate()----------
; Compute next cell state.
; uses a0-a2,d0-d6
    CNOP    0,4
nextstate:
    lea     state,a0          ; state address
    move.l  a0,a1
    move.w  rule,d3           ; rule
    clr.l   d0
    move.w  pos,d0            ; current position 
    move.l  d0,d1
    incmod  d1,nstates
    move.w  d1,pos            ; save new position
    lsl.w   #stwidthlog,d0
    lsl.w   #stwidthlog,d1
    add.l   d0,a0             ; current state
    add.l   d1,a1             ; next state
    clr     d4                ; shift buffer
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
    move.w  #0,d2             ; bit buffer
.loop:
    cmp.b   #0,(a6,d0.w)      ; test byte
    beq.b   .next
    or.l    d1,d2             ; set bit
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
    bset    #F_DATA,flags     ; set data flag
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

;-----copystate()-------
; Copy the contents of the rendered state at a0
; into the display at address a1
    CNOP    0,4
copystate:
    waitblt
    move.l  a1,_BLTDPT        ; set D pointer
    move.l  a0,_BLTAPT        ; set A pointer
    clr.w   _BLTAMOD          ; set A modulo
    move.w  #celloff*2,_BLTDMOD  ; set D modulo 
    move.w  #$09F0,_BLTCON0   ; enable A,D, LF A
    move.l  #stwidthw,d0      ; word count
    move.w  #csize,d1         ; height
    lsl.w   #6,d1             ; move height into position
    or.w    d1,d0             
    move.w  d0,_BLTSIZE       ; start the blit
    rts
    ENDC

;-----wavcopy(a0,a1)--------
; copy wave data at a1 into a0.
    CNOP    0,4
wavcopy:
    waitblt
    move.l  a0,_BLTDPT        ; D address
    move.l  a1,_BLTAPT        ; C address
    clr.w   _BLTAMOD          ; set A modulo
    clr.w   _BLTDMOD
    move.w  #$09F0,_BLTCON0   ; enable A,D, LF A 
    move.w  #TABSIZE,d0       ; word count
    or.w    #$40,d0           ; set height = 1
    move.w  d0,_BLTSIZE       ; start blit
    rts 
    CNOP    0,4
initwav:
    lea     saw128,a1
    lea     wav0,a0
    jsr     wavcopy
    lea     sin128,a1
    lea     wav1,a0
    jsr     wavcopy
    rts 

;-----playlead()-------------
; trigger lead note(s).
    CNOP    0,4
playlead:
    move.l  #_AUD0LC,a6       ; audio base
    lea     ldstate,a5        ; param base
    lea     scale,a4          ; scale data
    lea     ldenv,a3
    lea     ldlvl,a2
    clr.w   d5                ; clear word regs
    clr.w   d3
    move.w  #1,d6             ; loop counter
.loop:
    cmp.b   #0,LDT(a5)        ; check trigger
    beq     .next             ; skip if none
    move.b  LDN(a5),d5        ; scale note
    lsl.w   #1,d5             ; to word offset
    move.w  (a4,d5),d4        ; period value
    move.b  LDC(a5),d3        ; next voice
    bset    #E_DEC,(a3,d3)    ; set env state
    move.b  LDV(a5),(a2,d3)   ; set volume
    move.b  LDV(a5),d3       
    move.w  d3,8(a4)          ; level
    move.w  d4,6(a4)          ; period
    bchg    #0,LDV(a5)        ; toggle voice
    clr.b   LDT(a5)           ; clear trigger
.next:
    add.l   #AUDOFFSET*2,a6   ; next channel set
    add.l   #1,a5             ; next voice
    add.l   #2,a3             ; ""
    add.l   #2,a2             ; ""
    add.l   #sclen,a4         ; next scale
    dbra    d6,.loop
    rts

    IFD TEST
;-----seed()---------------
; Seed the prng
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
prng:
    movem.l   rng,d0-d1
    swap      d0
    add.l     d1,d0
    add.l     d0,d1
    movem.l   d0-d1,rng
    rts
rng:
    ds.l      2 
    ENDC

;------------------------------------------------------------------------------
    end
;------------------------------------------------------------------------------

