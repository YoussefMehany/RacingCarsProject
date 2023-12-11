
drawinitcar macro x,y,z           ;draw car at intial postion
    local intialcar
    mov ax, 320d
    mul y                            ; calculate number of pixel
    add ax,x
    mov di,ax
    sub di, (car_width / 2) + (car_height / 2) * 320                     ; get KeyLEFT KeyUPper pixel of car
    cld
    lea si,z                         ; set si as index of car pixels
    mov al,0
    mov dx,0
    intialcar:                       
    mov cx,car_width                         ; 5 width and 11 height
    rep movsb                         ; copy si (pixel color)  in di (pixel number)
    inc al
    add di, 320 - car_width
    cmp al,car_height
    jne intialcar                      
endm drawinitcar

checkCollapse macro
    local didntCollapse
    
    pusha
    mov ax, 320
    mul dx
    add ax, cx
    mov cx, 8
    xor dx, dx
    div cx
    mov bl, 10000000b    
    mov cl, dl
    shr bl, cl
    mov si, ax
    mov al, [pathfreq + si] 
    and al, bl
    cmp al, 0
    popa
    jz didntcollapse
    jmp codeBeginning

    didntcollapse:
endm checkCollapse

checkTurnCollapse macro
    local dir_Checker, dir_firstPixel, dir_CheckCollapseBothPixels, dir_CheckColl, dir_nextPixel, dir_didntcoll, dir_safeline, switchCol, switchRow, lp
    dir_Checker:
        mov bothPixels, 2

        dir_firstPixel:
        mov cx, x1     ; Column
        mov dx, y1     ; Row

        dir_checkCollapseBothPixels:
        mov bx, trackWidth + smallMargin + 1 ;so path is a bit far than the other

        dir_checkColl:
        push si
        mov si, curDirection
        add cx, [pathDirection_X + si]
        add dx, [pathDirection_Y + si]
        pop si
        pusha
        mov ax, 320
        mul dx
        add ax, cx
        mov cx, 8
        xor dx, dx
        div cx
        mov bl, 10000000b    
        mov cl, dl
        shr bl, cl
        mov si, ax
        mov al, [pathfreq + si] 
        and al, bl
        cmp al, 0
        popa
        jz dir_didntColl
        push si
        mov si, [curdirection]
        mov [blockeddirx + si], 1
        pop si
        jmp outer
        dir_didntColl:
        dec bx
        jz dir_nextPixel
        jmp dir_checkColl
        dir_nextPixel:
        dec [bothPixels]
        cmp bothPixels, 0
        jz dir_safeline
        cmp ud, 1
        jz switchCol
        switchRow:
        mov cx, x1    ; Column
        mov dx, y2   ; Row
        jmp lp
        switchCol:
        mov cx, x2    ; Column
        mov dx, y1   ; Row
        lp:
        jmp dir_checkCollapseBothPixels


        dir_safeLine:
endm checkTurnCollapse

drawBox macro x,y,c,s
    local lopdp
    mov ax,320
    mul y
    add ax,x
    mov di,ax
    mov bx,2
    mov ax,s
    div bx
    mov bx,ax
    mov ax,320
    mul bx
    sub di,ax
    sub di,bx
    mov al,c
    mov cx,s
    mov bx,s
    lopdp:
    mov es:[di],al
    inc di
    dec cx
    cmp cx,0
    jne lopdp
    add di,320
    sub di,s
    mov cx,s
    dec bx
    cmp bx,0
    jne lopdp
endm drawBox

checkSmallBoxColor macro x,y,c,s,chkr
    local checkdb,finishcheckdb,contcheckdb
    mov ax,320
    mul y
    add ax,x
    mov si,ax
    mov bx,2
    mov ax,s
    div bx
    mov bx,ax
    mov ax,320
    mul bx
    sub si,ax
    sub si,bx
    mov cx,s
    mov bx,s
    checkdb:
    mov al,es:[si]
    cmp al,c
    je contcheckdb
    mov chkr,1
    jmp finishcheckdb
    contcheckdb:
    inc si
    dec cx
    cmp cx,0
    jne checkdb
    add si,320
    sub si,s
    mov cx,s
    dec bx
    cmp bx,0
    jne checkdb
    mov chkr,0
    finishcheckdb:
endm checkSmallBoxColor

.286
.MODEL large
.STACK 128


.DATA

;---------------------CARDATA---------------

car_width equ 5
car_height equ 11

clicked db 0

canmovecara db 0d

canmovecarb db 0d

colorcara db 39
colorcarb db 9

car1image DB 39, 39, 39, 39, 39, 39, 20, 39, 20, 39, 16, 16, 39, 16, 16, 16
          DB 16, 39, 16, 16, 20, 39, 16, 39, 20, 20, 39, 16, 39, 20, 20, 39
          DB 16, 39, 20, 20, 39, 39, 39, 20, 16, 16, 39, 16, 16, 16, 16, 39, 16, 16, 39, 39, 39, 39, 39



car2image DB 9, 9, 9, 9, 9, 9, 20, 9, 20, 9, 16, 16, 9, 16, 16, 16, 16
          DB 9, 16, 16, 20, 9, 16, 9, 20, 20, 9, 16, 9, 20, 20, 9, 16, 9
          DB 20, 20, 9, 9, 9, 20, 16, 16, 9, 16, 16, 16, 16, 9, 16, 16, 9, 9, 9, 9, 9


; OLD  <  center of car a  > and position

xa dw smallmargin + 5   
ya dw verticalScreen - 5 - smallMargin 
posita db 'w'

velocitya dw 1

delaycara dw 0

; <NEW>


xna dw smallmargin + 5   
yna dw verticalScreen - 5 - smallMargin   
positna db 'w'

;OLD  <  center of car b  > and position

xb dw smallmargin + 12    
yb dw verticalScreen - 5 - smallMargin  
positb db 'w'

velocityb dw 1

delaycarb dw 0

;   <NEW>

xnb dw smallmargin + 12   
ynb dw verticalScreen - 5 - smallMargin   
positnb db 'w'


xBlack dw 00d
yBlack dw 00d
positToCompare db 0d
carToUse db 0d
obstacleA db 0d
obstacleB db 0d
canDraw db 0d
HaveSpeedA db 0d
ActivateSpeedA db 0d
HaveSpeedB db 0d
ActivateSpeedB db 0d
StartTimeSpeedA db 0d
StartTimeSpeedB db 0d
StartDelayA db 0d
StartDelayB db 0d
HaveDelayA db 0d
HaveDelayB db 0d
ActivateDelayB db 00d
ActivateDelayA db 00d
TemporaryPixle dw 0d
TemporaryColor db 0d
HavePassA db 0d
ActivatePassA db 00d
HavePassB db 0d
ActivatePassB db 00d
BlockWidth db 3d
BlockLength db 3d
BlockWidth2 dw 3d
BlockLength2 dw 3d

; <rocket>

keyf equ 21h
keyl equ 26h

xrocket dw 0d
yrocket dw 0d
xn1rocket dw 100d
yn1rocket dw 100d
xnrocket dw 100d
ynrocket dw 100d
positionrocket db 'w'
FreezeEnd db 0d

colorclearrocket db 08h
colordrawrocket  db 0eh

firecara dw 1
firecarb dw 1

rocketmoving dw 0

isrocketcollision dw 0
whatrocketcollision dw 'a'





; <scan key of wasd>
KeyW equ 11h
KeyS equ 1fh
KeyD equ 20h
KeyA equ 1eh

; <scan key of arrows>

KeyUP equ 48h
KeyDOWN equ 50h
KeyRIGHT equ 4Dh
KeyLEFT equ 4Bh

; <scan key for Car A powers>
KeyP equ 19h
KeyO equ 18h
KeyI equ 17h
KeyU equ 16h

; <scan key for Car B powers>
Key1 equ 02h
Key2 equ 03h
Key3 equ 04h
Key4 equ 05h


KeyEsc    equ 01h



keylist db 128 dup (0)

;---------------------------PATHDATA---------------------------


pathCount equ 70d
trackWidth equ 16d
streetLength equ 10d
finishLength equ 6d
alternatingFinish equ 2d
verticalScreen equ 160d
horizontalScreen equ 320d
smallmargin equ 5d
pathsize equ 5000
obstacleDim equ 5
powerupsDim equ 3
obsProb equ 3
powerupProb equ 1
obsColor equ 4
powerUpsColor equ 3
up equ 0
down equ 2
left equ 4
right equ 6
speedPower equ 1d ;blue
slowDownPower equ 2d ;green
placeWall equ 3d ;cyan
passWall equ 5d ;magenta
rocketPower equ 13d ;light magenta
randomNum dw ?

curStCol dw ?
curStRow dw ?
curEnCol dw ?
curEnRow dw ?

minx dw ?
maxx dw ?
miny dw ?
maxy dw ?

msg db 'Creating the racing track..$'

newDirection dw 0

pathDrawn dw 0 ;bool to check if a path is drawn
suitableStreet dw 0

pathDirection_X dw 0, 0, -1, 1
pathDirection_Y dw -1, 1, 0, 0
pathOpposites dw -1, 1, -2, 2
curDirection dw up; see directions above, set starting direction here
prevDirection dw up

extraPathDirection_X dw 1, -1, -1, 1 
extraPathDirection_Y dw -1, 1, -1, 1
xMul dw 0
yMul dw 0


i dw 0
j dw 0
firstColor db 15d
secondColor db 0d
firstLineCounter dw 0
secondLineCounter dw 0

;path array
curIdx dw 0
savedDirections dw pathsize dup(?)
pathLine1_X dw pathsize dup(?)
pathLine1_Y dw pathsize dup(?)
pathLine2_X dw pathsize dup(?)
pathLine2_Y dw pathsize dup(?)
pathFreq db 8192 dup(0) ;8k frequency array path


bothPixels db ?
blockedDirx dw 4 dup(0)
blkdOpposites dw 2, 0, 6, 4
x1 dw ?
x2 dw ?
y1 dw ?
y2 dw ?
ud db ?

dontDraw db ?

boxProb db ?
isObs db ?
boxDim db ?
halfBox db ?
boxDrawn db ?
boxDirection dw (obstacleDim + 1) / 2, -(obstacleDim + 1) / 2, (obstacleDim + 1) / 2, -(obstacleDim + 5) / 2
obsdrawn db 0
powerupsdrawn db 0
powerUpsRand db speedPower, slowDownPower, placeWall, passWall, rocketPower
chkboolBox db 0
sc db ? ;block check color

xBox dw ?
yBox dw ?
cBox db ?
sBox dw ?
sBoxBigger dw ?


.CODE

;---------------------------------CAR_PROCS----------------------------------------

;;; clear position of car a

clearcara proc
    mov ax,320d
    mul ya
    add ax,xa
    mov di,ax
    cmp posita,'d'
    je clearcaraRL                      ; chceck if the car horizontal not vertical 
    cmp posita,'a'
    je clearcaraRL
    sub di,(car_width / 2) + 320 * (car_height / 2)                      ; clear car in vertical view
    mov al,08h
    mov cl,0
    mov ch,0
    caraclrKeyUPD:
    cmp ch,11
    je finishcaraclr
    mov es:[di],al
    cmp cl,car_width-1
    je caratoclrKeyUPD
    inc di
    inc cl
    jmp caraclrKeyUPD
    caratoclrKeyUPD:
    add di, 320 - car_width + 1
    mov cl,0
    inc ch
    jmp caraclrKeyUPD
    clearcaraRL:                                   ; clear car in horizontal view 
    sub di, (car_width / 2) * 320 - car_height / 2
    mov al,08h
    mov cl,0
    mov ch,0
    caraclrRL:
    cmp ch,11
    je finishcaraclr
    mov es:[di],al
    cmp cl,car_width-1
    je caratoclrRL
    add di,320
    inc cl
    jmp caraclrRL
    caratoclrRL:
    sub di,(car_width - 1) * 320 + 1
    mov cl,0
    inc ch
    jmp caraclrRL
    finishcaraclr:
    ret
clearcara endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; draw car a at position (KeyUP_KeyDOWN);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DRAWCARAKeyUPKeyDOWN PROC 
    mov ax,320d
    mul ya
    add ax,xa
    mov di,ax
    sub di,(car_width / 2) + 320 * (car_height / 2)
    lea si,car1image
    cld
    cmp posita,'s'
    jne DRAWCARAKeyDOWN1
    std
    add si,car_width * car_height - 1
    DRAWCARAKeyDOWN1:
    mov ax,0
    dcaraKeyUP:                 
    mov cx,1
    rep movsb
    cmp posita,'s'
    jne DRAWCARAKeyDOWN2
    add di,2
    DRAWCARAKeyDOWN2:
    inc al
    cmp al,car_width
    jne dcaraKeyUP
    inc ah
    add di,320 - car_width
    mov al,0
    cmp ah,car_height
    jne dcaraKeyUP
    ret
DRAWCARAKeyUPKeyDOWN ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; draw car a at position (KeyRIGHT_KeyLEFT);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearBlock proc
  mov al,es:[si]
  mov TemporaryColor,al
  cmp TemporaryColor,4
  jne go
  mov BlockWidth,5d
  mov BlockLength,5d
   mov BlockWidth2,5d
  mov BlockLength2,5d
  jmp red
  go:
  mov BlockWidth,3d
  mov BlockLength,3d
   mov BlockWidth2,3d
  mov BlockLength2,3d
  red:
  l1:
  add si,320d
  mov al,es:[si]
  cmp al,TemporaryColor
  je l1
  sub si,320d
  l2:
  dec si
  mov al,es:[si]
  cmp al,TemporaryColor
  je l2
  inc si
  l3:
  sub si,320d
  mov al,es:[si]
  cmp al,TemporaryColor
  je l3
  add si,320d
  mov bl,BlockWidth
  mov bh,BlockLength
  mov di,si
  mov si,TemporaryPixle
  clear:
  mov es:[di],8d
  dec bl
  inc di
  cmp bl,0
  jne clear
  dec bh
  mov bl,BlockWidth
  add di,320d
  sub di,BlockLength2
  cmp bh,0
  jne clear

ret
ClearBlock endp

DRAWCARAKeyRIGHTKeyLEFT PROC 
    mov ax,320d
    mul ya
    add ax,xa
    mov di,ax
    sub di,(car_width / 2) * 320 - car_height / 2
    cld
    lea si,car1image
    cmp posita,'d'
    je DRAWCARAKeyLEFT1
    std
    add si,car_height * car_width - 1
    DRAWCARAKeyLEFT1:
    mov ax,0
    dcaraR1: 
    mov cx,1                
    rep movsb
    cmp posita,'d'
    je DRAWCARAKeyLEFT2
    add di,321d
    jmp DRAWCARAKeyLEFT3
    DRAWCARAKeyLEFT2:
    add di,319d
    DRAWCARAKeyLEFT3:
    inc al
    cmp al,car_width
    jne dcaraR1
    sub di,car_width * 320 + 1
    inc ah
    mov al,0
    cmp ah,car_height
    jne dcaraR1
    ret
DRAWCARAKeyRIGHTKeyLEFT ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; check position (KeyUP_KeyDOWN);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


checkmovecaraKeyUPKeyDOWN proc
    mov ax,320d
    mul yna
    add ax,xna
    mov si,ax
    sub si,(car_width / 2) + 320 * (car_height / 2)
    mov al,0
    mov cl,car_width
    mov ch,car_height
    checkpixels1:
    mov al,es:[si]
    cmp al,08h
    jne checkspeed1
    jmp contcheck1
    checkspeed1:
    cmp al,1d
    jne checkdelay1
    mov HaveSpeedA,1
    mov obstacleA,0
    mov HaveDelayA,0
    mov HavePassA,0
    mov TemporaryPixle,si
    jmp clearB1
    checkdelay1:
    cmp al,2d
    jne checkwallplace1
    mov HaveSpeedA,0
    mov obstacleA,0
    mov HaveDelayA,1
    mov HavePassA,0
    mov TemporaryPixle,si
    jmp clearB1
    checkwallplace1:
    cmp al,3d
    jne checkwallpass1
    mov HaveSpeedA,0
    mov obstacleA,1
    mov HaveDelayA,0
    mov HavePassA,0
    mov TemporaryPixle,si
    jmp clearB1
    checkwallpass1:
    cmp al,5d
    jne checkwallexist1
    mov HaveSpeedA,0
    mov obstacleA,0
    mov HaveDelayA,0
    mov HavePassA,1
    mov TemporaryPixle,si
    jmp clearB1
    checkwallexist1:
    cmp al,4d
    jne therepixelnotblack1
    cmp ActivatePassA,1
    jne therepixelnotblack1
    mov ActivatePassA,0d
    mov TemporaryPixle,si
    clearB1:
    call ClearBlock
    contcheck1:
    inc si
    dec cl
    cmp cl,0
    je c1
    jmp checkpixels1
    c1:
    add si,315d
    mov cl,5
    dec ch
    cmp ch,0
    je c2
    jmp checkpixels1
    c2:
    mov canmovecara,0
    jmp finishcheckmovecaraKeyUPKeyDOWN
    therepixelnotblack1:
    mov canmovecara,1
    finishcheckmovecaraKeyUPKeyDOWN: 
    ret
checkmovecaraKeyUPKeyDOWN endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; check position (KeyRIGHT_KeyLEFT);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


checkmovecaraKeyRIGHTKeyLEFT proc
    mov ax,320d
    mul yna
    add ax,xna
    mov si,ax
    sub si,(car_width / 2) * 320 - car_height / 2
    mov al,0
    mov cl,car_width
    mov ch,car_height
    checkpixels2:
    mov al,es:[si]
    cmp al,08h
    jne checkspeed3
    jmp contcheck3
    checkspeed3:
    cmp al,1d
    jne checkdelay3
    mov HaveSpeedA,1
    mov obstacleA,0
    mov HaveDelayA,0
    mov HavePassA,0
    mov TemporaryPixle,si
    jmp clearB3
    checkdelay3:
    cmp al,2d
    jne checkwallplace3
    mov HaveSpeedA,0
    mov obstacleA,0
    mov HaveDelayA,1
    mov HavePassA,0
    mov TemporaryPixle,si
    jmp clearB3
    checkwallplace3:
    cmp al,3d
    jne checkwallpass3
    mov HaveSpeedA,0
    mov obstacleA,0
    mov HaveDelayA,0
    mov HavePassA,1
    mov TemporaryPixle,si
    jmp clearB3
    checkwallpass3:
    cmp al,5d
    jne checkwallexist3
    mov HaveSpeedA,0
    mov obstacleA,0
    mov HaveDelayA,0
    mov HavePassA,1
    mov TemporaryPixle,si
    jmp clearB3
    checkwallexist3:
    cmp al,4d
    jne therepixelnotblack2
    cmp ActivatePassA,1
    jne therepixelnotblack2
    mov ActivatePassA,0d
    mov TemporaryPixle,si
    clearB3:
    call ClearBlock
    contcheck3:
    add si,320
    dec cl
    cmp cl,0
    je cc1
    jmp checkpixels2
    cc1:
    sub si,car_width * 320 + 1
    mov cl,car_width
    dec ch
    cmp ch,0
    je cc2
    jmp checkpixels2
    cc2:
    mov canmovecara,0
    jmp finishcheckmovecaraKeyRIGHTKeyLEFT
    therepixelnotblack2:
    mov canmovecara,1
    finishcheckmovecaraKeyRIGHTKeyLEFT: 
    ret
checkmovecaraKeyRIGHTKeyLEFT endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; check All position ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


checkcanmovecara proc

    cmp positna,'s'
    jne labelcheckcanmovecaraKeyDOWN
    call checkmovecaraKeyUPKeyDOWN  
    jmp labelfinishcheckcanmovecara

    labelcheckcanmovecaraKeyDOWN:

    cmp positna,'w'
    jne labelcheckcanmovecaraKeyUP
    call checkmovecaraKeyUPKeyDOWN
    jmp labelfinishcheckcanmovecara

    labelcheckcanmovecaraKeyUP:

    cmp positna,'d'
    jne labelcheckcanmovecaraKeyRIGHT
    call checkmovecaraKeyRIGHTKeyLEFT
    jmp labelfinishcheckcanmovecara

    labelcheckcanmovecaraKeyRIGHT:

    call checkmovecaraKeyRIGHTKeyLEFT

    labelfinishcheckcanmovecara:
    ret
checkcanmovecara endp



checkDoubleButtonsKeyUPcara proc
    mov al,0
    add al, [byte ptr keylist + KeyW]
    add al, [byte ptr keylist + KeyS]
    add al, [byte ptr keylist + KeyD]
    add al, [byte ptr keylist + KeyA]
    cmp ax,2
    jb finishcheckDoubleButtonsKeyUPcara
    mov al,posita
    mov positna,al
    finishcheckDoubleButtonsKeyUPcara:
  ret
checkDoubleButtonsKeyUPcara endp

launchrocketcara proc
    mov ax,xa
    mov cx,ya
    mov dl,posita
    cmp posita,'w'
    jne launchwcara
    sub cx,car_width+2
    jmp contlaunchcara
    launchwcara:
    cmp posita,'s'
    jne launchscara
    add cx,car_width+2
    jmp contlaunchcara
    launchscara:
    cmp posita,'d'
    jne launchdcara
    add ax,car_width+2
    jmp contlaunchcara
    launchdcara:
    sub ax,car_width+2
    contlaunchcara:
    mov xn1rocket,ax
    mov yn1rocket,cx
    mov xnrocket,ax
    mov ynrocket,cx
    mov positionrocket,dl
    mov rocketmoving,1
  ret
launchrocketcara endp



movecarA PROC       ; check the new position of car a
    mov velocitya,1
    cmp ActivateSpeedA,1
    jne nospeed
    mov velocitya,2
    nospeed:
    cmp delaycara,0
    je contdelaycara
    jmp far ptr finishmovebwithdelaycara
    contdelaycara:
    cmp ActivateDelayA,1
    jne nodelay2
    mov delaycara,1
    mov ah,2ch   
    int 21h
    cmp StartDelayB,dh
    je nodelay2
    mov delaycara,1
    jmp movcont2
    nodelay2:
    mov delaycara,0
    mov ActivateDelayA,0
    movcont2:
    cmp [byte ptr keylist + keyf], 1
    jne norocketpresscara
    cmp firecara,1
    jne norocketpresscara
    ; mov firecara,0
    call launchrocketcara
    norocketpresscara:
    mov ax,velocitya
    cmp [byte ptr keylist + KeyW], 1
    jne ks
    mov positna,'w'
    sub yna,ax
    ks:
    cmp [byte ptr keylist + KeyS], 1
    jne kd
    mov positna,'s'
    add yna,ax                                       
    kd:                                         ; check new position  and store it in positna
    cmp [byte ptr keylist + KeyD], 1
    jne ka
    mov positna,'d'
    add xna,ax
    ka:
    cmp [byte ptr keylist + KeyA], 1
    jne conta
    mov positna,'a'
    sub xna,ax
    conta:

    call checkDoubleButtonsKeyUPcara

    mov ax,xna
    mov cx,yna
    mov dl,positna
    cmp ax,xa
    jne checkmovcara                            ; check if new position equal l previous position skip (no clear and no draw)
    cmp cx,ya
    jne checkmovcara
    jmp finishmovea



    checkmovcara:
    call clearcara

    mov canmovecara,0
    call checkcanmovecara                             ; check if car can move to next position or not 
    cmp canmovecara,1                                 ; if not draw at previous position
    je labelcantmovecara

    mov ax,xna
    mov cx,yna
    mov dl,positna                                     ; move new position to previous position 
    mov xa,ax
    mov ya,cx


    cmp positna,'s'
    jne notKeyDOWNcarafromKeyUP
    cmp posita,'w'
    je notKeyDOWNcarafromKeyUP                               ; if car move KeyUP then KeyDOWN  (erg3 bdhro bdl mylf )
    mov posita,dl
    call DRAWCARAKeyUPKeyDOWN
    jmp finishmovea

    notKeyDOWNcarafromKeyUP:

    cmp positna,'w'
    jne notKeyUPcarafromKeyDOWN
    cmp posita,'s'
    je notKeyUPcarafromKeyDOWN                                    ; if car move KeyDOWN then KeyUP  (erg3 bdhro bdl mylf )
    mov posita,dl
    call DRAWCARAKeyUPKeyDOWN
    jmp finishmovea

    notKeyUPcarafromKeyDOWN:

    cmp positna,'d'
    jne notKeyRIGHTcarafromKeyLEFT
    cmp posita,'a'
    je notKeyRIGHTcarafromKeyLEFT                                 ; if car move KeyRIGHT then KeyLEFT  (erg3 bdhro bdl mylf )
    mov posita,dl
    call DRAWCARAKeyRIGHTKeyLEFT
    jmp finishmovea 

    notKeyRIGHTcarafromKeyLEFT:

    cmp positna,'a'
    jne notKeyLEFTcarafromKeyRIGHT
    cmp posita,'d'
    je notKeyLEFTcarafromKeyRIGHT                                 ; if car move KeyLEFT then KeyRIGHT  (erg3 bdhro bdl mylf )
    mov posita,dl
    call DRAWCARAKeyRIGHTKeyLEFT
    jmp finishmovea 

    labelcantmovecara:
    mov ax,xa
    mov cx,ya
    mov xna,ax                                           ; move new position to previous position
    mov yna,cx

    notKeyLEFTcarafromKeyRIGHT:

    cmp posita,'w'
    jne Dcad
    call DRAWCARAKeyUPKeyDOWN
    jmp finishmovea
    dcad:
    cmp posita,'s'
    jne Dcar
    call DRAWCARAKeyUPKeyDOWN                                  ; draw car 
    jmp finishmovea                                              
    dcar:
    cmp posita,'d'
    jne Dcal
    call DRAWCARAKeyRIGHTKeyLEFT
    jmp finishmovea
    Dcal:
    call DRAWCARAKeyRIGHTKeyLEFT
    jmp finishmovea

    finishmovebwithdelaycara:
    dec delaycara
    finishmovea:

    ret
movecarA ENDP


; clear position of car b 


clearcarb proc
    mov ax,320d
    mul yb
    add ax,xb
    mov di,ax
    cmp positb,'d'
    je clearcarbRL
    cmp positb,'a'
    je clearcarbRL
    sub di,(car_width / 2) + 320 * (car_height / 2) 
    mov al,08h
    mov cl,0
    mov ch,0
    carbclrKeyUPD:
    cmp ch,car_height
    je finishcarbclr
    mov es:[di],al
    cmp cl,car_width-1
    je carbtoclrKeyUPD
    inc di
    inc cl
    jmp carbclrKeyUPD
    carbtoclrKeyUPD:
    add di,320 - car_width + 1
    mov cl,0
    inc ch
    jmp carbclrKeyUPD
    clearcarbRL:
    sub di,(car_width / 2) * 320 - car_height / 2
    mov al,08h
    mov cl,0
    mov ch,0
    carbclrRL:
    cmp ch,car_height
    je finishcarbclr
    mov es:[di],al
    cmp cl,car_width-1
    je carbtoclrRL
    add di,320
    inc cl
    jmp carbclrRL
    carbtoclrRL:
    sub di,(car_width - 1) * 320 + 1
    mov cl,0
    inc ch
    jmp carbclrRL
    finishcarbclr:
    ret
clearcarb endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; draw car b at position (KeyUP_KeyDOWN);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DRAWCARBKeyUPKeyDOWN PROC 
    mov ax,320d
    mul yb
    add ax,xb
    mov di,ax
    sub di,(car_width / 2) + 320 * (car_height / 2)
    lea si,car2image
    cld
    cmp positb,'s'
    jne DRAWCARBKeyDOWN1
    std
    add si,car_width * car_height - 1
    DRAWCARBKeyDOWN1:
    mov ax,0
    dcarbKeyUP:                 
    mov cx,1
    rep movsb
    cmp positb,'s'
    jne DRAWCARBKeyDOWN2
    add di,2
    DRAWCARBKeyDOWN2:
    inc al
    cmp al,car_width
    jne dcarbKeyUP
    inc ah
    add di,320 - car_width
    mov al,0
    cmp ah,car_height
    jne dcarbKeyUP
    ret
DRAWCARBKeyUPKeyDOWN ENDP




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; draw car b at position (KeyRIGHT_KeyLEFT);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DRAWCARBKeyRIGHTKeyLEFT PROC 
    mov ax,320d
    mul yb
    add ax,xb
    mov di,ax
    sub di,(car_width / 2) * 320 - car_height / 2
    cld
    lea si,car2image
    cmp positb,'d'
    je DRAWCARBKeyLEFT1
    std
    add si,car_height * car_width - 1
    DRAWCARBKeyLEFT1:
    mov ax,0
    dcarbR1: 
    mov cx,1                
    rep movsb
    cmp positb,'d'
    je DRAWCARBKeyLEFT2
    add di,321d
    jmp DRAWCARBKeyLEFT3
    DRAWCARBKeyLEFT2:
    add di,319d
    DRAWCARBKeyLEFT3:
    inc al
    cmp al,car_width
    jne dcarbR1
    sub di,car_width * 320 + 1
    inc ah
    mov al,0
    cmp ah,car_height
    jne dcarbR1
    ret
DRAWCARBKeyRIGHTKeyLEFT ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; check position (KeyUP_KeyDOWN);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


checkmovecarbKeyUPKeyDOWN proc
    mov ax,320d
    mul ynb
    add ax,xnb
    mov si,ax
    sub si,(car_width / 2) + 320 * (car_height / 2)
    mov al,0
    mov cl,car_width
    mov ch,car_height
    checkpixels1carb:
    mov al,es:[si]
    cmp al,08h
    jne checkspeed
    jmp contcheck
    checkspeed:
    cmp al,1d
    jne checkdelay
    mov HaveSpeedB,1
    mov obstacleB,0
    mov HaveDelayB,0
    mov HavePassB,0
    mov TemporaryPixle,si
    jmp clearB
    checkdelay:
    cmp al,2d
    jne checkwallplace
    mov HaveSpeedB,0
    mov obstacleB,0
    mov HaveDelayB,1
    mov HavePassB,0
    mov TemporaryPixle,si
    jmp clearB
    checkwallplace:
    cmp al,3d
    jne checkwallpass
    mov HaveSpeedB,0
    mov obstacleB,1
    mov HaveDelayB,0
    mov HavePassB,0
    mov TemporaryPixle,si
    jmp clearB
    checkwallpass:
    cmp al,5d
    jne checkwallexist
    mov HaveSpeedB,0
    mov obstacleB,0
    mov HaveDelayB,0
    mov HavePassB,1
    mov TemporaryPixle,si
    jmp clearB
    checkwallexist:
    cmp al,4d
    jne therepixelnotblack1carb
    cmp ActivatePassB,1
    jne therepixelnotblack1carb
    mov ActivatePassB,0d
    mov TemporaryPixle,si
    clearB:
    call ClearBlock
    contcheck:
    inc si
    dec cl
    cmp cl,0
    je ccc1
    jmp checkpixels1carb
    ccc1:
    add si,320 - car_width
    mov cl,car_width
    dec ch
    cmp ch,0
    je ccc2
    jmp checkpixels1carb
    ccc2:
    mov canmovecarb,0
    jmp finishcheckmovecarbKeyUPKeyDOWN
    therepixelnotblack1carb:
    mov canmovecarb,1
    finishcheckmovecarbKeyUPKeyDOWN: 
    ret
checkmovecarbKeyUPKeyDOWN endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; check position (KeyRIGHT_KeyLEFT);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


checkmovecarbKeyRIGHTKeyLEFT proc
    mov ax,320d
    mul ynb
    add ax,xnb
    mov si,ax
    sub si,(car_width / 2) * 320 - car_height / 2
    mov al,0
    mov cl,car_width
    mov ch,car_height
    checkpixels2carb:
    mov al,es:[si]
    cmp al,08h
    je contcheck2
    checkspeed2:
    cmp al,1d
    jne checkdela2
    mov HaveSpeedB,1
    mov TemporaryPixle,si
    jmp clearB2
    checkdela2:
    cmp al,2d
    jne checkwallplace2
    mov HaveDelayB,1d
    mov TemporaryPixle,si
    jmp clearB2
    checkwallplace2:
    cmp al,3d
    jne checkwallpass2
    mov obstacleB,1d
    mov TemporaryPixle,si
    jmp clearB2
    checkwallpass2:
    cmp al,5d
    jne checkwallexist2
    mov HavePassB,1d
    mov TemporaryPixle,si
    jmp clearB2
    checkwallexist2:
    cmp al,4d
    jne therepixelnotblack2carb
    cmp ActivatePassB,1
    jne therepixelnotblack2carb
    mov ActivatePassB,0d
    mov TemporaryPixle,si
    clearB2:
    call ClearBlock
    contcheck2:
    add si,320
    dec cl
    cmp cl,0
    jne checkpixels2carb
    sub si,car_width * 320 + 1
    mov cl,car_width
    dec ch
    cmp ch,0
    jne checkpixels2carb
    mov canmovecarb,0
    jmp finishcheckmovecarbKeyRIGHTKeyLEFT
    therepixelnotblack2carb:
    mov canmovecarb,1
    finishcheckmovecarbKeyRIGHTKeyLEFT: 
    ret
checkmovecarbKeyRIGHTKeyLEFT endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; check All position ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


checkcanmovecarb proc

    cmp positnb,'s'
    jne labelcheckcanmovecarbKeyDOWN
    call checkmovecarbKeyUPKeyDOWN  
    jmp labelfinishcheckcanmovecarb

    labelcheckcanmovecarbKeyDOWN:

    cmp positnb,'w'
    jne labelcheckcanmovecarbKeyUP
    call checkmovecarbKeyUPKeyDOWN
    jmp labelfinishcheckcanmovecarb

    labelcheckcanmovecarbKeyUP:

    cmp positnb,'d'
    jne labelcheckcanmovecarbKeyRIGHT
    call checkmovecarbKeyRIGHTKeyLEFT
    jmp labelfinishcheckcanmovecarb

    labelcheckcanmovecarbKeyRIGHT:

    call checkmovecarbKeyRIGHTKeyLEFT

    labelfinishcheckcanmovecarb:
    ret
checkcanmovecarb endp


checkDoubleButtonsKeyUPcarb proc
    mov al,0
    add al, [byte ptr keylist + KeyUP]
    add al, [byte ptr keylist + KeyDOWN]
    add al, [byte ptr keylist + KeyRIGHT]
    add al, [byte ptr keylist + KeyLEFT]
    cmp ax,2
    jb finishcheckDoubleButtonsKeyUPcarb
    mov al,positb
    mov positnb,al
    finishcheckDoubleButtonsKeyUPcarb:
  ret
checkDoubleButtonsKeyUPcarb endp


launchrocketcarb proc
    mov ax,xb
    mov cx,yb
    mov dl,positb
    cmp positb,'w'
    jne launchwcarb
    sub cx,car_width+2
    jmp contlaunchcarb
    launchwcarb:
    cmp positb,'s'
    jne launchscarb
    add cx,car_width+2
    jmp contlaunchcarb
    launchscarb:
    cmp positb,'d'
    jne launchdcarb
    add ax,car_width+2
    jmp contlaunchcarb
    launchdcarb:
    sub ax,car_width+2
    contlaunchcarb:
    mov xn1rocket,ax
    mov yn1rocket,cx
    mov xnrocket,ax
    mov ynrocket,cx
    mov positionrocket,dl
    mov rocketmoving,1
  ret
launchrocketcarb endp


movecarB PROC       ; check the new position of car b
     mov velocityb,1
    cmp ActivateSpeedB,1
    jne nospeedb
    mov velocityb,2
    nospeedb:
  cmp delaycarb,0
  je contdelaycarb
  jmp far ptr finishmovebwithdelaycarb
  contdelaycarb:
  cmp ActivateDelayB,1
  jne nodelay
  mov delaycarb,1
  mov ah,2ch   
  int 21h
  cmp StartDelayA,dh
  je nodelay
  mov delaycarb,1
  jmp movcont
  nodelay:
  mov delaycarb,0
  mov ActivateDelayB,0
  movcont:
  cmp [byte ptr keylist + keyl], 1
  jne norocketpresscarb
  cmp firecarb,1
  jne norocketpresscarb
  ;mov firecarb,0
  call launchrocketcarb
  norocketpresscarb:
  mov ax,velocityb
  cmp [byte ptr keylist + KeyUP], 1
    jne kt7t
    mov positnb,'w'
    sub ynb,ax
    kt7t:
  cmp [byte ptr keylist + KeyDOWN], 1
    jne kymen
    mov positnb,'s'
    add ynb,ax                                                 
    kymen:
  cmp [byte ptr keylist + KeyRIGHT], 1
    jne kshmal
    mov positnb,'d'
    add xnb,ax
    kshmal:
  cmp [byte ptr keylist + KeyLEFT], 1
    jne contb
    mov positnb,'a'
    sub xnb,ax
    contb:

    call checkDoubleButtonsKeyUPcarb

    mov ax,xnb
    mov cx,ynb
    mov dl,positnb
    cmp ax,xb
    jne checkmovcarb
    cmp cx,yb
    jne checkmovcarb
    jmp finishmoveb


    checkmovcarb:
    call clearcarb

    mov canmovecarb,0
    call checkcanmovecarb                             ; check if car can move to next position or not 
    cmp canmovecarb,1                                 ; if not draw at previous position
    je labelcantmovecarb

    mov ax,xnb
    mov cx,ynb
    mov dl,positnb
    mov xb,ax
    mov yb,cx


    cmp positnb,'s'
    jne notcheckKeyDOWNcarb
    cmp positb,'w'
    je notcheckKeyDOWNcarb
    mov positb,dl
    call DRAWCARBKeyUPKeyDOWN
    jmp finishmoveb

    notcheckKeyDOWNcarb:

    cmp positnb,'w'
    jne notcheckKeyUPcarb
    cmp positb,'s'
    je notcheckKeyUPcarb
    mov positb,dl
    call DRAWCARBKeyUPKeyDOWN
    jmp finishmoveb

    notcheckKeyUPcarb:

    cmp positnb,'d'
    jne notcheckKeyRIGHTcarb
    cmp positb,'a'
    je notcheckKeyRIGHTcarb
    mov positb,dl
    call DRAWCARBKeyRIGHTKeyLEFT
    jmp finishmoveb 

    notcheckKeyRIGHTcarb:

    cmp positnb,'a'
    jne notcheckKeyLEFTcarb
    cmp positb,'d'
    je notcheckKeyLEFTcarb
    mov positb,dl
    call DRAWCARBKeyRIGHTKeyLEFT
    jmp finishmoveb 



    labelcantmovecarb:
    mov ax,xb
    mov cx,yb
    mov xnb,ax                                           ; move new position to previous position
    mov ynb,cx


    notcheckKeyLEFTcarb:

    cmp positb,'w'
    jne Dcbd
    call DRAWCARBKeyUPKeyDOWN
    jmp finishmoveb
    dcbd:
    cmp positb,'s'
    jne Dcbr
    call DRAWCARBKeyUPKeyDOWN
    jmp finishmoveb                                               
    dcbr:
    cmp positb,'d'
    jne Dcbl
    call DRAWCARBKeyRIGHTKeyLEFT
    jmp finishmoveb
    Dcbl:
    call DRAWCARBKeyRIGHTKeyLEFT
    jmp finishmoveb

    finishmovebwithdelaycarb:
    dec delaycarb
    finishmoveb:

    ret
movecarB ENDP

CheckBlack PROC
mov canDraw,1d
mov ax,320d
mul yBlack
add ax,xBlack
mov si,ax
mov al,0d
mov cl,5d
mov ch,5d
check1:
mov ch,5d
checkb2:
mov al,es:[si]
cmp al,0d
jne notblack
inc si
dec ch
cmp ch,0
jne checkb2
add si,320d
sub si,5d
dec cl
cmp cl,0
jne check1
jmp finishcheckB
notblack:
mov canDraw ,0d


finishcheckB:
ret
CheckBlack endp

generateBox PROC
mov ax,320d
mul yBlack
add ax,xBlack
mov di,ax
mov al,4d
mov cl,5d
color1:
mov ch,5d
color2:
mov es:[di],al
inc di
dec ch
cmp ch,0
jne color2
add di,320d
sub di,5d
dec cl
cmp cl,0d
jne color1
ret
generateBox endp

ActivatePass PROC
cmp [byte ptr keylist + KeyP], 1
jne che2
cmp HavePassA,1d
jne che2
mov ActivatePassA,1d
mov HavePassA,0d
che2:
cmp [byte ptr keylist + Key1], 1
jne finactivate
cmp HavePassB,1d
jne finactivate
mov ActivatePassB,1d
mov HavePassB,0d

finactivate:
ret
ActivatePass endp


generateObsA PROC
    cmp [byte ptr keylist + KeyP], 1
    je de1
    jmp ch2
    ch2:
    cmp [byte ptr keylist + Key1], 1
    je de2
    jmp dis
    de1:
    cmp obstacleA,1
    je p1
    jmp dis
    p1:
    mov ax,xa
    mov bx,ya
    mov cl,posita
    mov carToUse,'A'
    jmp go2
    de2:
    cmp obstacleB,1
    je p2
    jmp dis
    p2:
    mov ax,xb
    mov bx,yb
    mov cl,positb
    mov carToUse,'B'
  go2:
  mov xBlack,ax
  mov yBlack,bx
  mov positToCompare,cl
  z2:
  cmp positToCompare,'w'
  jne cops
  mov xBlack,ax
  mov yBlack,bx
  sub xBlack,3d
  add yBlack,6d
  jmp finishGen
  cops:
  cmp positToCompare,'s'
  jne copa
  mov xBlack,ax
  mov yBlack,bx
  sub xBlack,3d
  sub yBlack,10d
  jmp finishGen
  copa:
  cmp positToCompare,'a'
  jne copd
  mov xBlack,ax
  mov yBlack,bx
  add xBlack,6d
  sub yBlack,3d
  jmp finishGen
  copd:
  mov xBlack,ax
  mov yBlack,bx
  sub xBlack,11d
  sub yBlack,3d
  finishGen:
  call CheckBlack
  cmp canDraw,1d
  jne dis
  call generateBox
  cmp carToUse,'A'
  jne carB
  mov obstacleA,0d
  jmp dis
  carB:
  mov obstacleB,0d
  dis:
  ret
generateObsA endp

ActivateSpeed proc
  cmp [byte ptr keylist + KeyP], 1
  jne gocar2
  cmp HaveSpeedA,1
  jne gocar2
  mov ActivateSpeedA,1d
  mov HaveSpeedA,0d
  mov ah,2ch   
  int 21h
  mov StartTimeSpeedA,dh
  add StartTimeSpeedA,5d
  gocar2:
  cmp [byte ptr keylist + Key1], 1
  jne endSpeed
  cmp HaveSpeedB,1
  jne endSpeed
  mov ActivateSpeedB,1d
  mov HaveSpeedB,0d
  mov ah,2ch   
  int 21h
  mov StartTimeSpeedB,dh
  add StartTimeSpeedB,5d

  endSpeed:
ret
ActivateSpeed endp

ActivateDelay proc
  cmp [byte ptr keylist + KeyP], 1
  jne checkDelay2
  cmp HaveDelayA,1
  jne checkDelay2
  mov HaveDelayA,0
  mov ah,2ch   
  int 21h
  mov StartDelayA,dh
  add StartDelayA,5d
  mov ActivateDelayB,1
  checkDelay2:
  cmp [byte ptr keylist + Key1], 1
  jne finishDelay
  cmp HaveDelayB,1
  jne finishDelay
  mov HaveDelayB,0
  mov ah,2ch   
  int 21h
  mov StartDelayB,dh
  add StartDelayB,5d
  mov ActivateDelayA,1
  finishDelay:
ret
ActivateDelay endp

TerminateSpeed proc
    mov ah,2ch   
    int 21h
    cmp StartTimeSpeedA,dh
    jne TermB
    mov ActivateSpeedA,0
    TermB:
    cmp StartTimeSpeedB,dh
    jne finishTerm
    mov ActivateSpeedB,0
    finishTerm:
  ret
TerminateSpeed endp


sleepSomeTime proc
    mov cx, 0
    mov dx, 35000  
    mov ah, 86h
    int 15h  ; param is cx:dx (in microseconds)
    ret
sleepSomeTime endp



handlekeylist proc far 

  in al,60h
  cmp al,KeyW
  jne k1
  mov [byte ptr keylist + KeyW],1
  jmp finishhandlekeylist
  k1:
  cmp al,KeyW+80h
  jne kn1
  mov [byte ptr keylist + KeyW],0
  jmp finishhandlekeylist
  kn1:
  cmp al,KeyS
  jne k2
  mov [byte ptr keylist + KeyS],1
  jmp finishhandlekeylist
  k2:
  cmp al,KeyS+80h
  jne kn2
  mov [byte ptr keylist + KeyS],0
  jmp finishhandlekeylist
  kn2:
  cmp al,KeyD
  jne k3
  mov [byte ptr keylist + KeyD],1
  jmp finishhandlekeylist
  k3:
  cmp al,KeyD+80h
  jne kn3
  mov [byte ptr keylist + KeyD],0
  jmp finishhandlekeylist
  kn3:
  cmp al,KeyA
  jne k4
  mov [byte ptr keylist + KeyA],1
  jmp finishhandlekeylist
  k4:
  cmp al,KeyA+80h
  jne kn4
  mov [byte ptr keylist + KeyA],0
  jmp finishhandlekeylist
  kn4:
  cmp al,KeyUP
  jne k5
  mov [byte ptr keylist + KeyUP],1
  jmp finishhandlekeylist
  k5:
  cmp al,KeyUP+80h
  jne kn5
  mov [byte ptr keylist + KeyUP],0
  jmp finishhandlekeylist
  kn5:
  cmp al,KeyDOWN
  jne k6
  mov [byte ptr keylist + KeyDOWN],1
  jmp finishhandlekeylist
  k6:
  cmp al,KeyDOWN+80h
  jne kn6
  mov [byte ptr keylist + KeyDOWN],0
  jmp finishhandlekeylist
  kn6:
  cmp al,KeyRIGHT
  jne k7
  mov [byte ptr keylist + KeyRIGHT],1
  jmp finishhandlekeylist
  k7:
  cmp al,KeyRIGHT+80h
  jne kn7
  mov [byte ptr keylist + KeyRIGHT],0
  jmp finishhandlekeylist
  kn7:
  cmp al,KeyLEFT
  jne k8
  mov [byte ptr keylist + KeyLEFT],1
  jmp finishhandlekeylist
  k8:
  cmp al,KeyLEFT+80h
  jne kn8
  mov [byte ptr keylist + KeyLEFT],0
  jmp finishhandlekeylist
  kn8:
  cmp al,KeyP
  jne k9
  mov [byte ptr keylist + KeyP],1
  jmp finishhandlekeylist
  k9:
  cmp al,KeyP+80h
  jne kn9
  mov [byte ptr keylist + KeyP],0
  jmp finishhandlekeylist
  ;;;;
  kn9:
  cmp al,Key1
  jne k10
  mov [byte ptr keylist + Key1],1
  jmp finishhandlekeylist
  k10:
  cmp al,Key1+80h
  jne kn10
  mov [byte ptr keylist + Key1],0
   kn10:
  cmp al,KeyO
  jne k11
  mov [byte ptr keylist + KeyO],1
  jmp finishhandlekeylist
  k11:
  cmp al,KeyO+80h
  jne kn11
  mov [byte ptr keylist + KeyO],0
  jmp finishhandlekeylist
  kn11:
  cmp al,Key2
  jne k12
  mov [byte ptr keylist + Key2],1
  jmp finishhandlekeylist
  k12:
  cmp al,Key2+80h
  jne kn12
  mov [byte ptr keylist + Key2],0
  kn12:
  cmp al,KeyI
  jne k13
  mov [byte ptr keylist + KeyI],1
  jmp finishhandlekeylist
  k13:
  cmp al,KeyI+80h
  jne kn13
  mov [byte ptr keylist + KeyI],0
  kn13:
  cmp al,Key3
  jne k14
  mov [byte ptr keylist + Key3],1
  jmp finishhandlekeylist
  k14:
  cmp al,Key3+80h
  jne kn14
  mov [byte ptr keylist + Key3],0
  kn14:
  cmp al,KeyU
  jne k15
  mov [byte ptr keylist + KeyU],1
  jmp finishhandlekeylist
  k15:
  cmp al,KeyU+80h
  jne kn15
  mov [byte ptr keylist + KeyU],0
  kn15:
  cmp al,Key4
  jne k16
  mov [byte ptr keylist + Key4],1
  jmp finishhandlekeylist
  k16:
  cmp al,Key4+80h
  jne kn16
  mov [byte ptr keylist + Key4],0
  kn16:
  ;;;;
  cmp al,KeyEsc
  jne k17
  mov [byte ptr keylist + KeyEsc],1
  jmp finishhandlekeylist
  k17:
  cmp al,KeyEsc+80h
  jne kn17
  mov [byte ptr keylist + KeyEsc],0
  jmp finishhandlekeylist
  kn17:
  cmp al,keyf
  jne krocketa
  mov [byte ptr keylist + keyf],1
  jmp finishhandlekeylist
  krocketa:
  cmp al,keyf+80h
  jne knrocketa
  mov [byte ptr keylist + keyf],0
  jmp finishhandlekeylist
  knrocketa:
  cmp al,keyl
  jne krocketb
  mov [byte ptr keylist + keyl],1
  jmp finishhandlekeylist
  krocketb:
  cmp al,keyl+80h
  jne knrocketb
  mov [byte ptr keylist + keyl],0
  jmp finishhandlekeylist
  knrocketb:
  finishhandlekeylist:

  mov al,20h
  out 20h,al

  iret 
handlekeylist endp


clearrocket proc
  mov ax,320
  mul yrocket
  add ax,xrocket
  mov di,ax
  mov al,colorclearrocket
  mov es:[di],al
  ret
clearrocket endp


drawrocket proc
  mov ax,320
  mul yrocket
  add ax,xrocket
  mov di,ax
  mov al,colordrawrocket
  mov es:[di],al
  ret
drawrocket endp

checkrocketcollision2 proc
  mov ax,320
  mul ynrocket
  add ax,xnrocket
  mov si,ax
  mov al,es:[si]
  cmp al,colorcara
  jne checkcara2
  mov whatrocketcollision,'a'
  mov isrocketcollision,1
  mov ah,2ch   
  int 21h
  mov FreezeEnd,dh
  add FreezeEnd,5d
  mov rocketmoving,0
  jmp finishcheckrocketcollision2
  checkcara2:
  cmp al,colorcarb
  jne checkcarb2
  mov whatrocketcollision,'b'
  mov isrocketcollision,1
  mov ah,2ch   
  int 21h
  mov FreezeEnd,dh
  add FreezeEnd,5d
  mov rocketmoving,0
  jmp finishcheckrocketcollision2
  checkcarb2:
  cmp al,colordrawrocket
  je checkwall2
  cmp al,colorclearrocket
  je checkwall2 
  mov whatrocketcollision,'w'
  mov isrocketcollision,1
  mov rocketmoving,0
  jmp finishcheckrocketcollision2
  checkwall2:
  mov isrocketcollision,0
  finishcheckrocketcollision2:
  ret
checkrocketcollision2 endp


checkrocketcollision1 proc
  mov ax,320
  mul yn1rocket
  add ax,xn1rocket
  mov si,ax
  mov al,es:[si]
  cmp al,colorcara
  jne checkcara1
  mov whatrocketcollision,'a'
  mov isrocketcollision,1
  mov ah,2ch   
  int 21h
  mov FreezeEnd,dh
  add FreezeEnd,5d
  mov rocketmoving,0
  jmp finishcheckrocketcollision1
  checkcara1:
  cmp al,colorcarb
  jne checkcarb1
  mov whatrocketcollision,'b'
  mov isrocketcollision,1
  mov ah,2ch   
  int 21h
  mov FreezeEnd,dh
  add FreezeEnd,5d
  mov rocketmoving,0
  jmp finishcheckrocketcollision1
  checkcarb1:
  cmp al,colordrawrocket
  je checkwall1
  cmp al,colorclearrocket
  je checkwall1
  mov whatrocketcollision,'w'
  mov isrocketcollision,1
  mov rocketmoving,0
  jmp finishcheckrocketcollision1
  checkwall1:
  mov isrocketcollision,0
  finishcheckrocketcollision1:
  ret
checkrocketcollision1 endp


movrocket proc
  cmp positionrocket,'w'
  jne rocketdown2
  sub ynrocket,2
  sub yn1rocket,1
  jmp finishmovenewrocket
  rocketdown2:
  cmp positionrocket,'s'
  jne rocketright2
  add ynrocket,2
  add yn1rocket,1
  jmp finishmovenewrocket
  rocketright2:
  cmp positionrocket,'d'
  jne rocketleft2
  add xnrocket,2
  add xn1rocket,1
  jmp finishmovenewrocket
  rocketleft2:
  sub xnrocket,2
  sub xn1rocket,1
  finishmovenewrocket:


  call checkrocketcollision2
  cmp isrocketcollision,0
  jne jumpcontoooo
  call checkrocketcollision1
  jumpcontoooo:


  call clearrocket

  cmp isrocketcollision,1
  je partialfinishrocket


  mov ax,xnrocket
  mov cx,ynrocket
  mov xn1rocket,ax
  mov yn1rocket,cx
  mov xrocket,ax
  mov yrocket,cx
  call drawrocket
  jmp finishmoverocket

  partialfinishrocket:
  cmp whatrocketcollision,'w'
  jne finishmoverocket
  mov isrocketcollision,0
  finishmoverocket:
  ret
movrocket endp


overrideInt PROC
    cli
    push ds
    mov ax,cs
    mov ds,ax
    mov ax,2509h
    lea dx,handlekeylist
    int 21h
    pop ds
    sti
    ret
overrideInt ENDP

moveCars PROC
    drawinitcar xa,ya,car1image   ; car a
    drawinitcar xb,yb,car2image   ; car b

    lop:
    call sleepSomeTime


    call handlekeylist

    cmp rocketmoving,1
    jne movcars
    call movrocket
    movcars:
    cmp isrocketcollision,1
    jne moa
    cmp whatrocketcollision,'a'
    jne moa
    mov ah,2ch   
    int 21h
    cmp FreezeEnd,dh
    jne mob
    mov isrocketcollision,0d
    moa:
    call movecarA
    cmp isrocketcollision,1
    jne mob
    cmp whatrocketcollision,'b'
    jne mob
    mov ah,2ch   
    int 21h
    cmp FreezeEnd,dh
    jne nomov
    mov isrocketcollision,0d
    mob:
    call movecarB
    nomov:
    call generateObsA
    call TerminateSpeed
    call ActivateSpeed
    call ActivateDelay
    Call ActivatePass



    cmp [byte ptr keylist + KeyEsc],1
    jne lop

    ret
moveCars ENDP

;---------------------------------PATH_PROCS---------------------------------------
setBit PROC
    
    pusha
    mov ax, 320
    mul dx
    add ax, cx
    mov cx, 8
    xor dx, dx
    div cx
    mov bl, 10000000b    
    mov cl, dl
    shr bl, cl
    mov si, ax
    or [pathfreq + si], bl
    popa

    ret
setBit ENDP

resetBit PROC
    
    pusha

    mov ax, 320
    mul dx
    add ax, cx
    mov cx, 8
    xor dx, dx
    div cx
    mov si, ax
    mov [pathfreq + si], 0h

    popa
    
    ret
resetBit ENDP

clearScreen PROC
    mov ah, 0
    mov al, 3
    int 10h
    ret
clearScreen ENDP

videoMode PROC
    mov ah, 0
    mov al, 13h
    int 10h
    ret
videoMode ENDP

delay PROC
    mov cx, 1000
    delayLoop:
    mov dx, 100
    delayMore:
        dec dx
        jnz delayMore
    loop delayLoop
    ret
delay ENDP

drawBackGround PROC   
    ret
drawBackGround ENDP

finishLine PROC
    sub si, finishLength * 2
    sub di, finishLength * 2

    mov cx, [pathLine1_x + si]
    mov curStCol, cx
    mov cx, [pathLine1_y + si]
    mov curStRow, cx
    mov cx, [pathLine2_x + di]
    mov curEnCol, cx
    mov cx, [pathLine2_y + di]
    mov curEnRow, cx
    ;switch case (not to pass certain window line)
    finish_upCode:
        cmp curDirection, up
        jnz finish_downCode
        mov cx, [curstcol] ;for drawing the street in-between (same as down but with xchg between start col and end col)
        xchg cx, [curEnCol]
        mov [curstcol], cx
        inc curstcol
        jmp finish_continueInner

    finish_downCode:
        cmp curDirection, down
        jnz finish_leftCode
        inc curstcol
        jmp finish_continueInner

    finish_leftCode:
        cmp curDirection, left
        jnz finish_rightCode
        inc curstrow
        jmp finish_continueInner

    finish_rightCode:
        mov cx, [curstRow]
        xchg cx, [curEnRow] ;for drawing the street in-between (same as left but with xchg between start row and end row)
        mov [curstRow], cx
        inc curstrow
        jmp finish_continueInner

    finish_continueInner:

    ;---------- next block of code is to make the alternating black and white finish color-------
    mov i, alternatingFinish
    mov j, alternatingFinish
    mov dx, [curStRow]
    cmp dx, curEnRow
    jz finish_sameRow

    finish_sameCol:

        mov bx, finishLength
        mov cx, curStCol       ; Column
        innerIncCol:
        push bx
        mov bx, i
        cmp bx, 0
        jz chngColor1
        jmp keepColor1
        chngColor1:
            mov i, alternatingFinish
            mov bl, [firstcolor]
            xchg bl, [secondcolor]
            mov firstColor, bl
        keepColor1:
        pop bx
        mov dx, curStRow      ; Row
        mov j, alternatingFinish
        finish_streetLineRow: 
            push bx
            mov bx, j
            cmp bx, 0
            jz chngColor2
            jmp keepColor2
            chngColor2:
                mov j, alternatingFinish
                mov bl, [firstcolor]
                xchg bl, [secondcolor]
                mov firstColor, bl
            keepColor2:
            pop bx
            mov al, firstColor     ; Pixel color
            mov ah, 0ch     ; Draw Pixel Command
            int 10h
            dec j
            inc dx
            cmp dx, curEnRow
        jnz finish_streetLineRow
        push si
        mov si, prevDirection
        add cx, [pathDirection_X + si]
        pop si
        dec i
        dec bx
        cmp bx, 0
        jnz innerIncCol
    jmp finish

    finish_sameRow:
        mov bx, finishLength
        mov dx, curStRow      ; Row
        innerIncRow:
        push bx
        mov bx, i
        cmp bx, 0
        jz chngColor3
        jmp keepColor3
        chngColor3:
            mov i, alternatingFinish
            mov bl, [firstcolor]
            xchg bl, [secondcolor]
            mov firstColor, bl
        keepColor3:
        pop bx
        mov cx, curStCol       ; Column
        mov j, alternatingFinish
        finish_streetLineCol:
            push bx
            mov bx, j
            cmp bx, 0
            jz chngColor4
            jmp keepColor4
            chngColor4:
                mov j, alternatingFinish
                mov bl, [firstcolor]
                xchg bl, [secondcolor]
                mov firstColor, bl
            keepColor4:
            pop bx 
            mov al, firstColor     ; Pixel color
            mov ah, 0ch     ; Draw Pixel Command
            int 10h
            dec j
            inc cx
            cmp cx, curEnCol
        jnz finish_streetLineCol
        push si
        mov si, prevDirection
        add dx, [pathDirection_Y + si]
        pop si
        dec i
        dec bx
        cmp bx, 0
        jnz innerIncRow
    jmp finish

    finish:
    ret
finishLine ENDP

resetAllBits PROC
    mov si, 0
    fillZeros1:
        mov cx, [pathLine1_X + si]
        mov dx, [pathLine1_Y + si]
        call resetBit
        add si, 2
        cmp si, firstLineCounter
    jnz fillZeros1

    mov di, 0
    fillZeros2:
        mov cx, [pathLine2_X + di]
        mov dx, [pathLine2_Y + di]
        call resetBit
        add di, 2
        cmp di, SecondLineCounter
    jnz fillZeros2
    ret
resetAllBits ENDP

genRandom PROC
    xor ax, ax
    int 1Ah 
    mov ax, dx
    add randomnum, ax
    cmp randomNum, 0
    jz increaseRand
    jmp continueRandom
    increaseRand:
        inc randomNum
    continueRandom:
    mov bx, randomNum
    mov ax, [pathline1_x + si]
    cmp ax, 0
    jz increaseAx
    jmp secondContinue
    increaseAx:
    inc ax ;to ensure it's not zero
    secondContinue:
    mul bx ;mul result in ax
    ror ax, 1
    mov randomNum, ax
    mov al, ah
    mov ah, 0
    ret

genRandom ENDP

minMaxX PROC
    mov bx, [pathLine1_X + si]
    mov cx, [pathLine2_X + di]
    cmp bx, cx
    jb smallerX
    jmp movMinMaxX
    smallerX:
        xchg bx, cx ;bx now has the larger value
    movMinMaxX:
    mov minX, cx
    mov maxX, bx
    ret
minMaxX ENDP

minMaxY PROC
    mov bx, [pathLine1_Y + si]
    mov cx, [pathLine2_Y + di]
    cmp bx, cx
    jb smallerY
    jmp movMinMaxY
    smallerY:
        xchg bx, cx ;bx now has the larger value
    movMinMaxY: 
    mov minY, cx
    mov maxY, bx
    ret
minMaxY ENDP

setObs PROC
    mov isObs, 1
    mov cBox, obsColor
    mov sBox, obstacleDim
    mov al, obsDrawn
    mov boxDrawn, al
    mov boxDim, obstacleDim
    mov boxProb, obsProb
    ret
setObs ENDP

setPowerUp PROC
    mov isObs, 0
    push si
    call genRandom
    mov bl, 5
    div bl ;ah now has the rem (where to draw the Box)
    mov al, ah
    xor ah, ah
    mov si, ax
    mov al, [powerUpsRand + si]
    mov cBox, al
    pop si
    mov sBox, powerupsDim
    mov al, powerupsDrawn
    mov boxDrawn, al
    mov boxDim, powerupsDim
    mov boxProb, powerupProb
    ret
setPowerUp ENDP

checkDrawBox PROC
    mov ax, [sbox]
    add ax, 2
    mov sBoxBigger, ax
    xor ax, ax
    inc boxDim
    mov ah, [boxdim]
    add ah, 3
    mov al, ah
    mov bl, 2
    xor ah, ah
    div bl ;now al has the div
    mov halfBox, al
    cmp Boxdrawn, 0
    je Box
    jmp contBox
    Box:
    xor ah, ah
    mov al, boxDim
    cmp i, ax
    ja BoxDecide
    jmp contBox
    BoxDecide:
    cmp j, 0
    ja checkNotLast
    jmp contBox
    checkNotLast:
    cmp j, pathCount
    jb valid
    jmp contBox
    valid:
    call genRandom
    ;Random number is in al 
    ;Random number should be above 100 for the probability to work so if it is not, then make it equal to ff - rand
    cmp al, 100
    jb makeAboveH
    jmp continueBoxDecide
    makeaboveH:
    mov ah, 0ffh
    sub ah, al
    mov al, ah
    xor ah, ah
    ;now al has a number that is ge 100
    continueBoxDecide:
    mov bl, 101
    div bl ;ah now has the remainder which is the final rand no. (0-100)
    cmp ah, BoxProb
    jb LdrawBox
    jmp contBox
    LdrawBox:
    cmp isObs, 1
    jz drawnObs
    jnz drawnPowerup
    drawnObs:
    mov obsDrawn, 1
    jmp done
    drawnPowerup:
    mov powerupsdrawn, 1
    done:
    call genRandom
    mov bl, 0
    sub bl, halfBox
    add bl, trackWidth - 4
    div bl ;ah now has the rem (where to draw the Box)
    mov al, ah
    xor ah, ah
    cmp curDirection, 2
    jbe uporDownStreet
    jmp leftorRightStreet
    uporDownStreet:
    call minMaxX
    ;rand + minx + ceil(BoxDim / 2)
    add ax, minx
    mov bh, 0
    mov bl, halfBox
    add ax, bx
    mov xBox, ax
    mov ax, [pathLine1_y + si]
    push si
    mov si, curDirection
    add ax, [boxDirection + si]
    pop si
    mov yBox, ax
    pusha
    mov sc, 8
    mov chkBoolBox, 0
    checkSmallBoxColor xBox, yBox, sc, sBoxBigger, chkBoolbox
    cmp chkBoolbox, 0
    popa
    jz safeDraw1
    jnz filled1
    safeDraw1:
    pusha
    drawBox xBox, yBox, cBox, sBox
    popa
    filled1:
    jmp contBox
    leftorRightStreet:
    call minMaxY
    ;rand + miny + ceil(BoxDim / 2)
    add ax, miny
    mov bh, 0
    mov bl, halfBox
    add ax, bx
    mov yBox, ax
    mov ax, [pathLine1_x + si]
    push si
    mov si, curDirection
    add ax, [boxDirection + si]
    pop si
    mov xBox, ax
    pusha
    mov sc, 8
    mov chkBoolBox, 0
    checkSmallBoxColor xBox, yBox, sc, sBoxBigger, chkBoolbox
    cmp chkBoolbox, 0
    popa
    jz safeDraw2
    jnz filled2
    safeDraw2:
    pusha
    drawBox xBox, yBox, cBox, sBox
    popa
    filled2:
    contBox:
    ret
checkDrawBox ENDP

designPath PROC

    call clearScreen

    ;Set cursor position
    mov ah, 2       ; Subfunction: Set cursor position
    mov bh, 0       ; Video page number
    mov dh, 12   ; Row (vertical position)
    mov dl, 25   ; Column (horizontal position)
    int 10h

    ; Display the string
    mov ah, 09h     ; Function: Display string
    lea dx, [msg]   ; Load effective address of the string into dx
    int 21h

    mov si, 0
    mov di, 0
    
    codeBeginning:
    ;fill freq array with zeros
    mov firstLineCounter, si
    mov secondLineCounter, di
    add firstLineCounter, 4
    add secondLineCounter, 4
    call resetAllBits

    mov si, 0
    mov cx, 4
    initBlocked:
    mov [blockedDirx + si], 0
    add si, 2
    loop initBlocked

    mov curDirection, up
    mov [prevdirection], up
    mov xMul, 0
    mov yMul, 0
    mov i, 0
    mov j, 0
    mov curIdx, 0
    mov newDirection, 0
    mov suitableStreet, 0

    ;start in left corner
    mov [pathLine1_X], trackWidth + smallMargin
    mov [pathLine2_X], smallMargin
    mov [pathLine1_Y], verticalScreen - smallMargin
    mov [pathLine2_Y], verticalScreen - smallMargin
    
    
    ;set indices of path array
    mov si, 0
    mov di, 0

    ;get clock tick to use this random number over n over again (after modifying it)
    xor ax, ax
    int 1Ah   ; get system time, clock ticks count
    mov randomNum, dx

    ;MAIN FUNCTION draws the whole track

    pathDesign:
        mov i, 0
        streetDesign:  
            goStreet:
            ;---if curDirection not same as prevDirection (direction has changed)
            mov bx, [curDirection]
            cmp bx, [prevDirection]
            jnz diffDirection
            jmp outExtra
            ;handle each change by itself in nested conditions
            ;------------------------------CAUTION HUGE BLOCK COMING--------------------------------
            diffDirection:

            mov al, 7      ; Pixel color
            mov ah, 0ch     ; Draw Pixel Command

            ;get max and min Y-borders to avoid hitting the wall
            call minMaxY

            ;get max and min X-borders to avoid hitting the wall
            call minMaxX

            ;---------------------------------------for turning design------------
            upTurn:

            cmp curDirection, up
            jz upCont
            jmp downTurn
            upCont:

            mov bx, minY
            
            cmp bx, trackWidth + smallmargin
            
            ja decideUp

            push si
            mov si, curDirection
            mov [blockedDirx + si], 1
            pop si

            jmp outer

            
            decideUp:
            ;in case it was left b4
            mov bx, [pathLine1_x + si]
            mov x2, bx
            sub bx, trackWidth ;should not underflow
            mov x1, bx
            mov bx, [pathLine1_y + si]
            mov y1, bx
            cmp prevDirection, left
            jnz rt
            jmp up_Checker
            rt:
            ;in case it was right b4
            mov bx, [pathLine2_x + di]
            mov x1, bx
            add bx, trackWidth ;should not underflow
            mov x2, bx
            mov bx, [pathLine2_y + di]
            mov y1, bx
            
            
            ;Here we should check if u can't even turn because path would collapse
            up_Checker:
            mov ud, 1
            checkTurnCollapse

            cmp prevDirection, left
            jz LU_Turn
            jmp RU_Turn

            LU_Turn:
                mov bx, 0
                LU_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    dec cx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz LU_Line1
                mov bx, 0
                LU_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    dec dx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx
                    
                    checkCollapse
                    
                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz LU_Line2

            jmp downEnd
            RU_Turn:
                mov bx, 0
                RU_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    inc cx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz RU_Line1
                mov bx, 0
                RU_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    dec dx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz RU_Line2
            jmp downEnd

            downTurn:

            cmp curDirection, down
            jz downCont
            jmp leftTurn
            downCont:

            mov bx, maxY
            
            cmp bx, verticalScreen - trackWidth - smallmargin
            
            jb decideDown

            push si
            mov si, curDirection
            mov [blockedDirx + si], 1
            pop si

            jmp outer

            
            decideDown:
            mov bx, [pathLine2_x + di]
            mov x2, bx
            sub bx, trackWidth ;should not underflow
            mov x1, bx
            mov bx, [pathLine2_y + di]
            mov y1, bx
            cmp prevDirection, left
            jnz rdt
            jmp downChecker
            rdt:
            mov bx, [pathLine1_x + si]
            mov x1, bx
            add bx, trackWidth ;should not underflow
            mov x2, bx
            mov bx, [pathLine1_y + si]
            mov y1, bx

            ;Here we should check if path can't even turn because it would collapse
            downChecker:
            mov ud, 1
            checkTurnCollapse

            cmp prevDirection, left
            jz LD_Turn
            jmp RD_Turn
            
            LD_Turn:
                mov bx, 0
                LD_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    dec cx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz LD_Line1
                mov bx, 0
                LD_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    inc dx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz LD_Line2

            jmp leftEnd
            RD_Turn:  
                mov bx, 0
                RD_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    inc cx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz RD_Line1
                mov bx, 0
                RD_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    inc dx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz RD_Line2
            downEnd:
                jmp leftEnd

            leftTurn:

            cmp curDirection, left
            jz leftCont
            jmp rightTurn
            
            leftCont:
            
            mov bx, minX
            
            cmp bx, trackWidth + smallmargin
            
            ja decideLeft

            push si
            mov si, curDirection
            mov [blockedDirx + si], 1
            pop si

            jmp outer

            
            decideLeft:
            mov bx, [pathLine2_x + di]
            mov x1, bx
            mov bx, [pathLine2_y + di]
            mov y1, bx
            sub bx, trackWidth
            mov y2, bx
            cmp prevDirection, up
            jnz dlt
            jmp left_Checker
            dlt:
            mov bx, [pathLine1_x + si]
            mov x1, bx
            mov bx, [pathLine1_y + si]
            mov y1, bx
            add bx, trackWidth
            mov y2, bx

            left_Checker:
            mov ud, 0
            checkTurnCollapse

            cmp prevDirection, up
            jz UL_Turn
            jmp DWL_Turn 
            
            UL_Turn:
                mov bx, 0
                UL_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    dec dx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse
                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz UL_Line1
                mov bx, 0
                UL_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    dec cx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz UL_Line2

            jmp rightEnd
            DWL_Turn:
                mov bx, 0
                DL_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    inc dx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz DL_Line1
                mov bx, 0
                DL_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    dec cx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz DL_Line2
            leftEnd:
                jmp rightEnd
            rightTurn:
            
            mov bx, maxX
            
            cmp bx, horizontalscreen - trackWidth - smallmargin
            
            jb decideRight

            push si
            mov si, curDirection
            mov [blockedDirx + si], 1
            pop si

            jmp outer

            decideRight:
            mov bx, [pathLine1_x + si]
            mov x1, bx
            mov bx, [pathLine1_y + si]
            mov y1, bx
            sub bx, trackWidth
            mov y2, bx
            cmp prevDirection, up
            jnz drt
            jmp right_Checker
            drt:
            mov bx, [pathLine2_x + di]
            mov x1, bx
            mov bx, [pathLine2_y + di]
            mov y1, bx
            add bx, trackWidth
            mov y2, bx
            
            right_Checker:
            mov ud, 0
            checkTurnCollapse

            cmp prevDirection, up
            jz UR_Turn
            jmp DR_Turn
            
            UR_Turn:
                mov bx, 0
                UR_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    dec dx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz UR_Line1
                mov bx, 0
                UR_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    add di, 2
                    inc cx
                    mov [pathLine2_X + di], cx
                    mov [pathline2_Y + di], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz UR_Line2

            jmp rightEnd
            DR_Turn:
                mov bx, 0
                DR_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    inc dx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz DR_Line1
                mov bx, 0
                DR_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    add si, 2
                    inc cx
                    mov [pathLine1_X + si], cx
                    mov [pathline1_Y + si], dx

                    checkCollapse

                    call setBit

                    ;int 10h
                    inc bx
                    cmp bx, trackwidth
                jnz DR_Line2
            rightEnd:
                jmp outExtra
                    
            ;-----------------------------HUGE BLOCK ENDS HERE--------------------------------------------
            outExtra:
            ;switch case (not to pass certain window line)
            upCode:
                cmp curDirection, up 
                jnz downCode
                cmp [pathLine1_Y + si], trackWidth + smallmargin
                ja continueinner
                push si
                mov si, curDirection
                mov [blockedDirx + si], 1
                pop si
                jmp outer

            downCode:
                cmp curDirection, down
                jnz leftCode
                cmp [pathLine1_Y + si], verticalScreen - trackWidth - smallmargin
                jb continueinner
                push si
                mov si, curDirection
                mov [blockedDirx + si], 1
                pop si
                jmp outer

            leftCode:
                cmp curDirection, left
                jnz rightCode
                cmp [pathLine1_X + si], trackWidth + smallmargin
                ja continueinner
                push si
                mov si, curDirection
                mov [blockedDirx + si], 1
                pop si

                jmp outer

            rightCode:
                cmp [pathLine1_X + si], horizontalScreen - trackWidth - smallmargin
                jb continueinner
                push si
                mov si, curDirection
                mov [blockedDirx + si], 1
                pop si

                jmp outer

            continueInner:

                ;first check if path is going to collapse on itself then simply restart the path
                mov bothPixels, 2

                firstPixel:
                mov cx, [pathLine1_X + si]     ; Column
                mov dx, [pathLine1_Y + si]     ; Row

                checkCollapseBothPixels:
                mov bx, trackWidth + smallMargin + 1 ;so path is a bit far than the other

                checkColl:
                push si
                mov si, curDirection
                add cx, [pathDirection_X + si]
                add dx, [pathDirection_Y + si]
                pop si
                pusha
                mov ax, 320
                mul dx
                add ax, cx
                mov cx, 8
                xor dx, dx
                div cx
                mov bl, 10000000b    
                mov cl, dl
                shr bl, cl
                mov si, ax
                mov al, [pathfreq + si] 
                and al, bl
                cmp al, 0
                popa
                jz didntColl
                cmp bx, 1
                jnz FAIL
                push si
                mov si, curDirection
                mov [blockedDirx + si], 1
                pop si

                jmp outer
                FAIL:
                jmp codeBeginning
                didntColl:

                dec bx
                jz nextPixel
                jmp checkColl
                nextPixel:
                dec [bothPixels]
                cmp bothPixels, 0
                jz safeline
                mov cx, [pathLine2_X + di]     ; Column
                mov dx, [pathLine2_Y + di]     ; Row
                jmp checkCollapseBothPixels


                safeLine:


                mov cx, [pathLine1_X + si]     ; Column
                mov dx, [pathLine1_Y + si]     ; Row
                add si, 2
                push si
                mov si, [curDirection]
                add cx, [pathDirection_X + si] ; New pixel according to dir
                add dx, [pathDirection_Y + si]
                pop si
                mov [pathLine1_X + si], cx
                mov [pathline1_Y + si], dx

                checkCollapse

                call setBit
                ;first check if path is going to collapse on itself then simply restart the path

                mov al, 7     ; Pixel color
                mov ah, 0ch     ; Draw Pixel Command
                ;int 10h ; draw pixel interrupt
                
                mov cx, [pathLine2_X + di]     ; Column
                mov dx, [pathLine2_Y + di]     ; Row
                add di, 2
                push di
                mov di, [curDirection]
                add cx, [pathDirection_X + di] ; New pixel according to dir
                add dx, [pathDirection_Y + di]
                pop di
                mov [pathLine2_X + di], cx
                mov [pathline2_Y + di], dx

                checkCollapse

                call setBit

                ;check if path is going to collapse on itself then simply restart the path

                mov al, 7     ; Pixel color
                mov ah, 0ch     ; Draw Pixel Command
                ;int 10h ; draw pixel interrupt
                
                ;Reset street values
                storeVals:
                push si
                mov si, 0
                mov cx, 4
                resetBlocked:
                    mov [blockedDirx + si], 0
                    add si, 2
                loop resetBlocked
                pop si
                mov cx, curDirection
                mov prevDirection, cx
                mov newDirection, 1
                mov pathDrawn, 1
                inc suitableStreet
                inc i
                cmp i, streetLength
        jz outer  
        jmp streetDesign     
        outer: 
            mov bx, [pathdrawn]
            add j, bx
            cmp j, pathCount
            jnz stillConstructing
            cmp newDirection, 1
            jz addLastDir
            jmp dontAdd
            addLastDir:
            push si
            mov si, [curIdx]
            mov cx, prevDirection
            mov [saveddirections + si], cx
            add curIdx, 2
            pop si
            dontAdd:
            jmp finishLoop
            stillConstructing:
            cmp newDirection, 1
            jz addnewDir
            jnz newRandom
            addnewDir:
                mov suitableStreet, 0
                push si
                mov si, [curIdx]
                mov cx, prevDirection
                mov [saveddirections + si], cx
                add curIdx, 2
                pop si
        ;---pseudo-random algorithm that should be close to actually being random--
        newRandom:
            call genRandom
            ;random a direction only out of available directions and not blocked ones
            push si
            mov si, 0
            mov cx, 4
            mov bx, 4
            subFreeDirx:
                sub bx, [blockedDirx + si]
                add si, 2
            loop subFreeDirx
            ;if there is no remaining direction
            cmp bl, 0
            pop si

            jnz divide
            jmp codebeginning

            divide:
            ;now bl has num of blocked dirx
            div bl  ; remainder in ah
            inc ah
            ;get the nth free direction
            push si
            mov si, 0
            mov cx, 4
            mov bl, 0
            nthFreeDirx:
                cmp [blockedDirx + si], 0
                jz incFree
                jnz notnth
                incFree:
                inc bl
                cmp bl, ah
                jz suitable
                jnz notnth
                suitable:
                mov dx, si
                jmp nthDir
                notnth:
                add si, 2
            loop nthFreeDirx
            ;NOW YOU HAVE THE NTH FREE DIR
            nthDir:
            pop si
            ;check opp directions
            push si
            push di
            mov si, dx
            mov di, prevDirection
            mov cx, [pathOpposites + si]
            mov ax, [pathOpposites + di]
            add cx, ax
            pop di
            pop si
            cmp cx, 0
            jnz suitableDir
            push si
            mov si, dx
            mov [blockedDirx + si], 1
            pop si
            jmp newrandom

        suitableDir:
        ;dx contains a suitable new direction
        cmp dx, [prevDirection]
        jz sameDirCheck
        jnz DiffDirCheck
        ;here dx is same as prevDirection 
        sameDirCheck:
        jmp continueOuter
        

        DiffDirCheck:
        ;dx not equal prevDirection

        continueOuter:
        mov CurDirection, dx


    mov pathDrawn, 0
    mov newDirection, 0
    jmp pathDesign 
    
    finishLoop:
    cmp suitableStreet, finishlength
    ja perfectPath
    jmp codeBeginning
    perfectPath:
    mov firstLineCounter, si
    mov secondLineCounter, di
    add firstLineCounter, 4
    add secondLineCounter, 4
    ret
designPath ENDP

drawPath PROC

    call resetAllBits
    ;set indices of path array
    mov si, 0
    mov di, 0
    mov curIdx, 0
    mov [prevdirection], up
    mov xMul, 0
    mov yMul, 0
    mov j, 0
    mov [powerupsdrawn], 0

    ;MAIN FUNCTION draws the whole track

    Drawing_pathDraw:
        mov i, 0
        ;get curDirection from savedDirections
        push si
        mov si, curIdx
        mov bx, [savedDirections + si]
        mov curDirection, bx
        add curIdx, 2
        pop si
        Drawing_streetDraw:  
            cmp dontDraw, 1
            jz powerUps
            call delay ;to see the path getting drawn
            
            call setObs
            call checkDrawBox
            jmp Drawing_goStreet

            powerUps:
            call setPowerUp
            call checkDrawBox

            Drawing_goStreet:

            ;---if curDirection not same as prevDirection (direction has changed)
            mov bx, [curDirection]
            cmp bx, [prevDirection]
            jnz Drawing_diffDirection
            jmp Drawing_outExtra
            ;handle each change by itself in nested conditions
            ;---------------------------------------CAUTION HUGE BLOCK INCOMING--------------------------------
            Drawing_diffDirection:

            mov al, 7      ; Pixel color
            mov ah, 0ch     ; Draw Pixel Command

            ;get max and min Y-borders to avoid hitting the wall
            mov bx, [pathLine1_Y + si]
            mov cx, [pathLine2_Y + di]
            cmp bx, cx
            jb Drawing_smallerY
            jmp Drawing_movMinMaxY
            Drawing_smallerY:
                xchg bx, cx ;bx now has the larger value
            Drawing_movMinMaxY: 
            mov minY, cx
            mov maxY, bx

            ;get max and min X-borders to avoid hitting the wall
            mov bx, [pathLine1_X + si]
            mov cx, [pathLine2_X + di]
            cmp bx, cx
            jb Drawing_smallerX
            jmp Drawing_movMinMaxX
            Drawing_smallerX:
                xchg bx, cx ;bx now has the larger value
            Drawing_movMinMaxX:
            mov minX, cx
            mov maxX, bx

            ;for turns drawing

            Drawing_upTurn:

            cmp curDirection, up
            jz Drawing_upCont
            jmp Drawing_downTurn
            Drawing_upCont:

            mov bx, minY
            
            cmp bx, trackWidth + smallmargin
            
            ja Drawing_decideUp

            jmp Drawing_outer

            
            Drawing_decideUp:
            cmp prevDirection, left
            jz Drawing_LU_Turn
            jmp Drawing_RU_Turn

            
            Drawing_LU_Turn:
                mov bx, 0
                Drawing_LU_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw2
                    int 10h
                    dontdraw2:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_LU_Line1
                mov bx, 0
                Drawing_LU_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw3
                    int 10h
                    dontdraw3:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_LU_Line2

            jmp Drawing_downEnd
            Drawing_RU_Turn:
                mov bx, 0
                Drawing_RU_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw4
                    int 10h
                    dontdraw4:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_RU_Line1
                mov bx, 0
                Drawing_RU_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw5
                    int 10h
                    dontdraw5:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_RU_Line2
            jmp Drawing_downEnd

            Drawing_downTurn:

            cmp curDirection, down
            jz Drawing_downCont
            jmp Drawing_leftTurn
            Drawing_downCont:

            mov bx, maxY
            
            cmp bx, verticalScreen - trackWidth - smallmargin
            
            jb Drawing_decideDown

            jmp Drawing_outer

            
            Drawing_decideDown:
            cmp prevDirection, left
            jz Drawing_LD_Turn
            jmp Drawing_RD_Turn

            
            Drawing_LD_Turn:
                mov bx, 0
                Drawing_LD_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw6
                    int 10h
                    dontdraw6:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_LD_Line1
                mov bx, 0
                Drawing_LD_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw7
                    int 10h
                    dontdraw7:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_LD_Line2

            jmp Drawing_leftEnd
            Drawing_RD_Turn:  
                mov bx, 0
                Drawing_RD_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw8
                    int 10h
                    dontdraw8:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_RD_Line1
                mov bx, 0
                Drawing_RD_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw9
                    int 10h
                    dontdraw9:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_RD_Line2
            Drawing_downEnd:
                jmp Drawing_leftEnd
            Drawing_leftTurn:

            cmp curDirection, left
            jz Drawing_leftCont
            jmp Drawing_rightTurn
            
            Drawing_leftCont:
            
            mov bx, minX
            
            cmp bx, trackWidth + smallmargin
            
            ja Drawing_decideLeft

            jmp Drawing_Outer

            
            Drawing_decideLeft:
            cmp prevDirection, up
            jz Drawing_UL_Turn
            jmp Drawing_DWL_Turn
            
            
            Drawing_UL_Turn:
                mov bx, 0
                Drawing_UL_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw10
                    int 10h
                    dontdraw10:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_UL_Line1
                mov bx, 0
                Drawing_UL_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw11
                    int 10h
                    dontdraw11:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_UL_Line2

            jmp Drawing_rightEnd
            Drawing_DWL_Turn:
                mov bx, 0
                Drawing_DL_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw12
                    int 10h
                    dontdraw12:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_DL_Line1
                mov bx, 0
                Drawing_DL_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw13
                    int 10h
                    dontdraw13:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_DL_Line2
            Drawing_leftEnd:
                jmp Drawing_rightEnd
            Drawing_rightTurn:
            
            mov bx, maxX
            
            cmp bx, horizontalscreen - trackWidth - smallmargin
            
            jb Drawing_decideRight

            jmp Drawing_Outer

            Drawing_decideRight:
            cmp prevDirection, up
            jz Drawing_UR_Turn
            jmp Drawing_DR_Turn
            
            Drawing_UR_Turn:
                mov bx, 0
                Drawing_UR_Line1:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw14
                    int 10h
                    dontdraw14:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_UR_Line1
                mov bx, 0
                Drawing_UR_Line2:
                    mov cx, [pathLine2_X + di]     ; Column
                    mov dx, [pathLine2_Y + di]     ; Row
                    call setBit
                    add di, 2
                    cmp dontDraw, 1
                    jz dontdraw15
                    int 10h
                    dontdraw15:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_UR_Line2

            jmp Drawing_rightEnd
            Drawing_DR_Turn:
                mov bx, 0
                Drawing_DR_Line1:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw16
                    int 10h
                    dontdraw16:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_DR_Line1
                mov bx, 0
                Drawing_DR_Line2:
                    mov cx, [pathLine1_X + si]     ; Column
                    mov dx, [pathLine1_Y + si]     ; Row
                    call setBit
                    add si, 2
                    cmp dontDraw, 1
                    jz dontdraw17
                    int 10h
                    dontdraw17:
                    inc bx
                    cmp bx, trackwidth
                jnz Drawing_DR_Line2
            Drawing_rightEnd:
                jmp Drawing_outExtra
                 
            ;-----------------------------HUGE BLOCK ENDS HERE--------------------------------------------
            Drawing_outExtra:
            ;---this part determines the starting row and col
            ;---to draw line between each two pixels (representing street)
            mov cx, [pathLine1_x + si]
            mov curStCol, cx
            mov cx, [pathLine1_y + si]
            mov curStRow, cx
            mov cx, [pathLine2_x + di]
            mov curEnCol, cx
            mov cx, [pathLine2_y + di]
            mov curEnRow, cx
            ;switch case (not to pass certain window line)
            Drawing_upCode:
                cmp curDirection, up
                jnz Drawing_downCode
                mov cx, [curstcol] ;for drawing the street in-between (same as down but with xchg between start col and end col)
                xchg cx, [curEnCol]
                mov [curstcol], cx
                inc curstcol
                cmp [pathLine1_Y + si], trackWidth + smallmargin
                ja Drawing_continueinner
                jmp Drawing_outer

            Drawing_downCode:
                cmp curDirection, down
                jnz Drawing_leftCode
                inc curstcol
                cmp [pathLine1_Y + si], verticalScreen - trackWidth - smallmargin
                jb Drawing_continueinner
                jmp Drawing_outer

            Drawing_leftCode:
                cmp curDirection, left
                jnz Drawing_rightCode
                inc curstrow
                cmp [pathLine1_X + si], trackWidth + smallmargin
                ja Drawing_continueinner
                jmp Drawing_outer

            Drawing_rightCode:
                mov cx, [curstRow]
                xchg cx, [curEnRow] ;for drawing the street in-between (same as left but with xchg between start row and end row)
                mov [curstRow], cx
                inc curstrow
                cmp [pathLine1_X + si], horizontalScreen - trackWidth - smallmargin
                jb Drawing_continueinner
                jmp Drawing_outer

            Drawing_continueInner:
            
            ;first check if path is going to collapse on itself then simply restart the path
            mov bothPixels, 2

            mov cx, [pathLine1_X + si]     ; Column
            mov dx, [pathLine1_Y + si]     ; Row

            Drawing_checkCollapseBothPixels:
            mov bx, trackWidth + smallMargin + 1 ;so path is a bit far than the other

            Drawing_checkColl:
            push si
            mov si, curDirection
            add cx, [pathDirection_X + si]
            add dx, [pathDirection_Y + si]
            pop si
            pusha
            mov ax, 320
            mul dx
            add ax, cx
            mov cx, 8
            xor dx, dx
            div cx
            mov bl, 10000000b    
            mov cl, dl
            shr bl, cl
            mov si, ax
            mov al, [pathfreq + si] 
            and al, bl
            cmp al, 0
            popa
            jz Drawing_didntColl
            cmp bx, 1
            jnz Drawing_FAIL
            jmp Drawing_outer
            Drawing_FAIL:
            jmp codeBeginning
            Drawing_didntColl:

            dec bx
            jz Drawing_nextPixel
            jmp Drawing_checkColl
            Drawing_nextPixel:
            dec [bothPixels]
            cmp bothPixels, 0
            jz Drawing_safeline
            mov cx, [pathLine2_X + di]     ; Column
            mov dx, [pathLine2_Y + di]     ; Row
            jmp Drawing_checkCollapseBothPixels


            Drawing_safeLine:

            mov al, 8     ; Pixel color
            mov ah, 0ch     ; Draw Pixel Command
            mov dx, [curStRow]
            cmp dx, curEnRow
            jz Drawing_sameRow

            Drawing_sameCol:
                mov cx, curStCol       ; Column
                mov dx, curStRow      ; Row
                Drawing_streetLineRow: 
                    cmp dontDraw, 1
                    jz dontdraw18
                    int 10h
                    dontdraw18:
                    inc dx
                    cmp dx, curEnRow
                jnz Drawing_streetLineRow

            jmp Drawing_continueDraw

            Drawing_sameRow:
                mov cx, curStCol       ; Column
                mov dx, curStRow      ; Row
                Drawing_streetLineCol: 
                    cmp dontDraw, 1
                    jz dontdraw19
                    int 10h
                    dontdraw19:
                    inc cx
                    cmp cx, curEnCol
                jnz Drawing_streetLineCol

            Drawing_continueDraw:
                mov cx, [pathLine1_X + si]     ; Column
                mov dx, [pathLine1_Y + si]     ; Row
                call setBit
                add si, 2
                
                mov al, 7     ; Pixel color
                mov ah, 0ch     ; Draw Pixel Command
                cmp dontDraw, 1
                jz dontdraw20
                int 10h
                dontdraw20:
                
                mov cx, [pathLine2_X + di]     ; Column
                mov dx, [pathLine2_Y + di]     ; Row
                call setBit
                add di, 2

                mov al, 7     ; Pixel color
                mov ah, 0ch     ; Draw Pixel Command
                cmp dontDraw, 1
                jz dontdraw21
                int 10h
                dontdraw21:
                
                mov cx, curDirection
                mov prevDirection, cx
                inc i
                cmp i, streetLength
        jz Drawing_outer  
        jmp Drawing_streetDraw     

        Drawing_outer: 
        inc j
        cmp j, pathCount
        jnz Drawing_suitableNew
        jmp Drawing_finishLoop
        Drawing_suitableNew:
        ;dx contains a suitable new direction
        push si
        mov si, curIdx
        mov dx, [savedDirections + si]
        mov curDirection, dx
        pop si
        cmp dx, [prevDirection]
        jz Drawing_sameDirCheck
        jnz Drawing_DiffDirCheck
        ;here dx is same as prevDirection 
        ;should check if it's even drawable
        Drawing_sameDirCheck:
        jmp Drawing_continueOuter

        Drawing_DiffDirCheck:
        ;dx not equal prevDirection
        ;draw an extra path for the turning margin
        push dx
        push si
        mov si, prevDirection
        mov bx, [extrapathdirection_x + si]
        mov xMul, bx
        mov bx, [extrapathdirection_y + si]
        mov yMul, bx
        pop si
        mov dx, [pathLine2_Y + di]      ; Row
        mov al, 8       ; Pixel color
        mov ah, 0ch     ; Draw Pixel Command

        Drawing_DirBox:
        mov cx, [pathLine2_X + di]       ; Column
        Drawing_DirLine: 
            cmp dontDraw, 1
            jz dontdraw22
            int 10h
            dontdraw22:
            add cx, xMul
            mov bx, trackWidth
            push ax
            push dx
            mov ax, xMul
            xor dx, dx
            mul bx
            mov bx, ax
            add bx, [pathLine2_X + di] 
            pop dx
            pop ax
            cmp cx, bx
        jnz Drawing_DirLine
        add dx, yMul
        mov bx, trackWidth
        push ax
        push dx
        mov ax, yMul
        xor dx, dx
        mul bx
        mov bx, ax
        add bx, [pathLine2_Y + di]
        pop dx
        pop ax
        cmp dx, bx
        jnz Drawing_DirBox
        pop dx

        Drawing_continueOuter:
        mov obsdrawn, 0
        mov [powerupsdrawn], 0
    jmp Drawing_pathDraw 
    
    Drawing_finishLoop:
    cmp dontDraw, 1
    jz dontdraw23
    call finishLine
    dontdraw23:

    ret
drawPath ENDP


MAIN PROC FAR
    mov ax, @data
    mov ds, ax
    mov ax, 0A000h
    mov es,ax

    call overrideInt

    call designPath
    call videoMode
    call drawBackGround
    mov dontDraw, 0
    call drawPath

    mov cx, 3
    powerUpsLoop:
        push cx
        mov dontDraw, 1
        call drawPath
        pop cx
    loop powerUpsLoop



    call moveCars


    ;terminate 
    mov ah, 4CH
    int 21H

MAIN ENDP
END MAIN
