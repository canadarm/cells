          INCDIR  "Include/"
          INCLUDE "hardware/custom.i"
*******************************************************************************
*
* This instruction for the copper will cause it to wait forever since
* the wait command described in it will never happen.
*
COPPER_HALT  equ  $FFFFFFFE
*
*******************************************************************************
*
* This is the offset in the 680x0 address space to the custom chip registers
* It is the same as  _custom  when linking with AMIGA.lib
*
CUSTOM    equ     $DFF000

*
* Various control registers
*
_DMACONR  equ     CUSTOM+dmaconr         ; Just capitalization...
_VPOSR    equ     CUSTOM+vposr           ;  "         "
_VHPOSR   equ     CUSTOM+vhposr          ;  "         "
_JOY0DAT  equ     CUSTOM+joy0dat         ;  "         "
_JOY1DAT  equ     CUSTOM+joy1dat         ;  "         "
_CLXDAT   equ     CUSTOM+clxdat          ;  "         "
_ADKCONR  equ     CUSTOM+adkconr         ;  "         "
_POT0DAT  equ     CUSTOM+pot0dat         ;  "         "
_POT1DAT  equ     CUSTOM+pot1dat         ;  "         "
_POTINP   equ     CUSTOM+potinp          ;  "         "
_SERDATR  equ     CUSTOM+serdatr         ;  "         "
_INTENAR  equ     CUSTOM+intenar         ;  "         "
_INTREQR  equ     CUSTOM+intreqr         ;  "         "
_REFPTR   equ     CUSTOM+refptr          ;  "         "
_VPOSW    equ     CUSTOM+vposw           ;  "         "
_VHPOSW   equ     CUSTOM+vhposw          ;  "         "
_SERDAT   equ     CUSTOM+serdat          ;  "         "
_SERPER   equ     CUSTOM+serper          ;  "         "
_POTGO    equ     CUSTOM+potgo           ;  "         "
_JOYTEST  equ     CUSTOM+joytest         ;  "         "
_STREQU   equ     CUSTOM+strequ
_STRVBL   equ     CUSTOM+strvbl          ;  "         "
_STRHOR   equ     CUSTOM+strhor          ;  "         "
_STRLONG  equ     CUSTOM+strlong         ;  "         "
_DIWHIGH  equ     CUSTOM+$1E4
_DIWSTRT  equ     CUSTOM+diwstrt         ;  "         "
_DIWSTOP  equ     CUSTOM+diwstop         ;  "         "
_DDFSTRT  equ     CUSTOM+ddfstrt         ;  "         "
_DDFSTOP  equ     CUSTOM+ddfstop         ;  "         "
_DMACON   equ     CUSTOM+dmacon          ;  "         "
_INTENA   equ     CUSTOM+intena          ;  "         "
_INTREQ   equ     CUSTOM+intreq          ;  "         "
*
* Disk control registers
*
_DSKBYTR  equ     CUSTOM+dskbytr         ; Just capitalization...
_DSKPT    equ     CUSTOM+dskpt           ;  "         "
_DSKPTH   equ     CUSTOM+dskpt
_DSKPTL   equ     CUSTOM+dskpt+$02
_DSKLEN   equ     CUSTOM+dsklen          ;  "         "
_DSKDAT   equ     CUSTOM+dskdat          ;  "         "
_DSKSYNC  equ     CUSTOM+dsksync         ;  "         "
*
* Blitter registers
*
_BLTCON0  equ     CUSTOM+bltcon0         ; Just capitalization...
_BLTCON1  equ     CUSTOM+bltcon1         ;  "         "
_BLTAFWM  equ     CUSTOM+bltafwm         ;  "         "
_BLTALWM  equ     CUSTOM+bltalwm         ;  "         "
_BLTCPT   equ     CUSTOM+bltcpt          ;  "         "
_BLTCPTH  equ     CUSTOM+bltcpt
_BLTCPTL  equ     CUSTOM+bltcpt+$02
_BLTBPT   equ     CUSTOM+bltbpt          ;  "         "
_BLTBPTH  equ     CUSTOM+bltbpt
_BLTBPTL  equ     CUSTOM+bltbpt+$02
_BLTAPT   equ     CUSTOM+bltapt          ;  "         "
_BLTAPTH  equ     CUSTOM+bltapt
_BLTAPTL  equ     CUSTOM+bltapt+$02
_BLTDPT   equ     CUSTOM+bltdpt          ;  "         "
_BLTDPTH  equ     CUSTOM+bltdpt
_BLTDPTL  equ     CUSTOM+bltdpt+$02
_BLTSIZE  equ     CUSTOM+bltsize         ;  "         "
_BLTCMOD  equ     CUSTOM+bltcmod         ;  "         "
_BLTBMOD  equ     CUSTOM+bltbmod         ;  "         "
_BLTAMOD  equ     CUSTOM+bltamod         ;  "         "
_BLTDMOD  equ     CUSTOM+bltdmod         ;  "         "
_BLTCDAT  equ     CUSTOM+bltcdat         ;  "         "
_BLTBDAT  equ     CUSTOM+bltbdat         ;  "         "
_BLTADAT  equ     CUSTOM+bltadat         ;  "         "
_BLTDDAT  equ     CUSTOM+bltddat         ;  "         "
*
* Copper control registers
*
_COPCON   equ     CUSTOM+copcon          ; Just capitalization...
_COPINS   equ     CUSTOM+copins          ;  "         "
_COPJMP1  equ     CUSTOM+copjmp1         ;  "         "
_COPJMP2  equ     CUSTOM+copjmp2         ;  "         "
_COP1LC   equ     CUSTOM+cop1lc          ;  "         "
_COP1LCH  equ     CUSTOM+cop1lc
_COP1LCL  equ     CUSTOM+cop1lc+$02
_COP2LC   equ     CUSTOM+cop2lc          ;  "         "
_COP2LCH  equ     CUSTOM+cop2lc
_COP2LCL  equ     CUSTOM+cop2lc+$02
*
*
* Audio channel registers
*
AUDOFFSET equ     (aud1-aud0)
_ADKCON   equ     CUSTOM+adkcon          ; Just capitalization...
_AUD0LC   equ     CUSTOM+aud0
_AUD0LCH  equ     CUSTOM+aud0
_AUD0LCL  equ     CUSTOM+aud0+$02
_AUD0LEN  equ     CUSTOM+aud0+$04
_AUD0PER  equ     CUSTOM+aud0+$06
_AUD0VOL  equ     CUSTOM+aud0+$08
_AUD0DAT  equ     CUSTOM+aud0+$0A
_AUD1LC   equ     CUSTOM+aud1
_AUD1LCH  equ     CUSTOM+aud1
_AUD1LCL  equ     CUSTOM+aud1+$02
_AUD1LEN  equ     CUSTOM+aud1+$04
_AUD1PER  equ     CUSTOM+aud1+$06
_AUD1VOL  equ     CUSTOM+aud1+$08
_AUD1DAT  equ     CUSTOM+aud1+$0A
_AUD2LC   equ     CUSTOM+aud2
_AUD2LCH  equ     CUSTOM+aud2
_AUD2LCL  equ     CUSTOM+aud2+$02
_AUD2LEN  equ     CUSTOM+aud2+$04
_AUD2PER  equ     CUSTOM+aud2+$06
_AUD2VOL  equ     CUSTOM+aud2+$08
_AUD2DAT  equ     CUSTOM+aud2+$0A
_AUD3LC   equ     CUSTOM+aud3
_AUD3LCH  equ     CUSTOM+aud3
_AUD3LCL  equ     CUSTOM+aud3+$02
_AUD3LEN  equ     CUSTOM+aud3+$04
_AUD3PER  equ     CUSTOM+aud3+$06
_AUD3VOL  equ     CUSTOM+aud3+$08
_AUD3DAT  equ     CUSTOM+aud3+$0A
*
*
*  The bitplane registers
*
_BPL1PT   equ     CUSTOM+bplpt+$00
_BPL1PTH  equ     CUSTOM+bplpt+$00
_BPL1PTL  equ     CUSTOM+bplpt+$02
_BPL2PT   equ     CUSTOM+bplpt+$04
_BPL2PTH  equ     CUSTOM+bplpt+$04
_BPL2PTL  equ     CUSTOM+bplpt+$06
_BPL3PT   equ     CUSTOM+bplpt+$08
_BPL3PTH  equ     CUSTOM+bplpt+$08
_BPL3PTL  equ     CUSTOM+bplpt+$0A
_BPL4PT   equ     CUSTOM+bplpt+$0C
_BPL4PTH  equ     CUSTOM+bplpt+$0C
_BPL4PTL  equ     CUSTOM+bplpt+$0E
_BPL5PT   equ     CUSTOM+bplpt+$10
_BPL5PTH  equ     CUSTOM+bplpt+$10
_BPL5PTL  equ     CUSTOM+bplpt+$12
_BPL6PT   equ     CUSTOM+bplpt+$14
_BPL6PTH  equ     CUSTOM+bplpt+$14
_BPL6PTL  equ     CUSTOM+bplpt+$16
_BPLCON0  equ     CUSTOM+bplcon0         ; Just capitalization...
_BPLCON1  equ     CUSTOM+bplcon1         ;  "         "
_BPLCON2  equ     CUSTOM+bplcon2         ;  "         "
_BPL1MOD  equ     CUSTOM+bpl1mod         ;  "         "
_BPL2MOD  equ     CUSTOM+bpl2mod         ;  "         "
_DPL1DATA equ     CUSTOM+bpldat+$00
_DPL2DATA equ     CUSTOM+bpldat+$02
_DPL3DATA equ     CUSTOM+bpldat+$04
_DPL4DATA equ     CUSTOM+bpldat+$06
_DPL5DATA equ     CUSTOM+bpldat+$08
_DPL6DATA equ     CUSTOM+bpldat+$0A
*
*
* Sprite control registers
*
_SPR0PT   equ     CUSTOM+sprpt+$00
_SPR0PTH  equ     _SPR0PT+$00
_SPR0PTL  equ     _SPR0PT+$02
_SPR1PT   equ     CUSTOM+sprpt+$04
_SPR1PTH  equ     _SPR1PT+$00
_SPR1PTL  equ     _SPR1PT+$02
_SPR2PT   equ     CUSTOM+sprpt+$08
_SPR2PTH  equ     _SPR2PT+$00
_SPR2PTL  equ     _SPR2PT+$02
_SPR3PT   equ     CUSTOM+sprpt+$0C
_SPR3PTH  equ     _SPR3PT+$00
_SPR3PTL  equ     _SPR3PT+$02
_SPR4PT   equ     CUSTOM+sprpt+$10
_SPR4PTH  equ     _SPR4PT+$00
_SPR4PTL  equ     _SPR4PT+$02
_SPR5PT   equ     CUSTOM+sprpt+$14
_SPR5PTH  equ     _SPR5PT+$00
_SPR5PTL  equ     _SPR5PT+$02
_SPR6PT   equ     CUSTOM+sprpt+$18
_SPR6PTH  equ     _SPR6PT+$00
_SPR6PTL  equ     _SPR6PT+$02
_SPR7PT   equ     CUSTOM+sprpt+$1C
_SPR7PTH  equ     _SPR7PT+$00
_SPR7PTL  equ     _SPR7PT+$02
;
; Note:  SPRxDATB is defined as being +$06 from SPRxPOS.
; sd_datab should be defined as $06, however, in the 1.3 assembler
; include file hardware/custom.i it is incorrectly defined as $08.
;
_SPR0POS  equ     CUSTOM+spr+$00
_SPR0CTL  equ     _SPR0POS+sd_ctl
_SPR0DATA equ     _SPR0POS+sd_dataa
_SPR0DATB equ     _SPR0POS+$06     ; should use sd_datab ...
_SPR1POS  equ     CUSTOM+spr+$08
_SPR1CTL  equ     _SPR1POS+sd_ctl
_SPR1DATA equ     _SPR1POS+sd_dataa
_SPR1DATB equ     _SPR1POS+$06     ; should use sd_datab ...
_SPR2POS  equ     CUSTOM+spr+$10
_SPR2CTL  equ     _SPR2POS+sd_ctl
_SPR2DATA equ     _SPR2POS+sd_dataa
_SPR2DATB equ     _SPR2POS+$06     ; should use sd_datab ...
_SPR3POS  equ     CUSTOM+spr+$18
_SPR3CTL  equ     _SPR3POS+sd_ctl
_SPR3DATA equ     _SPR3POS+sd_dataa
_SPR3DATB equ     _SPR3POS+$06     ; should use sd_datab ...
_SPR4POS  equ     CUSTOM+spr+$20
_SPR4CTL  equ     _SPR4POS+sd_ctl
_SPR4DATA equ     _SPR4POS+sd_dataa
_SPR4DATB equ     _SPR4POS+$06     ; should use sd_datab ...
_SPR5POS  equ     CUSTOM+spr+$28
_SPR5CTL  equ     _SPR5POS+sd_ctl
_SPR5DATA equ     _SPR5POS+sd_dataa
_SPR5DATB equ     _SPR5POS+$06     ; should use sd_datab ...
_SPR6POS  equ     CUSTOM+spr+$30
_SPR6CTL  equ     _SPR6POS+sd_ctl
_SPR6DATA equ     _SPR6POS+sd_dataa
_SPR6DATB equ     _SPR6POS+$06     ; should use sd_datab ...
_SPR7POS  equ     CUSTOM+spr+$38
_SPR7CTL  equ     _SPR7POS+sd_ctl
_SPR7DATA equ     _SPR7POS+sd_dataa
_SPR7DATB equ     _SPR7POS+$06     ; should use sd_datab ...
*
* Color registers...
*
_COLOR00  equ     CUSTOM+color+$00
_COLOR01  equ     CUSTOM+color+$02
_COLOR02  equ     CUSTOM+color+$04
_COLOR03  equ     CUSTOM+color+$06
_COLOR04  equ     CUSTOM+color+$08
_COLOR05  equ     CUSTOM+color+$0A
_COLOR06  equ     CUSTOM+color+$0C
_COLOR07  equ     CUSTOM+color+$0E
_COLOR08  equ     CUSTOM+color+$10
_COLOR09  equ     CUSTOM+color+$12
_COLOR10  equ     CUSTOM+color+$14
_COLOR11  equ     CUSTOM+color+$16
_COLOR12  equ     CUSTOM+color+$18
_COLOR13  equ     CUSTOM+color+$1A
_COLOR14  equ     CUSTOM+color+$1C
_COLOR15  equ     CUSTOM+color+$1E
_COLOR16  equ     CUSTOM+color+$20
_COLOR17  equ     CUSTOM+color+$22
_COLOR18  equ     CUSTOM+color+$24
_COLOR19  equ     CUSTOM+color+$26
_COLOR20  equ     CUSTOM+color+$28
_COLOR21  equ     CUSTOM+color+$2A
_COLOR22  equ     CUSTOM+color+$2C
_COLOR23  equ     CUSTOM+color+$2E
_COLOR24  equ     CUSTOM+color+$30
_COLOR25  equ     CUSTOM+color+$32
_COLOR26  equ     CUSTOM+color+$34
_COLOR27  equ     CUSTOM+color+$36
_COLOR28  equ     CUSTOM+color+$38
_COLOR29  equ     CUSTOM+color+$3A
_COLOR30  equ     CUSTOM+color+$3C
_COLOR31  equ     CUSTOM+color+$3E

*******************************************************************************
*
* Non-absolute forms
*
DMACONR_  equ     dmaconr         ; Just capitalization...
VPOSR_    equ     vposr           ;  "         "
VHPOSR_   equ     vhposr          ;  "         "
JOY0DAT_  equ     joy0dat         ;  "         "
JOY1DAT_  equ     joy1dat         ;  "         "
CLXDAT_   equ     clxdat          ;  "         "
ADKCONR_  equ     adkconr         ;  "         "
POT0DAT_  equ     pot0dat         ;  "         "
POT1DAT_  equ     pot1dat         ;  "         "
POTINP_   equ     potinp          ;  "         "
SERDATR_  equ     serdatr         ;  "         "
INTENAR_  equ     intenar         ;  "         "
INTREQR_  equ     intreqr         ;  "         "
REFPTR_   equ     refptr          ;  "         "
VPOSW_    equ     vposw           ;  "         "
VHPOSW_   equ     vhposw          ;  "         "
SERDAT_   equ     serdat          ;  "         "
SERPER_   equ     serper          ;  "         "
POTGO_    equ     potgo           ;  "         "
JOYTEST_  equ     joytest         ;  "         "
STREQU_   equ     strequ
STRVBL_   equ     strvbl          ;  "         "
STRHOR_   equ     strhor          ;  "         "
STRLONG_  equ     strlong         ;  "         "
DIWSTRT_  equ     diwstrt         ;  "         "
DIWSTOP_  equ     diwstop         ;  "         "
DDFSTRT_  equ     ddfstrt         ;  "         "
DDFSTOP_  equ     ddfstop         ;  "         "
DMACON_   equ     dmacon          ;  "         "
INTENA_   equ     intena          ;  "         "
INTREQ_   equ     intreq          ;  "         "
*
* Disk control registers
*
DSKBYTR_  equ     dskbytr         ; Just capitalization...
DSKPT_    equ     dskpt           ;  "         "
DSKPTH_   equ     dskpt
DSKPTL_   equ     dskpt+$02
DSKLEN_   equ     dsklen          ;  "         "
DSKDAT_   equ     dskdat          ;  "         "
DSKSYNC_  equ     dsksync         ;  "         "
*
* Blitter registers
*
BLTCON0_  equ     bltcon0         ; Just capitalization...
BLTCON1_  equ     bltcon1         ;  "         "
BLTAFWM_  equ     bltafwm         ;  "         "
BLTALWM_  equ     bltalwm         ;  "         "
BLTCPT_   equ     bltcpt          ;  "         "
BLTCPTH_  equ     bltcpt
BLTCPTL_  equ     bltcpt+$02
BLTBPT_   equ     bltbpt          ;  "         "
BLTBPTH_  equ     bltbpt
BLTBPTL_  equ     bltbpt+$02
BLTAPT_   equ     bltapt          ;  "         "
BLTAPTH_  equ     bltapt
BLTAPTL_  equ     bltapt+$02
BLTDPT_   equ     bltdpt          ;  "         "
BLTDPTH_  equ     bltdpt
BLTDPTL_  equ     bltdpt+$02
BLTSIZE_  equ     bltsize         ;  "         "
BLTCMOD_  equ     bltcmod         ;  "         "
BLTBMOD_  equ     bltbmod         ;  "         "
BLTAMOD_  equ     bltamod         ;  "         "
BLTDMOD_  equ     bltdmod         ;  "         "
BLTCDAT_  equ     bltcdat         ;  "         "
BLTBDAT_  equ     bltbdat         ;  "         "
BLTADAT_  equ     bltadat         ;  "         "
BLTDDAT_  equ     bltddat         ;  "         "
*
* Copper control registers
*
COPCON_   equ     copcon          ; Just capitalization...
COPINS_   equ     copins          ;  "         "
COPJMP1_  equ     copjmp1         ;  "         "
COPJMP2_  equ     copjmp2         ;  "         "
COP1LC_   equ     cop1lc          ;  "         "
COP1LCH_  equ     cop1lc
COP1LCL_  equ     cop1lc+$02
COP2LC_   equ     cop2lc          ;  "         "
COP2LCH_  equ     cop2lc
COP2LCL_  equ     cop2lc+$02
*
*
* Audio channel registers
*
ADKCON_   equ     adkcon          ; Just capitalization...
AUD0LC_   equ     aud0
AUD0LCH_  equ     aud0
AUD0LCL_  equ     aud0+$02
AUD0LEN_  equ     aud0+$04
AUD0PER_  equ     aud0+$06
AUD0VOL_  equ     aud0+$08
AUD0DAT_  equ     aud0+$0A
AUD1LC_   equ     aud1
AUD1LCH_  equ     aud1
AUD1LCL_  equ     aud1+$02
AUD1LEN_  equ     aud1+$04
AUD1PER_  equ     aud1+$06
AUD1VOL_  equ     aud1+$08
AUD1DAT_  equ     aud1+$0A
AUD2LC_   equ     aud2
AUD2LCH_  equ     aud2
AUD2LCL_  equ     aud2+$02
AUD2LEN_  equ     aud2+$04
AUD2PER_  equ     aud2+$06
AUD2VOL_  equ     aud2+$08
AUD2DAT_  equ     aud2+$0A
AUD3LC_   equ     aud3
AUD3LCH_  equ     aud3
AUD3LCL_  equ     aud3+$02
AUD3LEN_  equ     aud3+$04
AUD3PER_  equ     aud3+$06
AUD3VOL_  equ     aud3+$08
AUD3DAT_  equ     aud3+$0A
*
*
*  The bitplane registers
*
BPL1PT_   equ     bplpt+$00
BPL1PTH_  equ     bplpt+$00
BPL1PTL_  equ     bplpt+$02
BPL2PT_   equ     bplpt+$04
BPL2PTH_  equ     bplpt+$04
BPL2PTL_  equ     bplpt+$06
BPL3PT_   equ     bplpt+$08
BPL3PTH_  equ     bplpt+$08
BPL3PTL_  equ     bplpt+$0A
BPL4PT_   equ     bplpt+$0C
BPL4PTH_  equ     bplpt+$0C
BPL4PTL_  equ     bplpt+$0E
BPL5PT_   equ     bplpt+$10
BPL5PTH_  equ     bplpt+$10
BPL5PTL_  equ     bplpt+$12
BPL6PT_   equ     bplpt+$14
BPL6PTH_  equ     bplpt+$14
BPL6PTL_  equ     bplpt+$16
BPLCON0_  equ     bplcon0         ; Just capitalization...
BPLCON1_  equ     bplcon1         ;  "         "
BPLCON2_  equ     bplcon2         ;  "         "
BPL1MOD_  equ     bpl1mod         ;  "         "
BPL2MOD_  equ     bpl2mod         ;  "         "
DPL1DATA_ equ     bpldat+$00
DPL2DATA_ equ     bpldat+$02
DPL3DATA_ equ     bpldat+$04
DPL4DATA_ equ     bpldat+$06
DPL5DATA_ equ     bpldat+$08
DPL6DATA_ equ     bpldat+$0A
*
*
* Sprite control registers
*
SPR0PT_   equ     sprpt+$00
SPR0PTH_  equ     SPR0PT_+$00
SPR0PTL_  equ     SPR0PT_+$02
SPR1PT_   equ     sprpt+$04
SPR1PTH_  equ     SPR1PT_+$00
SPR1PTL_  equ     SPR1PT_+$02
SPR2PT_   equ     sprpt+$08
SPR2PTH_  equ     SPR2PT_+$00
SPR2PTL_  equ     SPR2PT_+$02
SPR3PT_   equ     sprpt+$0C
SPR3PTH_  equ     SPR3PT_+$00
SPR3PTL_  equ     SPR3PT_+$02
SPR4PT_   equ     sprpt+$10
SPR4PTH_  equ     SPR4PT_+$00
SPR4PTL_  equ     SPR4PT_+$02
SPR5PT_   equ     sprpt+$14
SPR5PTH_  equ     SPR5PT_+$00
SPR5PTL_  equ     SPR5PT_+$02
SPR6PT_   equ     sprpt+$18
SPR6PTH_  equ     SPR6PT_+$00
SPR6PTL_  equ     SPR6PT_+$02
SPR7PT_   equ     sprpt+$1C
SPR7PTH_  equ     SPR7PT_+$00
SPR7PTL_  equ     SPR7PT_+$02
;
; Note:  SPRxDATB is defined as being +$06 from SPRxPOS.
; sd_datab should be defined as $06, however, in the 1.3 assembler
; include file hardware/custom.i it is incorrectly defined as $08.
;
SPR0POS_  equ     spr+$00
SPR0CTL_  equ     SPR0POS_+sd_ctl
SPR0DATA_ equ     SPR0POS_+sd_dataa
SPR0DATB_ equ     SPR0POS_+$06     ; should use sd_datab ...
SPR1POS_  equ     spr+$08
SPR1CTL_  equ     SPR1POS_+sd_ctl
SPR1DATA_ equ     SPR1POS_+sd_dataa
SPR1DATB_ equ     SPR1POS_+$06     ; should use sd_datab ...
SPR2POS_  equ     spr+$10
SPR2CTL_  equ     SPR2POS_+sd_ctl
SPR2DATA_ equ     SPR2POS_+sd_dataa
SPR2DATB_ equ     SPR2POS_+$06     ; should use sd_datab ...
SPR3POS_  equ     spr+$18
SPR3CTL_  equ     SPR3POS_+sd_ctl
SPR3DATA_ equ     SPR3POS_+sd_dataa
SPR3DATB_ equ     SPR3POS_+$06     ; should use sd_datab ...
SPR4POS_  equ     spr+$20
SPR4CTL_  equ     SPR4POS_+sd_ctl
SPR4DATA_ equ     SPR4POS_+sd_dataa
SPR4DATB_ equ     SPR4POS_+$06     ; should use sd_datab ...
SPR5POS_  equ     spr+$28
SPR5CTL_  equ     SPR5POS_+sd_ctl
SPR5DATA_ equ     SPR5POS_+sd_dataa
SPR5DATB_ equ     SPR5POS_+$06     ; should use sd_datab ...
SPR6POS_  equ     spr+$30
SPR6CTL_  equ     SPR6POS_+sd_ctl
SPR6DATA_ equ     SPR6POS_+sd_dataa
SPR6DATB_ equ     SPR6POS_+$06     ; should use sd_datab ...
SPR7POS_  equ     spr+$38
SPR7CTL_  equ     SPR7POS_+sd_ctl
SPR7DATA_ equ     SPR7POS_+sd_dataa
SPR7DATB_ equ     SPR7POS_+$06     ; should use sd_datab ...
*
* Color registers...
*
COLOR00_  equ     color+$00
COLOR01_  equ     color+$02
COLOR02_  equ     color+$04
COLOR03_  equ     color+$06
COLOR04_  equ     color+$08
COLOR05_  equ     color+$0A
COLOR06_  equ     color+$0C
COLOR07_  equ     color+$0E
COLOR08_  equ     color+$10
COLOR09_  equ     color+$12
COLOR10_  equ     color+$14
COLOR11_  equ     color+$16
COLOR12_  equ     color+$18
COLOR13_  equ     color+$1A
COLOR14_  equ     color+$1C
COLOR15_  equ     color+$1E
COLOR16_  equ     color+$20
COLOR17_  equ     color+$22
COLOR18_  equ     color+$24
COLOR19_  equ     color+$26
COLOR20_  equ     color+$28
COLOR21_  equ     color+$2A
COLOR22_  equ     color+$2C
COLOR23_  equ     color+$2E
COLOR24_  equ     color+$30
COLOR25_  equ     color+$32
COLOR26_  equ     color+$34
COLOR27_  equ     color+$36
COLOR28_  equ     color+$38
COLOR29_  equ     color+$3A
COLOR30_  equ     color+$3C
COLOR31_  equ     color+$3E

*******************************************************************************
*
* Interrupt vector tables
*
INTL2     equ     $68
INTL3     equ     $6C
INTL4     equ     $70
*
* INTENA bit definitions
*
INTF_AUD0 equ     $C080 ; set audio channel 0
INTF_AUD1 equ     $C100 ; set audio channel 1
INTF_AUD2 equ     $C200 ; set audio channel 2
INTF_AUD3 equ     $C400 ; set audio channel 3
INTF_AUD  equ     $C780 ; set all channels
INTF_NAUD0 equ    $0080 ; clear audio channel 0
INTF_NAUD1 equ    $0100 ; clear audio channel 1
INTF_NAUD2 equ    $0200 ; clear audio channel 2
INTF_NAUD3 equ    $0400 ; clear audio channel 3
INTF_NAUD equ     $0780 ; clear all audio channels
INTF_BLT  equ     $C040 ; set blitter
INTF_VBL  equ     $C020 ; set vertical blank
INTF_COP  equ     $C010 ; set copper
INTF_NBLT equ     $0040 ; clear blitter
INTF_NVBL equ     $0020 ; clear vertical blank
INTF_NCOP equ     $0010 ; clear copper
INTB_AUD0 equ     7     ; bit index audio 0
INTB_AUD1 equ     8     ; bit index audio 1
INTB_AUD2 equ     9     ; bit index audio 2
INTB_AUD3 equ     10    ; bit index audio 3
INTB_BLT  equ     6     ; bit index copper
INTB_VBL  equ     5     ; bit index vertical blank
INTB_COP  equ     4     ; bit index copper
*
* INTREQ bit definitions
*
INTR_DONE equ     $0020 ; interrupt processed
*
* DMACON bit definitions
*
DMAF_CLR  equ     $8000 ; set/clear bit
DMAF_PRI  equ     $8400 ; priority bit
DMAF_DMA  equ     $8200 ; master enable
DMAF_BPL  equ     $8300 ; bitplane enable
DMAF_COP  equ     $8280 ; copper enable
DMAF_BLT  equ     $8240 ; blitter enable
DMAF_SPR  equ     $8220 ; sprite enable
DMAF_DSK  equ     $8210 ; disk enable
DMAF_ALL  equ     $83E0 ; all but disk
DMAF_ALLN equ     $85E0 ; all but disk + pri bit
DMAF_ALLA equ     $83EF ; all but disk + audio
DMAF_AUD0 equ     $8201 ; enable aud0
DMAF_AUD1 equ     $8202 ; enable aud1
DMAF_AUD2 equ     $8204 ; enable aud2
DMAF_AUD3 equ     $8208 ; enable aud3
DMAF_AU23 equ     $820C ; enable aud2+3
DMAF_AUD  equ     $820F ; enable all audio
DMAF_NAUD equ     $000F ; disable all audio
*
* ADKCON bit definitions
*
ATPER3    equ     $8080 ; AUD3 -> nothing
ATPER2    equ     $8040 ; AUD2 -> PER3
ATPER1    equ     $8020 ; AUD1 -> PER2
ATPER0    equ     $8010 ; AUD0 -> PER1
ATVOL3    equ     $8008 ; AUD3 -> nothing
ATVOL2    equ     $8004 ; AUD2 -> VOL3
ATVOL1    equ     $8002 ; AUD1 -> VOL2
ATVOL0    equ     $8001 ; AUD0 -> VOL1
ATNMOD    equ     $00FF ; clear mod bits
*
* Blitter bit definitions: LINE mode
*
BC1_LINE  equ     $0001 ; BLTCON1 LINE MODE
BC1_SING  equ     $0002 ; BLTCON1 SINGle bit
BC1_AUL   equ     $0004 ; BLTCON1 AUL (always up/left)
BC1_SUD   equ     $0010 ; BLTCON1 SUD (up or down)
BC1_SUL   equ     $0008 ; BLTCON1 SUL (up or left)
BC1_SIGN  equ     $0040 ; BLTCON1 SIGN
BC1_TEXT  equ     $0C   ; BLTCON1 TEXTURE pos
BC1_SOL   equ     $0F00 ; BLTCON1 solid texture mask
BC1_DOT   equ     $0A00 ; BLTCON1 dot texture mask
BC1_DASH  equ     $0C00 ; BLTCON1 dash texture mask
BC0_LF    equ     $00   ; BLTCON0 LF pos
BC0_ST    equ     $0C   ; BLTCON0 START pos
BC0_LINE  equ     $0D00 ; BLTCON0 line bits 8-11
BC1_OCT0  equ     $0018 ; BLTCON1 octant 0 mask
BC1_OCT1  equ     $0004 ; BLTCON1 octant 1 mask
BC1_OCT2  equ     $000C ; BLTCON1 octant 2 mask
BC1_OCT3  equ     $001C ; BLTCON1 octant 3 mask
BC1_OCT4  equ     $0014 ; BLTCON1 octant 4 mask
BC1_OCT5  equ     $0008 ; BLTCON1 octant 5 mask
BC1_OCT6  equ     $0000 ; BLTCON1 octant 6 mask
BC1_OCT7  equ     $0010 ; BLTCON1 octant 7 mask
BC1_OCTM  equ     $001C ; BLTCON1 octant mask (all)
*
* Blitter bit definitions: AREA mode
*
BC1_DESC  equ     $0002 ; BLTCON1 DESCending mode
BC1_FCI   equ     $0004 ; BLTCON1 fill carry in
BC1_IFE   equ     $0008 ; BLTCON1 inclusive fill
BC1_EFE   equ     $0010 ; BLTCON1 exclusive fill
BC1_DOFF  equ     $0080 ; BLTCON1 DOFF
BC1_BSH   equ     $0C   ; BLTCON1 B shift pos
BC0_ASH   equ     $0C   ; BLTCON0 A shift pos
BC0_USEA  equ     $0800 ; BLTCON0 USEA bit
BC0_USEB  equ     $0400 ; BLTCON0 USEB bit
BC0_USEC  equ     $0200 ; BLTCON0 USEC bit
BC0_USED  equ     $0100 ; BLTCON0 USED bit
*
* Copper definitions and macros
*
CL_END    equ     $FFFFFFFE   ; END list
* write MOVE insn to \1 given reg offset \2 and value \3
C_MOVE    MACRO   
          move.w  #(\2),(\1)+
          move.w  \3,(\1)+  
          ENDM
* write WAIT insn to \1 given register pos \2 and mask \3 
C_WAITR   MACRO
          move.w  \2,(\1)+
          move.w  \3,(\1)+
          ENDM   
* write long copper insn to \1 from \2
C_INSN    MACRO
          move.l  \2,(\1)+
          ENDM
* write END insn to \1
C_ENDL    MACRO
          move.l  #CL_END,(\1)+
          ENDM   
*******************************************************************************
* CIA interfaces
*******************************************************************************
CIAA      equ   $BFE001
CIAB      equ   $BFD000
CIAPRA    equ   $0000
CIAPRB    equ   $0100
CIADDRA   equ   $0200
CIADDRB   equ   $0300
CIATALO   equ   $0400
CIATAHI   equ   $0500
CIATBLO   equ   $0600
CIATBHI   equ   $0700
CIATODLOW equ   $0800
CIATODMID equ   $0900
CIATODHI  equ   $0A00
CIASDR    equ   $0C00
CIAICR    equ   $0D00
CIACRA    equ   $0E00
CIACRB    equ   $0F00
