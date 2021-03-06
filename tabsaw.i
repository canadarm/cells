tabsizew    equ   16   ; waveform table size (words)
tabsize     equ   32   ; "" (bytes)
modsize     equ  128   ; mod table limit
    SECTION amdc,DATA_C
    CNOP    0,4
saw32:
    dc.b -127,-119,-111,-103,-95,-87,-79,-71
    dc.b -63,-56,-48,-40,-32,-24,-16,-8
    dc.b 0,8,16,24,32,40,48,56
    dc.b 64,71,79,87,95,103,111,119
sin32:
    dc.b 0,25,49,71,90,106,117,125
    dc.b 127,125,117,106,90,71,49,25
    dc.b 0,-25,-49,-71,-90,-106,-117,-125
    dc.b -127,-125,-117,-106,-90,-71,-49,-25
asin32:
    dc.b 0,49,90,117,126,117,90,49
    dc.b 0,49,90,117,126,117,90,49
    dc.b 0,-49,-90,-117,-126,-117,-90,-49
    dc.b 0,-49,-90,-117,-126,-117,-90,-49
sq32:
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
noise32:
    dc.b 97,-37,-31,-13,-84,-69,-60,54
    dc.b -1,-104,-105,38,25,-104,-51,61
    dc.b 99,120,-48,90,58,-93,-25,33
    dc.b 41,28,-122,112,6,-125,118,-3
mtab32:
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b 127,127,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,127,127
    dc.b 127,127,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,127,127,  0
    dc.b   0,127,127,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b 127,127,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0
    dc.b   0,  0,  0,  0,  0,  0,  0,  0

