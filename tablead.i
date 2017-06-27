TABSIZEW    equ   32   ; waveform table size (words)
TABSIZELOG  equ   6    ; log table size (bytes)
TABSIZEB    equ   (1<<TABSIZELOG)

    SECTION amd,DATA
    CNOP    0,4
sawtab:
saw64:
    dc.b -126,-123,-119,-115,-111,-107,-103,-99
    dc.b -95,-91,-87,-83,-79,-75,-71,-67
    dc.b -63,-60,-56,-52,-48,-44,-40,-36
    dc.b -32,-28,-24,-20,-16,-12,-8,-4
    dc.b 0,4,8,12,16,20,24,28
    dc.b 32,36,40,44,48,52,56,60
    dc.b 64,67,71,75,79,83,87,91
    dc.b 95,99,103,107,111,115,119,123
saw32:
    dc.b -126,-119,-111,-103,-95,-87,-79,-71
    dc.b -63,-56,-48,-40,-32,-24,-16,-8
    dc.b 0,8,16,24,32,40,48,56
    dc.b 64,71,79,87,95,103,111,119
    dc.b -126,-119,-111,-103,-95,-87,-79,-71
    dc.b -63,-56,-48,-40,-32,-24,-16,-8
    dc.b 0,8,16,24,32,40,48,56
    dc.b 64,71,79,87,95,103,111,119
saw16:
    dc.b -126,-111,-95,-79,-63,-48,-32,-16
    dc.b 0,16,32,48,64,79,95,111
    dc.b -126,-111,-95,-79,-63,-48,-32,-16
    dc.b 0,16,32,48,64,79,95,111
    dc.b -126,-111,-95,-79,-63,-48,-32,-16
    dc.b 0,16,32,48,64,79,95,111
    dc.b -126,-111,-95,-79,-63,-48,-32,-16
    dc.b 0,16,32,48,64,79,95,111
saw8:
    dc.b -126,-95,-63,-32,0,32,64,95
    dc.b -126,-95,-63,-32,0,32,64,95
    dc.b -126,-95,-63,-32,0,32,64,95
    dc.b -126,-95,-63,-32,0,32,64,95
    dc.b -126,-95,-63,-32,0,32,64,95
    dc.b -126,-95,-63,-32,0,32,64,95
    dc.b -126,-95,-63,-32,0,32,64,95
    dc.b -126,-95,-63,-32,0,32,64,95

sintab:
sin64:
    dc.b 0,12,25,37,49,60,71,81
    dc.b 90,98,106,112,117,122,125,126
    dc.b 126,126,125,122,117,112,106,98
    dc.b 90,81,71,60,49,37,25,12
    dc.b 0,-12,-25,-37,-49,-60,-71,-81
    dc.b -90,-98,-106,-112,-117,-122,-125,-126
    dc.b -126,-126,-125,-122,-117,-112,-106,-98
    dc.b -90,-81,-71,-60,-49,-37,-25,-12
sin32:
    dc.b 0,25,49,71,90,106,117,125
    dc.b 126,125,117,106,90,71,49,25
    dc.b 0,-25,-49,-71,-90,-106,-117,-125
    dc.b -126,-125,-117,-106,-90,-71,-49,-25
    dc.b 0,25,49,71,90,106,117,125
    dc.b 126,125,117,106,90,71,49,25
    dc.b 0,-25,-49,-71,-90,-106,-117,-125
    dc.b -126,-125,-117,-106,-90,-71,-49,-25
sin16:
    dc.b 0,49,90,117,126,117,90,49
    dc.b 0,-49,-90,-117,-126,-117,-90,-49
    dc.b 0,49,90,117,126,117,90,49
    dc.b 0,-49,-90,-117,-126,-117,-90,-49
    dc.b 0,49,90,117,126,117,90,49
    dc.b 0,-49,-90,-117,-126,-117,-90,-49
    dc.b 0,49,90,117,126,117,90,49
    dc.b 0,-49,-90,-117,-126,-117,-90,-49
sin8:
    dc.b 0,90,126,90,0,-90,-126,-90
    dc.b 0,90,126,90,0,-90,-126,-90
    dc.b 0,90,126,90,0,-90,-126,-90
    dc.b 0,90,126,90,0,-90,-126,-90
    dc.b 0,90,126,90,0,-90,-126,-90
    dc.b 0,90,126,90,0,-90,-126,-90
    dc.b 0,90,126,90,0,-90,-126,-90
    dc.b 0,90,126,90,0,-90,-126,-90

sqtab:
sq64:
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
sq32:
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
sq16:
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
sq8:
    dc.b -126,-126,-126,-126,126,126,126,126
    dc.b -126,-126,-126,-126,126,126,126,126
    dc.b -126,-126,-126,-126,126,126,126,126
    dc.b -126,-126,-126,-126,126,126,126,126
    dc.b -126,-126,-126,-126,126,126,126,126
    dc.b -126,-126,-126,-126,126,126,126,126
    dc.b -126,-126,-126,-126,126,126,126,126
    dc.b -126,-126,-126,-126,126,126,126,126

sqrtab:
sqr64:
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
sqr32:
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
sqr16:
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
    dc.b 126,126,126,126,126,126,126,126
    dc.b -126,-126,-126,-126,-126,-126,-126,-126
sqr8:
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126

sqmtab:
sqm64:
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
sqm32:
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
sqm16:
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
sqm8:
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
    dc.b 126,126,126,126,-126,-126,-126,-126
