_LVOSPFix	=	-30
_LVOSPFlt	=	-36
_LVOSPCmp	=	-42
_LVOSPTst	=	-48
_LVOSPAbs	=	-54
_LVOSPNeg	=	-60
_LVOSPAdd	=	-66
_LVOSPSub	=	-72
_LVOSPMul	=	-78
_LVOSPDiv	=	-84
_LVOSPFloor	=	-90
_LVOSPCeil	=	-96
CALLFFP	MACRO
	MOVE.L	_MathBase,A6
	JSR	_LVO\1(A6)
	ENDM
FFPNAME	MACRO
	DC.B	'mathffp.library',0
	ENDM
