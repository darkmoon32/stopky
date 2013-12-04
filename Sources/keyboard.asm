;**********************************************
;*                                            *
;*      Knihovna pro pr�ci s kl�vesnic�       *
;*    ===================================     *
;*                                            *
;*      Autor: Jaroslav Puchar                *
;*                                            *
;*      Datum posledn� �pravy: 18.5.2007      *
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
            psha                        ; uschov�n� registr� a akumul�toru
            pshx
            pshh
            MOV	    #$0F,PTADD          ; port A vstupn� re�im
            MOV	    #$F0,PTAPE          ; povol�me pull-up na PTA4-7
            mov     #%00000110,KBI1SC   ; povolen� p�eru�en� od KBI, sestupn� hrana vyvol� p�eru�en�
            mov     #%11110000,KBI1PE   ; horn� 4 bity jsou vstupy kl�vesnice   
            lda     #$FF
            sta     KeyPressed          ; po��te�n� hodnota prom�nn� 
            CLI                         ; povolen� p�eru�en�  
            pulh                        ; obnoven� registr� a akumul�toru
            pulx
            pula
            rts                         ; n�vrat z podprogramu
;=========================================================================            
ikwait      PSHH              ; uschov�n� registr� a akumul�toru
            PSHX
            PSHA
            LDHX    #$0010    ; nastaven� hodnoty pro zpo�d�n� 
ikwait1     AIX     #-1       ; H:X = H:X-1
            feed_watchdog     ; reset watchdogu
            CPHX    #0        ; je H:X = 0?
            BNE     ikwait1   ; pokud ne, sko� na ikwait1
            PULA              ; obnoven� registr� a akumul�toru
            PULX
            PULH
            RTS               ; n�vrat z podprogramu
;=========================================================================            
test_klaves:pshx                    ; uschovej registry a akumul�tor
            pshh                    ;
            psha                    ;
            jsr     ikwait          ; vyvolej �ek�n� pro ust�len� portu
            lda     PTAD            ; na�ti port kl�vesnice
            cmp     #$70            ; je hodnota portu 01110000 bin
            bne     test_klaves2    ; pokud ne, testuj dal�� sloupec
                                    ; pokud ano, byla stisknuta kl�vesa ve t�et�m sloupci
            lda     #$03            ; inicializuj KeyPressed na hodnotu 3
            sta     KeyPressed
            bra     test_klaves5    ; pokra�uj detekc� ��dku
test_klaves2:                       ;
            cmp     #$B0            ; je hodnota portu 10110000 bin
            bne     test_klaves3    ; pokud ne testuj dal�� sloupec       
            lda     #$02            ; inicializuj KeyPressed na hodnotu 2
            sta     KeyPressed
            bra     test_klaves5    ; pokra�uj detekc� ��dku
test_klaves3:                       ;
            cmp     #$D0            ; je hodnota portu 11010000 bin
            bne     test_klaves4    ; pokud ne testuj dal�� sloupec
            lda     #$01            ; inicializuj KeyPressed na hodnotu 1
            sta     KeyPressed
            bra     test_klaves5    ; pokra�uj detekc� ��dku
test_klaves4:                       ;
            cmp     #$E0            ; je hodnota portu 11100000 bin
            bne     test_klaves_ER  ; NE - ��dn� sloupec nen� aktivn� ERROR
            lda     #$00            ; inicializuj KeyPressed na hodnotu 0
            sta     KeyPressed
test_klaves5:                       ; DETEKCE ��DKU
            lda     #%11111110      ; ulo� do A detek�n� �et�zec
            sta     PTAD            ; po�li �et�zec na port
            jsr     ikwait          ; vyvolej �ek�n� pro ust�len� portu
            lda     PTAD            ; na�ti port do A 
            and     #%11110000      ; nuluj spodn� 4 bity
            cmp     #$F0            ; je hodnota  F0 hex
            beq     test_klaves6    ; ANO - v tomto ��dku nebyla stisknuta kl�vesa
            bra     test_klaves_kon ; NE - Byla stisknuta kl�vesa v prvn�m ��dku 
                                    ; Net�eba upravovat KeyPressed - ukon�i 
test_klaves6:
            lda     #%11111101      ; po�li na port detek�n� �et�zec
            sta     PTAD            ; po�li �et�zec na port
            jsr     ikwait          ; vyvolej �ek�n� pro ust�len� portu
            lda     PTAD            ; na�ti port do A 
            and     #%11110000      ; nuluj spodn� 4 bity
            cmp     #$F0            ; je hodnota  F0 hex  
            beq     test_klaves7    ; ANO - v tomto ��dku nebyla stisknuta kl�vesa
                                    ; NE  - Byla stisknuta kl�vesa ve druh�m ��dku 
            lda     KeyPressed      ; na�ti prom�nnou KeyPressed 
            add     #4              ; zvy� jej� hodnotu o 4
            sta     KeyPressed      ; ulo� prom�nnou            
            bra     test_klaves_kon ; ukon�i

test_klaves7:
            lda     #%11111011      ; po�li na port detek�n� �et�zec
            sta     PTAD            ; po�li �et�zec na port
            jsr     ikwait          ; vyvolej �ek�n� pro ust�len� portu
            lda     PTAD            ; na�ti port do A 
            and     #%11110000      ; nuluj spodn� 4 bity
            cmp     #$F0            ; je hodnota  F0 hex    
            beq     test_klaves8    ; ANO - v tomto ��dku nebyla stisknuta kl�vesa
                                    ; NE  - Byla stisknuta kl�vesa ve t�et�m ��dku 
            lda     KeyPressed      ; na�ti prom�nnou KeyPressed 
            add     #8              ; zvy� jej� hodnotu o 8
            sta     KeyPressed      ; ulo� prom�nnou               
            bra     test_klaves_kon ; ukon�i
test_klaves8:            
            lda     #%11110111      ; po�li na port detek�n� �et�zec
            sta     PTAD            ; po�li �et�zec na port
            jsr     ikwait          ; vyvolej �ek�n� pro ust�len� portu
            lda     PTAD            ; na�ti port do A
            and     #%11110000      ; nuluj spodn� 4 bity
            cmp     #$F0            ; je hodnota  F0 hex
            beq     test_klaves_ER  ; ANO - ��dn� ��dek nen� aktivn� ERROR
                                    ; NE  - Byla stisknuta kl�vesa ve t�et�m ��dku
            lda     KeyPressed      ; na�ti prom�nnou KeyPressed 
            add     #12             ; zvy� jej� hodnotu o 12
            sta     KeyPressed      ; ulo� prom�nnou
            
test_klaves_kon:                    ; standardn� ukon�en� p�eru�en�
            lda     #%11110000      ; obnov stav portu 
            sta     PTAD            ; 
            bset    2,KBI1SC        ; vynuluj p��znak p�eru�en� od kl�vesnice
            pula                    ; obnov registry a akumul�tor 
            pulh
            pulx
            rti                     ; n�vrat z obsluhy p�eru�en�

test_klaves_ER:                     ; ukon�en� p�eru�en� s CHYBOU
            lda     #$FF            ; nastav KeyPressed na  FF hex 
            sta     KeyPressed
            bra     test_klaves_kon ; sko� na ukon�en�            
;=========================================================================            
            org     $FFD2           ; adresa vektoru p�eru�en� od KBI
            dc.w    test_klaves     ; vypln�n� vektoru adresou na�� obsluhy

