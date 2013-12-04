// =======================================================================
// rtmon_08c.H
//
// Sluzby RTMON pro HC08
// Hlavickovy soubor pro RTMON
// =======================================================================
#ifndef  RTMON_HCO8_H_09
    #define RTMON_HCO8_H_09


// Chybove kody sluzeb
#define         RTMON_OK                 (0)
#define         RERR_ID_PROC        (3)         // chybne ID procesu
#define         RERR_NO_MEM        (1)         // malo pameti - vraci create_p pokud dojde zasobnik nebo uz je moc procesu
#define         RERR_NO_SUP         (9)         // neplatny parametr sluzby, nepodporovana funkce - vraci pro create_q s vice zpravami
#define         RERR_ID_QUEUE     (5)         // neplatne id schranky
#define         RERR_FULL_Q           (7)         // plna schranka (write_q)
#define         RERR_EMPTY_Q      (6)         // prazdna schranka     (read_q)
#define         RERR_WAIT_Q          (10)        // nelze cekat na schranku protoze uz ceka jiny proces (read_q_w a write_q_w)

// datova struktura procesu
typedef struct 
{
        unsigned char ident;     // ID procesu (index do pole struktur IDPROC)
        unsigned char no_ident;  // negace predchoziho
        unsigned char prio;     // priorita
        unsigned char   stat;   // stav procesu
        void (*pfunc)(void);    // adresa tela procesu
        //char*   pstack;         // adresa dna zasobniku
        unsigned int pstack;   // adresa vrcholu zasobniku - kde je SP pokud je zasobnik prazdny
        unsigned int   stack_size;     // velikost zasobniku
        //char*   akt_stack;       // aktualni hodnota SP procesu
        unsigned int    akt_stack;  
        unsigned int    time_period;    // perioda pri cyklickem spusteni
        unsigned int    time_to_start;  // cas do dalsiho spusteni
        unsigned int    time_to_continue;   // cas do pokracovani pro delay_p (toto v RTMON neni, je delano nejak jinak)
        //void*   prev;                   // adresa predchoziho a dalsiho procesu ve fronte?
        //void*   next;     
        
} IDPROC;     

// datova struktura schranky
typedef struct
{
        unsigned char ident;     // ID schranky (index do pole struktur)
        unsigned char no_ident;  // negace predchoziho    
        unsigned char l_msg;    // delka zpravy
        unsigned char n_wait_buff;      // zda je schranka obsazena (1 = obsazeno, 0 = volno)
        char* buff;     // ukazatel na buffer schranky
        IDPROC*  pid_proc_msg;  // proces cekajici na zpravu
        IDPROC* pid_proc_buff;      // proces cekajici na volnou schranku
        
} IDQUEUE;



// prototypy sluzeb
char rtm_init(IDPROC** init_id);  
char rtm_end(IDPROC* init_id);
char rtm_create_p(const char* pname, unsigned char prio, void(*pfunc)( ), int stack_size, IDPROC** proc_id );
char rtm_start_p(IDPROC* proc_id, int time_to_start, int time_period);
char rtm_delay_p(IDPROC* proc_id, int time_to_delay);
char rtm_continue_p(IDPROC * proc_id);
char rtm_ch_period_p(IDPROC * proc_id, int time_period);
char rtm_stop_p(IDPROC * proc_id );
char rtm_abort_p(IDPROC * proc_id );

char rtm_create_q(const char* pname, char l_msg, char n_buff, IDQUEUE** pid_queue);
char rtm_write_q(IDQUEUE*   pid_queue, void* pdata);
char rtm_write_q_w(IDQUEUE*   pid_queue, void* pdata);
char rtm_read_q(IDQUEUE*   pid_queue, void* pdata);
char rtm_read_q_w(IDQUEUE*   pid_queue, void* pdata);


/////////////////////////////////////////////////
#endif  // RTMON_HCO8_H_09
