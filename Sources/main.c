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
void counterFunction(char stream);
void intToTime(unsigned long t, char * string);
char strToTime(char * string); 

//global variables
unsigned long time = 0,counterTo = 0;
unsigned char mezicas = 0, stop = 0,tlac;
void (*pFun)(char);
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
  char string[10],znak;
  int pozice = 0;
  do{
    __RESET_WATCHDOG();
    if(pozice == 9)
      pozice = 0;
    znak = sci1_in();
    if(znak != 0)
      string[pozice++] = znak;
    if(strstr(string,"stopky") != NULL){  
      gpio_led_on(LED4);
      pFun = &stopkyFunction;
      pFun(1);
      gpio_led_off(LED4);
    } else if(strstr(string,"counter") != NULL){
      sci1_str_out("Zadejte cas ve formatu H:MM:SS,MS\r\n");
      pFun = &counterFunction;
      pFun(1);
    }
    string[0] = '\0';
  }while(strstr(string,"konec") == NULL);
  rtm_stop_p(pSCI);
}

void stopky(void)
{
    pFun(0);
    rtm_stop_p(pCas);
}


void stopkyFunction(char stream)
{
  int low,high,pozice = 0,delay = 0;
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
        
        if(mezicas == 0 && stop == 0){
          if(delay++ > 0xCFFF){
            delay = 0;
            gpio_led_toggle(LED1);
          }          
        }
        
        if(KeyPressed == 0xC || strstr(string,"start") != NULL){//stisknuto stop/start
          stop |= 1;
          if(stop == 1){
            rtm_ch_period_p(pCas,0);
            rtm_delay_p(pCas,0);
            if(stream == 1){
              sci1_str_out("Stop ");
              intToTime(time,string);
              sci1_str_out(string);
              sci1_str_out("\r\n");
            }
          } else{
            rtm_ch_period_p(pCas,2);
            rtm_continue_p(pCas);
            if(stream == 1){
              sci1_str_out("Start ");
              intToTime(time,string);
              sci1_str_out(string);
              sci1_str_out("\r\n");
            }
          }
        } else if(KeyPressed == 0xD || strstr(string,"mezi") != NULL){ //stisknut mezicas
          mezicas |= 1;
          gpio_led_toggle(LED1);
          if(stream == 1){
            sci1_str_out("Mezicas ");
            intToTime(time,string);
            sci1_str_out(string);
            sci1_str_out("\r\n");
          }
        } else if(KeyPressed == 0xE || strstr(string,"reset") != NULL){//stisknut reset
          if(stop == 1){
            time = 0;
            rtm_ch_period_p(pCas,0);
            rtm_delay_p(pCas,0);
            if(stream == 1){
              sci1_str_out("Restart ");
              intToTime(time,string);
              sci1_str_out(string);
              sci1_str_out("\r\n");
            }
          }else{
            RED10(0,0);
            GREEN10(0,0);
            stop = 0;
            mezicas = 0;
            if(stream == 1){
              sci1_str_out("Konec\r\n");
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
  pFun(0);
  rtm_stop_p(pCounter);    
}

void counterFunction(char stream){
  char *string = "0:00:00,00",znak;
  int pozice = 0, blink, low, high, display = 0;
  long pomTime;
  unsigned char hide = 0;
  if(stream == 1){
    do{
      __RESET_WATCHDOG();
      znak = sci1_in();
      string[pozice++] = znak;
      if(pozice> 19)
        pozice = 0;
    } while(znak != '#');
    if(strToTime(string)){
      sci1_str_out("Chybne zadani. Ukoncuji\n\r");
      return;
    }
  } else{
    pozice = 0xff;
    while(KeyPressed != 0xD){
      __RESET_WATCHDOG();
      blink = 0xfff;
      if(pozice == 0xff){
        pozice = (KeyPressed < 8 && KeyPressed != 0 ? KeyPressed : 0xff);
        KeyPressed = 0xff;
        low = ((counterTo / 100) % 60) + (counterTo % 100);
        high = (counterTo / 360000) + (counterTo / 6000) % 60;
        RED10(0,low);
        GREEN10(0,high);
        while(blink-- > 0)__RESET_WATCHDOG();
        CLRRED();
        CLRGREEN();
      } else{
        switch(pozice){
          case 4 : hide = 4;break;
          case 1 :
          case 5 : hide = 3;break;
          case 2 :
          case 6 : hide = 2;break;
          case 3 :
          case 7 : hide = 1;break;
          default : hide = 0;break;
        }
        display = (pozice < 4 ? 1 : 0);//1 zelený display 0 èervený
        while(KeyPressed > 9 || KeyPressed == 0){
          blink = 0xfff;
          if(display == 1){
            GREEN10(hide,high);
          } else{
            RED10(hide,low);
          }
          while(blink-- > 0)__RESET_WATCHDOG();
          if(display == 1){
            GREEN10(0,high);
          } else{
            RED10(0,low);
          }
        }
        switch(pozice){
          case 1 : string[0] = KeyPressed + '0';break;
          case 2 : string[2] = KeyPressed + '0';break;
          case 3 : string[3] = KeyPressed + '0';break;
          case 4 : string[5] = KeyPressed + '0';break;
          case 5 : string[6] = KeyPressed + '0';break;
          case 6 : string[8] = KeyPressed + '0';break;
          case 7 : string[9] = KeyPressed + '0';break;
        }
        string[10] = '\0';
        
        KeyPressed = pozice = 0xff;
      }
    }
  }
  while(KeyPressed != 0xD || sci1_in() == 's')__RESET_WATCHDOG();
  strToTime(string);
  time = 0;
  rtm_start_p(pCas,0,2);
  while(KeyPressed != 0xD || sci1_in() == 's'){
    __RESET_WATCHDOG();
    pomTime = counterTo - time;
    if(pomTime > 0){      
      low = ((pomTime / 100) % 60) + (pomTime % 100);
      high = (pomTime / 360000) + (pomTime / 6000) % 60;
      RED10(0,low);
      GREEN10(0,high);
    }
    if(pomTime <= 0 && pomTime > -500){
      while(pomTime > -500){
        __RESET_WATCHDOG();
        blink = 0xfff;
        CLRRED();
        CLRGREEN();
        while(blink-- > 0) __RESET_WATCHDOG();
        RED10(0,0);
        GREEN10(0,0);
        pomTime = counterTo - time;
      }
    } else{
      pomTime = abs(pomTime);
      low = ((pomTime / 100) % 60) + (pomTime % 100);
      high = (pomTime / 360000) + (pomTime / 6000) % 60;
      GREENDISP &= 0x0fff;
      GREENDISP |= 0x40000000;
    }
  }
  counterTo = 0;
  return;
}

char strToTime(char *string){
  long multiplier = 360000;
  unsigned long t = 0;
  char i = 0,decimal = 1;
  while(i < 10){
    if(string[i] < 48 || string[i] > 57)
      return 1;
    t += (string[i] - '0') * multiplier * decimal;
    i++;
    decimal = 1;
    if(string[i] == ':' || string[i] == ','){
      i++;
      decimal = 10;
      multiplier /= 60;
    }
  }
  counterTo = t;
  return 0;
}

void keyboard(void)
{
  char string[25];
    while(1)
    {   __RESET_WATCHDOG();
   strToTime("1:23:45,67");
        if(KeyPressed != 0xff && KeyPressed != tlac && KeyPressed > 9)
        {
            tlac = KeyPressed;
            switch(tlac)
            {
              case 0xC :
                  time = 0;
                  pFun = &stopkyFunction; 
                  rtm_start_p(pStopky,0,0);
                  //rtm_delay_p(pKeyboard,0);
              break;
              case 0xD : 
                pFun = &counterFunction;
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