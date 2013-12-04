// --------------------------------------------------------------------------------
// Hlavickovy soubor pro ovladac 7seg displeje "display.asm"
// FAI, UTB ve Zlínì, 2007
// --------------------------------------------------------------------------------

// funkce
void INITDISP(void);                // inicializace displeje
void CLRRED(void);                  // smazání èerveného displeje
void CLRGREEN(void);                // smazání zeleného displeje
void RED10(unsigned char t, unsigned int);           // zobrazení desítkového èísla na èervený displej
void GREEN10(unsigned char t, unsigned int);         // zobrazení desítkového èísla na zelený displej
void RED16(unsigned int);           // zobrazení 16-ti bitového èísla na èervený displej v hex tvaru
void GREEN16(unsigned int);         // zobrazení 16-ti bitového èísla na zelený displej v hex tvaru

// promìnné umožòující pøímý pøístup na display
extern unsigned long REDDISP;       // 4 bytová promìnná pro èervený displej
extern unsigned long GREENDISP;     // 4 bytová promìnná pro zelený displej
