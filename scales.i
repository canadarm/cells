seqlenlog   equ 3
seqlen      equ (1<<seqlenlog)    ; seq max length in bytes 
seqcnt      equ 7                 ; number of modes
scalecnt    equ 6                 ; number of scales/leads
modelenlog  equ (seqlenlog+2)     ; mode block size (log)
modelen     equ (1<<modelenlog)

;-----sequence lists----------
    SECTION amd,DATA
    EVEN
root:       
    dc.b    0
    CNOP    0,4
modes:
mode1:
    dc.b    0,4,7,5,0,7,4,0
    dc.b    7,10,5,7,4,12,10,7
    dc.b    12,12,7,10,7,0,7,4
    dc.b    10,10,5,7,12,5,4,7
mode2:
    dc.b    0,7,0,5,-7,7,0,-5
    dc.b    0,-5,5,7,0,12,0,7
    dc.b    12,5,7,7,0,7,5,12 
    dc.b    12,5,7,12,5,0,7,12
mode3:
    dc.b    0,7,-5,5,3,7,9,-5
    dc.b    0,7,-5,5,3,7,9,-5
    dc.b    12,5,3,9,0,5,10,12
    dc.b    9,3,7,0,5,0,7,12
mode4:
    dc.b    0,7,-4,5,3,7,8,-5
    dc.b    0,0,12,7,0,3,0,8
    dc.b    12,5,8,0,10,5,7,12
    dc.b    8,3,7,8,5,0,7,12
mode5:
    dc.b    0,7,-5,4,2,7,7,-5
    dc.b    0,0,12,7,0,2,0,7
    dc.b    12,4,7,0,9,4,7,12
    dc.b    7,3,7,7,4,0,7,12
mode6:
    dc.b    0,7,-5,3,3,7,10,-5
    dc.b    3,0,12,7,0,2,5,10
    dc.b    12,3,7,0,8,3,7,12
    dc.b    7,2,7,7,3,0,7,12 
mode7:
    dc.b    0,6,-6,3,3,6,10,-6
    dc.b    3,0,12,8,0,1,5,10
    dc.b    12,3,6,0,8,3,6,12
    dc.b    8,7,10,3,3,0,8,12

;-----lead scales-------------
scales:
scale1:
    dc.b    6, 0,2,4,7,9,10,0
scale2:
    dc.b    6, 0,2,3,5,7,10,0
scale3:
    dc.b    6, 0,3,5,7,8,10,0
scale4:
    dc.b    6, 0,2,4,7,9,11,0
scale5:
    dc.b    5, 0,2,5,7,10,0,0
scale6:
    dc.b    7, 0,1,3,5,6,8,10

;-----period values-----------
    CNOP    0,4
ptab8:
    dc.w    1600, 1512, 1424, 1344, 1272, 1200, 1128, 1064
ptab:
ptab4:
    dc.w    1008, 952, 896, 848, 800, 756, 712, 672, 636, 600, 564, 532
ptab2:
    dc.w    504, 476, 448, 424, 400, 378, 356, 336, 318, 300, 282, 266
ptab1:
    dc.w    252, 238, 224, 212, 200, 189, 178, 168, 159, 150, 141, 133
ptab0:
    dc.w    126, 119, 112, 106, 100, 95, 89, 84, 80, 75, 71, 67

