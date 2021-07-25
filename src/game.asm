;----------------------------------------------------------------------------
; Constant Definitions
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; # "Config" Constants #

; Note Lane & Hit Height
DEF WX_NOTE_LANE       EQU 100
DEF NOTE_HIT_LY        EQU $6C
DEF NOTE_DESPAWN_RANGE EQU 24

; Button Constants
DEF BTN_DRUM_A         EQU BTN_A | BTN_DPAD_R
DEF BTN_DRUM_B         EQU BTN_B | BTN_DPAD_L

; Accuracy Ranges (in pixels)
DEF RANGE_OKAY         EQU 24
DEF RANGE_GREAT        EQU 16
DEF RANGE_PERFECT      EQU 8

; Accuracy indices, DO NOT TOUCH
DEF INDEX_OKAY         EQU 0
DEF INDEX_GREAT        EQU 1
DEF INDEX_PERFECT      EQU 2
DEF INDEX_MISS         EQU 3

; Delay for accuracy labels (in frames)
DEF DELAY_LB_CLEAR     EQU 25

; BCD Config Variables
DEF SIZE_COMBO         EQU 2
DEF SIZE_SCORE         EQU 3

;----------------------------------------------------------------------------
; # Tile Numbers #

; Note Lane Tiles
DEF NOTE_LANE_TILE_L EQU $10
DEF NOTE_LANE_TILE_R EQU $11

; Drum & Circle Tiles
DEF DRUM_TILE_START  EQU $04
DEF CIRCLE_TILE_BASE EQU $02

; Label & Text Tiles
DEF LB_SCORE_START   EQU $94
DEF LB_COMBO_START   EQU $97
DEF LB_MISS_START    EQU $12
DEF LB_OKAY_START    EQU $15
DEF LB_GREAT_START   EQU $18
DEF LB_PERFECT_START EQU $1B
DEF NUM_TILE_BASE    EQU $80

;----------------------------------------------------------------------------
; # VRAM Addresses #

; Score Labels
DEF VRAM_SCORE       EQU $9C00
DEF VRAM_POINTS_HI   EQU $9C20
DEF VRAM_POINTS_LO   EQU VRAM_POINTS_HI+$20

; Combo Labels
DEF VRAM_COMBO       EQU $9E00
DEF VRAM_COMBO_HI    EQU $9DC0
DEF VRAM_COMBO_LO    EQU VRAM_COMBO_HI+$20

; Accuracy Labels
DEF VRAM_ACC_L       EQU $9A20
DEF VRAM_ACC_R       EQU $9A24



SECTION "Main Game", ROM0
;----------------------------------------------------------------------------
; Initialization Routine for the Main Game
;----------------------------------------------------------------------------
InitGame:
    ;----------------------------------------------------------------------------
    ; Basic Initialization

    ; Initialize Palettes
    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP0], a
    cpl
    ldh [rOBP1], a

    ; Set to Bank 1 for Graphics Data
    xor a
    ld [rROMB1], a
    inc a
    ld [rROMB0], a

    ; Reset & Initialize Audio Registers
    xor a
    ldh [rAUDENA], a
    ld a, $80
    ld [rAUDENA], a
    ld a, $FF
    ld [rAUDTERM], a
    ld a, $77
    ld [rAUDVOL], a

    ;----------------------------------------------------------------------------
    ; Load Window Tilemap

    ; Initially Clear Tilemaps
    ld hl, $9800
    ld bc, $A000-$9800
    ld d, 0
    call Memset

    ; Load Note Lane Tiles
    ld hl, $9800
    ld c, $0D
.noteLaneLoad
    ld de, NoteLaneTilemap
    call LoadTilemap
    dec c
    jr nz, .noteLaneLoad

    ; Load Taiko Tiles
    ld de, TaikoTilemap
    call LoadTilemap

    ;----------------------------------------------------------------------------
    ; Load Background Tilemap

    ; Load Score Label
    ld hl, VRAM_SCORE
    ld b, 3
    ld a, LB_SCORE_START
.scoreLabelLoad
    ld [hli], a
    inc a
    dec b
    jr nz, .scoreLabelLoad

    ; Load Points Label
    ld hl, VRAM_POINTS_HI
    ld de, VRAM_POINTS_LO
    ld a, NUM_TILE_BASE
    ld b, 8
.pointLabelLoad
    ld [hli], a
    add $0A
    ld [de], a
    inc de
    sub $0A
    dec b
    jr nz, .pointLabelLoad

    ; Load Combo Label
    ld hl, VRAM_COMBO
    ld b, 4
    ld a, LB_COMBO_START
.comboLabelLoad
    ld [hli], a
    inc a
    dec b
    jr nz, .comboLabelLoad
    ld hl, VRAM_COMBO_HI
    ld [hl], NUM_TILE_BASE
    ld hl, VRAM_COMBO_LO
    ld [hl], NUM_TILE_BASE + $0A

    ;----------------------------------------------------------------------------
    ; Load Tile Data into VRAM

    ; Load BG Tiles into VRAM
    ld hl, $8800
    ld de, GameTilesBG
    ld bc, EndGameTilesBG - GameTilesBG
    call Memcpy

    ; Load Sprite & Window Tiles into VRAM
    ld hl, $8020
    ld de, GameTilesSpritesWindow
    ld bc, EndGameTilesSpritesWindow - GameTilesSpritesWindow
    call Memcpy

    ;----------------------------------------------------------------------------
    ; Initialize (Shadow) OAM

    ; Initialize Shadow OAM
    ld hl, wShadowOAM
    ld b, OAM_COUNT
    ld c, OAMF_XFLIP
.initLoopOAM
    ld a, $FF
    ld [hli], a
    inc a
    ld [hli], a
    ld a, CIRCLE_TILE_BASE
    ld [hli], a
    ld a, c
    xor OAMF_XFLIP
    ld [hli], a
    ld c, a
    dec b
    jr nz, .initLoopOAM

    ; Transfer Shadow OAM to real OAM
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    ;----------------------------------------------------------------------------
    ; Map Initialization
    
    ; Fetch Pointer to Map Data
    ldh a, [hSelectedSong]
    ld l, a
    ld h, $00
    ld de, MapsetTable
    add hl, hl
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld b, 1     ; TODO: Load B with selected difficulty value
.difficultySelectLoop
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .difficultySelectLoop
    call GetPointerAbs

    ; Fetch map data length & approach speed
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a
    ld a, [hl]
    dec a
    ldh [hApproachSpeed], a

    ; Set initial song delay based on approach speed
    push hl
    ld hl, InitDelayTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    ldh [hSongPlayDelay], a
    pop hl

    ; Copy map to WRAM, preserve length & WRAM pointer in stack
    push bc
    ld d, h
    ld e, l
    inc de
    ld hl, wMapData
    push hl
    call Memcpy

    ;----------------------------------------------------------------------------
    ; Initialize Registers & Variables

    ; PPU Registers
    xor a
    ldh [rWY], a
    dec a
    ldh [rLYC], a
    ld a, WX_NOTE_LANE
    ldh [rWX], a
    ld a, -4
    ldh [rSCX], a
    ldh [rSCY], a

    ; hUGEDriver Initialization
    ldh a, [hSelectedSong]
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

    ; Game Variables
    ld a, 1
    ldh [hNextEventDelay], a
    xor a
    ldh [hPtrOAM], a
    ld [wScore], a
    ld [wScore+1], a
    ld [wScore+2], a
    ld [wCombo], a
    ld [wCombo+1], a

    ; Rendering Queue Variables ($FF)
    dec a
    ldh [hRenderLabelLeft], a
    ldh [hRenderLabelRight], a

    ;----------------------------------------------------------------------------
    ; Initialize Interrupts & Fall through to main loop

    ; Initialize Interrupts
    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei

    ; Initialize LCD and Loop
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WIN9800 | LCDCF_OBJON | LCDCF_WINON | LCDCF_BG8000 | LCDCF_OBJ16
    ldh [rLCDC], a


;----------------------------------------------------------------------------
; Main Loop for actual Gameplay
;----------------------------------------------------------------------------
MainGameLoop:
    ;----------------------------------------------------------------------------
    ; Wait for VBlank
    halt
    ldh a, [rLY]
    cp SCRN_Y
    jr c, MainGameLoop

    ;----------------------------------------------------------------------------
    ; Do OAM DMA
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    ;----------------------------------------------------------------------------
    ; Accuracy Label Rendering

    ; Left Taiko
    ldh a, [hRenderLabelLeft]
    cp $FF
    jr z, .noRenderLabelB
    ld hl, VRAM_ACC_L
    add a
    add LOW(GameLabelTable)
    ld c, a
    ld b, HIGH(GameLabelTable)
    jr nc, .noLabelAdjustB
    inc b
.noLabelAdjustB
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a
    call LoadTilemap
    ld a, $FF
    ldh [hRenderLabelLeft], a
.noRenderLabelB

    ; Right Taiko
    ldh a, [hRenderLabelRight]
    cp $FF
    jr z, .noRenderLabelA
    ld hl, VRAM_ACC_R
    add a
    add LOW(GameLabelTable)
    ld c, a
    ld b, HIGH(GameLabelTable)
    jr nc, .noLabelAdjustA
    inc b
.noLabelAdjustA
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a
    call LoadTilemap
    ld a, $FF
    ldh [hRenderLabelRight], a
.noRenderLabelA

    ;----------------------------------------------------------------------------
    ; Accuracy Label Despawning

    ; Left Taiko Label Clear
    ldh a, [hClearDelayLeft]
    dec a
    ldh [hClearDelayLeft], a
    jr nz, .noLeftLabelClear
    ld hl, VRAM_ACC_L
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
.noLeftLabelClear

    ; Right Taiko Label Clear
    ldh a, [hClearDelayRight]
    dec a
    ldh [hClearDelayRight], a
    jr nz, .noRightLabelClear
    ld hl, VRAM_ACC_R
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
.noRightLabelClear

    ;----------------------------------------------------------------------------
    ; Combo Label Rendering

    ; Clear First Label
    ld hl, VRAM_COMBO_HI
    ld de, VRAM_COMBO_LO
    xor a
REPT 4
    ld [hli], a
    ld [de], a
    inc de
ENDR

    ; Render Label
    ld hl, wCombo+SIZE_COMBO-1
    ld de, VRAM_COMBO_HI
    ld b, SIZE_COMBO
    call RenderBCD_NLZ

    ;----------------------------------------------------------------------------
    ; Score Label Rendering
    ld hl, wScore+SIZE_SCORE-1
    ld de, VRAM_POINTS_HI
    ld b, SIZE_SCORE
    call RenderBCD

    ;----------------------------------------------------------------------------
    ; Input Handler

    ; Fetch current input state
    call FetchInput

    ; Check for A Drum Button Press
    ldh a, [hPressedKeys]
    and BTN_DRUM_A
    jp z, .noDrumPressA

    ; Search for lowest A Drum Circle
    ld hl, wShadowOAM
    ld b, l
    ld c, l
    ld d, OAM_COUNT/2
.circleScanLoopA
    ; Load Y-Pos of next circle
    ld a, [hli]
    cp $FF
    jr z, .noLowestCircleA
    cp b
    jr c, .noLowestCircleA
    ; Check if circle is actually A-drum circle via palette bit
    inc hl
    inc hl
    push af
    ld a, [hli]
    and OAMF_PAL1
    jr z, .noLowestCirclePalA
    ; Update Output Registers
    pop af
    ld b, a                    ; Load lowest Circle Y into B
    ld c, l                    ; Load lowest Circle Address into C
    dec c
    dec c
    dec c
    dec c
    inc hl
    inc hl
    inc hl
    inc hl
    dec d
    jr nz, .circleScanLoopA
    jr .endCircleScanA
.noLowestCirclePalA
    pop af
    dec hl
    dec hl
    dec hl
.noLowestCircleA
    ; Go to next circle
    ld a, 7
    add l
    ld l, a
    dec d
    jr nz, .circleScanLoopA
.endCircleScanA

    ; If note is above OKAY range act as if nothing happened
    ld a, b
    cp NOTE_HIT_LY - RANGE_OKAY
    jr c, .noDrumPressA

    ; Move note out of frame
    ld h, HIGH(wShadowOAM)
    ld l, c
    ld [hl], $FF
    ld a, 4
    add l
    ld l, a
    ld [hl], $FF

    ; Get difference between perfect hit and circle sprite
    ld a, NOTE_HIT_LY
    sub b
    jr nc, .noAdjustDiffA
    ld a, b
    sub NOTE_HIT_LY
.noAdjustDiffA

    ; Determine hit range
    ld b, INDEX_MISS
    cp RANGE_OKAY
    jr nc, .endHitRangeCalcA
    ld b, INDEX_OKAY
    cp RANGE_GREAT
    jr nc, .endHitRangeCalcA
    ld b, INDEX_GREAT
    cp RANGE_PERFECT
    jr nc, .endHitRangeCalcA
    ld b, INDEX_PERFECT
.endHitRangeCalcA

    ; Queue Rendering of Accuracy Labels
    ld a, b
    ldh [hRenderLabelRight], a

    ; TODO: Update score
    ld hl, wScore
    ld a, 1
    ld b, SIZE_SCORE
    call AddBCD

    ; Update Combo
    ld hl, wCombo
    ld a, 1
    ld b, SIZE_COMBO
    call AddBCD

    ; Update Accuracy Label Clear Timeouts
    ld a, DELAY_LB_CLEAR
    ldh [hClearDelayRight], a
.noDrumPressA

    ; Check for B Button Presses
    ldh a, [hPressedKeys]
    and BTN_DRUM_B
    jp z, .noDrumPressB

    ; Search for lowest A Drum Circle
    ld hl, wShadowOAM
    ld b, l
    ld c, l
    ld d, OAM_COUNT/2
.circleScanLoopB
    ; Load Y-Pos of next circle
    ld a, [hli]
    cp $FF
    jr z, .noLowestCircleB
    cp b
    jr c, .noLowestCircleB
    ; Check if circle is actually A-drum circle via palette bit
    inc hl
    inc hl
    push af
    ld a, [hli]
    and OAMF_PAL1
    jr nz, .noLowestCirclePalB
    ; Update Output Registers
    pop af
    ld b, a                    ; Load lowest Circle Y into B
    ld c, l                    ; Load lowest Circle Address into C
    dec c
    dec c
    dec c
    dec c
    inc hl
    inc hl
    inc hl
    inc hl
    dec d
    jr nz, .circleScanLoopB
    jr .endCircleScanB
.noLowestCirclePalB
    pop af
    dec hl
    dec hl
    dec hl
.noLowestCircleB
    ; Go to next circle
    ld a, 7
    add l
    ld l, a
    dec d
    jr nz, .circleScanLoopB
.endCircleScanB

    ; If note is above OKAY range act as if nothing happened
    ld a, b
    cp NOTE_HIT_LY - RANGE_OKAY
    jr c, .noDrumPressB

    ; Move note out of frame
    ld h, HIGH(wShadowOAM)
    ld l, c
    ld [hl], $FF
    ld a, 4
    add l
    ld l, a
    ld [hl], $FF

    ; Get difference between perfect hit and circle sprite
    ld a, NOTE_HIT_LY
    sub b
    jr nc, .noAdjustDiffB
    ld a, b
    sub NOTE_HIT_LY
.noAdjustDiffB

    ; Determine hit range
    ld b, INDEX_MISS
    cp RANGE_OKAY
    jr nc, .endHitRangeCalcB
    ld b, INDEX_OKAY
    cp RANGE_GREAT
    jr nc, .endHitRangeCalcB
    ld b, INDEX_GREAT
    cp RANGE_PERFECT
    jr nc, .endHitRangeCalcB
    ld b, INDEX_PERFECT
.endHitRangeCalcB

    ; Queue Rendering of Accuracy Labels
    ld a, b
    ldh [hRenderLabelLeft], a

    ; TODO: Update score
    ld hl, wScore
    ld a, 1
    ld b, SIZE_SCORE
    call AddBCD

    ; Update Combo
    ld hl, wCombo
    ld a, 1
    ld b, SIZE_COMBO
    call AddBCD

    ; Update Accuracy Label Clear Timeouts
    ld a, DELAY_LB_CLEAR
    ldh [hClearDelayLeft], a
.noDrumPressB

    ;----------------------------------------------------------------------------
    ; Handle Event Spawning

    ; Check Event Delay
    ldh a, [hNextEventDelay]
    dec a
    ldh [hNextEventDelay], a
    jp nz, .waitForEvent

    ; Restore counters from stack & read next event byte
    pop hl
    pop bc
    ld a, [hli]
    dec bc

    ; Check for A Circle Spawn
    sla a
    jr nc, .noPressA

    ; Preserve Regs & Fetch Pointers
    push af
    push hl
    ld h, HIGH(wShadowOAM)
    ldh a, [hPtrOAM]
    ld l, a

    ; Load OAM Data
    xor a
    ld [hli], a
    ld a, WX_NOTE_LANE + 5 + 4*8
    ld [hli], a
    inc hl
    ld a, OAMF_PAL1
    ld [hli], a
    xor a
    ld [hli], a
    ld a, WX_NOTE_LANE + 13 + 4*8
    ld [hli], a
    inc hl
    ld a, OAMF_PAL1 | OAMF_XFLIP
    ld [hli], a

    ; Update OAM Pointer
    ld a, l
    cp $9F
    jr c, .oamInRangeA
    xor a
.oamInRangeA
    ldh [hPtrOAM], a

    ; Restore Registers
    pop hl
    pop af

    ; Check for B Circle Spawn
.noPressA
    sla a
    jr nc, .noPressB

    ; Preserve Regs & Fetch Pointers
    push af
    push hl
    ld h, HIGH(wShadowOAM)
    ldh a, [hPtrOAM]
    ld l, a

    ; Load OAM Data
    xor a
    ld [hli], a
    ld a, WX_NOTE_LANE + 5
    ld [hli], a
    inc hl
    ld a, OAMF_PAL0
    ld [hli], a
    xor a
    ld [hli], a
    ld a, WX_NOTE_LANE + 13
    ld [hli], a
    inc hl
    ld a, OAMF_PAL0 | OAMF_XFLIP
    ld [hli], a

    ; Update OAM Pointer
    ld a, l
    cp $9F
    jr c, .oamInRangeB
    xor a
.oamInRangeB
    ldh [hPtrOAM], a

    ; Restore Registers
    pop hl
    pop af

    ; Update Delay & Counters for Next Event
.noPressB
    ldh [hNextEventDelay], a
    push bc
    push hl

    ;----------------------------------------------------------------------------
    ; Update Sprites in Shadow OAM

    ; Initialize Update Loop
.waitForEvent
    ld hl, wShadowOAM
    ld c, 20
.circleUpdateLoop

    ; Check if circle is off screen
    ld a, [hl]
    cp $FF
    jr z, .offscreenCircle

    ; Calculate new Y Value, check if in range
    ld b, a
    ldh a, [hApproachSpeed]
    inc a
    add b
    cp NOTE_HIT_LY + NOTE_DESPAWN_RANGE
    jr c, .noteInRange

    ; Reset combo on missed note, set Y Value to $FF
    xor a
    ld [wCombo], a
    ld [wCombo+1], a
    ld a, $FF

    ; Update Y Values in Shadow OAM
.noteInRange
    ld [hli], a
    inc hl
    inc hl
    inc hl
    ld [hli], a
    inc hl
    inc hl
    inc hl
    dec c
    jr nz, .circleUpdateLoop
    jr .endCircleUpdate

    ; If circle off screen, skip 2 sprites (8 bytes)
.offscreenCircle
    ld a, 8
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    dec c
    jr nz, .circleUpdateLoop
.endCircleUpdate

    ;----------------------------------------------------------------------------
    ; Check initial song delay & do sound

    ; Check if delay is 0
    ldh a, [hSongPlayDelay]
    and a
    jr z, .doSound

    ; Decrement delay and return to start of loop
    dec a
    ldh [hSongPlayDelay], a
    jp MainGameLoop

    ; Play Sound and return to start of loop
.doSound
    call _hUGE_dosound
    jp MainGameLoop

;----------------------------------------------------------------------------
; Rendering routine for BCD numbers (Score & Combo)
; Falls through to RenderBCD but makes sure to remove all leading zeroes.
; Input:
;  HL - Pointer to HIGHEST byte of BCD Number
;  DE - Pointer to VRAM (upper tile address)
;  B  - Amount of BCD Bytes
;----------------------------------------------------------------------------
RenderBCD_NLZ:
    ; Skip all zero bytes
    ld a, [hl]
    and a
    jr nz, .noZeroBytes
    dec hl
    dec b
    jr z, .numberIsZero
    jr RenderBCD_NLZ
.numberIsZero
    xor a
    jr RenderBCD.renderNibble
.noZeroBytes

    ; Check if upper nibble is zero
    ld c, a
    and $F0
    ld a, c
    jr z, RenderBCD.onlyUpperNibble

;----------------------------------------------------------------------------
; Rendering routine for BCD numbers (Score & Combo)
; Input:
;  HL - Pointer to HIGHEST byte of BCD Number
;  DE - Pointer to VRAM (upper tile address)
;  B  - Amount of BCD Bytes
;----------------------------------------------------------------------------
RenderBCD:
    ; Load BCD byte, back up in C, swap nibbles
    ld a, [hld]
    ld c, a
    swap a

    ; Render lower nibble, swap nibbles, render upper nibble
    call .renderNibble
    ld a, c
.onlyUpperNibble
    call .renderNibble

    ; Check if all bytes have been rendered, if so return, otherwise loop
    dec b
    jr nz, RenderBCD
    ret

.renderNibble
    ; Get lower nibble, calculate upper tile address, write to VRAM
    and $0F
    add NUM_TILE_BASE
    ld [de], a

    ; Go to next tile line
    push af
    ld a, $20
    add e
    ld e, a
    adc d
    sub e
    ld d, a
    pop af

    ; Get lower tile index, load into VRAM, reset pointer to upper tile of next digit
    add 10
    ld [de], a
    ld a, e
    sub $1F
    ld e, a
    ret nc
    dec d
    ret



SECTION "Game Data", ROM0
InitDelayTable:
    db NOTE_HIT_LY/1
    db NOTE_HIT_LY/2
    db NOTE_HIT_LY/3
    db NOTE_HIT_LY/4

GameLabelTable:
    dw LabelTilemapOKAY
    dw LabelTilemapGREAT
    dw LabelTilemapPERFECT
    dw LabelTilemapMISS

LabelTilemapOKAY:    db 1, LB_OKAY_START,    1, LB_OKAY_START+1,    1, LB_OKAY_START+2,    1, 0, 0
LabelTilemapGREAT:   db 1, LB_GREAT_START,   1, LB_GREAT_START+1,   1, LB_GREAT_START+2,   1, 0, 0
LabelTilemapPERFECT: db 1, LB_PERFECT_START, 1, LB_PERFECT_START+1, 1, LB_PERFECT_START+2, 1, LB_PERFECT_START+3, 0
LabelTilemapMISS:    db 1, LB_MISS_START,    1, LB_MISS_START+1,    1, LB_MISS_START+2,    1, 0, 0



SECTION "Main Game WRAM", WRAM0
wCombo: ds SIZE_COMBO
wScore: ds SIZE_SCORE



SECTION "Main Game HRAM", HRAM
hApproachSpeed: db
hSongPlayDelay: db
hNextEventDelay: db
hPtrOAM: db

; Accuracy Label Variables
hClearDelayLeft: db
hClearDelayRight: db
hRenderLabelLeft: db
hRenderLabelRight: db



SECTION "Shadow OAM", WRAM0, ALIGN[8]
wShadowOAM::
    ds OAM_COUNT * 4



SECTION "Map Data RAM", WRAM0, ALIGN[8]
wMapData::
    ds $1000



SECTION "Ingame Graphics", ROMX, BANK[1]

GameTilesBG:
INCBIN "gfx/numbers.2bpp"
INCBIN "gfx/score.2bpp"
INCBIN "gfx/combo.2bpp"
EndGameTilesBG:

GameTilesSpritesWindow:
INCBIN "gfx/circle.2bpp"
INCBIN "gfx/drums.2bpp"
INCBIN "gfx/note_lane.2bpp"
INCBIN "gfx/miss.2bpp"
INCBIN "gfx/okay.2bpp"
INCBIN "gfx/great.2bpp"
INCBIN "gfx/perfect.2bpp"
EndGameTilesSpritesWindow:

NoteLaneTilemap:
db 1, NOTE_LANE_TILE_L, 1, $00, 1, NOTE_LANE_TILE_R, 1, $00, 1, NOTE_LANE_TILE_L, 1, $00, 1, NOTE_LANE_TILE_R, $19, $00, 0

TaikoTilemap:
db 1, DRUM_TILE_START,   1, DRUM_TILE_START+1,  1, DRUM_TILE_START+2,  1, $00, 1, DRUM_TILE_START,   1, DRUM_TILE_START+1,  1, DRUM_TILE_START+2, $19, $00
db 1, DRUM_TILE_START+3, 1, DRUM_TILE_START+4,  1, DRUM_TILE_START+5,  1, $00, 1, DRUM_TILE_START+3, 1, DRUM_TILE_START+4,  1, DRUM_TILE_START+5, $19, $00
db 1, DRUM_TILE_START+6, 1, "B",                1, DRUM_TILE_START+8,  1, $00, 1, DRUM_TILE_START+6, 1, "A",                1, DRUM_TILE_START+8, $19, $00
db 1, DRUM_TILE_START+9, 1, DRUM_TILE_START+10, 1, DRUM_TILE_START+11, 1, $00, 1, DRUM_TILE_START+9, 1, DRUM_TILE_START+10, 1, DRUM_TILE_START+11
db 0