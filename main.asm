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
    jr @