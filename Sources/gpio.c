//#include "gpio.h"
#include "derivative.h"

#define Pin0               1
#define Pin1               2
#define Pin2               4
#define Pin3               8
#define Pin4               16
#define Pin5               32
#define Pin6               64
#define Pin7               128
#define vystupMode         0 
#define vstupMode          1

void gpio_led_init(int ledx)
{
    PTFPE &= ~ledx;
    PTFDD ^= ledx; 
}

void gpio_led_on(int ledx)
{
    PTFD &= ~ledx;
}

void gpio_led_off(int ledx)
{
    PTFD |= ledx;
}

void gpio_led_toggle(int ledx)
{
    PTFD ^= ledx;
}

void gpio_button_init(int buttonx)
{
    PTADD ^= ~buttonx;
    PTAPE ^= buttonx;
}

int gpio_button_test(int buttonx)
{   
    if((PTAD & buttonx) == 0)
        return 1;
    else
        return 0;
}

void gpio_button_test_w(int buttonx)
{
    while(gpio_button_test(buttonx) != 1);
}