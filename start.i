    JUMPPTR start
    INCDIR  "git/"
    INCLUDE "wmacro.i"
    INCLUDE "hwdefs.i"

    SECTION main,CODE
    CNOP    0,4
start:
    movem.l d1-d6/a0-a6,-(sp)   ; save system regs
    move.l  4.w,a6              ; get execbase
    clr.l   d0                  ; start lib calls
    move.l  #gfxname,a1     
    jsr     -552(a6)            ; openlibrary()
    move.l  d0,gfxbase          ; save result = gfxbase
    move.l  d0,a6
    move.l  34(a6),viewport     ; save viewport
    move.l  38(a6),copsave      ; save copper ptr
    move.w  _DMACONR,d1         ; save control regs
    move.w  _INTENAR,d2   
    move.w  _INTREQR,d3
    move.w  _ADKCONR,d4
    movem.l d1-d4,-(sp)         ; save BPL controls
    move.w  _BPLCON0,d1
    move.w  _BPLCON1,d2
    move.w  _BLTCON0,d3
    move.w  _BLTCON1,d4
    movem.l d1-d4,-(sp)
    move.l  #CIAB,a5            ; save CIA-B regs
    move.b  CIACRA(a5),d2
    move.b  CIACRB(a5),d3
    move.b  CIAICR(a5),d4
    move.b  CIATBLO(a5),d5
    move.b  CIATBHI(a5),d6
    movem.l d2-d6,-(sp)
    move.l  #CIAA,a5            ; save CIA-A regs
    move.b  CIACRA(a5),d1
    move.b  CIACRB(a5),d2
    move.b  CIAICR(a5),d3
    move.b  CIATBLO(a5),d4
    move.b  CIATBHI(a5),d5
    movem.l d1-d5,-(sp)
    IFND DEBUG
    move.l  gfxbase,a6          ; load gfxbase
    move.l  #0,a1               ; graceful exit prep
    jsr     -222(a6)            ; LoadView
    jsr     -270(a6)            ; WaitTOF (x2)
    jsr     -270(a6)      
    jsr     -456(a6)            ; OwnBlitter
    jsr     -228(a6)            ; WaitBlit - yes, _after_ own
    move.l  4.w,a6              ; execbase
    jsr     -132(a6)            ; Forbid MT
    ENDC

    jsr     main                ; call main routine

    IFND DEBUG
    move.w  #$7FFF,_INTENA      ; turn off interrupts
    move.l  #CIAB,a6
    move.l  #CIAA,a5
    move.b  #$7F,CIAICR(a6)     ; clear CIA-B interrupts
    move.b  #$7F,CIAICR(a6)     ; ?
    move.b  #$7F,CIAICR(a5)     ; clear CIA-A interrupts
    move.b  #$7F,CIAICR(a5)     ; ?
    bclr.b  #0,CIACRB(a6)       ; stop timer
    ENDC
    movem.l (sp)+,d2-d6         ; pop CIA-A regs
    IFND DEBUG
    move.b  d2,CIACRA(a5)
    move.b  d3,CIACRB(a5)
    or.b    #$80,d4
    move.b  d4,CIAICR(a5)
    move.b  d5,CIATBLO(a5)
    move.b  d6,CIATBHI(a5)
    ENDC
    movem.l (sp)+,d2-d6         ; pop CIA-B regs
    IFND DEBUG
    move.b  d2,CIACRA(a6)
    move.b  d3,CIACRB(a6)
    or.b    #$80,d4
    move.b  d4,CIAICR(a6)
    move.b  d5,CIATBLO(a6)
    move.b  d6,CIATBHI(a6)
    ENDC
    movem.l (sp)+,d3-d6         ; pop BPL controls
    IFND DEBUG
    move.w  d3,_BPLCON0
    move.w  d4,_BPLCON1
    move.w  d5,_BLTCON0
    move.w  d6,_BLTCON1
    ENDC
    movem.l (sp)+,d3-d6         ; pop saved system control regs
    IFND DEBUG
    move.w  #$7FFF,_DMACON  
    or.w    #$8000,d3           ; write bit
    move.w  d3,_DMACON
    move.w  #$7FFF,_INTENA      ; disable ints before resotre
    or.w    #$8000,d4
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
    move.w  #$7FFF,_ADKCON
    move.w  #$7FFF,_ADKCON
    or.w    #$8000,d6
    move.w  d6,_ADKCON
    move.l  gfxbase,a6          ; get gfxbase
    move.l  viewport,a1         ; saved view
    jsr     -222(a6)            ; LoadView
    jsr     -270(a6)            ; WaitTOF (x2)
    jsr     -228(a6)            ; WaitBlit
    jsr     -462(a6)            ; Disown
    move.l  copsave,_COP1LCH    ; restore copper
    ENDC
    move.l  4.w,a6              ; get execbase
    move.l  gfxbase,a1          ; gfx ptr
    jsr     -414(a6)            ; closelibrary
    IFND DEBUG
    jsr     -132(a6)            ; permit MT
    ENDC
.return:
    movem.l (sp)+,d1-d6/a0-a6
    rts

main:
    ; main code follows
