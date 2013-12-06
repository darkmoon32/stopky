#include <hidef.h> /* for EnableInterrupts macro */
#include "derivative.h" /* include peripheral declarations */

#include "main_asm.h" /* interface to the assembly module */
#include "display.h"
#include "keyboard.h"
#include "gpio.h"
#include "rtmon_08.h"
#include "sci_gb60.h"
#include <stdio.h> 

#define SCIDEBUG  0
#define LED1      1
#define LED2      2
#define LED3      4
#define LED4      8

IDPROC *init, *pSCI, *pStopky, *pCounter, *pKeyboard, *pCas; 
//functions prototypes
void sci( void );
void stopky(void);
void counter(void);
void keyboard(void);
void cas(void);
void stopkyFunction(char stream);
 

//global variables
unsigned long time = 124142;
unsigned char mezicas = 0, stop = 0,tlac;

void main(void) {
  
  EnableInterrupts; /* enable interrupts */
  /* include your code here */
  ATD1C = 0xC4;   	// zapnuti prevodniku, 8 bit vysledek    
  ATD1PE = 1;     	// pin PTB0 prepneme do rezimu 			  	// vstupu A/D prevodniku  
  PTADD_PTADD5 =0;      	// PTA4 vstupni rezim
  PTAPE_PTAPE5 = 1;	// pull-up pro PTA4 zapnut

  #if SCIDEBUG
    sci1_init(BD9600);
  #endif

  INITDISP();           //inicializace displeje
  INITKEYB();           //inicializace klavesnice
  tlac = KeyPressed;
  gpio_led_init(0xf);
  gpio_led_off(0xf);

  asm_main(); /* call the assembly function */

  rtm_init(&init);
  rtm_create_p("proc1", 100, sci, 100, &pSCI );
  rtm_create_p("proc2", 10, stopky, 100, &pStopky );
  rtm_create_p("proc3", 20, counter, 32, &pCounter );
  rtm_create_p("proc4", 254, keyboard, 32, &pKeyboard );
  rtm_create_p("proc5", 1, cas, 32, &pCas );
  rtm_start_p(pCas,0,2);
  rtm_start_p(pKeyboard,0,0);

  rtm_delay_p(init,0);

  for(;;) {
    __RESET_WATCHDOG(); /* feeds the dog */
  } /* loop forever */
  /* please make sure that you never leave main */
}

//function definition
void cas(void)
{
    time++;
    rtm_stop_p(pCas);
}

void sci( void )
{
  gpio_led_on(LED4);
  stopkyFunction(1);
  gpio_led_off(LED4);
  rtm_stop_p(pSCI);
}

void stopky(void)
{
    stopkyFunction(0);
    rtm_stop_p(pCas);
}


void stopkyFunction(char stream)
{
  int low,high,pozice = 0;
  char znak;
  char string[25];
    while(1)
    {   __RESET_WATCHDOG();
      if(stream == 1){
        do{
          znak = sci1_in();
          string[pozice++] = znak;
        }while(znak != '#');
        string[pozice] = '\0';
        pozice = 0;
      }
        if(mezicas == 0 && stream == 0){          
          low = ((time / 100) % 60) + (time % 100);
          high = (time / 360000) + (time / 6000) % 60;
          RED10(0,low);
          GREEN10(0,high);
        }
        
        if(KeyPressed == 0xC || strstr(string,"start") != NULL){//stisknuto stop/start
          stop |= 1;
          if(stop == 1){
            rtm_ch_period_p(pCas,0);
            rtm_delay_p(pCas,0);
            if(stream == 1){
              sci1_str_out("Stop");
            }
          } else{
            rtm_ch_period_p(pCas,2);
            rtm_continue_p(pCas);
            if(stream == 1){
              sci1_str_out("Start");
            }
          }
        } else if(KeyPressed == 0xD || strstr(string,"mezi") != NULL){ //stisknut mezicas
          mezicas |= 1;
          if(stream == 1){
            sci1_str_out("Mezicas");
          }
        } else if(KeyPressed == 0xE || strstr(string,"reset") != NULL){//stisknut reset
          if(stop == 1){
            time = 0;
            rtm_ch_period_p(pCas,0);
            rtm_delay_p(pCas,0);
            if(stream == 1){
              sci1_str_out("Restart");
            }
          }else{
            RED10(0,0);
            GREEN10(0,0);
            stop = 0;
            mezicas = 0;
            if(stream == 1){
              sci1_str_out("Konec");
            }
            return;
          }
          
        }
    }
}

void intToTime(unsigned long t, char * string){
  int i = 0, divide = 0, pozice = 0;
  long divider = 360000;
  while(i++ < 4){
    divide = t / divider;
    t -= divide * divider;
    string[pozice++] = divide / 10 + '0';
    string[pozice++] = divide % 10 + '0';
    if(i < 3)
      string[pozice++] = ':';
    else if(i == 3)
      string[pozice++] = ',';
    divider /= 60;
  }
  string[pozice] = '\0';
}

void counter(void)
{
    
}

void keyboard(void)
{
  char string[25];
    while(1)
    {   __RESET_WATCHDOG();
    intToTime(time,string);
        if(KeyPressed != 0xff && KeyPressed != tlac && KeyPressed > 9)
        {
            tlac = KeyPressed;
            switch(tlac)
            {
              case 0xC :
                  time = 0; 
                  rtm_start_p(pStopky,0,0);
                  //rtm_delay_p(pKeyboard,0);
              break;
              case 0xD : 
                rtm_start_p(pCounter,0,0);
              break;
              case 0xE :
                rtm_start_p(pSCI,0,0);
              break;
              case 0xF : break;
            }
        }
    }
    rtm_stop_p(pKeyboard);
}