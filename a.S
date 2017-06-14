    JUMPPTR init
    INCDIR  "git/"
    INCLUDE "wmacro.i"
    INCLUDE "hwdefs.i"
    INCDIR  "Include/"
    INCLUDE "exec/exec_lib.i"
    INCLUDE "exec/nodes.i"
;-----macro defs-----------
;DEBUG       SET 1
;NOGRAPH     SET 1
;ONEVOICE    SET 1

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
hsize       equ (ncells*wsize)  ; history window size
hsizel      equ (hsize/4)       ; history window size in dwords
hsizemod    equ (hsize-1)
ncolslog    equ 2               ; log2(ncols)
ncols       equ (1<<ncolslog)   ; number of columns for metrics
colsize     equ (ncells>>ncolslog)
colsizel    equ (colsize/4)

;-----flag bits------------
F_DRAW      equ 0               ; render next vblank
F_KEY       equ 1               ; key pressed
F_UPDATE    equ 2               ; update sequence parms
F_COLOR     equ 3               ; modulate color
F_MOD       equ 4               ; modulate sequence
F_TRANSP    equ 5               ; transpose root
F_CLOCK16   equ 6               ; 16 tick event
F_CLOCK8    equ 7               ; 8 tick event
F_ERR       equ 15              ; error exit

;-----buffer defs----------
bsize       equ stwidth*csize           ; render buffer size
bsizel      equ bsize/4                 ; render buffer size in dwords
coff        equ (bplwidth-stwidth)/2    ; offset of cell display in bytes
coffw       equ (bplwidthw-stwidthw)/2  ; offset of cell display in words
kbsizelog   equ 3                       ; keyboard buffer size log 2
kbsize      equ (1<<kbsizelog)          ; keyboard buffer size

;-----color defs-----------
fgbase      equ $0555
bgmax       equ $0333

;-----sequence defs--------
countmod    equ 64                      ; 16th notes between mode transition
F_DESC      equ 0                       ; descending flag
F_PERF      equ 1                       ; move to perfect flag

;-----timing defs----------
; one tick = 1.396825ms (clock interval is 279.365 nanoseconds)
; .715909 Mhz NTSC; .709379 Mhz PAL
; PAL 7093,79 ~ 7094 = 10ms   | NTSC 7159,09 ~ 7159 = 10ms
; 120 bpm = 32dq/s ~ 22371 (NTSC)
; 60hz ~ 11934 (NTSC)
period      equ 14800           ; timer interrupt period
kbhs        equ 95              ; keyboard handshake duration - 02 clocks

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
    IFND NOGRAPH
    move.w  #$1200,_BPLCON0     ; 
    move.w  #00,_BPLCON1        ; hscroll = 0
    move.w  #0,_BPL1MOD         ; mod for odd planes (bg)
    move.w  #$0038,_DDFSTRT     ; data-fetch start = $38/3Chi
    move.w  #$00D0,_DDFSTOP     ;            stop  = $D0/D4hi
    move.w  #$2100,_DIWHIGH     ; diw-high  = msb set for stop
    move.w  #$2C81,_DIWSTRT     ; diw-start = $2C81
    move.w  #$F4C1,_DIWSTOP     ; diw-stop  = $F4C1 (NTSC, PAL 2CC1)
    move.w  #$0111,_COLOR00     ; bg color (0) 
    move.w  #$0FFF,_COLOR01     ; fg color (1)
    ENDC

;-----init bitplanes-------
    IFND DEBUG
    lea     state,a0            ; cell state address
    move.l  #stsizel-1,d0       ; loop counter
.initstate:
    clr.l   (a0)+
    dbra    d0,.initstate
    lea     hist,a0             ; history buffer address
    move.l  #hsizel*2-1,d0      ; loop counter
.inithist:  
    clr.l   (a0)+
    dbra    d0,.inithist
    IFND NOGRAPH
    lea     bgpl,a0             ; bitplane address
    move.l  #bplsizel*2-1,d0    ; loop counter
.initbpl:
    clr.l   (a0)+
    dbra    d0,.initbpl
    ENDC
    lea     cbuf,a0             ; state buffer addr
    move.l  #bsizel-1,d0        ; loop counter
.initbuf:
    clr.l   (a0)+
    dbra    d0,.initbuf
    ENDC

;-----init state-----------
    move.w  #30,rule
    lea     state,a0
    move.b  #1,16(a0)
    move.l  #0,copypos
    move.l  #width,bplpos

;-----init sequence--------
    lea     seqtrig,a0
    lea     seq,a1
    move.w  #(seqlen*ncols-1),d4
.inittrig:
    move.b  #1,(a0)+
    move.b  #0,(a1)+
    dbra    d4,.inittrig
    lea     seqstate,a0
    move.w  #ncols-1,d4
.initseq:
    move.b  #0,SQP(a0)          ; position
    move.b  #0,SQL(a0)          ; level
    move.b  #1,SQG(a0)          ; gate
    move.b  #0,SQM(a0)          ; modulation
    move.b  #seqlen,SQLN(a0)    ; length
    move.b  #64,SQV(a0)         ; volume
    move.b  #9,SQD(a0)          ; decay
    move.b  d4,d3
    and.b   #1,d3
    add.b   #1,d3
    move.b  d3,SQO(a0)          ; octave
    addq    #1,a0
    dbra    d4,.initseq
    clr.w   d0
    jsr     mkseq               ; init sequences

;-----init metrics---------
    lea     oncount,a0
    move.w  #(2*ncols/4-1),d4
.initcnt:
    clr.l   (a0)+
    dbra    d4,.initcnt
    lea     maj,a0
    move.w  #(ncells/4-1),d4
.initmaj:
    clr.l   (a0)+
    dbra    d4,.initmaj

;-----other init-----------
    clr.b   key

;-----setup copper list----
    IFND NOGRAPH
    move.l  #bgpl,d0            ; set up bg pointer
    move.w  d0,copptrl
    swap    d0
    move.w  d0,copptrh
    IFND DEBUG 
    move.l  #copstart,_COP1LCH 
    ENDC
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
    and.b   #$18,CIACRB(a5)     ; CIA-A TA: one-shot, KB input mode
    and.b   #$C0,CIACRB(a6)     ; CIA-B TB: continuous, pulse, PB6OFF
    move.b  #(period&$FF),CIATBLO(a6) ; set CIA-B timer B period 
    move.b  #(period>>8),CIATBHI(a6)  ; ..for timer interrupt
    move.b  #(kbhs&$FF),CIATBLO(a5)   ; set CIA-A timer B period
    move.b  #(kbhs>>8),CIATBHI(a5)    ; .. for kb handshake
    move.l  #keyint,$68.w       ; install lvl2 handler (cia-a)
    IFND NOGRAPH
    move.l  #vblankint,$6C.w    ; install lvl3 handler
    ENDC
    move.l  #timerint,$78.w     ; install lvl6 handler (cia-b)
    move.b  #$88,CIAICR(a5)     ; enable CIA-A SP interrupt (keyboard)
    move.b  #$82,CIAICR(a6)     ; enable CIA-B TB interrupt
    move.w  #$E028,_INTENA      ; enable lvl2/3/6
    waitr   a1,d0,d1,d2
    bset.b  #0,CIACRB(a6)       ; start CIA-B TB
    IFND NOGRAPH
    move.w  _COPJMP1,d0         ; start copper
    ENDC
    move.w  #$8000,_ADKCON      ; clear mod bits
    move.w  #$7FFF,_DMACON      
    move.w  #DMAF_ALLA,_DMACON  ; start DMA
    ENDC

;-----frame loop start-------
.mainloop:
    btst    #F_KEY,flags
    beq     .nokey
    jsr     handlekb 
.nokey:
    btst    #F_UPDATE,flags
    beq     .noupdate
;   jsr     pack
;   jsr     writepp
    jsr     playseq
    jsr     update
    bclr    #F_UPDATE,flags
    bne     .exit
.noupdate:
    btst    #F_MOD,flags
    beq     .nomod
    jsr     modulate
.nomod:
    btst    #F_CLOCK8,flags
    beq     .noclock8
    jsr     settrig
    jsr     setseq
.noclock8
.endmain:
    btst    #6,$bfe001
    bne     .mainloop
;-----frame loop end---------

;-----exit code------------
.exit:
    move.w  #$7FFF,_INTENA      ; turn off interrupts
    move.l  #CIAB,a6
    move.l  #CIAA,a5
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
    or.w    #$8000,d5
    move.w  #$7FFF,_INTREQ      ; clear pending
    move.w  #$7FFF,_INTREQ
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
    move.w  #1,d0
    rts

;------interrupts----------

keyint:
    movem.l d4-d6/a0-a1,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #3,d0               ; PORTS handler
    beq     .exit
    move.l  #CIAA,a0            ; CIA-A base
    btst    #3,CIAICR(a0)       ; test SP bit
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
.exit:
    move.w  #$4008,_INTREQ      ; clear INTREQ
    move.w  #$4008,_INTREQ      ; ... twice
    movem.l (sp)+,d4-d6/a0-a1
    rte
    
vblankint:
    movem.l d1-d6/a0-a1,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #5,d0               ; VBLANK handler
    beq     .exit
    btst    #F_DRAW,flags
    beq     .nodraw
    bclr    #F_DRAW,flags
    move.l  coprpos,d5          ; get copper offset
    move.l  #bgpl,d6
    addmod  d5,width,bplsize    ; update start
    move.l  d5,coprpos
    add.l   d5,d6               ; copper start
    move.w  d6,copptrl          ; update copper
    swap    d6
    move.w  d6,copptrh
    lea     bgpl,a1             ; screen base for copy
    move.l  copypos,d4          ; offset for copy
    move.l  d4,d5
    add.l   #coff,d5
    add.l   d5,a1               ; copy address
    addmod  d4,width,bplsize    ; increment
    move.l  d4,copypos
    lea     cbuf,a0             ; source address
    jsr     copystate
.nocopy: 
    move.w  drawpos,d0          ; state position
    bsr     drawstate           ; copy state
    lea     bgplhi,a1           ; screen base for render
    move.l  bplpos,d4           ; offset for render
    move.l  d4,d5
    add.l   #coff,d5
    add.l   d5,a1               ; render address
    addmod  d4,width,bplsize    ; increment
    move.l  d4,bplpos
    lea     cbuf,a0             ; source address
    jsr     copystate           ; render new state
.nodraw:
    lea     seqstate,a0         ; envelope state
    move.l  #_AUD0LC,a1         ; audio ptr
    clr.l   d3                  ; zero volume reg
    move.w  #ncols-1,d4         ; loop counter
.loop:
    move.b  SQL(a0),d3          ; volume amount
    move.b  SQD(a0),d2          ; decay amount
    sub.b   d2,d3
    cmp.b   #0,d3
    bgt.b   .pos
    clr.l   d3
.pos
    move.b  d3,SQL(a0)          ; update env
    move.w  d3,8(a1)            ; set volume
    add.l   #AUDOFFSET,a1       ; next channel
    addq    #1,a0               ; next track
    dbra    d4,.loop 
    btst    #F_COLOR,flags
    beq     .exit
    jsr     colormod
    bclr    #F_COLOR,flags
.exit:
    move.w  #$4020,_INTREQ      ; clear INTREQ
    move.w  #$4020,_INTREQ      ; ... twice
    movem.l (sp)+,d1-d6/a0-a1
    rte

timerint:
    movem.l d1-d6/a0-a6,-(sp)
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
;   bset    #F_MOD,flags        ; reset count and modulate
.nomod:
    move.b  count,d0            ; check counter modulo
    and.b   #$0F,d0             ; 16th note
    cmp.b   #0,d0
    bne.b   .no16
    bset    #F_CLOCK16,flags
.no16:
    and.b   #$07,d0
    cmp.b   #0,d0
    beq.b   .no8
    bset    #F_CLOCK8,flags
.no8:
    move.b  cpos,d0             ; increment mod position
    addq    #1,d0
    cmp.b   #(csize/2),d0       ; if halfway, request render
    bne.b   .nodraw
    bset    #F_DRAW,flags       ; set draw bit
    move.w  pos,drawpos         ; set draw position
.nodraw
    and.b   #(csize-1),d0       ; mod and test 0
    move.b  d0,cpos
    cmp.b   #0,d0
    bne.b   .done
    bsr     nextstate
    bset    #F_UPDATE,flags
.done 
.exit:
    move.w  #$6000,_INTREQ      ; clear INTREQ
    move.w  #$6000,_INTREQ      ; ... twice
    movem.l (sp)+,d1-d6/a0-a6
    rte

;-----tables---------------
    INCDIR  "git/"
    INCLUDE "tabsaw.i"
    INCLUDE "scales.i"

;------locals--------------
    SECTION amd,DATA
    EVEN
fgcol:
    dc.w    0                   ; foreground color mod
bgcol:
    dc.w    0                   ; background color mod
pos:
    dc.w    0                   ; state position
drawpos:
    dc.w    0                   ; render positon
hpos:
    dc.w    0                   ; history position
copypos:
    dc.l    0                   ; bitplane offset for copy
bplpos:
    dc.l    0                   ; bitplane offset for render
coprpos:
    dc.l    0                   ; copper offset  
flags:
    dc.w    0
rule:
    dc.w    0                   ; automata rule
negate:
    dc.w    0                   ; 1 to flip states
oncount:
    ds.b    ncols               ; count of set bits by column
xoncount:
    ds.b    ncols               ; count of changes by column
maj:
    ds.b    ncells              ; count by individual columns
key:
    dc.w    0                   ; last keypress
popcnt:
    dc.b    0,1,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 1,2  
    EVEN
cpos:
    dc.b    0                   ; scroll position mod 8
count:
    dc.b    0                   ; step counter
    EVEN

;------saves/system--------
    SECTION amd,DATA
    EVEN
dbg:
    dc.l    0
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

;-----cell state-----------
    CNOP    0,4
state:
    ds.b    stsize
hist:
    ds.b    hsize
xhist:
    ds.b    hsize
hbuf:
    ds.b    ncells
xhbuf:
    ds.b    ncells
packed:
    dc.l    0                   ; packed state for transfer

;-----sequencer data--------
    CNOP    0,4
seq:
    ds.w    seqlen*ncols        ; sequence note lists
seqtrig:
    ds.b    seqlen*ncols        ; sequence triggers
seqstate:
seqpos:
    ds.b    ncols               ; current notes
seqlvl: 
    ds.b    ncols               ; current volumes
seqgate:
    ds.b    ncols               ; clock gate
seqmod:
    ds.b    ncols               ; modulation position
seqoct:
    ds.b    ncols               ; octave
seql:
    ds.b    ncols               ; sequence lengths
seqvol:
    ds.b    ncols               ; volume
seqdec:
    ds.b    ncols               ; decay
    EVEN
nextmod:
    dc.w    0                   ; next voice to modulate
modflags:
    dc.w    0                   ; modulation state

;-----sequencer addressing----
SQP         equ     (seqpos-seqstate)
SQL         equ     (seqlvl-seqstate)
SQLN        equ     (seql-seqstate)
SQG         equ     (seqgate-seqstate)
SQV         equ     (seqvol-seqstate)
SQD         equ     (seqdec-seqstate)
SQO         equ     (seqoct-seqstate)
SQM         equ     (seqmod-seqstate)

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
coplist:
    dcb.l   64, CL_END
;   dc.w    $C801,$FF00     ; wait for line 200
;   dc.w    INTREQ_,$8010   ; trigger lvl3 irq

;-----bitplanes------------
    SECTION ambss,BSS_C
    CNOP    0,4
bgpl:
    ds.b    bplsize
bgplhi:
    ds.b    bplsize
    CNOP    0,4
cbuf:
    ds.b    stwidth*csize     ; state display buffer
    CNOP    0,4

;-----functions------------
    SECTION amc,CODE

;-----settrig()-------------
; Set sequence triggers from maj array.
    CNOP    0,4
settrig:
    lea     seqtrig,a0      ; trigger list
    lea     maj,a1          ; column counts
    move.w  #ncells-1,d6    ; loop counter
.trigloop:
    clr.b   d1              ; zero trigger
    move.b  (a1)+,d0        ; count
    cmp.b   #(wsize/2),d0   ; test majority
    blt.b   .notrig
    add.b   #1,d1
.notrig:
    move.b  d1,(a0)+        ; store trigger value
    dbra    d6,.trigloop
    rts

;-----setseq()---------------
; Set sequence lengths from xoncount.
    CNOP    0,4
setseq:
    lea     oncount,a0
    lea     xoncount,a1
    lea     seql,a2
    move.w  #ncols-1,d6     ; loop counter
.loop:
    move.b  (a1)+,d0        ; count
    lsr.b   #3,d0           ; divide by 8
    add.b   #2,d0           ; add 2
    cmp.b   #seqlen,d0      ; saturate  
    blt.b   .nosat
    move.b  #seqlen,d0
.nosat:
    move.b  d0,(a2)+        ; set length
    dbra    d6,.loop
    rts

;-----update()-------------
; Update sequence metrics and history.
; uses a0-a4,d0-d6
    CNOP    0,4
update:
    lea     hist,a0
    lea     hbuf,a1
    lea     maj,a2            ; column counts
    clr.l   d0
    move.w  hpos,d0           ; history position
    lsl.w   #ncellslog,d0     ; history index
    add.l   d0,a0
    move.w  #ncells-1,d6      ; loop counter
.loop:
    move.b  (a1)+,d1          ; next cell
    move.b  (a0)+,d2          ; history cell
    sub.b   d2,d1             ; subtract
    add.b   d1,(a2)+          ; update count
    dbra    d6,.loop
    lea     hist,a0
    lea     hbuf,a1
    lea     popcnt,a2
    lea     oncount,a3
    lea     xhist,a4
    move.w  #ncols-1,d6       ; outer loop over columns
.outer:
    move.w  #colsizel-1,d5    ; inner loop over dwords 
.inner:
    move.l  (a4,d0.w),d1      ; xhistory word
    move.b  (a2,d1.w),d2      ; popcnt hist high
    swap    d1
    move.b  (a2,d1.w),d3      ; popcnt hist low
    add.b   d2,d3             ; popcnt hist
    move.l  ncells(a1),d1     ; xbuf word
    move.l  d1,(a4,d0.w)      ; save in history
    move.b  (a2,d1.w),d2      ; popcnt buf high
    swap    d1
    move.b  (a2,d1.w),d4      ; popcnt buf low
    add.b   d4,d2             ; popcnt buf
    sub.b   d3,d2             ; total change
    add.b   d2,ncols(a3)      ; store new col value
    move.l  (a0,d0.w),d1      ; history word
    move.b  (a2,d1.w),d2      ; popcnt hist high
    swap    d1
    move.b  (a2,d1.w),d3      ; popcnt hist low
    add.b   d2,d3             ; popcnt hist
    move.l  (a1)+,d1          ; buf word
    move.l  d1,(a0,d0.w)      ; save in history
    move.b  (a2,d1.w),d2      ; popcnt buf high
    swap    d1
    move.b  (a2,d1.w),d4      ; popcnt buf low
    add.b   d4,d2             ; popcnt buf
    sub.b   d3,d2             ; total change
    add.b   d2,(a3)           ; store new col value
    add.w   #4,d0             ; advance history word
    dbra    d5,.inner
    addq    #1,a3             ; advance column
    dbra    d6,.outer
    bclr    #F_UPDATE,flags   ; clear flag
    add.w   #1,hpos           ; update history position
    and.w   #wsize-1,hpos     ; mod wsize
    rts 
    
;-----nextstate()----------
; Compute next cell state.
; uses a0-a2,d0-d6
    CNOP    0,4
nextstate:
    lea     state,a0          ; state address
    move.l  a0,a1
    lea     hbuf,a2           ; history buffer address
    lea     xhbuf,a3  
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
    move.b  d1,(a2)+          ; save in hist
    eor.b   d2,d1             ; compute xor with prev
    and.b   #1,d1
    move.b  d1,(a3)+          ; save in xhist
    move.b  d4,d2             ; previous buffer in d2
    lsl.b   #1,d4             ; advance bits
    and.b   #7,d4
    dbra    d0,.stloop
    or.b    d6,d4             ; last
    move    d3,d1             ; check rule bit
    lsr.b   d4,d1
    and.b   #1,d1
    move.b  d1,(a1)           ; store new state
    move.b  d1,(a2)
    eor.b   d2,d1             ; xor with prev
    and.b   #1,d1
    move.b  d1,(a3)
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
    move.b  (a0)+,d3          ; current cell
    cmp.b   #0,d3             ; test
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

;-----copystate(a1,d6)-------
; Copy the contents of the rendered state at a0
; into the display at address a1
; uses d0-d1
    CNOP    0,4
copystate:
    waitblt
    move.l  a1,_BLTDPT        ; set D pointer
    move.l  a0,_BLTAPT        ; set A pointer
    clr.w   _BLTAMOD          ; set A modulo
    move.w  #coff*2,_BLTDMOD  ; set D modulo 
    move.w  #$09F0,_BLTCON0   ; enable A,D, LF A
    move.l  #stwidthw,d0      ; word count
    move.w  #csize,d1         ; height
    lsl.w   #6,d1             ; move height into position
    or.w    d1,d0             
    move.w  d0,_BLTSIZE       ; start the blit
    rts

;-----mkseq()--------------
; write period values into seq for each channel.
; uses a2-a6,d1-d5.
    CNOP    0,4
mkseq:
    lea     modes,a6          ; get mode base
    lea     ptab,a5           ; get period table base
    lea     seq,a4            ; seq base
    lea     seqstate,a3       ; sequence state
    clr.w   d5                ; zero index reg
    move.w  #ncols-1,d2       ; loop counter
.outer:
    move.b  root,d6           ; get root note
    move.b  SQO(a3),d1        ; load octave
    lsl.b   #2,d1             ; oct * 12 + root
    add.b   d1,d6
    lsl.b   #1,d1
    add.b   d1,d6
    clr.w   d0
    move.b  SQM(a3),d0        ; get mode position
    lsl.w   #modelenlog,d0    ; get mode index
    move.w  #seqlen-1,d4      ; loop counter
.inner:
    move.b  (a6,d0.w),d5      ; get offset
    add.w   #1,d0             ; next note in mode
    add.b   d6,d5             ; add to root
    lsl.b   #1,d5             ; get word offset
    move.w  (a5,d5.w),d3      ; load period value
    move.w  d3,(a4)+          ; store into seq
    dbra    d4,.inner
    addq    #1,a3             ; next voice
    dbra    d2,.outer
    rts

;-----playseq()-------------
; Play next sequence notes.
    CNOP    0,4
playseq:
    lea     seqtrig,a6        ; sequence triggers
    lea     seq,a5            ; sequence data
    move.l  #_AUD0LC,a4       ; audio register base
    lea     seqstate,a3       ; sequence state
    move.w  #ncols-1,d6       ; loop counter
    IFD ONEVOICE
    clr.w   d6
    ENDC
.loop:
    move.b  SQP(a3),d5        ; position
    clr.w   d4
    move.b  d5,d4             ; convert to word offset
    lsl.b   #1,d4
    move.w  (a5,d4),d3        ; period
    addq    #1,d5             ; increment position
    cmp.b   SQLN(a3),d5       ; check against length
    blt.b   .nowrap
    clr.b   d5
.nowrap:
    move.b  d5,SQP(a3)        ; new position
    cmp.b   #0,(a6,d4)        ; check for 0 trigger
    beq.b   .notrig
    move.b  SQV(a3),d2
    move.b  d2,SQL(a3)        ; level
    move.w  #TABSIZE,4(a4)    ; length
    move.l  #wav32,0(a4)      ; pointer
    move.w  d2,8(a4)          ; volume
    move.w  d3,6(a4)          ; period
.notrig:
    add.l   #AUDOFFSET,a4     ; next channel
    add.w   #1,a3             ; ""
    add.l   #seqlen,a5        ; ""
    dbra    d6,.loop
    rts

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
    bra     .done
.row1:
    lea     seqdec,a1
    and.w   #$03,d6
    sub.b   #1,(a1,d6.w)
    bra     .done
.row2:
    lea     seqdec,a1
    and.w   #$03,d6
    add.b   #1,(a1,d6.w)
    bra     .done
.row3:
    lea     state,a1
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
    move.b  _VHPOSR,d6
    and.w   #2,d6
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
.done:
    bclr    #F_KEY,flags
    rts

;-----modulate()-----------
; advance the modulation to
; the next position.
    CNOP    0,4
modulate:
    lea     seqmod,a6           ; sequencer mod state
    move.w  nextmod,d6          ; next mod index
    move.b  mode,d5             ; next mode
    btst    #F_PERF,modflags    ; test if moving to perfect (0) or next mode
    beq     .next
    clr.b   d5                  ; use perfect mode
.next:
    move.b  d5,(a6,d6.w)        ; update mod of next voice
    btst    #F_DESC,modflags    ; test if descending
    bne     .desc
    add.w   #1,d6               ; advance voice
    cmp.w   #ncols,d6           ; check for top
    blt     .done
    move.w  #ncols-1,d6         ; reverse direction 
    bset    #F_DESC,modflags    ; set descending
    bchg    #F_PERF,modflags    ; toggle mode bit
    bne     .done
    add.b   #1,mode             ; increment mode
    bra     .done
.desc:
    sub.w   #1,d6               ; advance voice
    cmp.w   #0,d6               ; check for bottom
    bge     .done
    move.w  #0,d6               ; reverse direction
    bclr    #F_DESC,modflags    ; set ascending
    bchg    #F_PERF,modflags    ; toggle mode bit
    bne     .done
    add.b   #1,mode             ; increment mode
.done:
    move.w  d6,nextmod          ; update next mod position
    cmp.b   #seqcnt,mode        ; wrap mode if needed
    blt     .return
    move.b  #1,mode             ; restart mode counter
.return:
    bclr    #F_MOD,flags
    jsr     mkseq               ; compute new sequences
    rts

;-----colormod()-----------
; modulate colors.
; uses d5,d6
    CNOP    0,4
colormod:
    move.w  fgcol,d5
    move.w  bgcol,d6
    add.w   #$0001,d5 
    move.w  d5,fgcol
    add.w   #fgbase,d5
    and.w   #$FFF,d5
    move.w  d5,_COLOR01 
    add.w   #$0011,d6 
    move.w  d6,bgcol
    and.w   #bgmax,d6
    move.w  d6,_COLOR00
    rts

;-----pack()---------------
; pack state at d0 into packed as dword.
; uses d0-d2,d6,a6
    CNOP    0,4
pack:
    lea     state,a6          ; compute state address
    lsl.w   #stwidthlog,d0    
    move.w  #ncells-1,d6      ; loop counter
    move.l  #1,d1             ; bit mask
    move.w  #0,d2             ; bit buffer
.loop:
    cmp.b   #0,(a6,d0.w)      ; test byte
    beq.b   .next
    or.l    d1,d2             ; set bit
.next:
    lsl.l   #1,d1             ; advance mask
    add.w   #1,d0             ; advance position
    dbra    d6,.loop
    move.l  d2,packed         ; store bits
    rts

;-----writepp()-----------------
; write packed state over parallel port.
; TODO: poll ACK line between writes..
    CNOP    0,4
writepp:
    lea     packed,a6         ; packed data (dword)
    move.l  #CIAA,a5          ; get CIAA base
    move.l  #CIAB,a4          ; get CIAB base
    move.b  #$FF,CIADDRB(a5)  ; set bits to output
    move.b  (a6)+,d0          
    move.b  d0,CIAPRB(a5)     ; write byte  
    tst.b   CIAPRA(a4)        ; waste cycle
    move.b  (a6)+,d0          
    move.b  d0,CIAPRB(a5)     ; write byte  
    tst.b   CIAPRA(a4)        ; waste cycle
    move.b  (a6)+,d0          
    move.b  d0,CIAPRB(a5)     ; write byte  
    tst.b   CIAPRA(a4)        ; waste cycle
    move.b  (a6)+,d0          
    move.b  d0,CIAPRB(a5)     ; write byte  
    tst.b   CIAPRA(a4)        ; waste cycle
    rts
    
;------------------------------------------------------------------------------
    end
;------------------------------------------------------------------------------

