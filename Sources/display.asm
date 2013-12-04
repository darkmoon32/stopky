;**********************************************
;*                                            *
;*      Knihovna pro pr�ci s displejem        *
;*    ==================================      *
;*                                            *
;*      Autor: Jaroslav Puchar                *
;*                                            *
;*      Datum posledn� �pravy: 18.5.2007      *
;*                                            * 
;**********************************************

;rev.2 (19.11.2007)
;p�epracov�na obsluha p�eru�en� z d�vodu vysok� z�t�e CPU
;rev.3 (26.11.2008)
;�prava ovlada�e pro pou�it� s TPM2
;�prava inicializa�n� rutiny INITDISP


    INCLUDE 'derivative.inc'
  
  xdef  INITDISP              ; inicializace displeje
  xdef  CLRRED                ; smaz�n� �erven�ho displeje
  xdef  CLRGREEN              ; smaz�n� zelen�ho displeje
  xdef  RED10                 ; zobrazen� des�tkov�ho ��sla na �erven� displej
  xdef  GREEN10               ; zobrazen� des�tkov�ho ��sla na zelen� displej
  xdef  RED16                 ; zobrazen� 16-ti bitov�ho ��sla na �erven� displej v hex tvaru
  xdef  GREEN16               ; zobrazen� 16-ti bitov�ho ��sla na zelen� displej v hex tvaru
  xdef  REDDISP               ; 4 bytov� prom�nn� pro �erven� displej
  xdef  GREENDISP             ; 4 bytov� prom�nn� pro zelen� displej

  

MY_ZEROPAGE: SECTION  SHORT

GREENDISP   rmb   4           ; 4 bytov� prom�nn� pro zelen� displej 
REDDISP     rmb   4           ; 4 bytov� prom�nn� pro �erven� displej
activdisp   rmb   1           ; zde se ukl�d� ��slo aktivn�ho displeje p�i obsluze p�eru�en�
adrdisp     rmb   1           ; slouzi pro adresaci aktivniho displeje
pom         rmb   1
            

MyCode:     SECTION

; tabulka znak� pou��van�ch knihovnou


Num0:       equ %11000000     ; znak 0
Num1:       equ %01111001     ; znak 1
Num2:       equ %00100100     ; znak 2
Num3:       equ %00110000     ; znak 3
Num4:       equ %00011001     ; znak 4
Num5:       equ %00010010     ; znak 5
Num6:       equ %00000010     ; znak 6
Num7:       equ %01111000     ; znak 7
Num8:       equ %00000000     ; znak 8
Num9:       equ %00010000     ; znak 9
NumA:       equ %00001000     ; znak A
NumB:       equ %00000011     ; znak B
NumC:       equ %01000110     ; znak C
NumD:       equ %00100001     ; znak D
NumE:       equ %00000110     ; znak E
NumF:       equ %00001110     ; znak F
Zhasni:     equ %11111111     ; zhasnut� segmentu  
CharH:      equ %00001001     ; znak H


;=========================================================================            
INITDISP:
            psha                        ; uschov�n� registr� a akumul�toru
            pshx
            pshh
            clr     activdisp
            clr     adrdisp
            lda     PTEDD
            ora     #%00111000
            sta     PTEDD               ; inicializace portu E (PTE3-5 v�stupn� re�im)
            mov     #$ff,PTCDD          ; inicializace portu C
                                        ; inicializace �asova�e
            mov     #%01001000,TPM2SC   ; inicializace TPM2, fsource=busclk, prescaler=1
            ldhx    #50000              ; obsah modulo registru pro ttof=1/400s
            sthx    TPM2MODH            ; nastaven� modulo registru 
            ldhx    #REDDISP            ; inicializace prom�nn� REDDISP 
            lda     #Zhasni             ; pro zhasnut� cel�ho �erven�ho displeje
            sta     0,X
            sta     1,X
            sta     2,X
            sta     3,X
            ldhx    #GREENDISP          ; inicializace prom�nn� REDDISP 
            sta     0,X                 ; pro zhasnut� cel�ho �erven�ho displeje
            sta     1,X
            sta     2,X
            sta     3,X
            CLI                         ; povolen� p�eru�en�
            pulh                        ; obnoven� registr� a akumul�toru
            pulx
            pula
            rts                         ; n�vrat z podprogramu
;=========================================================================            
CLRRED      psha                ; uschov�n� registr� a akumul�toru
            pshx
            pshh
            ldhx    #REDDISP    ; na�ten� adresy prom�nn� REDDISP
            bra     clrdata     ; skok na smaz�n� prom�nn� 
CLRGREEN    pshh                ; uschov�n� registr� a akumul�toru
            pshx
            psha
            ldhx    #GREENDISP  ; na�ten� adresy prom�nn� REDDISP
clrdata     sei                 ; zak�z�n� p�eru�en� 
            lda     #Zhasni     ; na�ti konstantu pro zhasnut�
            sta     0,X         ; vynuluj prom�nnou
            sta     1,X         
            sta     2,X
            sta     3,X
            cli                 ; povolen� p�eru�en�
            pulh                ; obnoven� registr� a akumul�toru
            pulx               
            pula
            rts                 ; n�vrat z podprogramu
;=========================================================================            
RED10:      
            psha                ; uschov�n� registr� a akumul�toru
            pshx
            pshh
            pshx
            pshh
            ldhx    #REDDISP    ; na�ten� adresy prom�nn� REDDISP        
                                ; kontrola nen�-li zadan� ��slo v�t�� ne� 9999 (270F hex)
            lda     1,SP        ; na�ten� horn�ho bytu p�ev�d�n�ho ��sla
            cmp     #$27        ; porovnej horn� byte s hodnotou 27 hex 
            bhi     ERROR10     ; pokud je horn� byte v�t�� CHYBA 
            blo     Red10A      ; pokud je horn� byte men�� m��e� sko�it na p�evod
                                ; pokud je horn� byte roven otestuj spodn� byte
            lda     2,SP        ; na�ten� spodn�ho bytu p�ev�d�n�ho ��sla
            cmp     #$0F        ; porovnej spodn� byte s hodnotou 0F hex 
            bhi     ERROR10     ; pokud je horn� byte v�t�� CHYBA
                                ; pokud je men�� nebo roven m��e� pokra�ovat v p�evodu 
Red10A:     pulh                ; na�ti horn� byte do reg H (pro ��ely d�len�)
            pshh
            lda     2,SP        ; na�ti spodn� byte do akumul�toru A (pro ��ely d�len�)
            ldx     #100        ; do reg X na�ti d�litel 100
            div                 ; prove� d�len�
            pshh                ; schovej zbytek po d�len�
            psha                ; schovej pod�l          
            clrh                ; sma� reg H (pro ��ely d�len�)
            ldx     #10         ; do X na�ti d�litel 10
            div                 ; prove� d�len�
                                
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            pshh                ; uschovej zbytek na z�sobn�k (pro sou�et)
            ora     1,SP        ; se�ti rotovan� pod�l a zbytek
            pulh                ; odstra� zbytek ze z�sobn�ku
            sta     1,SP        ; uschovej nov� horn� byte na z�sobn�ku
            lda     2,SP        ; na�ti zbytek po d�len� 100
            clrh                ; sma� reg H (pro ��ely d�len�)
            ldx     #10         ; do X na�ti d�litel 10
            div                 ; prove� d�len�
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            pshh                ; uschovej zbytek na z�sobn�k (pro sou�et)
            ora     1,SP        ; se�ti rotovan� pod�l a zbytek
            pulh                ; odstra� zbytek ze z�sobn�ku
            sta     2,SP        ; uschovej nov� spodn� byte na z�sobn�ku
            pulh                ; na�ti vytvo�en� 16-ti bitov� ��slo do H:X
            pulx
            ais     #2          ; uprav ukazatel na z�sobn�k 
            jmp     RED16a      ; pokra�uj skokem na RED16a
;=========================================================================            
ERROR10:    lda     #$FF        ; ulo� chybovou n�vratovou hodnotu 
            sta     5,SP        
            lda     #CharH      ; na�ti znak H pro segment
            sei                 ; zaka� p�eru�en� 
            sta     0,X         ; ulo� znak H na cel� displej
            sta     1,X
            sta     2,X
            sta     3,X
            cli                 ; povol p�eru�en�
            pulh                ; obnov stav registr� a akumul�toru
            pulx
            pulh
            pulx
            pula
            rts                 ; n�vrat z podprogramu
;=========================================================================            
GREEN10:    psha                ; uschov�n� registr� a akumul�toru
            pshx
            pshh
            pshx
            pshh
            
            ldhx    #GREENDISP  ; na�ten� adresy prom�nn� GREENDISP        
                                ; kontrola nen�-li zadan� ��slo v�t�� ne� 9999 (270F hex)
            lda     1,SP        ; na�ten� horn�ho bytu p�ev�d�n�ho ��sla
            cmp     #$27        ; porovnej horn� byte s hodnotou 27 hex 
            bhi     ERROR10     ; pokud je horn� byte v�t�� CHYBA 
            blo     Green10A    ; pokud je horn� byte men�� m��e� sko�it na p�evod
                                ; pokud je horn� byte roven otestuj spodn� byte
            lda     2,SP        ; na�ten� spodn�ho bytu p�ev�d�n�ho ��sla
            cmp     #$0F        ; porovnej spodn� byte s hodnotou 0F hex 
            bhi     ERROR10     ; pokud je horn� byte v�t�� CHYBA
                                ; pokud je men�� nebo roven m��e� pokra�ovat v p�evodu 
Green10A:   pulh                ; na�ti horn� byte do reg H (pro ��ely d�len�)
            pshh
            lda     2,SP        ; na�ti spodn� byte do akumul�toru A (pro ��ely d�len�)
            ldx     #100        ; do reg X na�ti d�litel 100
            div                 ; prove� d�len�
            pshh                ; schovej zbytek po d�len�
            psha                ; schovej pod�l
            clrh                ; sma� reg H (pro ��ely d�len�)
            ldx     #10         ; do X na�ti d�litel 10
            div                 ; prove� d�len�
                                
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            pshh                ; uschovej zbytek na z�sobn�k (pro sou�et)
            ora     1,SP        ; se�ti rotovan� pod�l a zbytek
            pulh                ; odstra� zbytek ze z�sobn�ku
            sta     1,SP        ; uschovej nov� horn� byte na z�sobn�ku
            lda     2,SP        ; na�ti zbytek po d�len� 100
            clrh                ; sma� reg H (pro ��ely d�len�)
            ldx     #10         ; do X na�ti d�litel 10
            div                 ; prove� d�len�
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            clc                 ; sma� carry
            rola                ; rotuj pod�l do leva
            pshh                ; uschovej zbytek na z�sobn�k (pro sou�et)
            ora     1,SP        ; se�ti rotovan� pod�l a zbytek
            pulh                ; odstra� zbytek ze z�sobn�ku
            sta     2,SP        ; uschovej nov� spodn� byte na z�sobn�ku
            pulh                ; na�ti vytvo�en� 16-ti bitov� ��slo do H:X
            pulx
            ais     #2          ; uprav ukazatel na z�sobn�k 
            jmp     GREEN16a    ; pokra�uj skokem na GREEN16a
;=========================================================================            
RED16:      psha                  ; uschovej registry a akumul�tor
            pshx
            pshh
RED16a:     pshx                  ; vstup z podprogramu RED10
            pshh
            ldhx    #REDDISP      ; na�ti adresu prom�nn� REDDISP
            jmp     Load16        ; pokra�uj v na��tan� na Load16
GREEN16:    psha                  ; uschovej registry a akumul�tor
            pshx
            pshh
GREEN16a:   pshx                  ; vstup z podprogramu GREEN10
            pshh
            ldhx    #GREENDISP    ; na�ti adresu prom�nn� GREENDISP
Load16:     sei                   ; zak�z�n� p�eru�en�
            lda     1,SP          ; na�ti horn� byte vstupn� hodnoty
            and     #%11110000    ; vynuluj spodn� 4 bity
            clc                   ; sma� carry (pro ��ely rotace)
            rora                  ; rotuj o 4 bity doprava
            rora
            rora
            rora
            sta     pom            
            lda     5,sp
            cmp     #4
            beq     Treti
            lda     pom
            jmp     TretiFalse
Treti       lda     #16       
TretiFalse                
            jsr     Priradhodnotu ; volej podprogram na p�i�azen� hodnoty                     
            aix     #1            ; inkrementuj ukazatel na prom�nnou 
            lda     5,sp
            cmp     #3
            beq     Druha          
            lda     1,SP          ; na�ti horn� byte vstupn� hodnoty
            and     #%00001111    ; vynuluj horn� 4 bity
            jmp     DruhaFalse
Druha       lda     #16     
DruhaFalse
            jsr     Priradhodnotu ; volej podprogram na p�i�azen� hodnoty         
            aix     #1            ; inkrementuj ukazatel na prom�nnou 
            lda     5,sp
            cmp     #2
            beq     Prvni 
            lda     2,SP          ; na�ti spodn� byte vstupn� hodnoty
            and     #%11110000    ; vynuluj spodn� 4 bity
            clc                   ; sma� carry (pro ��ely rotace)
            rora                  ; rotuj o 4 bity doprava
            rora
            rora
            rora
            jmp     PrvniFalse
Prvni       lda     #16     
PrvniFalse
            jsr     Priradhodnotu ; volej podprogram na p�i�azen� hodnoty                     
            aix     #1            ; inkrementuj ukazatel na prom�nnou 
            lda     5,sp
            cmp     #1
            beq     Nulta
            lda     2,SP          ; na�ti spodn� byte vstupn� hodnoty
            and     #%00001111    ; vynuluj horn� 4 bity
            jmp     NultaFalse
Nulta       lda     #16
NultaFalse
            jsr     Priradhodnotu ; volej podprogram na p�i�azen� hodnoty                
            aix     #2     
            pulh                  ; obnoven� registru a akumul�toru
            pulx
            pulh
            pulx
            pula
            cli                   ; povolen� p�eru�en�
            rts                   ; n�vrat z podprogramu
;=========================================================================            
Priradhodnotu                 ; v A je ulo�en index znaku kter� se m� zobrazit
                              ; v H:X je adresa kam bude znak ulo�en  
            cmp     #0        ; porovnej A s hodnotou 0
            bne     H1        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num0     ; pokud je A 0 na�ti znak 0
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H1          cmp     #1        ; porovnej A s hodnotou 
            bne     H2        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num1     ; pokud je A 1 na�ti znak 1
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H2          cmp     #2        ; porovnej A s hodnotou 2
            bne     H3        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num2     ; pokud je A 2 na�ti znak 2
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H3          cmp     #3        ; porovnej A s hodnotou 3
            bne     H4        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num3     ; pokud je A 3 na�ti znak 3
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H4          cmp     #4        ; porovnej A s hodnotou 4
            bne     H5        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num4     ; pokud je A 4 na�ti znak 4
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H5          cmp     #5        ; porovnej A s hodnotou 5
            bne     H6        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num5     ; pokud je A 5 na�ti znak 5
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H6          cmp     #6        ; porovnej A s hodnotou 6
            bne     H7        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num6     ; pokud je A 6 na�ti znak 6
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H7          cmp     #7        ; porovnej A s hodnotou 7
            bne     H8        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num7     ; pokud je A 7 na�ti znak 7
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H8          cmp     #8        ; porovnej A s hodnotou 8
            bne     H9        ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num8     ; pokud je A 8 na�ti znak 8
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H9          cmp     #9        ; porovnej A s hodnotou 9
            bne     H10       ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #Num9     ; pokud je A 9 na�ti znak 9
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H10         cmp     #10       ; porovnej A s hodnotou 10
            bne     H11       ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #NumA     ; pokud je A 10 na�ti znak A
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H11         cmp     #11       ; porovnej A s hodnotou 11
            bne     H12       ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #NumB     ; pokud je A 11 na�ti znak B
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H12         cmp     #12       ; porovnej A s hodnotou 12
            bne     H13       ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #NumC     ; pokud je A 12 na�ti znak C
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H13         cmp     #13       ; porovnej A s hodnotou 13
            bne     H14       ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #NumD     ; pokud je A 13 na�ti znak D
            sta     0,X       ; ulo� jej na adresu ukazatele H:X             
            rts               ; n�vrat z podprogramu
H14         cmp     #14       ; porovnej A s hodnotou 14
            bne     H15       ; pokud nen� roven porovnej s dal�� hodnotou
            lda     #NumE     ; pokud je A 14 na�ti znak E
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
H15         cmp     #15       ; porovnej A s hodnotou 15
            bne     WX        ; pokud nen� roven porovnej segment
            lda     #NumF     ; pokud je A 15 na�ti znak F
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
WX          lda     #Zhasni   ; na�ti znak zhasnut� segmentu
            sta     0,X       ; ulo� jej na adresu ukazatele H:X
            rts               ; n�vrat z podprogramu
;=========================================================================            
IDWAIT      PSHH              ; ulo� pou��van� registry na z�sobn�k
            PSHX
            PSHA
            LDHX    #$1000
IDWAIT1     AIX     #-1       ; H:X = H:X-1
            feed_watchdog     ; reset watchdogu
            CPHX    #0        ; je H:X = 0?
            BNE     IDWAIT1   ; pokud ne, sko� na idwait1
            PULA              ; obnov p�vodn� obsah registr� ze z�sobn�ku
            PULX
            PULH
            RTS               ; n�vrat z podprogramu
;=========================================================================            
LED_INT:
            pshh                    ; uschovej registr H
            lda     TPM2SC          ; p�e�ti stav TPM1
            bclr    7,TPM2SC        ; vynuluj p��znak p�eru�en�
            lda     activdisp
            cmp     #8
            blo     n1
            clr     activdisp
            clr     adrdisp
n1          ldhx    #GREENDISP
            txa  
            add     activdisp
            tax
            bcc     n2              ; pokud neni nastaven carry, skoc
            pshh                    ; pokud je C nastaven, inkrementuj H o 1
            pula
            inca
            psha
            pulh
n2          lda     adrdisp
            sta     PTED            ; aktivace prislusneho segmentu
            lda     0,x
            sta     PTCD            ; zobrazeni znaku
            inc     activdisp
            lda     adrdisp
            add     #%00001000      ; zvyseni adresy displeje
            sta     adrdisp
            pulh                    ; obnov registr H ze z�sobn�ku
            rti                     ; n�vrat z obsluhy p�eru�en�            
            
            
;=========================================================================            
            org     $ffe2           ; adresa vektoru p�eru�en� TOF od TPM2
            dc.w    LED_INT         ; vypln�n� vektoru adresou obsluhy p�eru�en�
            