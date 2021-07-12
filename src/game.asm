;----------------------------------------------------------------------------
; Constant Definitions
;----------------------------------------------------------------------------

; "Config" Constants
DEF WX_NOTE_LANE     EQU 100
DEF NOTE_HIT_LY      EQU $6C

; Tile Numbers
DEF NOTE_LANE_TILE_L EQU $10
DEF NOTE_LANE_TILE_R EQU $11
DEF DRUM_TILE_START  EQU $04
DEF LB_SCORE_START   EQU $94
DEF LB_COMBO_START   EQU $97
DEF NUM_TILE_BASE    EQU $80
DEF CIRCLE_TILE_BASE EQU $02
DEF LB_MISS_START    EQU $12
DEF LB_OKAY_START    EQU $15
DEF LB_GREAT_START   EQU $18
DEF LB_PERFECT_START EQU $1B

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
    ld hl, $9C00
    ld b, 3
    ld a, LB_SCORE_START
.scoreLabelLoad
    ld [hli], a
    inc a
    dec b
    jr nz, .scoreLabelLoad

    ; Load Points Label
    ld hl, $9C20
    ld de, $9C40
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
    ld hl, $9E00
    ld b, 4
    ld a, LB_COMBO_START
.comboLabelLoad
    ld [hli], a
    inc a
    dec b
    jr nz, .comboLabelLoad
    ld hl, $9DC0
    ld [hl], NUM_TILE_BASE
    ld hl, $9DE0
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

    ; Copy map to WRAM, preserve length in stack
    push bc
    ld d, h
    ld e, l
    inc de
    ld hl, wMapData
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
    xor a
    ldh [hNextEventDelay], a

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
    ; Check initial song delay & do sound

    ; Check if delay is 0
    ldh a, [hSongPlayDelay]
    and a
    jr z, .doSound

    ; Decrement delay and return to start of loop
    dec a
    ldh [hSongPlayDelay], a
    jr MainGameLoop

    ; Play Sound and return to start of loop
.doSound
    call _hUGE_dosound
    jr MainGameLoop



SECTION "Initial Delay Table", ROM0
InitDelayTable:
    db NOTE_HIT_LY/1
    db NOTE_HIT_LY/2
    db NOTE_HIT_LY/3
    db NOTE_HIT_LY/4



SECTION "Main Game HRAM", HRAM
hApproachSpeed: db
hSongPlayDelay: db
hNextEventDelay: db



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