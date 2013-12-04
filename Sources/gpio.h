#ifndef gpio_h
#define gpio_h

void gpio_led_init(int ledx);
void gpio_led_on(int ledx);
void gpio_led_off(int ledx);
void gpio_led_toggle(int ledx);
void gpio_button_test_w(int buttonx);
int gpio_button_test(int buttonx);
void gpio_button_init(int buttonx);
#endif