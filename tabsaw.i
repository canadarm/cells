TABSIZE     equ   32   ; waveform table size (words)

    SECTION amdc,DATA_C
    CNOP    0,4
wav32:
    dc.b -127,-119,-111,-103,-95,-87,-79,-71
    dc.b -63,-56,-48,-40,-32,-24,-16,-8
    dc.b 0,8,16,24,32,40,48,56
    dc.b 64,71,79,87,95,103,111,119

