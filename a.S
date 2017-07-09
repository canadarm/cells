;-----macro defs-----------
;DEBUG       SET 1
;NOGRAPH     SET 1
;ONEVOICE    SET 1
;PPOUT       SET 1

    INCDIR  "git/"
    INCLUDE "defs.i"
    INCLUDE "start.i"

;-----state defs-----------
wsizelog    equ 3               ; log2(wsize)
wsize       equ (1<<wsizelog)   ; window size (rows)
hsize       equ (ncells*wsize)  ; history window size
hsizel      equ (hsize/4)       ; history window size in dwords
ncolslog    equ 2               ; log2(ncols)
ncols       equ (1<<ncolslog)   ; number of columns for metrics
colsize     equ (ncells>>ncolslog)
colsizel    equ (colsize/4)

;-----flag bits------------
F_DRAW      equ 0               ; render next vblank
F_KEY       equ 1               ; key pressed
F_UPDATE    equ 2               ; update state
F_ENV       equ 3               ; update audio
F_MOD       equ 4               ; modulate sequence
F_TRANSP    equ 5               ; transpose root
F_CLOCK16   equ 6               ; 16 tick event
F_CLOCK4    equ 7               ; 4 tick event

;-----flag2 bits-----------
G_RAND      equ 0               ; randomize next
G_ONE       equ 1               ; init next
G_TABMOD    equ 2               ; mod tables next
G_ERR       equ 7               ; error exit

;-----sequence defs--------
S_DESC      equ 0                       ; descending flag
S_PERF      equ 1                       ; move to perfect flag

;-----entry point----------
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
    move.w  #$0000,_BLTCON1     ; clear BLTCON1
    ENDC

;-----init state-----------
    jsr     seed
    move.w  #0,pattern
    clr.w   d0
    jsr     setpat
    move.w  #1,state+16

    IFD DEBUG
    jsr     nextstate
    jsr     pack
    jsr     update
    bra     .exit
    ENDC

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
    move.b  #90,SQV(a0)         ; volume
    move.b  #12,SQD(a0)         ; decay
    move.b  #0,SQT(a0)          ; table pos
    move.b  #2,SQR(a0)          ; table mod rate
    move.b  #0,SQC(a0)          ; table mod count
    move.b  #0,SQX(a0)          ; enable
    move.b  d4,d3
    and.b   #1,d3
    move.b  d3,SQO(a0)          ; octave
    addq    #1,a0
    dbra    d4,.initseq
; tweaks
    move.b  #4,seqstate+SQR+0
    move.b  #4,seqstate+SQR+1
    move.b  #8,seqstate+SQR+2
    move.b  #12,seqstate+SQR+3
    move.b  #1,seqstate+SQO+0
    move.b  #1,seqstate+SQO+1
    move.b  #2,seqstate+SQO+2
    move.b  #1,seqstate+SQO+3
    move.w  #0,d0
    jsr     mkseq
    move.w  #1,d0
    jsr     mkseq
    move.w  #2,d0
    jsr     mkseq
    move.w  #3,d0
    jsr     mkseq

;-----init audio-----------
    move.l  #_AUD0LC,a6
    move.l  #wav,d5
    move.w  #ncols-1,d6
.audlp:
    move.w  #tabsizew,4(a6)
    clr.w   6(a6)
    clr.w   8(a6)
    move.l  d5,(a6)
    add.l   #tabsize,d5
    add.l   #AUDOFFSET,a6
    dbra    d6,.audlp
    jsr     mktab

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

;-----system setup---------
    IFND DEBUG
    waitr   a1,d0,d1,d2
    move.l  #CIAA,a5            ; CIA-A base
    move.l  #CIAB,a6            ; CIA-B base
    move.b  #$7F,CIAICR(a5)     ; clear CIA-A interrupts
    move.b  #$7F,CIAICR(a6)     ; clear CIA-B interrupts

    IFD PPOUT
    move.b  #$FF,CIADDRB(a5)    ; CIA-A DDRB: ppt output
    and.b   #$F8,CIADDRA(a6)    ; CIA-B DDRA: set BUSY/POUT/SEL to input (reset)
    or.b    #$07,CIAPRA(a6)     ; CIA-B DDRA: init all high
    ENDC 

    move.b  #$18,CIACRA(a5)     ; CIA-A TA: one-shot, KB input mode
    and.b   #$80,CIACRA(a6)     ; CIA-B TB: continuous, pulse, PB6OFF
    or.b    #$10,CIACRB(a6)     ;
    move.b  #(period&$FF),CIATBLO(a6) ; set CIA-B timer B period 
    move.b  #(period>>8),CIATBHI(a6)  ; ..for timer interrupt
    move.b  #(kbhs&$FF),CIATBLO(a5)   ; set CIA-A timer B period
    move.b  #(kbhs>>8),CIATBHI(a5)    ; .. for kb handshake

    move.l  #keyint,$68.w       ; install lvl2 handler (cia-a)
    move.l  #vblankint,$6C.w    ; install lvl3 handler
    move.l  #timerint,$78.w     ; install lvl6 handler (cia-b)
    move.b  #$88,CIAICR(a5)     ; enable CIA-A SP interrupt (keyboard)
    IFND PPOUT
    move.b  #$82,CIAICR(a6)     ; enable CIA-B TB interrupt
    ENDC
    move.w  #$E028,_INTENA      ; enable lvl2/3/6
    bset.b  #0,CIACRB(a6)       ; start CIA-B TB
    waitr   a1,d0,d1,d2
    move.w  _COPJMP1,d0         ; start copper
    move.w  #$0088,_ADKCON      ; clear mod bits
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
    bclr    #F_UPDATE,flags   ; clear flag
    jsr     nextstate
    jsr     pack
    IFD PPOUT
    jsr     writepp
    ENDC
    jsr     playseq
    jsr     update
    jsr     setseq
.noupdate:
    btst    #F_ENV,flags
    beq     .noenv
    bclr    #F_ENV,flags
    jsr     doenv
.noenv:
    btst    #G_TABMOD,flags2
    beq     .notab
    bclr    #G_TABMOD,flags2
    jsr     mktab
.notab:
    btst    #F_MOD,flags
    beq     .nomod
    bclr    #F_MOD,flags
    jsr     modulate
.nomod:
    btst    #F_CLOCK16,flags
    beq     .noclock16
    bclr    #F_CLOCK16,flags
    jsr     setoct
    move.w  #0,d0
    jsr     mkseq
    move.w  #1,d0
    jsr     mkseq
    move.w  #2,d0
    jsr     mkseq
    move.w  #3,d0
    jsr     mkseq
.noclock16:
    btst    #F_CLOCK4,flags
    beq     .noclock4
    bclr    #F_CLOCK4,flags
    jsr     settrig
.noclock4:
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
    rts

;------interrupts----------

keyint:
    movem.l d0-d6/a0-a6,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #3,d0               ; PORTS handler
    beq     .exit
    move.l  #CIAA,a0            ; CIA-A base
    btst    #3,CIAICR(a0)       ; test SP bit
    beq     .exit
    move.b  CIASDR(a0),d6       ; load serial data
    bset    #0,CIACRB(a0)       ; start CIA-A TB (one shot)
    or.b    #$40,CIACRA(a0)     ; set output mode (handshake)
    not.b   d6                  ; decode key
    lsr.b   #1,d6
    bcs     .handshake
    and.w   #$7F,d6             ; test key value
    move.w  d6,key
    bset    #F_KEY,flags 
.handshake:
    move.b  #2,d6               ; busy wait for timer underflow
    and.b   CIAICR(a0),d6
    beq     .handshake
    and.b   #$BF,CIACRA(a0)     ; set input mode
.exit:
    move.w  #$0008,_INTREQ      ; clear INTREQ
    move.w  #$0008,_INTREQ      ; ... twice
    movem.l (sp)+,d0-d6/a0-a6
    rte
    
vblankint:
    movem.l d0-d6/a0-a6,-(sp)
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
    lea     (a0,d5.w),a1
    move.l  a1,d6
    move.w  d6,copptrl          ; update copper
    swap    d6 
    move.w  d6,copptrh
    lea     bgpl,a0             ; screen base for copy
    move.w  bplpos,d4           ; offset for copy
    move.w  d4,d5
    add.w   #doff,d5
    lea     (a0,d5.w),a1        ; copy address
    lea     cbuf,a0             ; source address
    jsr     copystate
    move.w  drawpos,d0          ; state position
    jsr     drawstate           ; copy state
    lea     bgplhi,a0           ; screen base for render
    addmod  d4,width,bplsize    ; increment
    move.w  d4,bplpos
    move.w  d4,d5
    add.w   #doff,d5
    lea     (a0,d5.w),a1        ; render address
    lea     cbuf,a0             ; source address
    jsr     copystate           ; render new state
.nodraw:
    bset    #F_ENV,flags
.exit:
    move.w  #$0020,_INTREQ      ; clear INTREQ
    move.w  #$0020,_INTREQ      ; ... twice
    movem.l (sp)+,d0-d6/a0-a6
    rte

timerint:
    movem.l d0-d6/a0-a6,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    and.w   #$2000,d0           ; PORTS handler
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
    and.b   #$3F,d0
    and.b   d0,d1
    bne.b   .no16
    bset    #F_CLOCK16,flags
.no16:
    and.b   #$F,d0
    bne.b   .no4
    bset    #F_CLOCK4,flags
    bset    #G_TABMOD,flags2    ; set tabmod bit
.no4:
    move.b  cpos,d0             ; increment mod position
    add.b   #1,d0
    cmp.b   #(csize/2),d0       ; if halfway, request render
    bne.b   .nodraw
    bset    #F_DRAW,flags       ; set draw bit
    move.w  pos,drawpos         ; set draw position
.nodraw
    and.b   #(csize-1),d0       ; mod and test 0
    move.b  d0,cpos
    cmp.b   #0,d0
    bne.b   .done
    bset    #F_UPDATE,flags
.done 
.exit:
    move.w  #$2000,_INTREQ      ; clear INTREQ
    move.w  #$2000,_INTREQ      ; ... twice
    movem.l (sp)+,d0-d6/a0-a6
    rte

;-----tables---------------
    INCDIR  "git/"
    INCLUDE "tabsaw.i"
    INCLUDE "scales.i"
    INCLUDE "pattern.i"

;------locals--------------
    SECTION progst,DATA
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
bplpos:
    dc.w    0                   ; bitplane offset for render
coprpos:
    dc.w    0                   ; copper offset  
flags:
    dc.w    0
flags2:
    dc.w    0
rule:
    dc.b    0
ruleb:
    dc.b    0                   ; automata rule
negate:
    dc.b    0
negateb:
    dc.b    0                   ; 1 to flip states
key:
    dc.w    0                   ; last keypress
    EVEN
cpos:
    dc.b    0                   ; scroll position mod 8
count:
    dc.b    0                   ; step counter
pat:
    dc.b    0                   ; current pattern
md:
    dc.b    0                   ; current mode
    EVEN

    SECTION cmetrics,BSS_F
    CNOP    0,4
oncount:
    ds.b    ncols               ; count of set bits by column
xoncount:
    ds.b    ncols               ; count of changes by column
maj:
    ds.b    ncells              ; count by individual columns

    SECTION cmisc,DATA_F
    CNOP    0,4
packed:
    dc.l    0                   ; packed state for transfer
zeros:
    dc.b    0
    CNOP    0,4
popcnt:
    dc.b    0,1,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0
    dc.b    0,0,0,0,0,0,0,0 ;16
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;32
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;48
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;64
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;80
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;96
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;112
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;128
    dc.b    0,0,0,0,0,0,0,0
    dc.b    0,0,0,0,0,0,0,0 ;16
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;32
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;48
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;64
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;80
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;96
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    0,0,0,0,0,0,0,0 ;112
    dc.b    0,0,0,0,0,0,0,0 
    dc.b    1,2,0,0,0,0,0,0 ;128

;------saves/system--------
    SECTION saves,DATA
    EVEN
dbg:
    dc.l    0
dbg2:
    dc.l    0
savelvl2:
    dc.l    0                   ; saved lvl2 handler
savelvl3:
    dc.l    0                   ; saved lvl3 handler
savelvl6:
    dc.l    0                   ; saved lvl6 handler
gfxbase:
    dc.l    0
viewport:
    dc.l    0
copsave:
    dc.l    0
gfxname:
    dc.b    "graphics.library",0

;-----cell state-----------
    SECTION cellst,BSS_F
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
newstate:
    ds.b    ncells              ; buffer for reset/random

;-----sequencer data--------
    SECTION seqst,DATA_F
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
seqtab:
    ds.b    ncols               ; mod table position
seqrate:
    ds.b    ncols               ; table mod rate
seqrcnt:
    ds.b    ncols               ; mod counter
seqdis:
    ds.b    ncols               ; global disable
volbase:
    dc.b    80,80,80,80
    EVEN
nextmod:
    dc.w    0                   ; next voice to modulate
modflags:
    dc.w    0                   ; modulation state
seqptr:
    dc.l    sq32
    dc.l    asin32 
    dc.l    saw32  
    dc.l    sin32

;-----sequencer addressing----
SQP         equ     (seqpos-seqstate)
SQL         equ     (seqlvl-seqstate)
SQLN        equ     (seql-seqstate)
SQG         equ     (seqgate-seqstate)
SQV         equ     (seqvol-seqstate)
SQD         equ     (seqdec-seqstate)
SQO         equ     (seqoct-seqstate)
SQM         equ     (seqmod-seqstate)
SQT         equ     (seqtab-seqstate)
SQR         equ     (seqrate-seqstate)
SQC         equ     (seqrcnt-seqstate)
SQX         equ     (seqdis-seqstate)

;-----wave buffers---------
    SECTION wave,BSS_C
    CNOP    0,4
wav:
    ds.w    ncols*tabsizew

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
coplist:
    dcb.l   64, CL_END
;   dc.w    $C801,$FF00     ; wait for line 200
;   dc.w    INTREQ_,$8010   ; trigger lvl3 irq

;-----bitplanes------------
    SECTION planes,BSS_C
    CNOP    0,4
bgpad:
    ds.b    stwidth
bgpl:
    ds.b    bplsize
bgplhi:
    ds.b    bplsize
    CNOP    0,4
cpad:
    ds.b    stwidth
cbuf:
    ds.b    stwidth*csize     ; state display buffer

;-----functions------------
    SECTION funcs,CODE

;-----settrig()-------------
; Set sequence triggers from maj array.
    CNOP    0,4
settrig:
    lea     seqtrig,a0      ; trigger list
    lea     maj,a1          ; column counts
    move.w  #ncells-1,d6    ; loop counter
    cmp.b   #0,negateb
    bne     .negloop
.trigloop:
    clr.b   d1              ; zero trigger
    move.b  (a1)+,d0        ; count
    cmp.b   #(wsize/2)-2,d0 ; test majority
    blt.b   .notrig
    add.b   #1,d1
.notrig:
    move.b  d1,(a0)+        ; store trigger value
    dbra    d6,.trigloop
    rts
.negloop:
    clr.b   d1              ; zero trigger
    move.b  (a1)+,d0        ; count
    cmp.b   #(wsize/2)+2,d0 ; test majority
    bge.b   .notrig2
    add.b   #1,d1
.notrig2:
    move.b  d1,(a0)+        ; store trigger value
    dbra    d6,.negloop
    rts

;-----setoct()---------------
; Set octaves from maj.
    CNOP    0,4
setoct:
    lea     seqoct,a0       ; octave params
    lea     maj,a1          ; column counts
    lea     seqrate,a2      ; mod rates
    move.w  #ncols-1,d6     ; outer loop counter
.outer:
    clr.w   d0              ; maj sum
    move.w  #colsize-1,d5   ; inner loop
.inner:
    move.b  (a1)+,d1
    cmp.b   #(wsize/2),d1   ; test maj
    blt     .nomaj
    add.w   #1,d0
.nomaj:
    dbra    d5,.inner
    lsr.w   #1,d0
    subq.w  #2,d0           ; subtract and clamp
    bge     .next
    clr.w   d0
.next:
    move.b  d0,(a0)+        ; store octave
    dbra    d6,.outer
    rts

;-----setseq()---------------
; Set sequence lengths from xoncount.
    CNOP    0,4
setseq:
    lea     oncount,a0
    lea     xoncount,a1
    lea     seql,a2
    lea     seqgate,a3
    lea     seqvol,a4
    lea     seqdec,a5
    lea     volbase,a6
    move.w  #ncols-1,d6     ; loop counter
.loop:
    move.b  (a0)+,d0        ; count
    move.b  d0,d1
    lsr.b   #2,d1           ; div by 4
    move.b  (a6)+,d2
    add.b   d2,d1
    move.b  d1,(a4)+        ; set vol = c/4 + base (80)
    lsr.b   #3,d0           ; divide by 8
    add.b   #3,d0           ; add 3
    cmp.b   #seqlen,d0      ; saturate  
    blt.b   .nosat
    move.b  #seqlen,d0
.nosat:
    move.b  d0,(a2)+        ; set length
    move.b  (a1)+,d0        ; xcount
    clr.b   d1              ; gate value
    cmp.b   #11,d0          ; check gate threshold
    blt     .setgate
    move.b  #1,d1
.setgate:
    move.b  d1,(a3)+        ; set gate value
    move.b  d0,d1
    lsr.b   #3,d1           ; div by 8
    add.b   #6,d1         
    move.b  d1,(a5)+        ; set decay
    dbra    d6,.loop
    rts

;-----update()-------------
; Update sequence metrics and history.
; uses a0-a5,d0-d6
    CNOP    0,4
update:
    lea     hist,a0
    lea     hbuf,a1
    lea     maj,a2            ; column counts
    move.w  hpos,d0           ; history position
    ext.l   d0
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
    lea     xoncount,a5
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
    lea     (a2,d1.w),a6
    move.b  (a2,d1.w),d2      ; popcnt buf high
    swap    d1
    move.b  (a2,d1.w),d4      ; popcnt buf low
    add.b   d4,d2             ; popcnt buf
    sub.b   d3,d2             ; total change
    add.b   d2,(a5)+          ; store new col value
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
    add.b   d2,(a3)+          ; store new col value
    add.w   #4,d0             ; advance history word
    dbra    d5,.inner
    dbra    d6,.outer
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
    lea     (a1,d6.w),a1      ; next state
    lea     hbuf,a2           ; history buffer address
    lea     xhbuf,a3  
    move.w  rule,d3           ; rule
    clr.b   d4                ; shift buffer
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
    move.w  #doff*2,_BLTDMOD  ; set D modulo 
    move.w  #$09F0,_BLTCON0   ; enable A,D, LF A
    move.l  #stwidthw,d0      ; word count
    move.w  #csize,d1         ; height
    lsl.w   #6,d1             ; move height into position
    or.w    d1,d0             
    move.w  d0,_BLTSIZE       ; start the blit
    rts

;-----mkseq(d0)------------
; write period values into seq for channel
; index in d0.
; uses a2-a6,d0-d6.
    CNOP    0,4
mkseq:
    lea     modes,a6          ; get mode base
    lea     ptab4,a5          ; get period table base
    lea     seq,a4            ; seq base
    lea     seqoct,a3         ; octaves
    lea     seqmod,a2         ; modes
    move.b  (a2,d0.w),d2      ; get mode position
    ext.w   d2
    lsl.w   #modelenlog,d2    ; get mode index
    move.b  root,d6           ; get root note
    move.b  (a3,d0.w),d1      ; load octave
    lsl.b   #2,d1             ; oct * 12 + root
    add.b   d1,d6
    lsl.b   #1,d1
    add.b   d1,d6
    lsl.w   #seqlenlog,d0     ; get sequence offset
    add.w   d0,d2             ; get mode offset
    move.w  #seqlen-1,d4      ; loop counter
    clr.w   d5                ; zero index reg
.inner:
    move.b  (a6,d2.w),d5      ; get offset
    add.b   d6,d5             ; add to root
    lsl.b   #1,d5             ; get word offset
    move.w  (a5,d5.w),d3      ; load period value
    move.w  d3,(a4,d0.w)      ; store into seq
    add.w   #1,d2             ; next note in mode
    add.w   #2,d0             ; next seq position
    dbra    d4,.inner
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
.loop:
    cmp.b   #0,SQG(a3)        ; gate
    beq     .notrig 
    move.b  SQP(a3),d5        ; position
    move.b  d5,d4             ; convert to word offset
    ext.w   d4
    lsl.w   #1,d4
    move.w  (a5,d4),d3        ; period
    add.b   #1,d5             ; increment position
    cmp.b   SQLN(a3),d5       ; check against length
    blt.b   .nowrap
    clr.b   d5
.nowrap:
    move.b  d5,SQP(a3)        ; new position
    cmp.b   #0,(a6,d4)        ; check for 0 trigger
    beq.b   .notrig
    move.b  SQV(a3),d2
    cmp.b   #0,SQX(a3)        ; check enable
    beq     .cont
    clr.b   d2
.cont:
    move.b  d2,SQL(a3)        ; level
    ext.w   d2
    move.w  d2,8(a4)          ; volume
    move.w  d3,6(a4)          ; period
.notrig:
    add.l   #AUDOFFSET,a4     ; next channel
    add.l   #1,a3             ; ""
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
.row0:
    sub.w   #1,d6
    cmp.w   #8,d6
    bge     .mod
    lea     seqdis,a1
    and.w   #$03,d6
    eor.b   #1,(a1,d6.w)
    bra     .done
.mod:
    subq.w  #8,d6
    ble     .dec
    move.b  #5,d0
    jsr     chroot
    bra     .done  
.dec:
    move.b  #-5,d0
    jsr     chroot
    bra     .done
.row1:
    lea     volbase,a1
    and.w   #$03,d6
    add.b   #4,(a1,d6.w)
    bra     .done
.row2:
    lea     volbase,a1
    and.w   #$03,d6
    sub.b   #4,(a1,d6.w)
    bra     .done
.row3:
    lea     state,a1
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
    cmp.b   #1,d6
    beq.b   .reset1
.resetrand:
    bset    #G_RAND,flags2
    bra     .done
.reset1:
    bset    #G_ONE,flags2
    bra     .done
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

;-----modulate()-----------
; advance the modulation to
; the next position.
    CNOP    0,4
modulate:
    lea     seqmod,a6           ; sequencer mod state
    move.w  nextmod,d6          ; next mod index
    move.b  mode,d5             ; next mode
    move.w  d6,d0               ; save nextmod for mkseq
    btst    #S_PERF,modflags    ; test if moving to perfect (0) or next mode
    beq     .next
    clr.b   d5                  ; use perfect mode
.next:
    move.b  d5,(a6,d6.w)        ; update mod of next voice
    btst    #S_DESC,modflags    ; test if descending
    bne     .desc
    add.w   #1,d6               ; advance voice
    cmp.w   #ncols,d6           ; check for top
    blt     .done
    move.w  #ncols-1,d6         ; reverse direction 
    move.b  d5,md               ; record mode
    bset    #S_DESC,modflags    ; set descending
    bchg    #S_PERF,modflags    ; toggle mode bit
    bne     .done
    add.b   #1,mode             ; increment mode
    bra     .done
.desc:
    sub.w   #1,d6               ; advance voice
    cmp.w   #0,d6               ; check for bottom
    bge     .done
    move.w  #0,d6               ; reverse direction
    move.b  d5,md               ; record mode
    bclr    #S_DESC,modflags    ; set ascending
    bchg    #S_PERF,modflags    ; toggle mode bit
    bne     .done
    add.b   #1,mode             ; increment mode
.done:
    move.w  d6,nextmod          ; update next mod position
    cmp.b   #seqcnt,mode        ; wrap mode if needed
    blt     .return
    move.b  #1,mode             ; restart mode counter
.return:
    jsr     mkseq               ; compute new sequences
    rts

;-----pack()---------------
; pack state at d0 into packed as dword.
; uses d0-d3,d6,a6
    CNOP    0,4
pack:
    lea     state,a6          ; compute state address
    move.w  pos,d0            ; get state position
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
    move.l  d2,packed         ; store bits
    add.b   #1,d3             ; count zeros
    add.b   d3,zeros
    cmp.b   #countz,zeros     ; test for dead state
    blt     .norand
    clr.b   zeros
    bset    #G_RAND,flags2
.norand:
    rts

;-----writepp()-----------------
; write packed state over parallel port.
; TODO: poll ACK line between writes..
    CNOP    0,4
writepp:
    lea     packed,a6               ; packed data (dword)
    move.l  #CIAA,a5                ; get CIAA base
    move.l  #CIAB,a4                ; get CIAB base
    move.w  #$4000,_INTENA          ; turn off ints
    move.b  (a6)+,d0                ; write state
    jsr     writepb
    move.b  (a6)+,d0
    jsr     writepb
    move.b  (a6)+,d0
    jsr     writepb
    move.b  (a6)+,d0
    jsr     writepb
    move.b  mode,d0                 ; write mode,root,pat
    jsr     writepb
    move.b  root,d0
    jsr     writepb 
    move.b  pat,d0
    jsr     writepb
    move.w  #$C000,_INTENA          ; re-enable ints
    rts

writepb:
    move.b  d0,CIAPRB(a4)           ; write data
    bset.b  #2,CIADDRA(a5)          ; set CTL to output
    bclr.b  #2,CIAPRA(a5)           ; pulse CTL (int)
    bset.b  #2,CIAPRA(a5)
    bset.b  #1,CIADDRA(a5)          ; set valid to output (send)
    bclr.b  #1,CIAPRA(a5)           ; pull valid low (trigger ack)
.w1 btst.b  #0,CIAPRA(a5)	          ; busy wait on ack
    bne	    .w1
    and.b   #$F8,CIADDRA(a5)	      ; set controls to input (reset)
    or.b    #7,CIAPRA(a5)	          ; reset
    rts

;-----setpat(d0)----------------
; Advance pattern by the amount in d0 with wrap 
    CNOP    0,4
setpat: 
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
    move.b  d1,pat              ; record for B on next pack
    lea     rules,a6 
    lsl.w   #rulesl,d1
    move.b  0(a6,d1.w),ruleb
    move.b  1(a6,d1.w),negateb
    rts

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

;-----prng()---------------
; get prn in d0.l
    CNOP      0,4
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
; uses a0,d0-d3
randstate:
    lea     newstate,a0
    move.w  #ncells-1,d2        ; loop counter
.randloop:
    jsr     prng
    move.b  d0,d1
    lsl.b   #2,d1
    or.b    d1,d0
    lsl.b   #2,d1
    or.b    d1,d0 
    and.b   #1,d0
    move.b  d0,(a0)+
    dbra    d2,.randloop
    rts

;-----initstate()----------
; initialize the current state
; uses a0,d0
initstate:
    lea     newstate,a0
    move.l  #ncells/4-1,d0
.clearloop:
    clr.l   (a0)+
    dbra    d0,.clearloop
    move.b  #1,newstate+16
    rts

;-----mktab()--------------
; set wave tables with blitter, and
; update sequence modulation
    CNOP      0,4
mktab:
    lea     wav,a0              ; dest position
    lea     mtab32,a2           ; source B (mask)
    lea     seqptr,a5
    lea     seqstate,a6
    move.w  #(tabsizew+$40),d1  ; set size for 1 line
    clr.w   d3                  ; param position
    move.w  #ncols-1,d6         ; loop counter
.tabloop:
    move.b  SQC(a6,d3.w),d4     ; check count
    subq.b  #1,d4
    bge     .cont
    move.b  SQR(a6,d3.w),d4
    bra     .done
.cont:
    waitblt
    move.b  SQT(a6,d3.w),d5     ; mod position 
    ext.w   d5
    lea     (a2,d5.w),a3        ; form mod address
    move.w  #$0D30,_BLTCON0     ; set params (A,B,D), LF AB'
    move.l  a0,_BLTDPT
    clr.w   _BLTAMOD            ; clear modulos
    clr.w   _BLTBMOD
    clr.w   _BLTDMOD
    move.l  a3,_BLTBPT          ; set mask pointer
    move.l  (a5)+,_BLTAPT       ; set source pointer
    move.w  d1,_BLTSIZE         ; start blit 
    clr.b   d4                  ; reset count
    add.b   #2,d5               ; increment pos  
    and.b   #modsize-1,d5       ; clamp
.done:
    move.b  d4,SQC(a6,d3.w)     ; update count
    move.b  d5,SQT(a6,d3.w)     ; update position
    add.w   #1,d3               ; next params
    add.l   #tabsize,a0         ; next table
    dbra    d6,.tabloop
    rts

;-----doenv()---------------
; update envelopes and wave tables
    CNOP    0,4
doenv:
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
    rts

;-----chroot()----------------
; update the root note by amt in d0
    CNOP    0,4
chroot:
    move.b  root,d1
    add.b   d0,d1
    cmp.b   #0,d1
    bge     .pos
.add:
    add.b   #12,d1
    cmp.b   #0,d1
    blt     .add  
.pos:
    cmp.b   #12,d1
    blt     .done
.sub:
    sub.b   #12,d1
    cmp.b   #12,d1
    bge     .sub
.done
    move.b  d1,root
    move.w  #0,d0
    jsr     mkseq 
    move.w  #1,d0
    jsr     mkseq 
    move.w  #2,d0
    jsr     mkseq 
    move.w  #3,d0
    jsr     mkseq 
    rts

;------------------------------------------------------------------------------
    end
;------------------------------------------------------------------------------

