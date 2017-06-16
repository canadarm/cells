numpat      equ   12

;-----rule lists--------------
    SECTION amd,DATA
    CNOP    0,4
pattern:
    dc.w    0         ; current pattern
    CNOP    0,4
rulesl      equ   1   ; shift for rule index
rulen       equ   0   ; rule offset
rulep       equ   1   ; parity offset
rules:
    dc.b    109,0 
    dc.b    32,0
    dc.b    150,0
    dc.b    110,0
    dc.b    161,0
    dc.b    165,0
    dc.b    15,1
    dc.b    9,0
    dc.b    120,0
    dc.b    18,1
    dc.b    125,1
    dc.b    131,0

;-----pattern bits--------
    CNOP    0,4
patsl       equ   4   ; shift for pattern index
pat1        equ   0   ; offset of first
pat2        equ   8   ; offset of second
patsizelog  equ   2   ; 8x8 patterns
patsize     equ   (1<<patsizelog)
patterns:
p109:
    dc.b    %00000000
    dc.b    %01010000
    dc.b    %01110000
    dc.b    %00000000
    dc.b    0,0,0,0      
    dc.b    %00010000
    dc.b    %01000100
    dc.b    %01111100
    dc.b    %00000000
    dc.b    0,0,0,0
p32:
    dc.b    %11111111
    dc.b    %11011111
    dc.b    %10101111
    dc.b    %11111111
    dc.b    0,0,0,0
    dc.b    %11011111
    dc.b    %10101111
    dc.b    %01010111
    dc.b    %11111111
    dc.b    0,0,0,0
p150:
    dc.b    %11111111
    dc.b    %11000111
    dc.b    %10000011
    dc.b    %00000001
    dc.b    0,0,0,0
    dc.b    %00000000
    dc.b    %00111000
    dc.b    %01111100
    dc.b    %11111110
    dc.b    0,0,0,0
p110:
    dc.b    %01000000
    dc.b    %01100000
    dc.b    %01110000
    dc.b    %00000000
    dc.b    0,0,0,0
    dc.b    %01000000
    dc.b    %00100000
    dc.b    %00010000
    dc.b    %00001000
    dc.b    %00000000
    dc.b    0,0,0
p161:
    dc.b    %01001000
    dc.b    %10000100
    dc.b    %00000000
    dc.b    %11111100
    dc.b    0,0,0,0
    dc.b    %00010100
    dc.b    %00100010
    dc.b    %01000001
    dc.b    %00000000
    dc.b    %00000000
    dc.b    0,0,0
p165:
    dc.b    %10111111
    dc.b    %00011111
    dc.b    %01011111
    dc.b    0,0,0,0,0
    dc.b    %01010111
    dc.b    %10001111
    dc.b    %00000111
    dc.b    %01010111
    dc.b    0,0,0,0
p15:
    dc.b    %11000000
    dc.b    %01000000
    dc.b    %00100000
    dc.b    0,0,0,0,0
    dc.b    %00011111
    dc.b    %11000111
    dc.b    0,0,0,0,0,0
p9:
    dc.b    %01111111
    dc.b    %00011111
    dc.b    %11111111
    dc.b    0,0,0,0,0
    dc.b    %00011111
    dc.b    %01011111
    dc.b    %00011111
    dc.b    0,0,0,0,0
p120:
    dc.b    %01100000
    dc.b    %11000000
    dc.b    0,0,0,0,0,0
    dc.b    %00100000
    dc.b    %01100000
    dc.b    %11100000
    dc.b    %00000000
p18:
    dc.b    %00010000
    dc.b    %00111000
    dc.b    %01111100
    dc.b    %11111110
    dc.b    %01010100
    dc.b    0,0,0
    dc.b    %01110000
    dc.b    %00100000
    dc.b    0,0,0,0,0,0
p125:
    dc.b    %00000100
    dc.b    %01111100
    dc.b    0,0,0,0,0,0
    dc.b    %00100000
    dc.b    %01100000
    dc.b    0,0,0,0,0,0
p135:
    dc.b    %10100000
    dc.b    %11000000
    dc.b    %11100000
    dc.b    0,0,0,0,0
    dc.b    %01000000
    dc.b    %01100000
    dc.b    %00000000
    dc.b    0,0,0,0,0
 
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
mask47    equ   (*-masks)
    dc.b    %11111110
    dc.b    %11111110
    dc.b    %11111110
    dc.b    %11111110
    dc.b    0,0,0,0
mask150   equ   (*-masks)
    dc.b    %00000000
    dc.b    %01111110
    dc.b    %11111110
    dc.b    %11111110
    dc.b    0,0,0,0
mask110     equ   (*-masks)
    dc.b    %11110000
    dc.b    %11110000
    dc.b    %11110000
    dc.b    %11100000
    dc.b    0,0,0,0
mask110b    equ   (*-masks)
    dc.b    %11000000
    dc.b    %11100000
    dc.b    %11110000
    dc.b    %11111000
    dc.b    %11111000
    dc.b    0,0,0
mask161a    equ   (*-masks)
    dc.b    %01111000
    dc.b    %11111100
    dc.b    %11111100
    dc.b    %11111100
    dc.b    0,0,0,0
mask161b    equ   (*-masks)
    dc.b    %00011100
    dc.b    %00111110
    dc.b    %01111111
    dc.b    %11111111
    dc.b    0,0,0,0
mask33      equ   (*-masks)
    dc.b    %11100000
    dc.b    %11100000
    dc.b    %11100000
    dc.b    0,0,0,0,0
mask165     equ   (*-masks)
    dc.b    %01110000
    dc.b    %11111000
    dc.b    %11111000
    dc.b    %11111000
    dc.b    0,0,0,0
mask25      equ   (*-masks)
    dc.b    %11111000
    dc.b    %11111000
    dc.b    0,0,0,0,0,0
mask23      equ   (*-masks)
    dc.b    %11100000
    dc.b    %11100000
    dc.b    0,0,0,0,0,0
mask120     equ   (*-masks)
    dc.b    %01110000
    dc.b    %11110000
    dc.b    %11110000
    dc.b    %11110000
    dc.b    0,0,0,0
mask18a     equ   (*-masks)
    dc.b    %00111000
    dc.b    %01111100
    dc.b    %11111110
    dc.b    %11111110
    dc.b    %11111110
    dc.b    0,0,0
mask18b     equ   (*-masks)
    dc.b    %11111000
    dc.b    %01110000
    dc.b    0,0,0,0,0,0
mask125a    equ   (*-masks)
    dc.b    %11111110
    dc.b    %11111110
    dc.b    0,0,0,0,0,0
mask125b    equ   (*-masks)
    dc.b    %01100000
    dc.b    %11100000
    dc.b    0,0,0,0,0,0
mask131b    equ   (*-masks)
    dc.b    %11100000
    dc.b    %11100000
    dc.b    %01100000
    dc.b    0,0,0,0,0

;-----mask mappings-----------
    SECTION amdc,DATA_C
    CNOP    0,4
mmapsl      equ   2     ; shift for map index
map0        equ   0     ; offset of first
map1        equ   2     ; offset of second
mmap:
m109:
    dc.w    mask45 
    dc.w    mask47  
m32:
    dc.w    mask45 
    dc.w    mask45 
m150:
    dc.w    mask150 
    dc.w    mask150 
m110:
    dc.w    mask110 
    dc.w    mask110b  
m165:
    dc.w    mask33 
    dc.w    mask165 
m15:
    dc.w    mask33 
    dc.w    mask25 
m9:
    dc.w    mask33 
    dc.w    mask33 
m120:
    dc.w    mask23 
    dc.w    mask120 
m18:
    dc.w    mask18a 
    dc.w    mask18b 
m125:
    dc.w    mask125a 
    dc.w    mask125b 
m131:
    dc.w    mask33
    dc.w    mask131b

;-----invert bits---------
invsl       equ   1     ; shift for inv index
bit0        equ   0     ; offset of first
bit1        equ   1     ; offset of second
invert:
b109:
    dc.b    0,0
b32:
    dc.b    1,1
b150:
    dc.b    1,0
b110:
    dc.b    0,0
b161:
    dc.b    1,1
b165: 
    dc.b    1,1
b15:
    dc.b    0,1
b9:
    dc.b    1,1
b120:
    dc.b    0,0
b18:
    dc.b    0,0
b125:
    dc.b    0,0
b131:
    dc.b    1,1

