_LVOSPAtan	=	-30
_LVOSPSin	=	-36
_LVOSPCos	=	-42
_LVOSPTan	=	-48
_LVOSPSincos	=	-54
_LVOSPSinh	=	-60
_LVOSPCosh	=	-66
_LVOSPTanh	=	-72
_LVOSPExp	=	-78
_LVOSPLog	=	-84
_LVOSPPow	=	-90
_LVOSPSqrt	=	-96
_LVOSPTieee	=	-102
_LVOSPFieee	=	-108
_LVOSPAsin	=	-114
_LVOSPAcos	=	-120
_LVOSPLog10	=	-126
CALLMATHTRANS	MACRO
	MOVE.L	_MathTransBase,A6
	JSR	_LVO\1(A6)
	ENDM
MATHTRANSNAME	MACRO
	DC.B	'mathtrans.library',0
	ENDM
