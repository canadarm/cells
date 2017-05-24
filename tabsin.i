TABSIZE     equ   32   ; waveform table size (words)

    SECTION amdc,DATA_C
    CNOP    0,4
wav32:
    dc.b 0,25,49,71,90,106,117,125
    dc.b 127,125,117,106,90,71,49,25
    dc.b 0,-25,-49,-71,-90,-106,-117,-125
    dc.b -127,-125,-117,-106,-90,-71,-49,-25

