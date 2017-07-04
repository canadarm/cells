numpat      equ   15

;-----rule lists--------------
    SECTION amd,DATA
    CNOP    0,4
pattern:
    dc.w    0         ; current pattern
    CNOP    0,4
rulesl      equ   1   ; shift for rule index
rules:
    dc.b    109,0 ;0
    dc.b    32,1  ;1
    dc.b    150,0 ;2
    dc.b    110,0 ;3
    dc.b    161,0 ;4
    dc.b    165,0 ;5
    dc.b    165,0 ;6
    dc.b    15,1  ;7
    dc.b    9,0   ;8
    dc.b    9,0   ;9
    dc.b    120,0 ;10
    dc.b    18,1  ;11
    dc.b    125,1 ;12
    dc.b    131,0 ;13
    dc.b    153,0 ;14

;-----pattern bits--------
    CNOP    0,4
patsl       equ   4   ; shift for pattern index
patsizelog  equ   2   ; 8x8 patterns
patsize     equ   (1<<patsizelog)
patterns:
p109:
    dc.b    %11111000
    dc.b    %10001000
    dc.b    %10101000
    dc.b    %11111000
    dc.b    0,0,0,0      
    dc.b    %11111110
    dc.b    %10000010
    dc.b    %10111010
    dc.b    %11101110
    dc.b    0,0,0,0
p32:
    dc.b    %00000000
    dc.b    %01010000
    dc.b    %00100000
    dc.b    %00000000
    dc.b    0,0,0,0
    dc.b    %00000000
    dc.b    %10101000
    dc.b    %01010000
    dc.b    %00100000
    dc.b    0,0,0,0
p150:
    dc.b    %11111100
    dc.b    %01111000
    dc.b    %00110000
    dc.b    %00000000
    dc.b    0,0,0,0
    dc.b    %10000010
    dc.b    %01000100
    dc.b    %00101000
    dc.b    0,0,0,0,0
p110:
    dc.b    %11100000
    dc.b    %10100000
    dc.b    %11100000
    dc.b    0,0,0,0,0
    dc.b    %11111000
    dc.b    %10001000
    dc.b    %10010000
    dc.b    %10100000
    dc.b    %11000000
    dc.b    0,0,0
p161:
    dc.b    %11111000
    dc.b    %01110000
    dc.b    %00100000
    dc.b    %00000000
    dc.b    0,0,0,0
    dc.b    %00000000
    dc.b    %01100000
    dc.b    %00000000
    dc.b    0,0,0,0,0
p165:
    dc.b    %10100000
    dc.b    %11100000
    dc.b    %01000000
    dc.b    0,0,0,0,0
    dc.b    %00101000
    dc.b    %01111100
    dc.b    %00111000
    dc.b    %00000000
    dc.b    0,0,0,0
p165x:
    dc.b    %01000000
    dc.b    %10100000
    dc.b    %01000000
    dc.b    0,0,0,0,0
    dc.b    %01000000
    dc.b    %10100000
    dc.b    %01000000
    dc.b    0,0,0,0,0
p15:
    dc.b    %11000000
    dc.b    %00011100
    dc.b    0,0,0,0,0,0
    dc.b    %01000000
    dc.b    %10010000
    dc.b    %00100000
    dc.b    %01000000
    dc.b    0,0,0,0
p9:
    dc.b    %00000000
    dc.b    %01000000
    dc.b    %00000000
    dc.b    0,0,0,0,0
    dc.b    %11111000
    dc.b    %10000000
    dc.b    0,0,0,0,0,0
p9x:
    dc.b    %00000000
    dc.b    %01000000
    dc.b    %00000000
    dc.b    %01000000
    dc.b    %00000000
    dc.b    0,0,0
    dc.b    %11100000
    dc.b    %10000000
    dc.b    0,0,0,0,0,0
p120:
    dc.b    %10100000
    dc.b    %01010000
    dc.b    0,0,0,0,0,0
    dc.b    %10001000
    dc.b    %01001000
    dc.b    %00100000
    dc.b    %00010000
    dc.b    0,0,0,0
p18:
    dc.b    %10100000
    dc.b    %00010000
    dc.b    %10100000
    dc.b    0,0,0,0,0
    dc.b    %10101010
    dc.b    %00000001
    dc.b    %10000010
    dc.b    %01000100
    dc.b    %00101000
    dc.b    0,0,0
p125:
    dc.b    %10000010
    dc.b    %00001010
    dc.b    0,0,0,0,0,0
    dc.b    %10001000
    dc.b    %00101000
    dc.b    0,0,0,0,0,0
p131:
    dc.b    %00100000
    dc.b    %01000000
    dc.b    %10000000
    dc.b    0,0,0,0,0
    dc.b    %00000000
    dc.b    %11100000
    dc.b    %01000000
    dc.b    0,0,0,0,0
p153:
    dc.b    %00000000
    dc.b    %01100000
    dc.b    %01000000
    dc.b    0,0,0,0,0
    dc.b    %00000000
    dc.b    %11110000
    dc.b    %11100000
    dc.b    %11000000
    dc.b    %10000000
    dc.b    0,0,0
 
;-----masks-------------------
    SECTION amdc,DATA_C
    CNOP    0,4
masks:
mask45      equ   (*-masks)
    dc.b    %11111000
    dc.b    %11111000
    dc.b    %11111000
    dc.b    %11111000
    dc.b    0,0,0,0
mask32a     equ   (*-masks)
    dc.b    %01110000
    dc.b    %01110000
    dc.b    %01110000
    dc.b    %11111000
    dc.b    0,0,0,0
mask47      equ   (*-masks)
    dc.b    %11111110
    dc.b    %11111110
    dc.b    %11111110
    dc.b    %11111110
    dc.b    0,0,0,0
mask150     equ   (*-masks)
    dc.b    %11111100
    dc.b    %11111100
    dc.b    %01111000
    dc.b    %00000000
    dc.b    0,0,0,0
mask150b    equ   (*-masks)
    dc.b    %11111110
    dc.b    %01111100
    dc.b    %00111000
    dc.b    0,0,0,0,0
mask110b    equ   (*-masks)
    dc.b    %11111000
    dc.b    %11111000
    dc.b    %11110000
    dc.b    %11100000
    dc.b    %11000000
    dc.b    0,0,0
mask161a    equ   (*-masks)
    dc.b    %11111100
    dc.b    %11111000
    dc.b    %01110000
    dc.b    %00000000
    dc.b    0,0,0,0
mask34      equ   (*-masks)
    dc.b    %11110000
    dc.b    %11110000
    dc.b    %11110000
    dc.b    %00000000
    dc.b    0,0,0,0
mask33      equ   (*-masks)
    dc.b    %11100000
    dc.b    %11100000
    dc.b    %11100000
    dc.b    0,0,0,0,0
mask44      equ   (*-masks)
    dc.b    %11110000
    dc.b    %11110000
    dc.b    %11110000
    dc.b    %11110000
    dc.b    0,0,0,0
mask165b    equ   (*-masks)
    dc.b    %11111100
    dc.b    %11111100
    dc.b    %01111000
    dc.b    %00000000
    dc.b    0,0,0,0
mask165xa   equ   (*-masks)
    dc.b    %01100000
    dc.b    %11100000
    dc.b    %11000000
    dc.b    0,0,0,0,0
mask165xb   equ   (*-masks)
    dc.b    %11000000
    dc.b    %11100000
    dc.b    %01100000
    dc.b    0,0,0,0,0
mask15b     equ   (*-masks)
    dc.b    %01110000
    dc.b    %11110000
    dc.b    %11100000
    dc.b    %11000000
    dc.b    0,0,0,0
mask26      equ   (*-masks)
    dc.b    %11111100
    dc.b    %11111100
    dc.b    0,0,0,0,0,0
mask23      equ   (*-masks)
    dc.b    %11100000
    dc.b    %11100000
    dc.b    0,0,0,0,0,0
mask24      equ   (*-masks)
    dc.b    %11110000
    dc.b    %11110000
    dc.b    0,0,0,0,0,0
mask120a    equ   (*-masks)
    dc.b    %11100000
    dc.b    %01110000
    dc.b    0,0,0,0,0,0
mask120b    equ   (*-masks)
    dc.b    %11111000
    dc.b    %01111000
    dc.b    %00110000
    dc.b    %00010000
    dc.b    0,0,0,0
mask18a     equ   (*-masks)
    dc.b    %11100000
    dc.b    %11110000
    dc.b    %11100000
    dc.b    0,0,0,0,0
mask18b     equ   (*-masks)
    dc.b    %11111110
    dc.b    %11111111
    dc.b    %11111110
    dc.b    %01111100
    dc.b    %00111000
    dc.b    0,0,0
mask125a    equ   (*-masks)
    dc.b    %11111110
    dc.b    %00001110
    dc.b    0,0,0,0,0,0
mask125b    equ   (*-masks)
    dc.b    %11111000
    dc.b    %00111000
    dc.b    0,0,0,0,0,0
mask153a    equ   (*-masks)
    dc.b    %01110000
    dc.b    %11110000
    dc.b    %11100000
    dc.b    0,0,0,0,0
mask153b    equ   (*-masks)
    dc.b    %11111000
    dc.b    %11111000
    dc.b    %11110000
    dc.b    %11100000
    dc.b    %11000000
    dc.b    0,0,0
mask53      equ   (*-masks)
    dc.b    %11100000
    dc.b    %11100000
    dc.b    %11100000
    dc.b    %11100000
    dc.b    %11100000
    dc.b    0,0,0

;-----mask mappings-----------
    SECTION amdc,DATA_C
    CNOP    0,4
mmapsl      equ   2     ; shift for map index
mmap:
m109:
    dc.w    mask45 
    dc.w    mask47  
m32:
    dc.w    mask32a
    dc.w    mask45 
m150:
    dc.w    mask150 
    dc.w    mask150b
m110:
    dc.w    mask33
    dc.w    mask110b  
m161:
    dc.w    mask161a
    dc.w    mask34
m165:
    dc.w    mask33 
    dc.w    mask165b
m165x:
    dc.w    mask165xa
    dc.w    mask165xb
m15:
    dc.w    mask26
    dc.w    mask15b
m9:
    dc.w    mask33 
    dc.w    mask26
m9x:
    dc.w    mask53
    dc.w    mask24
m120:
    dc.w    mask120a 
    dc.w    mask120b
m18:
    dc.w    mask18a
    dc.w    mask18b 
m125:
    dc.w    mask125a
    dc.w    mask125b
m131:
    dc.w    mask33
    dc.w    mask33
m153:
    dc.w    mask153a
    dc.w    mask153b

;-----invert bits---------
invsl       equ   1     ; shift for inv index
invert:
b109:
    dc.b    1,1
b32:
    dc.b    0,0
b150:
    dc.b    0,1
b110:
    dc.b    0,1
b161:
    dc.b    0,1
b165: 
    dc.b    0,0
b165x: 
    dc.b    1,1
b15:
    dc.b    1,1
b9:
    dc.b    1,0
b9x:
    dc.b    1,0
b120:
    dc.b    1,1
b18:
    dc.b    1,1
b125:
    dc.b    1,1
b131:
    dc.b    0,0
b153:
    dc.b    0,0


