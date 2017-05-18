    SECTION amc,CODE
    JUMPPTR init
    INCDIR  ""
    INCLUDE "hwdefs.i"
;-----macro defs-----------
;DEBUG       SET 1

;-----screen defs----------
width       equ 320             ; plane width
height      equ 200             ; plane height (NTSC)
bplwidth    equ width/8         ; width in bytes
bplsize     equ bplwidth*height ; size in bytes
bplsizel    equ bplsize/4       ; size in dwords
bplwidthw   equ bplwidth/2      ; width in words
bplwidthl   equ bplwidth/4      ; width in dwords

;-----state defs-----------
ncells      equ 32              ; cell count
csize       equ 8               ; cell size (bits)
csizelog    equ 3               ; log2(csize)
csizeb      equ 1               ; cell size (bytes)
nstates     equ height/csize    ; number of states
stwidth     equ ncells*csizeb   ; state size in bytes
stlast      equ stwidth-1       ; last state offset
stwidthw    equ stwidth/2       ; state size in words
stwidthl    equ stwidth/4       ; state size in dwords
stsize      equ stwidth*nstates ; total state size
stsizel     equ stsize/4        ; total state size in dwords
wsize       equ 8               ; window size (rows)
ncols       equ 4               ; number of columns for metrics

;-----buffer defs----------
bsize       equ stwidth*csize   ; render buffer size
bsizel      equ bsize/4         ; render buffer size in dwords
coff        equ (bplwidth-stwidth)/2    ; offset of cell display in bytes
coffw       equ (bplwidthw-stwidthw)/2  ; offset of cell display in words

;-----timing defs----------
; one tick = 1.396825ms (clock interval is 279.365 nanoseconds)
; .715909 Mhz NTSC; .709379 Mhz PAL
; PAL 7093,79 ~ 7094 = 10ms   | NTSC 7159,09 ~ 7159 = 10ms
period      equ 12000
clkmask     equ $1F

;-----macro functions------
; waitr, waitblt, setblt
    INCDIR  ""
    INCLUDE "wmacro.i"

;-----entry point----------
; most of the CIA saving is trying
; to allow asmone to recover after close.
; however, this is only a convenience issue..
    SECTION amc,CODE
    CNOP    0,4
init:
    movem.l d1-d7/a0-a6,-(sp)
    move.w  _DMACONR,d1         ; save regs
    move.w  _INTENAR,d2   
    move.w  _INTREQR,d3
    move.w  _ADKCONR,d4
    movem.l d1-d4,-(sp)
    move.l  #CIAB,a6            ; CIA-B base
    move.b  CIACRB(a6),d1       ; save more regs
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

;-----init bitplanes-------
    IFND DEBUG
    lea     state,a0            ; cell state address
    move.l  #stsizel-1,d0       ; loop counter
.initstate:
    clr.l   (a0)+
    dbra    d0,.initstate
    lea     bgpl,a0             ; bitplane address
    move.l  #bplsizel*2-1,d0    ; loop counter
.initbpl:
    clr.l   (a0)+
    dbra    d0,.initbpl
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
    move.w  #0,pos

;-----setup copper list----
    move.l  #bgpl,d0            ; set up bg pointer
    move.w  d0,copptrl
    swap    d0
    move.w  d0,copptrh
    IFND DEBUG 
    move.l  #copstart,_COP1LCH 
    ENDC

;-----system setup---------
    waitr   a1,d0,d1,d2
    IFND DEBUG
    move.w  #$7fff,_INTENA      ; disable all bits in INTENA
    move.w  #$3070,_INTREQ      ; clear pending lvl3,6 
    move.l  $78.w,d0            ; save lvl2 handler
    move.l  d0,savelvl2       
    move.l  $6C.w,d0            ; save lvl3 handler
    move.l  d0,savelvl3       
    move.l  #intlvl2,$78.w      ; install lvl2 handler (cia-a)
    move.l  #intlvl3,$6C.w      ; install lvl3 handler (copper)
    move.l  #CIAB,a6            ; CIA-A base
    move.b  CIACRB(a6),d0
    and.b   #$C0,d0             ; continuous, pulse, PB6OFF
    move.b  d0,CIACRB(a6)       ; set CRA
    move.b  #$7F,CIAICR(a6)     ; clear CIA-A interrupts
    move.b  #(period&$FF),CIATBLO(a6) ; set timer period
    move.b  #(period>>8),CIATBHI(a6) 
    move.w  #$E020,_INTENA      ; enable lvl2-3
    move.b  #$82,CIAICR(a6)     ; enable TB interrupt
    bset.b  #0,CIACRB(a6)       ; start timer
    move.w  #$7FFF,_DMACON
    move.w  #DMAF_ALL,_DMACON
    move.w  _COPJMP1,d0         ; start copper
    ENDC

;-----frame loop start-------
.mainloop:
.endmain:
    btst    #6,$bfe001
    bne     .mainloop
;-----frame loop end---------

.exit:
;-----exit code------------
    move.w  #$7FFF,_INTENA      ; turn off interrupts
    move.l  #CIAB,a6            ; restore CIA regs
    bclr.b  #0,CIACRB(a6)
    move.b  #$7F,CIAICR(a6)     ; clear CIA-A interrupts
    movem.l (sp)+,d1-d2         ; pop saved copper,view
    movem.l (sp)+,d3-d6         ; pop CIA regs
    IFND DEBUG
    move.l  #CIAB,a6            ; restore CIA regs
    or.b    #$80,d3             ; write bit
    move.b  d3,CIACRB(a6)
    or.b    #$80,d4             ; write bit
    move.b  d4,CIAICR(a6)
    move.b  d5,CIATBLO(a6)
    move.b  d6,CIATBHI(a6)
    ENDC
    movem.l (sp)+,d3-d6         ; pop saved regs
    IFND DEBUG
    or.w    #$8000,d3           ; restore regs (set bit 15 to write)
    move.w  #$7FFF,_DMACON  
    move.w  d3,_DMACON
    or.w    #$8000,d4
    move.w  #$7FFF,_INTENA 
    move.l  savelvl2,d0         ; restore lvl2 handler
    move.l  d0,$78.w
    move.l  savelvl3,d0         ; restore lvl3 handler
    move.l  d0,$6C.w
    move.w  d4,_INTENA
    or.w    #$8000,d5
    move.w  #$7FFF,_INTREQ
    move.w  d5,_INTREQ
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
    movem.l (sp)+,d1-d7/a0-a6
;   clr.l   d0
    move.l  ctr,d0
    rts

;------interrupts----------

; Software lvl3 handler
intlvl3:
    movem.l d0-d1,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #5,d0               ; VERTB handler
    beq     .exit
    move.w  clk,d0
    and.w   #clkmask,d0
    move.w  clk,d0
    addq    #1,d0
    and.w   #clkmask,d0
    move.w  d0,clk
.exit:
    movem.l (sp)+,d0-d1
    rte

intlvl2:
    movem.l d0-d6/a0-a2,-(sp)
    move.w  _INTREQR,d0         ; check req mask
    btst    #13,d0              ; PORTS handler
    beq     .exit
    move.l  #CIAB,a0            ; CIA-B base
    move.b  CIAICR(a0),d0       ; poll CIA mask
    btst    #1,d0
    beq     .exit
    move.l  ctr,d0
    addq    #1,d0
    move.l  d0,ctr
    jsr     nextstate           ; compute next state
    move.w  pos,d6
    jsr     drawstate
    jsr     copystate
.exit:
    movem.l (sp)+,d0-d6/a0-a2
    rte

;------locals--------------
    EVEN
vpos:
    dc.l    0                   ; scroll position for bitplanes
rule:
    dc.w    0                   ; automata rule
negate:
    dc.w    0                   ; 1 to flip states
pos:
    dc.w    0                   ; state position
clk:
    dc.w    0
oncount:
    ds.b    4                   ; count of set bits by column
xoncount:
    ds.b    4                   ; count of changes by column
ctr:
    dc.l    0

;------saves/system--------
    EVEN
savelvl2:
    dc.l    0                   ; saved lvl2 handler
savelvl3:
    dc.l    0                   ; saved lvl3 handler
gfxbase:
    dc.l    0
gfxname:
    dc.b    "graphics.library",0

;-----cell state-----------
    SECTION amd,DATA
    CNOP    0,4
state: 
    ds.b    stsize          ; state history
statehi:
    ds.b    stsize

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
    dcb.l   64,CL_END
;   dc.w    $C801,$FF00     ; wait for line 200
;   dc.w    INTREQ_,$8010   ; trigger lvl3 irq

;-----bitplanes------------
    SECTION ambss,BSS_C
    CNOP    0,4
cbuf:
    ds.b    stwidth*csize     ; state display buffer
    CNOP    0,4
bgpl:
    ds.b    bplsize*2

;-----functions------------
    SECTION amc,CODE

;-----nextstate------------
; Compute next cell state.
; uses a0-a1,d0-d4
    CNOP    0,4
nextstate:
    lea     state,a0          ; state address
    move.l  a0,a1
    move.w  rule,d3           ; rule
    clr.l   d0
    move.w  pos,d0            ; current position 
    move.l  d0,d1
    addq    #1,d1             ; next position
    cmp.w   #nstates,d1
    bne     .nowrap
    clr.l   d1
.nowrap:
    move.w  d1,pos            ; save new position
    mulu.w  #stwidth,d0
    mulu.w  #stwidth,d1
    add.l   d0,a0             ; current state
    add.l   d1,a1             ; next state
    clr     d4                ; shift buffer
    move.b  stlast(a0),d0     ; s-1
    lsl.b   #2,d0
    or.b    d0,d4             ; add to buffer
    move.b  (a0)+,d0          ; s
    move.b  d0,d2             ; save first in d2
    lsl.b   #1,d0
    or.b    d0,d4             ; add to buffer
    move.w  #ncells-1,d0      ; loop counter
.stloop:
    move.b  (a0)+,d1          ; next
    or.b    d1,d4     
    move    d3,d1             ; check rule bit
    lsr.b   d4,d1
    and.b   #1,d1
    move.b  d1,(a1)+          ; store new state
    lsl.b   #1,d4             ; advance bits
    and.b   #7,d4
    dbra    d0,.stloop
    or.b    d2,d4             ; last
    move    d3,d1             ; check rule bit
    lsr.b   d4,d1
    and.b   #1,d1
    move.b  d1,(a1)           ; store new state
    rts

;-----drawstate(d6)--------
; Render the cell state at position in d6 to cbuf.
; uses a0-a1,d0-d3, preserves d6.
    CNOP    0,4
drawstate:
    waitblt                   ; dont change before blitter done!
    move.l  d6,d0
    lea     state,a0          ; compute state addr
    mulu.w  #stwidth,d0
    add.l   d0,a0
    lea     cbuf,a1           ; cell ptr
    move.w  #ncells-1,d0      ; loop counter
    move.l  #$FF000000,d1     ; bit pattern
    clr.l   d2                ; current word
.drawloop:
    move.b  (a0)+,d3          ; current cell
    cmp.b   #0,d3             ; test
    beq     .off 
    or.l    d1,d2             ; set bit 
.off: 
    lsr.l   #csize,d1         ; advance bit
    bne     .nxt
    move.l  #$FF000000,d1     ; reset pattern
    move.l  d2,(a1)+          ; store word
    clr.l   d2                ; clear current word
.nxt:
    dbra    d0,.drawloop
    move.w  #csize-2,d1       ; outer loop counter
.copyout:
    lea     cbuf,a0
    move.w  #stwidthl-1,d0    ; inner loop counter
.copyloop:
    move.l  (a0)+,d2          ; copy by dwords
    move.l  d2,(a1)+
    dbra    d0,.copyloop
    dbra    d1,.copyout
    rts 

;-----copystate(d6)-------
; Copy the contents of the state buffer cbuf into
; the display at row indicated by d0.
; uses a0,d0-d1, preserves d6
    CNOP    0,4
copystate:
    waitblt
    move.l  d6,d0
    lea     bgpl,a0           ; get screen base
    mulu.w  #bplwidth,d0      ; calculate row offset
    mulu.w  #csize,d0
    add.w   #coff,d0          ; add cell offset
    add.l   d0,a0             ; start address (dest)
    move.l  a0,_BLTDPT        ; set D pointer
    lea     cbuf,a0
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

;------------------------------------------------------------------------------
    end
;------------------------------------------------------------------------------

