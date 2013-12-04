;**********************************************
;*                                            *
;*      Knihovna pro práci s klávesnicí       *
;*    ===================================     *
;*                                            *
;*      Autor: Jaroslav Puchar                *
;*                                            *
;*      Datum poslední úpravy: 18.5.2007      *
;*                                            * 
;********************************************** 
            
    INCLUDE 'derivative.inc'

  xdef  KeyPressed
  xdef  INITKEYB

MY_ZEROPAGE: SECTION  SHORT

KeyPressed  rmb   1

;=========================================================================            
MyCode:     SECTION

INITKEYB    
            psha                        ; uschování registrù a akumulátoru
            pshx
            pshh
            MOV	    #$0F,PTADD          ; port A vstupní režim
            MOV	    #$F0,PTAPE          ; povolíme pull-up na PTA4-7
            mov     #%00000110,KBI1SC   ; povolení pøerušení od KBI, sestupná hrana vyvolá pøerušení
            mov     #%11110000,KBI1PE   ; horní 4 bity jsou vstupy klávesnice   
            lda     #$FF
            sta     KeyPressed          ; poèáteèní hodnota promìnné 
            CLI                         ; povolení pøerušení  
            pulh                        ; obnovení registrù a akumulátoru
            pulx
            pula
            rts                         ; návrat z podprogramu
;=========================================================================            
ikwait      PSHH              ; uschování registrù a akumulátoru
            PSHX
            PSHA
            LDHX    #$0010    ; nastavení hodnoty pro zpoždìní 
ikwait1     AIX     #-1       ; H:X = H:X-1
            feed_watchdog     ; reset watchdogu
            CPHX    #0        ; je H:X = 0?
            BNE     ikwait1   ; pokud ne, skoè na ikwait1
            PULA              ; obnovení registrù a akumulátoru
            PULX
            PULH
            RTS               ; návrat z podprogramu
;=========================================================================            
test_klaves:pshx                    ; uschovej registry a akumulátor
            pshh                    ;
            psha                    ;
            jsr     ikwait          ; vyvolej èekání pro ustálení portu
            lda     PTAD            ; naèti port klávesnice
            cmp     #$70            ; je hodnota portu 01110000 bin
            bne     test_klaves2    ; pokud ne, testuj další sloupec
                                    ; pokud ano, byla stisknuta klávesa ve tøetím sloupci
            lda     #$03            ; inicializuj KeyPressed na hodnotu 3
            sta     KeyPressed
            bra     test_klaves5    ; pokraèuj detekcí øádku
test_klaves2:                       ;
            cmp     #$B0            ; je hodnota portu 10110000 bin
            bne     test_klaves3    ; pokud ne testuj další sloupec       
            lda     #$02            ; inicializuj KeyPressed na hodnotu 2
            sta     KeyPressed
            bra     test_klaves5    ; pokraèuj detekcí øádku
test_klaves3:                       ;
            cmp     #$D0            ; je hodnota portu 11010000 bin
            bne     test_klaves4    ; pokud ne testuj další sloupec
            lda     #$01            ; inicializuj KeyPressed na hodnotu 1
            sta     KeyPressed
            bra     test_klaves5    ; pokraèuj detekcí øádku
test_klaves4:                       ;
            cmp     #$E0            ; je hodnota portu 11100000 bin
            bne     test_klaves_ER  ; NE - žádný sloupec není aktivní ERROR
            lda     #$00            ; inicializuj KeyPressed na hodnotu 0
            sta     KeyPressed
test_klaves5:                       ; DETEKCE ØÁDKU
            lda     #%11111110      ; ulož do A detekèní øetìzec
            sta     PTAD            ; pošli øetìzec na port
            jsr     ikwait          ; vyvolej èekání pro ustálení portu
            lda     PTAD            ; naèti port do A 
            and     #%11110000      ; nuluj spodní 4 bity
            cmp     #$F0            ; je hodnota  F0 hex
            beq     test_klaves6    ; ANO - v tomto øádku nebyla stisknuta klávesa
            bra     test_klaves_kon ; NE - Byla stisknuta klávesa v prvním øádku 
                                    ; Netøeba upravovat KeyPressed - ukonèi 
test_klaves6:
            lda     #%11111101      ; pošli na port detekèní øetìzec
            sta     PTAD            ; pošli øetìzec na port
            jsr     ikwait          ; vyvolej èekání pro ustálení portu
            lda     PTAD            ; naèti port do A 
            and     #%11110000      ; nuluj spodní 4 bity
            cmp     #$F0            ; je hodnota  F0 hex  
            beq     test_klaves7    ; ANO - v tomto øádku nebyla stisknuta klávesa
                                    ; NE  - Byla stisknuta klávesa ve druhém øádku 
            lda     KeyPressed      ; naèti promìnnou KeyPressed 
            add     #4              ; zvyš její hodnotu o 4
            sta     KeyPressed      ; ulož promìnnou            
            bra     test_klaves_kon ; ukonèi

test_klaves7:
            lda     #%11111011      ; pošli na port detekèní øetìzec
            sta     PTAD            ; pošli øetìzec na port
            jsr     ikwait          ; vyvolej èekání pro ustálení portu
            lda     PTAD            ; naèti port do A 
            and     #%11110000      ; nuluj spodní 4 bity
            cmp     #$F0            ; je hodnota  F0 hex    
            beq     test_klaves8    ; ANO - v tomto øádku nebyla stisknuta klávesa
                                    ; NE  - Byla stisknuta klávesa ve tøetím øádku 
            lda     KeyPressed      ; naèti promìnnou KeyPressed 
            add     #8              ; zvyš její hodnotu o 8
            sta     KeyPressed      ; ulož promìnnou               
            bra     test_klaves_kon ; ukonèi
test_klaves8:            
            lda     #%11110111      ; pošli na port detekèní øetìzec
            sta     PTAD            ; pošli øetìzec na port
            jsr     ikwait          ; vyvolej èekání pro ustálení portu
            lda     PTAD            ; naèti port do A
            and     #%11110000      ; nuluj spodní 4 bity
            cmp     #$F0            ; je hodnota  F0 hex
            beq     test_klaves_ER  ; ANO - žádný øádek není aktivní ERROR
                                    ; NE  - Byla stisknuta klávesa ve tøetím øádku
            lda     KeyPressed      ; naèti promìnnou KeyPressed 
            add     #12             ; zvyš její hodnotu o 12
            sta     KeyPressed      ; ulož promìnnou
            
test_klaves_kon:                    ; standardní ukonèení pøerušení
            lda     #%11110000      ; obnov stav portu 
            sta     PTAD            ; 
            bset    2,KBI1SC        ; vynuluj pøíznak pøerušení od klávesnice
            pula                    ; obnov registry a akumulátor 
            pulh
            pulx
            rti                     ; návrat z obsluhy pøerušení

test_klaves_ER:                     ; ukonèení pøerušení s CHYBOU
            lda     #$FF            ; nastav KeyPressed na  FF hex 
            sta     KeyPressed
            bra     test_klaves_kon ; skoè na ukonèení            
;=========================================================================            
            org     $FFD2           ; adresa vektoru pøerušení od KBI
            dc.w    test_klaves     ; vyplnìní vektoru adresou naší obsluhy

