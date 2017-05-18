	IFND	DEVICES_KEYMAP_I
DEVICES_KEYMAP_I	=	1
	IFND	EXEC_NODES_I
	INCLUDE	exec/nodes.i
	ENDC
	IFND	EXEC_LISTS_I
	INCLUDE	exec/lists.i
	ENDC
	RSRESET
KeyMap		RS.B	0
km_LoKeyMapTypes	RS.L	1
km_LoKeyMap	RS.L	1
km_LoCapsable	RS.L	1
km_LoRepeatable	RS.L	1
km_HiKeyMapTypes	RS.L	1
km_HiKeyMap	RS.L	1
km_HiCapsable	RS.L	1
km_HiRepeatable	RS.L	1
km_SIZEOF	RS.W	0
	RSRESET
KeyMapNode	RS.B	0
kn_Node		RS.B	LN_SIZE
kn_KeyMap	RS.B	km_SIZEOF
kn_SIZEOF	RS.W	0
	RSRESET
KeyMapResource	RS.B	0
kr_Node		RS.B	LN_SIZE
kr_List		RS.B	LH_SIZE
kr_SIZEOF	RS.W	0
KCB_NOP		=	7
KCF_NOP		=	$80
KC_NOQUAL	=	0
KC_VANILLA	=	7
KCB_SHIFT	=	0
KCF_SHIFT	=	$01
KCB_ALT		=	1
KCF_ALT		=	$02
KCB_CONTROL	=	2
KCF_CONTROL	=	$04
KCB_DOWNUP	=	3
KCF_DOWNUP	=	$08
KCB_DEAD	=	5
KCF_DEAD	=	$20
KCB_STRING	=	6
KCF_STRING	=	$40
DPB_MOD		=	0
DPF_MOD		=	$01
DPB_DEAD	=	3
DPF_DEAD	=	$08
DP_2DINDEXMASK	=	$0F
DP_2DFACSHIFT	=	4
	ENDC
