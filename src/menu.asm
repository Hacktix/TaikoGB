;----------------------------------------------------------------------------
; Constant Definitions
;----------------------------------------------------------------------------
DEF LY_SELECT        EQU $34
DEF SEL_HEIGHT       EQU 24
DEF MENU_SCX         EQU -14
DEF SEL_SCROLL_SPEED EQU 3
DEF SEL_PLAY_CD      EQU 120

SECTION "Song Menu", ROM0
;----------------------------------------------------------------------------
; Initialization Routine for the Song Selection Menu
;----------------------------------------------------------------------------
InitMenu:
    ;----------------------------------------------------------------------------
    ; Basic Initialization

    ; Initialize Palettes
    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a

    ; Clear VRAM
    ld hl, $8000
    ld bc, $4000
    ld d, 0
    call Memset

    ; Set to Bank 1 for Graphics Data
    xor a
    ld [rROMB1], a
    inc a
    ld [rROMB0], a

    ;----------------------------------------------------------------------------
    ; Load Tile Data into VRAM

    ; Load Font into VRAM
    ld hl, $8410
    ld de, FontUppercase
    ld bc, EndFontUppercase - FontUppercase
    call Memcpy
    ld hl, $8610
    ld de, FontLowercase
    ld bc, EndFontLowercase - FontLowercase
    call Memcpy

    ; Load cursor into VRAM
    ld hl, $8010
    ld de, TaikoCursor
    ld c, EndTaikoCursor - TaikoCursor
    rst MemcpySmall

    ; Load Common Tiles into VRAM
    ld hl, $8020
    ld de, CommonTiles
    ld bc, EndCommonTiles - CommonTiles
    call Memcpy

    ;----------------------------------------------------------------------------
    ; Initialize Registers & Variables

    ; Scrolling & Window
    ld a, MENU_SCX
    ldh [rSCX], a
    ld a, 7
    ldh [rWX], a
    xor a
    ldh [rSCY], a
    ldh [hChangeSCY], a

    ; LYC & STAT Registers (+ STAT Handler Index)
    inc a
    ldh [hIndexSTAT], a           ; Set STAT Handler to $01 (= ToggleWindow_STAT)
    ld a, STATF_LYC
    ldh [rSTAT], a
    ld a, 15
    ldh [rLYC], a

    ; Song Preview
    ld a, SEL_PLAY_CD
    ldh [hSelectedSongCooldown], a
    xor a
    call InitSongPreview

    ; Audio Registers
    ld a, $80
    ld [rAUDENA], a
    ld a, $FF
    ld [rAUDTERM], a
    ld a, $77
    ld [rAUDVOL], a

    ; VAddr & Index Variables
    ld a, $60
    ld [wSelectionVAddrTop], a
    ld [wSelectionVAddrBottom], a
    ld a, $9B
    ld [wSelectionVAddrTop+1], a
    ld a, $9A
    ld [wSelectionVAddrBottom+1], a
    ld a, SongEntryCounter - 4
    ld [wSelectionIndexTop], a

    ;----------------------------------------------------------------------------
    ; Load tilemap data into VRAM

    ; Render Window
    ld hl, $9C03
    ld de, strSongMenuTitle
    call Strcpy
    ld hl, $9C20
    ld bc, 64
    ld d, $02
    call Memset

    ; Render Initial Song List
    ld a, SongEntryCounter - 3
    ld b, 7
    ld hl, $9BC0
.initSongList
    push bc
    call RenderSongLabel
    pop bc
    inc a
    dec b
    jr nz, .initSongList
    ld [wSelectionIndexBottom], a

    ;----------------------------------------------------------------------------
    ; Initialize OAM

    ; Clear OAM
    ld hl, _OAMRAM
    ld bc, OAM_COUNT*4
    ld d, $00
    call Memset

    ; Load OAM with required data
    ld hl, _OAMRAM
    ld de, SongMenuOAM
    ld c, EndSongMenuOAM - SongMenuOAM
    rst MemcpySmall

    ;----------------------------------------------------------------------------
    ; Initialize Interrupts & Fall through to main loop

    ; Initialize Interrupts & LYC
    xor a
    ldh [rIF], a
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    ei

    ; Initialize LCD and Loop
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_WINON | LCDCF_WIN9C00
    ldh [rLCDC], a


;----------------------------------------------------------------------------
; Main Loop for the Song Selection Menu Game State
;----------------------------------------------------------------------------
SongMenuLoop:
    ;----------------------------------------------------------------------------
    ; Wait for VBlank
    halt
    ldh a, [rLY]
    cp SCRN_Y
    jr c, SongMenuLoop

    ;----------------------------------------------------------------------------
    ; Song Selection Scrolling

    ; Check if scrolling should be done
    ldh a, [hChangeSCY]
    and a
    jr z, .noScrollingNeeded

    ; Check whether to increment or decrement & update SCY
    bit 7, a
    jr z, .scrollInc
    add SEL_SCROLL_SPEED
    ldh [hChangeSCY], a
    ldh a, [rSCY]
    sub SEL_SCROLL_SPEED
    jr .endScroll
.scrollInc
    sub SEL_SCROLL_SPEED
    ldh [hChangeSCY], a
    ldh a, [rSCY]
    add SEL_SCROLL_SPEED
.endScroll
    ldh [rSCY], a
    jp .skipInputCheck
.noScrollingNeeded

    ;----------------------------------------------------------------------------
    ; Input Handler

    ; Fetch Input State & Check for Up/Down Inputs
    call FetchInput
    ldh a, [hHeldKeys]
    and BTN_DPAD_D | BTN_DPAD_U
    jp z, .noUpDown

    ; Jump depending on whether UP or DOWN were pressed
    and BTN_DPAD_U
    jr z, .pressedDown

    ; # Up Press Handler
    ; Update hChangeSCY
    ld b, -SEL_HEIGHT
    ldh a, [hChangeSCY]
    add b
    ldh [hChangeSCY], a

    ; Pre-render top song label
    ld a, [wSelectionVAddrTop]
    ld l, a
    ld a, [wSelectionVAddrTop+1]
    ld h, a
    ld a, [wSelectionIndexTop]
    call RenderSongLabel

    ; Store New Values in WRAM variables
    dec a
    ld [wSelectionIndexTop], a
    ld a, l
    sub $C0
    ld [wSelectionVAddrTop], a
    jr nc, .noCarryTopAdjust
    dec h
.noCarryTopAdjust
    ld a, h
    or $98
    and $9B
    ld [wSelectionVAddrTop+1], a
    ld a, [wSelectionVAddrBottom]
    ld l, a
    ld a, [wSelectionVAddrBottom+1]
    ld h, a
    ld a, l
    sub $60
    ld [wSelectionVAddrBottom], a
    jr nc, .noCarryBottomAdjust
    dec h
.noCarryBottomAdjust
    ld a, h
    or $98
    and $9B
    ld [wSelectionVAddrBottom+1], a
    ld a, [wSelectionIndexBottom]
    dec a
    ld [wSelectionIndexBottom], a

    ; Update Song Preview Variables
    ldh a, [hSelectedSong]
    dec a
    call InitSongPreview

    jr .noUpDown
.pressedDown
    ; # Down Press Handler
    ; Update hChangeSCY
    ld b, SEL_HEIGHT
    ldh a, [hChangeSCY]
    add b
    ldh [hChangeSCY], a

    ; Pre-render bottom song label
    ld a, [wSelectionVAddrBottom]
    ld l, a
    ld a, [wSelectionVAddrBottom+1]
    ld h, a
    ld a, [wSelectionIndexBottom]
    call RenderSongLabel

    ; Store New Values in WRAM variables
    inc a
    ld [wSelectionIndexBottom], a
    ld a, l
    ld [wSelectionVAddrBottom], a
    ld a, h
    ld [wSelectionVAddrBottom+1], a
    ld a, [wSelectionVAddrTop]
    ld l, a
    ld a, [wSelectionVAddrTop+1]
    ld h, a
    ld de, $0060
    add hl, de
    ld a, l
    ld [wSelectionVAddrTop], a
    ld a, h
    or $98
    and $9B
    ld [wSelectionVAddrTop+1], a
    ld a, [wSelectionIndexTop]
    inc a
    ld [wSelectionIndexTop], a

    ; Update Song Preview Variables
    ldh a, [hSelectedSong]
    inc a
    call InitSongPreview

.noUpDown

    ; Check song play cooldown
    ldh a, [hSelectedSongCooldown]
    and a
    jr z, .doPlaySong
    dec a
    ldh [hSelectedSongCooldown], a
    jr .skipInputCheck
.doPlaySong
    call _hUGE_dosound

.skipInputCheck
    jp SongMenuLoop
    


;----------------------------------------------------------------------------
; Song Selection Menu Subroutines
;----------------------------------------------------------------------------

InitSongPreview:
    ; Bounds Checking
    cp SongEntryCounter
    jr c, .inRange
    sub SongEntryCounter
    jr InitSongPreview
.inRange

    ; Load pointer & initialize
    ldh [hSelectedSong], a
    ld l, a
    ld h, $00
    ld de, MapsetTable
    add hl, hl
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    call GetPointerAbs
    call hUGE_init
    ld a, SEL_PLAY_CD
    ldh [hSelectedSongCooldown], a

;----------------------------------------------------------------------------
; Input:
;  * A  - Song Index   (Preserved)
;  * HL - VRAM Pointer (Set to next valid value)
RenderSongLabel:
    ; Check if index is out of range
    cp SongEntryCounter
    jr c, .inRange
    sub SongEntryCounter
    jr RenderSongLabel
.inRange

    ; Preserve VRAM Pointer
    push af
    ld a, h
    and $9B
    ld h, a
    ld a, l
    and $E0
    ld l, a
    pop af
    push af
    push hl

    ; Fetch Pointer to Song header and offset by $0F (Start of Song Title)
    ld l, a
    xor a
    ld h, a
    add hl, hl
    ld de, MapsetTable
    add hl, de
    ld a, [hli]
    ld d, a
    ld h, [hl]
    ld l, d
    ld de, $000F
    add hl, de

    ; Load String pointer into DE and VRAM pointer into HL and print
    ld d, h
    ld e, l
    pop hl
    call Strcpy

    ; Go to new line in VRAM & Print Artist String
    ld a, $20
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, h
    and $9B
    ld h, a
    ld a, l
    and $E0
    ld l, a
    call Strcpy

    ; Go to new line in VRAM & clear
    ld de, $0020
    add hl, de
    ld a, h
    and $9B
    ld h, a
    ld a, l
    and $E0
    ld l, a
    ld bc, 32
    call Memset

    ; Return from Subroutine
    pop af
    ret


;----------------------------------------------------------------------------
; Song Selection Menu STAT Handlers
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Flips BGP for the selection bar section of the screen
SongMenu_FlipBGP_STAT:
    ; Wait for HBlank
    ld a, [rSTAT]
    and STATF_BUSY
    jr nz, SongMenu_FlipBGP_STAT

    ; Flip BGP Bits
    ldh a, [rBGP]
    cpl 
    ldh [rBGP], a

    ; Update LYC & STAT Handle Index
    ldh a, [rLYC]
    cp LY_SELECT - 1
    ld b, STATR_FLIP_BGP_MENU        ; If is start of select bar, keep STAT routine at BGP flip
    ld a, LY_SELECT + SEL_HEIGHT - 1 ; and set LYC to end of select bar
    jr z, .isSelectStart
    ld b, STATR_FLIP_WIN_EN_MENU     ; Otherwise set routine to Window Toggle
    ld a, SCRN_Y - 17                ; and set LYC to end of frame
.isSelectStart
    ldh [rLYC], a
    ld a, b
    ldh [hIndexSTAT], a

    ; Restore Registers & Return
    pop hl
    pop de
    pop bc
    pop af
    reti

;----------------------------------------------------------------------------
; Toggles the window enable bit for screen borders
SongMenu_ToggleWindow_STAT:
    ; Wait for HBlank
    ld a, [rSTAT]
    and STATF_BUSY
    jr nz, SongMenu_ToggleWindow_STAT

    ; Flip Window Enable Bit
    ldh a, [rLCDC]
    xor LCDCF_WINON
    ldh [rLCDC], a

    ; Update LYC & STAT Handle Index
    ldh a, [rLYC]
    cp SCRN_Y - 17
    ld b, STATR_FLIP_WIN_EN_MENU     ; If is end of frame window enable, keep routine at window toggle
    ld a, 15                         ; and set LYC to 15
    jr z, .isEndOfFrame
    ld b, STATR_FLIP_BGP_MENU        ; Otherwise set routine to BGP flip
    ld a, LY_SELECT - 1              ; and set LYC to start of select bar
.isEndOfFrame
    ldh [rLYC], a
    ld a, b
    ldh [hIndexSTAT], a

    ; Restore Registers & Return
    pop hl
    pop de
    pop bc
    pop af
    reti



SECTION "Song Menu Graphics", ROMX, BANK[1]

TaikoCursor:
INCBIN "gfx/taiko.2bpp"
EndTaikoCursor:

SongMenuOAM:
db LY_SELECT + (SEL_HEIGHT/2) + 12, $0A, $01, $00
EndSongMenuOAM:



SECTION "Song Selection HRAM", HRAM
hChangeSCY: db
hSelectedSong: db
hSelectedSongCooldown: db

SECTION "Song Selection WRAM", WRAM0
wSelectionVAddrTop: dw
wSelectionVAddrBottom: dw
wSelectionIndexTop: db
wSelectionIndexBottom: db