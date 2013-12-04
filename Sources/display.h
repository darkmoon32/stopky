// --------------------------------------------------------------------------------
// Hlavickovy soubor pro ovladac 7seg displeje "display.asm"
// FAI, UTB ve Zl�n�, 2007
// --------------------------------------------------------------------------------

// funkce
void INITDISP(void);                // inicializace displeje
void CLRRED(void);                  // smaz�n� �erven�ho displeje
void CLRGREEN(void);                // smaz�n� zelen�ho displeje
void RED10(unsigned char t, unsigned int);           // zobrazen� des�tkov�ho ��sla na �erven� displej
void GREEN10(unsigned char t, unsigned int);         // zobrazen� des�tkov�ho ��sla na zelen� displej
void RED16(unsigned int);           // zobrazen� 16-ti bitov�ho ��sla na �erven� displej v hex tvaru
void GREEN16(unsigned int);         // zobrazen� 16-ti bitov�ho ��sla na zelen� displej v hex tvaru

// prom�nn� umo��uj�c� p��m� p��stup na display
extern unsigned long REDDISP;       // 4 bytov� prom�nn� pro �erven� displej
extern unsigned long GREENDISP;     // 4 bytov� prom�nn� pro zelen� displej
