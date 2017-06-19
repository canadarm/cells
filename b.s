    JUMPPTR init
    INCDIR  "git/"
    INCLUDE "wmacro.i"
    INCLUDE "hwdefs.i"
    INCDIR  "Include/"
    INCLUDE "exec/exec_lib.i"
    INCLUDE "exec/nodes.i"
;-----macro defs-----------
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
F_DRAW      equ 0               ; render next vblank
F_KEY       equ 1               ; key pressed
F_DATA      equ 2               ; data on LPT
F_MATCH     equ 3               ; match hit
F_ERR       equ 15              ; error exit

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
ctabsize    equ   8
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
    move.w  #$0913,_COLOR03     ; fg color (3)

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
    ENDC
    clr.w   d0
    jsr     setpat
    lea     buf,a0
    move.w  #hsize-1,d6
.buflp:
    move.b  #$80,(a0)+ 
    dbra    d6,.buflp

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

;-----test-------------------
;   jsr     match
;   jsr     findmatch
;   move.w  d0,mx0
;   move.w  d1,mx1

;-----frame loop start-------
.mainloop:
    btst    #F_DATA,flags
    beq     .nodata
;   jsr     match
;   jsr     findmatch
.nodata:
.endmain:
    btst    #6,$bfe001
    bne     .mainloop
;-----frame loop end---------

;-----exit code------------
.exit:
    move.w  #$7FFF,_INTENA      ; turn off interrupts
    move.l  #CIAA,a5
    move.l  #CIAB,a6
    bclr.b  #0,CIACRB(a6)       ; stop timer
    move.b  #$7F,CIAICR(a6)     ; clear CIA-B interrupts
    move.b  #$7F,CIAICR(a5)     ; clear CIA-A interrupts
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
    move.l  dbg,d0
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
    lea     buf,a2
    move.w  bpos,d6
    move.l  #CIAB,a1            ; CIAB base
    move.b  CIAPRB(a0),d0       ; load parallel data
    move.b  d0,(a2,d6.w)        ; store state
    move.w  #$8010,CIAICR(a0)   ; set FLAG bit (handshake)
    addq    #1,d6               ; increment position
    and.w   #$1F,d6             ; mod 4*window size
    move.w  d6,bpos             ; update position
    and.w   #$3,d6              ; test for full line
    cmp.b   #0,d6
    bne.b   .exit
    bset    #F_DATA,flags       ; set data bit
.exit:
    move.w  #$4008,_INTREQ
    move.w  #$4008,_INTREQ
    movem.l (sp)+,d6/a0-a2
    rte

vblankint:
    movem.l d1-d6/a0-a1,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #5,d0               ; VBLANK handler
    beq     .exit
    btst    #F_DRAW,flags
    beq     .nodraw
    bclr    #F_DRAW,flags
    move.w  coprpos,d5          ; get copper offset
    addmod  d5,width,bplsize    ; update start
    move.w  d5,coprpos
    lea     bgpl,a0
    lea     (a0,d5.w),a1        ; copper start
    move.l  a1,d6
    move.w  d6,copptrl          ; update copper
    swap    d6
    move.w  d6,copptrh
    lea     bgpl0,a0            ; screen base for copy
    move.w  bplpos,d4           ; offset for copy
    cmp.l   #0,d4               ; clear on reset
    bne.b   .noclearlo
    lea     bgpl,a1
    jsr     clearpl
.noclearlo:
    move.w  d4,d5
    add.w   #celloff,d5
    lea     (a0,d5.w),a1        ; copy address
    clr.w   d0
    clr.w   d1
    jsr     drawpat             ; draw pattern 0
    lea     bgplhi0,a0          ; screen base for render
    addmod  d4,width,bplsize    ; increment
    move.w  d4,bplpos
    cmp.l   #0,d4               ; clear on reset
    bne.b   .noclearhi
    lea     bgplhi,a1
    jsr     clearpl
.noclearhi:
    move.w  d4,d5 
    add.w   #celloff,d5
    lea     (a0,d5.w),a1        ; render address
    clr.w   d0
    clr.w   d1
    jsr     drawpat             ; draw pattern 0
    lea     fgpl0,a1            ; get fg pointer
    jsr     clearrow            ; clear fg row
.nodraw:
    btst    #F_MATCH,flags
    beq     .exit
    bclr    #F_MATCH,flags
    lea     fgpl0,a0            ; get fg pointer
    lea     celloff(a0),a1
    clr.w   d0
    clr.w   d1
    jsr     drawpat             ; draw pattern 0
.exit:
    move.w  #$4020,_INTREQ      ; clear INTREQ
    move.w  #$4020,_INTREQ      ; ... twice
    movem.l (sp)+,d1-d6/a0-a1
    rte

timerint:
    move.l  a0,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #13,d0              ; PORTS handler
    beq     .exit
    move.l  #CIAB,a0            ; CIA-B base
    btst    #1,CIAICR(a0)
    beq     .exit
    add.b   #1,count            ; increment count mod countmod
    cmp.b   #countmod,count     ; check for mod divider
    bne     .nomod
    clr.b   count
    bset    #F_MATCH,flags
.nomod:
    move.b  cpos,d0             ; increment mod position
    add.b   #1,d0
    cmp.b   #(csize/2),d0       ; if halfway, request render
    bne.b   .nodraw
    bset    #F_DRAW,flags       ; set draw bit
.nodraw
    and.b   #(csize-1),d0       ; mod and test 0
    move.b  d0,cpos
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
    EVEN
flags:
    dc.w    0                   ; state flags
key:
    dc.w    0                   ; last keypress
bpos:
    dc.w    0                   ; buffer position
    EVEN
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
    EVEN
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
    EVEN
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
ptmp:
    dc.b    0

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
bgpl0:
    ds.b    width*pwidth
bgpl:
    ds.b    bplsize-width*pwidth
bgplhi0:
    ds.b    width*pwidth
bgplhi:
    ds.b    bplsize
fgpl:
    ds.b    bplsize-width*pwidth
fgpl0:
    ds.b    width*pwidth

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
    neg.b   d4                  ; negate bits
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
    neg.b   d4                  ; negate bits
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
    and.w   #$1F,d5             ; mod (8 rows * 4 bytes/row)
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
    and.w   #$1F,d5             ; mod (8 rows * 4 bytes/row)
    dbra    d4,.loop 
.found:
    ; here d6 is is the number of rotate rights done
    ; the match position is (24 - d6) % 32
    neg.w   d6
    add.w   #56,d6
    and.w   #$1F,d6
    lea     mbits0,a2           ; get match base
    lsl.w   #2,d3               ; match offset (0,1)
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
    rts 

;-----findmatch()------------
; checks mbits0, mbits1 for a pattern
; match. Sets d0,d1 to the match index + 1 or
; 0 if no match was found.
    CNOP    0,4
findmatch:
    move.b  #15,d5              ; down counter
    move.b  #16,d6              ; up counter 
    clr.l   d0                  ; initial result
    clr.l   d1
.loop0:
    btst    d5,mbits0
    bne     .down0
    btst    d6,mbits0
    bne     .up0
    add.b   #1,d6
    dbra    d5,.loop0
    bra     .next
.down0:
    add.b   #1,d5
    move.b  d5,d0 
    bra     .next
.up0:
    add.b   #1,d6
    move.b  d6,d0
.next:
    move.b  #15,d5              ; down counter
    move.b  #16,d6              ; up counter 
.loop1:
    btst    d5,mbits1
    bne     .down1
    btst    d6,mbits1
    bne     .up1
    add.b   #1,d6
    dbra    d5,.loop1
    bra     .done
.down1:
    add.b   #1,d5
    move.b  d5,d1 
    bra     .done
.up1:
    add.b   #1,d6
    move.b  d6,d1
.done:
    rts

;-----drawpat(d0,d1,a1)------
; Render the pattern indicated by d1 at 
; to address a1 at offset d0.
; TODO: can use the blitter LF to invert and even mask?
    CNOP    0,4
drawpat:
    waitblt
    lea     (a1,d0.w),a2      ; dest pointer
    move.l  a2,_BLTDPT        ; D address
    move.l  a2,_BLTCPT        ; C address
    lea     spr0,a0           ; pattern base 
    cmp.w   #0,d1
    beq     .idx0
    lea     spr1,a0
.idx0:
    move.l  a0,_BLTAPT        ; source pointer
    clr.w   _BLTAMOD          ; set A modulo
    move.w  #coff*2,_BLTDMOD  ; set D modulo
    move.w  #coff*2,_BLTCMOD  ; set C modulo
    move.w  #$0BFA,_BLTCON0   ; enable A,C,D, LF A + C
    move.w  #sprwidthw,d0     ; word count
    move.w  #csize*pwidth,d1  ; height
    lsl.w   #6,d1             ; in bit pos 6
    or.w    d1,d0             ; form blit size
    move.w  d0,_BLTSIZE       ; start blit
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

;------------------------------------------------------------------------------
    end
;------------------------------------------------------------------------------

