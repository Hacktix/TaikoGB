INCLUDE "hardware.inc"

SECTION "Vectors", ROM0[0]
    ds $40 - @

iVBlank:
    reti
    ds $48 - @

iSTAT:
    reti
    ds $50 - @

iTimer:
    reti
    ds $58 - @

iSerial:
    reti
    ds $60 - @

iJoypad:
    reti 
    ds $100 - @



SECTION "Main", ROM0[$100]
    jr Main

    ds $150 - @

Main::
    ld hl, totaka
    call hUGE_init

    ; TODO: Replace this with actual game code, just used to test hUGEDriver for now
.musicLoop
    call _hUGE_dosound
.idleLoop
    ldh a, [rLY]
    cp SCRN_Y
    jr nz, .idleLoop
    jr .musicLoop