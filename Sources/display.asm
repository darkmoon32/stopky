;**********************************************
;*                                            *
;*      Knihovna pro práci s displejem        *
;*    ==================================      *
;*                                            *
;*      Autor: Jaroslav Puchar                *
;*                                            *
;*      Datum poslední úpravy: 18.5.2007      *
;*                                            * 
;**********************************************

;rev.2 (19.11.2007)
;pøepracována obsluha pøerušení z dùvodu vysoké zátìže CPU
;rev.3 (26.11.2008)
;úprava ovladaèe pro použití s TPM2
;úprava inicializaèní rutiny INITDISP


    INCLUDE 'derivative.inc'
  
  xdef  INITDISP              ; inicializace displeje
  xdef  CLRRED                ; smazání èerveného displeje
  xdef  CLRGREEN              ; smazání zeleného displeje
  xdef  RED10                 ; zobrazení desítkového èísla na èervený displej
  xdef  GREEN10               ; zobrazení desítkového èísla na zelený displej
  xdef  RED16                 ; zobrazení 16-ti bitového èísla na èervený displej v hex tvaru
  xdef  GREEN16               ; zobrazení 16-ti bitového èísla na zelený displej v hex tvaru
  xdef  REDDISP               ; 4 bytová promìnná pro èervený displej
  xdef  GREENDISP             ; 4 bytová promìnná pro zelený displej

  

MY_ZEROPAGE: SECTION  SHORT

GREENDISP   rmb   4           ; 4 bytová promìnná pro zelený displej 
REDDISP     rmb   4           ; 4 bytová promìnná pro èervený displej
activdisp   rmb   1           ; zde se ukládá èíslo aktivního displeje pøi obsluze pøerušení
adrdisp     rmb   1           ; slouzi pro adresaci aktivniho displeje
pom         rmb   1
            

MyCode:     SECTION

; tabulka znakù používaných knihovnou


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
Zhasni:     equ %11111111     ; zhasnutí segmentu  
CharH:      equ %00001001     ; znak H


;=========================================================================            
INITDISP:
            psha                        ; uschování registrù a akumulátoru
            pshx
            pshh
            clr     activdisp
            clr     adrdisp
            lda     PTEDD
            ora     #%00111000
            sta     PTEDD               ; inicializace portu E (PTE3-5 výstupní režim)
            mov     #$ff,PTCDD          ; inicializace portu C
                                        ; inicializace èasovaèe
            mov     #%01001000,TPM2SC   ; inicializace TPM2, fsource=busclk, prescaler=1
            ldhx    #50000              ; obsah modulo registru pro ttof=1/400s
            sthx    TPM2MODH            ; nastavení modulo registru 
            ldhx    #REDDISP            ; inicializace promìnné REDDISP 
            lda     #Zhasni             ; pro zhasnutí celého èerveného displeje
            sta     0,X
            sta     1,X
            sta     2,X
            sta     3,X
            ldhx    #GREENDISP          ; inicializace promìnné REDDISP 
            sta     0,X                 ; pro zhasnutí celého èerveného displeje
            sta     1,X
            sta     2,X
            sta     3,X
            CLI                         ; povolení pøerušení
            pulh                        ; obnovení registrù a akumulátoru
            pulx
            pula
            rts                         ; návrat z podprogramu
;=========================================================================            
CLRRED      psha                ; uschování registrù a akumulátoru
            pshx
            pshh
            ldhx    #REDDISP    ; naètení adresy promìnné REDDISP
            bra     clrdata     ; skok na smazání promìnné 
CLRGREEN    pshh                ; uschování registrù a akumulátoru
            pshx
            psha
            ldhx    #GREENDISP  ; naètení adresy promìnné REDDISP
clrdata     sei                 ; zakázání pøerušení 
            lda     #Zhasni     ; naèti konstantu pro zhasnutí
            sta     0,X         ; vynuluj promìnnou
            sta     1,X         
            sta     2,X
            sta     3,X
            cli                 ; povolení pøerušení
            pulh                ; obnovení registrù a akumulátoru
            pulx               
            pula
            rts                 ; návrat z podprogramu
;=========================================================================            
RED10:      
            psha                ; uschování registrù a akumulátoru
            pshx
            pshh
            pshx
            pshh
            ldhx    #REDDISP    ; naètení adresy promìnné REDDISP        
                                ; kontrola není-li zadané èíslo vìtší než 9999 (270F hex)
            lda     1,SP        ; naètení horního bytu pøevádìného èísla
            cmp     #$27        ; porovnej horní byte s hodnotou 27 hex 
            bhi     ERROR10     ; pokud je horní byte vìtší CHYBA 
            blo     Red10A      ; pokud je horní byte menší mùžeš skoèit na pøevod
                                ; pokud je horní byte roven otestuj spodní byte
            lda     2,SP        ; naètení spodního bytu pøevádìného èísla
            cmp     #$0F        ; porovnej spodní byte s hodnotou 0F hex 
            bhi     ERROR10     ; pokud je horní byte vìtší CHYBA
                                ; pokud je menší nebo roven mùžeš pokraèovat v pøevodu 
Red10A:     pulh                ; naèti horní byte do reg H (pro úèely dìlení)
            pshh
            lda     2,SP        ; naèti spodní byte do akumulátoru A (pro úèely dìlení)
            ldx     #100        ; do reg X naèti dìlitel 100
            div                 ; proveï dìlení
            pshh                ; schovej zbytek po dìlení
            psha                ; schovej podíl          
            clrh                ; smaž reg H (pro úèely dìlení)
            ldx     #10         ; do X naèti dìlitel 10
            div                 ; proveï dìlení
                                
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            pshh                ; uschovej zbytek na zásobník (pro souèet)
            ora     1,SP        ; seèti rotovaný podíl a zbytek
            pulh                ; odstraò zbytek ze zásobníku
            sta     1,SP        ; uschovej nový horní byte na zásobníku
            lda     2,SP        ; naèti zbytek po dìlení 100
            clrh                ; smaž reg H (pro úèely dìlení)
            ldx     #10         ; do X naèti dìlitel 10
            div                 ; proveï dìlení
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            pshh                ; uschovej zbytek na zásobník (pro souèet)
            ora     1,SP        ; seèti rotovaný podíl a zbytek
            pulh                ; odstraò zbytek ze zásobníku
            sta     2,SP        ; uschovej nový spodní byte na zásobníku
            pulh                ; naèti vytvoøené 16-ti bitové èíslo do H:X
            pulx
            ais     #2          ; uprav ukazatel na zásobník 
            jmp     RED16a      ; pokraèuj skokem na RED16a
;=========================================================================            
ERROR10:    lda     #$FF        ; ulož chybovou návratovou hodnotu 
            sta     5,SP        
            lda     #CharH      ; naèti znak H pro segment
            sei                 ; zakaž pøerušení 
            sta     0,X         ; ulož znak H na celý displej
            sta     1,X
            sta     2,X
            sta     3,X
            cli                 ; povol pøerušení
            pulh                ; obnov stav registrù a akumulátoru
            pulx
            pulh
            pulx
            pula
            rts                 ; návrat z podprogramu
;=========================================================================            
GREEN10:    psha                ; uschování registrù a akumulátoru
            pshx
            pshh
            pshx
            pshh
            
            ldhx    #GREENDISP  ; naètení adresy promìnné GREENDISP        
                                ; kontrola není-li zadané èíslo vìtší než 9999 (270F hex)
            lda     1,SP        ; naètení horního bytu pøevádìného èísla
            cmp     #$27        ; porovnej horní byte s hodnotou 27 hex 
            bhi     ERROR10     ; pokud je horní byte vìtší CHYBA 
            blo     Green10A    ; pokud je horní byte menší mùžeš skoèit na pøevod
                                ; pokud je horní byte roven otestuj spodní byte
            lda     2,SP        ; naètení spodního bytu pøevádìného èísla
            cmp     #$0F        ; porovnej spodní byte s hodnotou 0F hex 
            bhi     ERROR10     ; pokud je horní byte vìtší CHYBA
                                ; pokud je menší nebo roven mùžeš pokraèovat v pøevodu 
Green10A:   pulh                ; naèti horní byte do reg H (pro úèely dìlení)
            pshh
            lda     2,SP        ; naèti spodní byte do akumulátoru A (pro úèely dìlení)
            ldx     #100        ; do reg X naèti dìlitel 100
            div                 ; proveï dìlení
            pshh                ; schovej zbytek po dìlení
            psha                ; schovej podíl
            clrh                ; smaž reg H (pro úèely dìlení)
            ldx     #10         ; do X naèti dìlitel 10
            div                 ; proveï dìlení
                                
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            pshh                ; uschovej zbytek na zásobník (pro souèet)
            ora     1,SP        ; seèti rotovaný podíl a zbytek
            pulh                ; odstraò zbytek ze zásobníku
            sta     1,SP        ; uschovej nový horní byte na zásobníku
            lda     2,SP        ; naèti zbytek po dìlení 100
            clrh                ; smaž reg H (pro úèely dìlení)
            ldx     #10         ; do X naèti dìlitel 10
            div                 ; proveï dìlení
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            clc                 ; smaž carry
            rola                ; rotuj podíl do leva
            pshh                ; uschovej zbytek na zásobník (pro souèet)
            ora     1,SP        ; seèti rotovaný podíl a zbytek
            pulh                ; odstraò zbytek ze zásobníku
            sta     2,SP        ; uschovej nový spodní byte na zásobníku
            pulh                ; naèti vytvoøené 16-ti bitové èíslo do H:X
            pulx
            ais     #2          ; uprav ukazatel na zásobník 
            jmp     GREEN16a    ; pokraèuj skokem na GREEN16a
;=========================================================================            
RED16:      psha                  ; uschovej registry a akumulátor
            pshx
            pshh
RED16a:     pshx                  ; vstup z podprogramu RED10
            pshh
            ldhx    #REDDISP      ; naèti adresu promìnné REDDISP
            jmp     Load16        ; pokraèuj v naèítaní na Load16
GREEN16:    psha                  ; uschovej registry a akumulátor
            pshx
            pshh
GREEN16a:   pshx                  ; vstup z podprogramu GREEN10
            pshh
            ldhx    #GREENDISP    ; naèti adresu promìnné GREENDISP
Load16:     sei                   ; zakázání pøerušení
            lda     1,SP          ; naèti horní byte vstupní hodnoty
            and     #%11110000    ; vynuluj spodní 4 bity
            clc                   ; smaž carry (pro úèely rotace)
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
            jsr     Priradhodnotu ; volej podprogram na pøiøazení hodnoty                     
            aix     #1            ; inkrementuj ukazatel na promìnnou 
            lda     5,sp
            cmp     #3
            beq     Druha          
            lda     1,SP          ; naèti horní byte vstupní hodnoty
            and     #%00001111    ; vynuluj horní 4 bity
            jmp     DruhaFalse
Druha       lda     #16     
DruhaFalse
            jsr     Priradhodnotu ; volej podprogram na pøiøazení hodnoty         
            aix     #1            ; inkrementuj ukazatel na promìnnou 
            lda     5,sp
            cmp     #2
            beq     Prvni 
            lda     2,SP          ; naèti spodní byte vstupní hodnoty
            and     #%11110000    ; vynuluj spodní 4 bity
            clc                   ; smaž carry (pro úèely rotace)
            rora                  ; rotuj o 4 bity doprava
            rora
            rora
            rora
            jmp     PrvniFalse
Prvni       lda     #16     
PrvniFalse
            jsr     Priradhodnotu ; volej podprogram na pøiøazení hodnoty                     
            aix     #1            ; inkrementuj ukazatel na promìnnou 
            lda     5,sp
            cmp     #1
            beq     Nulta
            lda     2,SP          ; naèti spodní byte vstupní hodnoty
            and     #%00001111    ; vynuluj horní 4 bity
            jmp     NultaFalse
Nulta       lda     #16
NultaFalse
            jsr     Priradhodnotu ; volej podprogram na pøiøazení hodnoty                
            aix     #2     
            pulh                  ; obnovení registru a akumulátoru
            pulx
            pulh
            pulx
            pula
            cli                   ; povolení pøerušení
            rts                   ; návrat z podprogramu
;=========================================================================            
Priradhodnotu                 ; v A je uložen index znaku který se má zobrazit
                              ; v H:X je adresa kam bude znak uložen  
            cmp     #0        ; porovnej A s hodnotou 0
            bne     H1        ; pokud není roven porovnej s další hodnotou
            lda     #Num0     ; pokud je A 0 naèti znak 0
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H1          cmp     #1        ; porovnej A s hodnotou 
            bne     H2        ; pokud není roven porovnej s další hodnotou
            lda     #Num1     ; pokud je A 1 naèti znak 1
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H2          cmp     #2        ; porovnej A s hodnotou 2
            bne     H3        ; pokud není roven porovnej s další hodnotou
            lda     #Num2     ; pokud je A 2 naèti znak 2
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H3          cmp     #3        ; porovnej A s hodnotou 3
            bne     H4        ; pokud není roven porovnej s další hodnotou
            lda     #Num3     ; pokud je A 3 naèti znak 3
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H4          cmp     #4        ; porovnej A s hodnotou 4
            bne     H5        ; pokud není roven porovnej s další hodnotou
            lda     #Num4     ; pokud je A 4 naèti znak 4
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H5          cmp     #5        ; porovnej A s hodnotou 5
            bne     H6        ; pokud není roven porovnej s další hodnotou
            lda     #Num5     ; pokud je A 5 naèti znak 5
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H6          cmp     #6        ; porovnej A s hodnotou 6
            bne     H7        ; pokud není roven porovnej s další hodnotou
            lda     #Num6     ; pokud je A 6 naèti znak 6
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H7          cmp     #7        ; porovnej A s hodnotou 7
            bne     H8        ; pokud není roven porovnej s další hodnotou
            lda     #Num7     ; pokud je A 7 naèti znak 7
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H8          cmp     #8        ; porovnej A s hodnotou 8
            bne     H9        ; pokud není roven porovnej s další hodnotou
            lda     #Num8     ; pokud je A 8 naèti znak 8
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H9          cmp     #9        ; porovnej A s hodnotou 9
            bne     H10       ; pokud není roven porovnej s další hodnotou
            lda     #Num9     ; pokud je A 9 naèti znak 9
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H10         cmp     #10       ; porovnej A s hodnotou 10
            bne     H11       ; pokud není roven porovnej s další hodnotou
            lda     #NumA     ; pokud je A 10 naèti znak A
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H11         cmp     #11       ; porovnej A s hodnotou 11
            bne     H12       ; pokud není roven porovnej s další hodnotou
            lda     #NumB     ; pokud je A 11 naèti znak B
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H12         cmp     #12       ; porovnej A s hodnotou 12
            bne     H13       ; pokud není roven porovnej s další hodnotou
            lda     #NumC     ; pokud je A 12 naèti znak C
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H13         cmp     #13       ; porovnej A s hodnotou 13
            bne     H14       ; pokud není roven porovnej s další hodnotou
            lda     #NumD     ; pokud je A 13 naèti znak D
            sta     0,X       ; ulož jej na adresu ukazatele H:X             
            rts               ; návrat z podprogramu
H14         cmp     #14       ; porovnej A s hodnotou 14
            bne     H15       ; pokud není roven porovnej s další hodnotou
            lda     #NumE     ; pokud je A 14 naèti znak E
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
H15         cmp     #15       ; porovnej A s hodnotou 15
            bne     WX        ; pokud není roven porovnej segment
            lda     #NumF     ; pokud je A 15 naèti znak F
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
WX          lda     #Zhasni   ; naèti znak zhasnutí segmentu
            sta     0,X       ; ulož jej na adresu ukazatele H:X
            rts               ; návrat z podprogramu
;=========================================================================            
IDWAIT      PSHH              ; ulož používané registry na zásobník
            PSHX
            PSHA
            LDHX    #$1000
IDWAIT1     AIX     #-1       ; H:X = H:X-1
            feed_watchdog     ; reset watchdogu
            CPHX    #0        ; je H:X = 0?
            BNE     IDWAIT1   ; pokud ne, skoè na idwait1
            PULA              ; obnov pùvodní obsah registrù ze zásobníku
            PULX
            PULH
            RTS               ; návrat z podprogramu
;=========================================================================            
LED_INT:
            pshh                    ; uschovej registr H
            lda     TPM2SC          ; pøeèti stav TPM1
            bclr    7,TPM2SC        ; vynuluj pøíznak pøerušení
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
            pulh                    ; obnov registr H ze zásobníku
            rti                     ; návrat z obsluhy pøerušení            
            
            
;=========================================================================            
            org     $ffe2           ; adresa vektoru pøerušení TOF od TPM2
            dc.w    LED_INT         ; vyplnìní vektoru adresou obsluhy pøerušení
            