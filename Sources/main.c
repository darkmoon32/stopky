#include <hidef.h> /* for EnableInterrupts macro */
#include "derivative.h" /* include peripheral declarations */

#include "main_asm.h" /* interface to the assembly module */
#include "display.h"
#include "keyboard.h"
#include "gpio.h"
#include "rtmon_08.h"
#include "sci_gb60.h" 

IDPROC *init, *pSCI, *pStopky, *pCounter, *pKeyboard, *pCas; 
//functions prototypes
void sci( void );
void stopky(void);
void counter(void);
void keyboard(void);
void cas(void);
 

//global variables
unsigned long time = 0;
unsigned char mezicas = 0, stop = 0,tlac;

void main(void) {
  
  EnableInterrupts; /* enable interrupts */
  /* include your code here */
  ATD1C = 0xC4;   	// zapnuti prevodniku, 8 bit vysledek    
  ATD1PE = 1;     	// pin PTB0 prepneme do rezimu 			  	// vstupu A/D prevodniku  
  PTADD_PTADD5 =0;      	// PTA4 vstupni rezim
  PTAPE_PTAPE5 = 1;	// pull-up pro PTA4 zapnut

  INITDISP();           //inicializace displeje
  INITKEYB();           //inicializace klavesnice
  tlac = KeyPressed;
  gpio_led_init(0xf);
  gpio_led_off(0xf);

  asm_main(); /* call the assembly function */

  rtm_init(&init);
  rtm_create_p("proc1", 100, sci, 0x100, &pSCI );
  rtm_create_p("proc2", 10, stopky, 32, &pStopky );
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

}

void stopky(void)
{
    int low,high;
    while(1)
    {       
        low = ((time / 60) * 100) + (time % 100);
        high = (time & 0xff00) >> 4;
        //p = 124574 % 100;
        //t = (124574 / 6000);
        RED10(0,low);
        GREEN10(0,high);
    }
}

void counter(void)
{
    
}

void keyboard(void)
{
    while(1)
    {
        if(KeyPressed != 0xff && KeyPressed != tlac)
        {
            tlac = KeyPressed;
            switch(tlac)
            {
                case 0xc :
                    time = 0; 
                    rtm_start_p(pStopky,0,0);
                    rtm_delay_p(pKeyboard,0);
                break;
                case 0xd : break;
                case 0xe : break;
                case 0xf : break;
            }
        }
    }
    rtm_stop_p(pKeyboard);
}