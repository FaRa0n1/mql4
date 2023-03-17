//+------------------------------------------------------------------+
//|                                 FSAP v 1 0001.mq4 |
//zlecenia Buy otwierasz po cenie Ask , zamykasz po cenie Bid . 
//zlecenie Sell otwierasz po cenie Bid , zamykasz po cenie Ask. 
//japan
//#property strict
//int    rsi_period      = 14;
int        TICK =200;  //co ile tickow ma wykoywac kod - w celu przyspieszeniabacktestow

int    rsi_price       = PRICE_TYPICAL;
int    rsi_shift       = 0;     // 0 -sygnal na biezacej swiecy , 1 - sygnal po zamknieciu siewcy
double rsi_open_long   = 20.0;  // poziom wskaznika rsi dla otwarcia pozycji dlugiej
double rsi_open_short  = 80.0;  // poziom wskaznika rsi dla otwarcia pozycji krotkiej
double rsi_close_long  = 80.0;  // poziom wskaznika rsi dla zamkniecia pozycji dlugiejdebugerr

double rsi_close_short = 20.0;  // poziom wskaznika rsi dla zamkniecia pozycji krotkiejomment
double total_orders   ;         // suma zlecen buy i sell
double max_orders =1;           // maksymalna ilosc zlecen
int    max_oneway_orders = 1;   // maksymalna ilosc otwartych zlecen w jedna strone
int    next_step      = 10;     // ile minimum pipsow straty od ostatniej trasakcji zeby pozwolilo na otwarcie kolejnej transakcji (chodzi chyba o to gdy strategia uwzglednia wiecej niz 1 zlecenie w tym samym kierunku)

int    stop_loss      = 31;     // 0 lub wiecej ustawia stoploss , -1 wy³¹czony
int    dynamic_stop_loss_min  = 20;     // minimalny poziom na jaki zezwala znizyc sie dynamicznemu stop_loss opartemu o liniee keltnera
int    take_profit    = -1;     // 0 lub wiecej ustawia takeprofit , -1 wy³¹czony
int    wait_bars      = 4;      // ile musi uplynac swieczek od ostatniego sl zeby otworzylo nowa transakcje 

int    activate_be    = -1;     // przy ilu pipsach zysku maprzestawic be , -1 wy³¹czony  // Zadziala gdy stop_loss jest wylaczony (-1)  //DODAC POROWNYWANIE KTORY Z NICH JEST MNIEJSZY
int    step_be        = 5;      // na ile pipsow zysku ma przestawic stoploss , -1 wy³aczony /default 5
//Nieprzetestowane w przypadku roznych platform
int    activate_ts    = 0;     // przy ilu pisach zysku ma zaczac dziala TS, -1 wy³¹czony. // aby dzialo musi byc stop_loss>-1
int    step_ts        = 10;      // co ile pipsow zysku ma przestawiac TS
int    stop_loss_ts   = 10;     // stoploss dla TS , -1 korzysta z ogolnego stoploss podanego w zmiennej stop_loss (min.10)

int    hide_sl        = -1;     // ukryty stoploss , na ilu pipsach starty ma zamknac cala transakcje, -1 wy³¹czony
int    hide_tp        = -1;     // ukryty takeprofit , na ilu pipsach zysku ma zamknac cala transakcje, -1 wy³¹czony



extern bool   ecn_stp      = true;// jezeli broker ma zlecenia market execution ustawiamy true, w przeciwnym wypadku false;
extern double lot_size     = 1.0;// wielkoœæ pozycji
extern int    magic_number = 04062012;// unikalny numer ea po ktorym rozpoznaje swoje zlecenia
string comment_ea   = "FSAP KN1";// komentarz do zlecen
////////////////////////////////////////////////////////////////////////////////////////////////////////
// zmienne ze starego Ea
#define SIGNAL_NONE      0
#define SIGNAL_BUY       1
#define SIGNAL_SELL      2
#define SIGNAL_CLOSEBUY  3
#define SIGNAL_CLOSESELL 4
//#define OP_BUY -1
//#define OP_SELL -1
#property link      " "

extern int     MagicNumber  = 0;
extern bool    SignalMail   = False;
extern bool    EachTickMode = True;
extern double  Lots         = 1.0;
extern int     Slippage     = 3;
extern bool    UseStopLoss  = True;


int token_game       = 0;             // zamykanie na podstawie przekazywanego tokenu | 0 - wylaczone 1 - wlaczone
int token_short_game = 0;
int rsi100_game      = 0;
//  JEZELI StopLoss i min_First_OpenSL oraz min_OpenSL = beda mialy ustawione takie same wart. to funkcja zmiany SL bedzie wylaczona
int StopLoss         = 31; //30
int min_First_OpenSL = 31;            //minimalny poziom pierwotnego SL  //25
int min_OpenSL       = 31;            //minimalny poziom zmodyfikowanego SL //20

extern bool UseTakeProfit   = False;
extern int  TakeProfit      = 40 ;
extern bool UseTrailingStop = False;   // do wywalenia
extern int  TrailingStop    = 1;       //jezeli wieksze od 0 akt. ruchomego stop loss
//extern int TrailingStep   = 10;
int         BreakEven       = 1;       //|---poziom BE/ 0 off--------------------break even


//extern int BE_ActivatedLevel=30;     //do wywalenia
// ok A:15,D:5 dla slabego trendu? lub A:15 d:15 dla lepszego, moze tez 30:5, 20:15, ostatnie:40:15
extern int TS_ActivatedLevel = 1;      //35 //poziom aktywacji ruchomego stop loss
extern int TS_Distance       = 5;      // minimalna wartosc trailing stop / w procentowym SL nieuzywane
double     SL_proc           = 0;      // ile procent wartosci zlecenia ma byc SL
//---------------------------------------------------------
datetime time;
//double   MaxZysk=0,maksprice=0;
double maksprice_buy=0;
double maksprice_sell=0;
double MaxZysk_buy=0;
double MaxZysk_sell=0;
double price_min4 , price_max4, price_min_p[7], price_max_p[7], price_from_down, price_from_top, wielkosc_poslizgu, price_max_ask_tmp, price_max_bid_tmp; // funkcja sprawdza max i min roznice w cenie na przestrzenie ostatnich 4 swiec. Filtr.

int      BarCount;
int      Current;
double   Poin, mt;
double      pt; //pips
double points; // dla obliczania miejsc po przecinku - tutaj odgrywa np.*100
double points2; //dla obliczania miejsc po przecinku- tutaj odgrywa  np.*1000
//-------------obl sratnych pozycji-------------------
double Strata=0;
   int Ilosc=0;
//-------------------
double Supp_tmp, Resist_tmp; //zmienne do przechowywania istatnich wartosci support i resist
//S_15m[0],S_15m[1],S_15m[2],S_15m[3],S_15m[5],S_15m[6],R_15m[1],R_15m[2],R_15m[3],R_15m[4],R_15m[5],
double Supp_tmp_C, Resist_tmp_C; //zmienne do przechowywania istatnich wartosci support i resist w wersji Close (SR_Barry_Close)
//double S_c_15m[1],S_c_15m[2],S_c_15m[3],S_c_15m[4],S_c_15m[5],R_c_15m[1],R_c_15m[2],R_c_15m[3],R_c_15m[4],R_c_15m[5],
double Resist_15m,Support_15m, Resist_1h,Support_1h, Resist_4h,Support_4h, Resist_1d, Support_1d; //poziomy S/R dla wskaznika MTF Barry
//double Support;  // dla wskaznika SR_Barry_v5)
double Resist_C_15m, Support_C_15m;  //dla wskaznik SR_Barry_Close)
double Resist_C_1h,  Support_C_1h;  //dla wskaznik SR_Barry_Close)
double Resist_C_4h,  Support_C_4h;  //dla wskaznik SR_Barry_Close)
double Resist_C_1d,  Support_C_1d;  //dla wskaznik SR_Barry_Close)

double S_15m[7],R_15m[7],S_c_15m[7],R_c_15m[7]; //bylo zadeklarowane 6
double S_1h[7], R_1h[7], S_c_1h[7], R_c_1h[7];
double S_4h[7], R_4h[7], S_c_4h[7], R_c_4h[7];
double S_1d[7], R_1d[7], S_c_1d[7], R_c_1d[7];

//double R_15m[6], R_15m[6], S_c_15m[6], R_c_15m[6];


double R_15m_save_for_close_buy;                 // zmienna do przechowywania ostatniej wartosci Resist w momencie spelenienia warunku zamkniecia
double S_15m_save_for_close_sell;

double Last_R1_15m, Last_S1_15m;                 // zmienne do przechowywania ostatniej wartoœci SR w momencie otwarcia zlecenia
double Last_R_c_15m[], Last_S_c_15m[]; // jw. ale dla wskaznika w wersji Close (SR_Barry_Close)
//double PipsToLock=0.10;
int DoubleS_15m, DoubleR_15m;                    //licznik nowotworzonych pod raz linii Supportu lub Resist
int DoubleS_1h, DoubleR_1h;                    //licznik nowotworzonych pod raz linii Supportu lub Resist
int DoubleS_4h, DoubleR_4h;                    //licznik nowotworzonych pod raz linii Supportu lub Resist
int DoubleS_1d, DoubleR_1d;                    //licznik nowotworzonych pod raz linii Supportu lub Resist

int rtrend_15m=-1;                            //rodzaj trendu - rosnacy/malejacy/boczny
int rtrend_1h=-1;                            //rodzaj trendu - rosnacy/malejacy/boczny
int rtrend_4h=-1;                            //rodzaj trendu - rosnacy/malejacy/boczny
int rtrend_1d=-1;                            //rodzaj trendu - rosnacy/malejacy/boczny

int factor_buy;                  // ilosc punktow dla danego wejscia
int factor_sell;
int factor_buy_close;
int factor_sell_close;
   
int rtrend_short_15m;       // rodzaj trendu bliskotermionowego
int rtrend_short_1h;
int rtrend_short_4h;
int rtrend_short_1d;

datetime czas_otwarcia_buy;
datetime czas_otwarcia_sell;   

int ticket_for_close_buy;              //zezwolenie na zamkniecie clecenia (po drugij probie)
int ticket_for_close_sell;             //zezwolenie na zamkniecie clecenia (po drugij probie)
int ticket_for_close_buy_top_kelter;   //zezwolenie na zamkniecie gdy cena wraca ponizej gornej linii keltnera
int ticket_crit_for_buy;               //zezwolenie na natychmiastowe zamkniecie poprzez short dla buy
int ticket_crit_for_sell;              //zezwolenie na natychmiastowe zamkniecie poprzez short dla sell
int ticket_crit_for_buy2;              //zezwolenie na natychmiastowe zamkniecie gdy S (tak S a nie R) jest ponizej ceny zakupu (zamkniecie nastepuje przy drugiej fladze)
int ticket_crit_for_sell2;             //zezwolenie na natychmiastowe zamkniecie gdy R (tak R a nie S) jest powyzej ceny zakupu (zamkniecie nastepuje przy drugiej fladze)
int ticket_crit_for_buy3;              //zezwolenie na natychmiastowe zamkniecie gdy force index > 150
int ticket_crit_for_sell3;             //zezwolenie na natychmiastowe zamkniecie gdy force index > 150
int ticket_close_buy_sr_ket;           // zezwolenie na bezwzgledne zamykniecie buy poprzez srodkowa linie keltnera gdy cena zblizy sie do gornej linii keltnera
int ticket_close_sell_sr_ket;          // zezwolenie na bezwzgledne zamykniecie sell poprzez srodkowa linie keltnera gdy cena zblizy sie do dolnej linii keltnera

int ticket_open_short_buy, ticket_open_short_sell;       // ticket wymuszenie otwarcia poprzez short
int ticket_close_short_buy, ticket_close_short_sell;     // ticket wymuszenia zamkniecia poprzez short


int ticket_be_buy;  // realizacja bezwzglednego zamkniecia na BE po osiagnieciu danego zysku
int ticket_be_sell;

double save_s0_for_crit_close;       //na potrzeby przypisywania flagi ticket_crit_for_buy2
double save_r0_for_crit_close;       //na potrzeby przypisywania flagi ticket_crit_for_sell2
              
int ticket_close_sr_buy, ticket_close_sr_sell; // przdzielenie flagi zamkniecia przez sr.l.k gdy zysk bedzie wiekszy niz np 100pips
int ticket_after_close_sr_buy, ticket_after_close_sr_sell; // przdzielenie flagi szybkiego zamkniecia nastepnego zlecenia po zamknieciu wczesniejszego przez sr.l.k             


//keltner bands
double KD_15m, KM_15m, KU_15m;    //keltner down,middle,up dla linii Support i Ressist
double KD_1h, KM_1h, KU_1h;    //keltner down,middle,up dla linii Support i Ressist
double KD_4h, KM_4h, KU_4h;    //keltner down,middle,up dla linii Support i Ressist
double KD_1d, KM_1d, KU_1d;    //keltner down,middle,up dla linii Support i Ressist

double ketler_kat_dn, ketler_kat_up; // kat nachylenia linii ketlera
double sredni_kat_ketlera, sredni_kat_ketlera_p3, sredni_kat_ketlera_p7, sredni_kat_ketlera_p14, sredni_kat_ketlera_p21, sredni_kat_ketlera_p28,sredni_kat_ketlera_p100; // sredni kat dolenj liniii ketlera

double KD2_15m, KM2_15m, KU2_15m; // dla zapamietywania stanu l.keltnera z Period2
double KD2_1h, KM2_1h, KU2_1h; // dla zapamietywania stanu l.keltnera z Period2
double KD2_4h, KM2_4h, KU2_4h; // dla zapamietywania stanu l.keltnera z Period2
double KD2_1d, KM2_1d, KU2_1d; // dla zapamietywania stanu l.keltnera z Period2


double KDR_15m, KDS_15m, KMR_15m, KMS_15m, KUR_15m, KUS_15m;   //zapamietanie wartosci kazdej z linii kanalu ketlera w momencie wystapienia linii Support jak i Resist w celu porownania ich wzajemnych wart.
double KDR_1h, KDS_1h, KMR_1h, KMS_1h, KUR_1h, KUS_1h;   //zapamietanie wartosci kazdej z linii kanalu ketlera w momencie wystapienia linii Support jak i Resist w celu porownania ich wzajemnych wart.
double KDR_4h, KDS_4h, KMR_4h, KMS_4h, KUR_4h, KUS_4h;   //zapamietanie wartosci kazdej z linii kanalu ketlera w momencie wystapienia linii Support jak i Resist w celu porownania ich wzajemnych wart.
double KDR_1d, KDS_1d, KMR_1d, KMS_1d, KUR_1d, KUS_1d;   //zapamietanie wartosci kazdej z linii kanalu ketlera w momencie wystapienia linii Support jak i Resist w celu porownania ich wzajemnych wart.

//double KDR_c, KDS_c, KMR_c, KMS_c, KUR_c, KUS_c;   // jw. dla wersji wskaznika z poziomem Close`
//double KDR_c_tmp, KDS_c_tmp, KMR_c_tmp, KMS_c_tmp, KUR_c_tmp, KUS_c_tmp; //jw. ale jako zm. tymczasowa na potrzeby "przetasowania"
double KUO_15m, KMO_15m, KDO_15m;  //zapamietanie poziomu lini keltnera w momencie zakupu

//do wywalenia ponizsze
//zapamietanie wczesniejszych poziomow linii keltera w momencie wystapienia nowego S/R
//double KUR_c_15m[1],KUR_c_15m[2],KUR_c_15m[3],KUR_c_15m[4],KUR_c_15m[5]; //zmienne na potrzeby zapamietania nowych poziomow linii gornej l_keltera tworzonych przez nowy Resist
//double KMR_c_15m[1],KMR_c_15m[2],KMR_c_15m[3],KMR_c_15m[4],KMR_c_15m[5]; //zmienne na potrzeby zapamietania nowych poziomow linii sr. l_keltera tworzonych przez nowy Resist
//double KDR_c_15m[0],KDR_c_15m[1],KDR_c_15m[2],KDR_c_15m[3],KDR_c_15m[4],KDR_c_15m[5]; //zmienne na potrzeby zapamietania nowych poziomow linii dolnej l_keltera tworzonych przez nowy Resist
//double KUS_c_15m[0],KUS_c_15m[1],KUS_c_15m[2],KUS_c_15m[3],KUS_c_15m[4],KUS_c_15m[5]; //zmienne na potrzeby zapamietania nowych poziomow linii gornej l_keltera tworzonych przez nowy Support
//double KMS_c_15m[0],KMS_c_15m[1],KMS_c_15m[2],KMS_c_15m[3],KMS_c_15m[4],KMS_c_15m[5]; //zmienne na potrzeby zapamietania nowych poziomow linii sr. l_keltera tworzonych przez nowy Support
//double KDS_c_15m[0],KDS_c_15m[2],KDS_c_15m[2],KDS_c_15m[3],KDS_c_15m[4],KDS_c_15m[5]; //zmienne na potrzeby zapamietania nowych poziomow linii dolnej l_keltera tworzonych przez nowy Support

double KUR_c_15m[7],KUS_c_15m[7],KMR_c_15m[7],KMS_c_15m[7],KDR_c_15m[7],KDS_c_15m[7];
double KUR_c_1h[7], KUS_c_1h[7], KMR_c_1h[7], KMS_c_1h[7], KDR_c_1h[7], KDS_c_1h[7];
double KUR_c_4h[7], KUS_c_4h[7], KMR_c_4h[7], KMS_c_4h[7], KDR_c_4h[7], KDS_c_4h[7];
double KUR_c_1d[7], KUS_c_1d[7], KMR_c_1d[7], KMS_c_1d[7], KDR_c_1d[7], KDS_c_1d[7];


// RSI --------------------------------------------------------------------------
double RSI7_15m, RSI14_15m;
double RSI7_1h, RSI14_1h;
double RSI7_4h, RSI14_4h;
double RSI7_1d, RSI14_1d;

//double RSI7_p[7]; 
//double RSI14_p[7];
double RSI7_15m_p[7],RSI14_15m_p[7];
double RSI7_1h_p[7], RSI14_1h_p[7];
double RSI7_4h_p[7], RSI14_4h_p[7];
double RSI7_1d_p[7], RSI14_1d_p[7];

double ketler_kat_tmp;   
double ketler_kat_p[101];// zapamietanie 21 periods katow linii ketlera
int ketler_trend_up;    // zlicza ile bylo pod rzad wystapien z dodatnim katem linii ketlera
int ketler_trend_dn;    // zlicza ile bylo pod rzad wystapien z ujemnym katem linii ketlera 
 
double a1[7], a2[7];
double RSI7_max_15m, RSI14_max_15m;
double RSI7_Min_15m, RSI14_Min_15m;
double RSI7_max_1h, RSI14_max_1h;
double RSI7_Min_1h, RSI14_Min_1h;
double RSI7_max_4h, RSI14_max_4h;
double RSI7_Min_4h, RSI14_Min_4h;
double RSI7_max_1d, RSI14_max_1d;
double RSI7_Min_1d, RSI14_Min_1d;


double rsi7_tmp, rsi14_tmp;
double rsi7_tmp_1h, rsi14_tmp_1h;
double rsi7_tmp_4h, rsi14_tmp_4h;
double rsi7_tmp_1d, rsi14_tmp_1d;

double RSI7_R_15m_Last, RSI7_S_15m_Last;    // tymczasowe zmienne do zapamietania poziomu RSI7_S_15m/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI7_S_15m/R po wystapieniu fa³szywej linii oporu
double RSI14_R_15m_Last,RSI14_S_15m_Last;   // tymczasowe zmienne do zapamietania poziomu RSI14_S_15m/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI14_S_15m/R po wystapieniu fa³szywej linii oporu
double RSI7_R_1h_Last,  RSI7_S_1h_Last;     // tymczasowe zmienne do zapamietania poziomu RSI7_S_1h/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI7_S_1h/R po wystapieniu fa³szywej linii oporu
double RSI14_R_1h_Last, RSI14_S_1h_Last;    // tymczasowe zmienne do zapamietania poziomu RSI14_S_1h/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI14_S_1h/R po wystapieniu fa³szywej linii oporu
double RSI7_R_4h_Last,  RSI7_S_4h_Last;     // tymczasowe zmienne do zapamietania poziomu RSI7_S_4h/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI7_S_4h/R po wystapieniu fa³szywej linii oporu
double RSI14_R_4h_Last, RSI14_S_4h_Last;    // tymczasowe zmienne do zapamietania poziomu RSI14_S_4h/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI14_S_4h/R po wystapieniu fa³szywej linii oporu
double RSI7_R_1d_Last,  RSI7_S_1d_Last;     // tymczasowe zmienne do zapamietania poziomu RSI7_S_1d/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI7_S_1d/R po wystapieniu fa³szywej linii oporu
double RSI14_R_1d_Last, RSI14_S_1d_Last;    // tymczasowe zmienne do zapamietania poziomu RSI14_S_1d/R w celu mo¿liwoœci przywrócenia prawid³owych wart. zmiennych RSI14_S_1d/R po wystapieniu fa³szywej linii oporu


double RSI100;
//double RSI7_p[0], RSI7_p[2], RSI7_p[2], RSI7_p[3]; // zmienne dla wskaznika RSI(7) dla Period 0,1,2,3
//double RSI14_p[0], RSI14_p[2], RSI14_p[2], RSI14_p[3]; // zmienne dla wskaznika RSI(14) dla Period 0,1,2,3
double RSI_Buy ;                    //wymagany poziom RSI dla buy
double RSI_Sell;                    //wymagany poziom RSI dla sell

//double RSI3_1;
double RSI7_S_15m ,RSI7_R_15m ;            // zapamietanie poziomu RSI(7) w momencie wystapienia S/R w wersji Close
double RSI14_S_15m,RSI14_R_15m ;           // zapamietanie poziomu RSI(14) w momencie wystapienia S/R w wersji Close
double RSI7_S_1h  ,RSI7_R_1h ;             // zapamietanie poziomu RSI(7) w momencie wystapienia S/R w wersji Close
double RSI14_S_1h ,RSI14_R_1h ;            // zapamietanie poziomu RSI(14) w momencie wystapienia S/R w wersji Close
double RSI7_S_4h ,RSI7_R_4h ;              // zapamietanie poziomu RSI(7) w momencie wystapienia S/R w wersji Close
double RSI14_S_4h,RSI14_R_4h ;             // zapamietanie poziomu RSI(14) w momencie wystapienia S/R w wersji Close
double RSI7_S_1d ,RSI7_R_1d ;              // zapamietanie poziomu RSI(7) w momencie wystapienia S/R w wersji Close
double RSI14_S_1d,RSI14_R_1d ;             // zapamietanie poziomu RSI(14) w momencie wystapienia S/R w wersji Close

double HighRSI7_15m_srednia_t[7];
double HighRSI7_15m_srednia;
double HighRSI7_15m_srednia_tmp;

double wysokosc_trendu_15m_t[7];
double wysokosc_trendu_15m;               // Si³a rynku. stosunek odleglosci S wzgledem aktualnej ceny, ktora to moze znajdowac sie powyzej R. Inaczej jaki proc. czesc kanalu keltnera stanowi wysokosc pomiedzy liniami S i R. 
double wysokosc_trendu_15m_now;           // Si³a rynku. stosunek odleglosci S wzgledem R do wysokosci kanalu keltnera. Inaczej jaki proc. czesc kanalu keltnera stanowi wysokosc pomiedzy liniami S i R. 
double srednia_wysokosc_trendu_15m;

double wysokosc_trendu_1h_t[7];
double wysokosc_trendu_1h;
double wysokosc_trendu_1h_now;
double srednia_wysokosc_trendu_1h;

double odleglosc_pips_od_KU_15m;
double odleglosc_pips_od_KD_15m;
double odleglosc_proc_od_KU_15m;
double odleglosc_proc_od_KD_15m;
double odleglosc_proc_od_KU_15m_now;
double odleglosc_proc_od_KD_15m_now;
double odleglosc_pips_od_KU_15m_now;
double odleglosc_pips_od_KD_15m_now;
double wysokosc_keltera_15m;

double odleglosc_pips_od_KU_1h;
double odleglosc_pips_od_KD_1h;
double odleglosc_proc_od_KU_1h;
double odleglosc_proc_od_KD_1h;
double odleglosc_proc_od_KU_1h_now;
double odleglosc_proc_od_KD_1h_now;
double odleglosc_pips_od_KU_1h_now;
double odleglosc_pips_od_KD_1h_now;
double wysokosc_keltera_1h;


double HighRSI7_15m,HighRSI14_15m ;        // wyznaczenie roznicy RSI pomiedzy ostatnia linia Support a Resist
double HighRSI7_1h,HighRSI14_1h ;          // wyznaczenie roznicy RSI pomiedzy ostatnia linia Support a Resist
double HighRSI7_4h,HighRSI14_4h ;          // wyznaczenie roznicy RSI pomiedzy ostatnia linia Support a Resist
double HighRSI7_1d,HighRSI14_1d ;          // wyznaczenie roznicy RSI pomiedzy ostatnia linia Support a Resist


double Price_RSI7_S_15m,Price_RSI7_R_15m;  // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
double Price_RSI7_S_1h,Price_RSI7_R_1h;   //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
double Price_RSI7_S_4h,Price_RSI7_R_4h;   //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
double Price_RSI7_S_1d,Price_RSI7_R_1d;   //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)

double Price_RSI14_S_15m,Price_RSI14_R_15m; //zapamietanie ceny w momecie wystapienia S/R w wersji Close
double Price_RSI14_S_1h,Price_RSI14_R_1h; //zapamietanie ceny w momecie wystapienia S/R w wersji Close
double Price_RSI14_S_4h,Price_RSI14_R_4h; //zapamietanie ceny w momecie wystapienia S/R w wersji Close
double Price_RSI14_S_1d,Price_RSI14_R_1d; //zapamietanie ceny w momecie wystapienia S/R w wersji Close

double BuyHighRSI7_15m, SellHighRSI7_15m,BuyHighRSI14_15m, SellHighRSI14_15m; // zmienna okreslajaca czy zm. High_RSI7 moze zezwalac na buy czy moze sell
double tmp_resist_price7,tmp_support_price7,tmp_resist_price14,tmp_support_price14; //zmienne tymczasowe na potrzeby powyzszych obl. BuyHighRSI7_15m

//#####################33
string CRC,CRCO, CRC2, CRC3; //zmienna dla debugera
int lp_closebuy1, lp_closebuy2, lp_closebuy3, lp_closebuy4, lp_closebuy5, lp_closebuy6, lp_closebuy7,lp_closebuy8, lp_closebuy9, lp_closebuy10, lp_closebuy11, lp_closebuy12, lp_closebuy13, lp_closebuy14 , lp_closebuy15;
int lp_closesell1, lp_closesell2, lp_closesell3, lp_closesell4, lp_closesell5, lp_closesell6, lp_closesell7,lp_closesell8, lp_closesell9, lp_closesell10, lp_closesell11, lp_closesell12, lp_closesell13, lp_closesell14 , lp_closesell15;

double crc_open_buy,crc_open_sell; // na potrzeby dubugera


string TSI;
double TSI_0,TSI_1,TSI_2,TSI_3,TSI_5;
double TSI_0b, TSI_1b, TSI_2b, TSI_3b, TSI_5b, TSI_10b;
double TSI_0v;                      // - sluzy jako filtr dla zamkniec przez gorna/dolna linie keltnera
double TSI_1v, TSI_2v, TSI_3v;  
// rsi - poziomy i trend
bool trendup2, trenddn2, trendstp2, trendup1, trenddn1, trendstp1,trendup0, trenddn0, trendstp0;

bool R1_trendup, R1_trenddn, R1_trendstp; // Zapamietanie stanu SW_hull_RSI w momencie nowej S/R (wyznaczanie sily trendu)
bool S1_trendup, S1_trenddn, S1_trendstp;
// Zmienne do wyznaczania poziomu RSI (i sily trendu) poprzez wskaznik SW_hull
bool   trendup2_rsi, trenddn2_rsi, trendstp2_rsi, trendup0_rsi, trenddn0_rsi, trendstp0_rsi;
//double trend0_p2_rsi, trend1_p2_rsi, trend2_p2_rsi;
//double trend0_p0_rsi, trend1_p0_rsi,trend2_p0_rsi; 
double trend0_rsi_p[7],trend1_rsi_p[7],trend2_rsi_p[7];
double trend0_rsi,trend1_rsi,trend2_rsi;
double powertrend_15m0_p[7],powertrend_15m1_p[7],powertrend_15m2_p[7];
double powertrend_15m0, powertrend_15m1, powertrend_15m2;

//zmienne do wyznaczania poziomu trendu poprzez wskaznik SW_hull_trendpower
//bool powertrend_15m0_p2,powertrend_15m1_p2,powertrend_15m2_p2;
//bool powertrend_15m0_p0,powertrend_15m1_p0,powertrend_15m2_p0;
double powertrend_15m0_p2,powertrend_15m1_p2,powertrend_15m2_p2, powertrend_15m_up2, powertrend_15m_stp2,powertrend_15m_dn2;
double powertrend_15m0_p0,powertrend_15m1_p0,powertrend_15m2_p0, powertrend_15m_up0, powertrend_15m_stp0,powertrend_15m_dn0;

//-----------
double trend0, trend1, trend2; // na potrzeby wskaznika SW_hull_THV

// na potrzeby wskaznika SW_hull_THV. Ponizsze z Period1 na potrzeby uruchamiania BE 
double trend0_p1, trend1_p1,trend2_p1;

string opis;
string zamkniecie_buy,zamkniecie_sell, otwarcie_buy, otwarcie_sell, info1; //opisy sposobu wejscia/zamkniecia dla debugera
string sp_wejscia_buy,sp_wejscia_sell;

//double WynikTR=0;
//double WynikTR2=0;
double WynikTR_buy=0;
double WynikTR_sell=0;

double bilans_poz_buy;  // ma sumowac zyski i straty wszystkich pozycji buy podczas trwania pozycji sell
double bilans_poz_sell; // ma sumowac zyski i straty wszystkich pozycji sell podczas trwania pozycji buy
int ilosc_last_buy; //ile z rzedu byla strata buy
int ilosc_last_sell;
 


double sl,tp; double sl_buy; double sl_sell;

double sl_tmp2; //chwilowa dla debugera


double StopLossLevel, TakeProfitLevel;

int Long; // typ otwarcia long=1 Short=0
int dl_wejscia; //flaga dlugosci wejscia - Long, Short, vShort
// ----news
double News0, News1, News2,News3, News4, News5, News6, News7, News8, News9, News10, News11, News12, News13, News14, News15, News16, News17, News18, News19, News20;
// FILTR FORCE INDEX

double FI7_p1, FI7_p2, FI7_p5; // dla wejsc o mocnym FI dla TSI_vshort;
double FI21_p4, FI21_p2,FI21_p0; //wzamian wskaznika sw_hull
int    opoznij_close_buy, opoznij_close_sell ; // flaga zwiekszajaca dynamiczny s/l na podstawie linii k., gdy FI jest ponad norme 

double tmp_StopLoss;
double ustaw_Buy_SL, ustaw_Sell_SL; //flaga czy zlecenie ma miec ustawiony poziom SL 0=nie 1=tak
string opisSL; //opis war s/l dla comment

double first_open_resist_15m;     // zapamietanie pierwszej linii suporrt w momencie kupna. Na potrzeby dynamicznego S/L, aby ustawiæ wstêpny S/L na poziomie nie mniejszym niz 15pips do czasu az zniknie pierwsza liniia resist
double first_open_support_15m;    // zapamietanie pierwszej linii suporrt w momencie kupna. Na potrzeby dynamicznego S/L, aby ustawiæ wstêpny S/L na poziomie nie mniejszym niz 15pips do czasu az zniknie pierwsza liniia support


int token_high_buy , token_high_sell; // przyznawanie tokenu do ponownego otwarcia pozycji w tym samym kier. dla transakcji zamykanych przez gorna linie keltnera
int token_short_buy, token_short_sell;
int open_by_token; //flaga dla zlecen otwaieranych na podstawie otrzymanego tokena - wykorzystywane do ich zamykania
int all_token_buy, all_token_sell; // liczba przyznych tokenow - dla celow diagnostycznych

 int Order = SIGNAL_NONE;
 static datetime TimeB;
 double TimeS;  //na potrzeby oznaczenia swiecy na ktorej wystapil sygnal
 bool  newBar;
 bool  signalBar;  //swiec na ktorej wystapil sygnal
 
 bool  line_3s_dn_15m, line_3r_dn_15m, line_3s_up_15m, line_3r_up_15m;  // formacje rosnace i malejace dla Resist i Support
 
 bool  hak_r_up_15m;     // zakonczenie formacji rosnacej  Resist
 bool  hak_s_up_15m;     // zakoñczenie formacji rosnacej  Support
 bool  hak_r_dn_15m;     // zakonczenie formacji malejacej Resist
 bool  hak_s_dn_15m;     // zakonczenie formacji malejacej Support
 
 bool  line_3s_dn_1h, line_3r_dn_1h, line_3s_up_1h, line_3r_up_1h;  // formacje rosnace i malejace dla Resist i Support
 bool  hak_r_up_1h;     // zakonczenie formacji rosnacej  Resist
 bool  hak_s_up_1h;     // zakoñczenie formacji rosnacej  Support
 bool  hak_r_dn_1h;     // zakonczenie formacji malejacej Resist
 bool  hak_s_dn_1h;     // zakonczenie formacji malejacej Support
 
 bool  line_3s_dn_4h, line_3r_dn_4h, line_3s_up_4h, line_3r_up_4h;  // formacje rosnace i malejace dla Resist i Support
 bool  hak_r_up_4h;     // zakonczenie formacji rosnacej  Resist
 bool  hak_s_up_4h;     // zakoñczenie formacji rosnacej  Support
 bool  hak_r_dn_4h;     // zakonczenie formacji malejacej Resist
 bool  hak_s_dn_4h;     // zakonczenie formacji malejacej Support
 
 bool  line_3s_dn_1d, line_3r_dn_1d, line_3s_up_1d, line_3r_up_1d;  // formacje rosnace i malejace dla Resist i Support
 bool  hak_r_up_1d;     // zakonczenie formacji rosnacej  Resist
 bool  hak_s_up_1d;     // zakoñczenie formacji rosnacej  Support
 bool  hak_r_dn_1d;     // zakonczenie formacji malejacej Resist
 bool  hak_s_dn_1d;     // zakonczenie formacji malejacej Support
 
 
// ################################################################################################
// ---
bool TickCheck = False;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void init()
{
   //pt=Point;
   maksprice_sell=Ask;  //ustawienie pocz¹tkowej wartoœci
   maksprice_buy=Bid;
  
    
    if (Digits == 2 )
   
   {
      stop_loss *= 1;   //sprawdzone ok
      take_profit *= 1;
      activate_be *= 1;
      step_be *= 1;
      activate_ts *= 1;
      step_ts *= 1;
      stop_loss_ts *= 1;  // to jest wazne nie tylko przy TS
      next_step *= 1;    //uzywany przy ordersend
      hide_sl*= 1;
      hide_tp*= 1;
      pt =1;// 100*Point;
      points= 100;    // dotyczy WynikTR_sell, WynikTR_buy MaxZysk_buy, MaxZysk_buy, MaxZysk_sell,    //wynik musi byc dziesietny
      points2=100;    // dotyczy dynamicznego SL
                      // odleglosc_pips_od_KU_15m, odleglosc_pips_od_KD_15m, wysokosc_keltera_15m
                      // odleglosc_pips_od_KU_15m_now
                      // odleglosc_pips_od_KD_15m_now
                      // odleglosc_pips_od_KU_1h
   
    }

   if (Digits == 3)
   {
      stop_loss *= 10;  //sprawdzone ok
      take_profit *= 10; // sprawdzone ok
      activate_be *= 10;
      step_be *= 10;
      activate_ts *= 10;
      step_ts *= 10;
      stop_loss_ts *= 10; // to jest wazne // sprawdzone ok
      next_step *= 10;
      hide_sl*= 10;
      hide_tp*= 10;
      pt =1;// 100*Point;
      points= 100;  //1000    //zweryfikowane ok
      points2=1000; //10000   //sprawdzone ok
      //WynikTR *=1000;
   //   MaxZysk_buy*=100;
   //   MaxZysk_sell*=100;
      
   }
   
 if (Digits == 4)
   
   {
      stop_loss *= 1;   //sprawdzone ok
      take_profit *= 1;
      activate_be *= 1;
      step_be *= 1;
      activate_ts *= 1;
      step_ts *= 1;
      stop_loss_ts *= 1;
      next_step *= 1;
      hide_sl*= 1;
      hide_tp*= 1;
      pt =1;// 100*Point;
      points= 10000;  //10000       //wynik ma byc dziesietny
      points2=10000;  //10000
    }
   
 
 if (Digits == 5)
   
   {
      stop_loss *= 10;  //zweryfikowane ok
      take_profit *= 10; //zweryfikowane ok
      activate_be *= 10;
      step_be *= 10;
      activate_ts *= 10;
      step_ts *= 10;
      stop_loss_ts *= 10;
      next_step *= 10;
      hide_sl*= 10;
      hide_tp*= 10;
      pt =1;// 100*Point;
      points= 10000;    // zweryfikowano ok // tu wynikTR jest chyba po kropce (ale inaczej zdaje sie ze nie mozna)
      points2=100000;   //wysokosc kanalu ketlera ma byc dziesietnie // jest ok
   
    }

 
 
 //else if(Digits==6) pt = 100*Point;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void deinit()
{
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void start()
{
//if (TICK>0&&iVolume(Symbol(),1,0)>TICK)return(0);  //niby przyspiesza backtest
//if (TICK>0&&iVolume(Symbol(),1,0)>TICK)return(0);
  //    formacja Support dla trendu rosnacego
 
// if (S_15m[0] == Support_15m)
  total_orders = orders_total(OP_BUY)+orders_total(OP_SELL);
  newBar       = (TimeB != Time[0]);  TimeB = Time[0];
 
 price_min4();  //
 
//##if(BreakEven>0 && trendup2==1 && trendstp1==1 && MathAbs(MaxZysk)>=0.15){MoveTrailingStop();} //Print (" STOPLOSS UP")
//##if(BreakEven>0 && trenddn2==1 && trendstp1==1 && MathAbs(MaxZysk)>=0.15){MoveTrailingStop();} //Print (" STOPLOSS DN");   


   formacje_15m();  
   if (newBar==1)formacje_1h();
   if (newBar==1)formacje_4h();
   if (newBar==1)formacje_1d();


 silny_szczyt(); //obciaza mocno, ale po dodaniu newbar szwankuje dynamiczny Stoploss (cos przeskakuje) //   ZWIEKSZA CZAS BACKTESTU O 200%
//if (newBar==1) zapis_silny_szczyt();        // po modyfikacji funkcji silny_szczyt przez wsk. FI. funkcja ta nie jest juz potrzebna
// BE_custom();

//powertrend_15m(); // czy ten tez w newbar?

 kanal_ketlera_15m(); //wplyw newbar powienien byc niewielki na wynik, a pewnie znaczaco przyspieszy testy
 if (newBar==1) ketler_angle(); // WYREMOWAC NEWBAR
 if (newBar==1)  kanal_ketlera_1h(); //te zostawic z newbar
 if (newBar==1)  kanal_ketlera_4h();
 if (newBar==1)  kanal_ketlera_1d();
 
//#3 - zmienia wyniki - tego chyba nie trzeba pryspieszac poprzez newbar
   odleglosc_sr_w_rsi_15m();     // wyznacza rsi7/14 min i max i polecenie token rsi100
  if (newBar==1) odleglosc_sr_w_rsi_1h();      // wyznacza rsi7/14 min i max i polecenie token rsi100
  if (newBar==1) odleglosc_sr_w_rsi_4h();      // wyznacza rsi7/14 min i max i polecenie token rsi100
  if (newBar==1) odleglosc_sr_w_rsi_1d();      // wyznacza rsi7/14 min i max i polecenie token rsi100

// TA OBCIAZA MOCNO!!
 if (newBar==1)   wyznacz_linie_sr();           // MTF_Barry i Barry_Close
  
//wskaznik wejscia mocno korzysta z funkcji tsi - obciaza
 wskaznik_wejscia();           // przeniesc z niego poziomy rsi do funkcji wejsc  // poprawic w nim funkcje fi - wybrac inna bo ta nie ma poziomow 150
   flaga_rsi();
if (newBar==1)   debuger();
// MaxZysk_buy();
   MaxxZysk();
   WynikkTR();
if (orders_total(OP_BUY ) == 0 && ticket_be_buy >=0)  ticket_be_buy =-1;     // wyzerowanie ticketu dla buy // moze to kasuje ticket dla buy?
if (orders_total(OP_SELL) == 0 && ticket_be_sell>=0)  ticket_be_sell=-1;     // wyzerowanie ticketu dla sell 


// warunki_zamkniecia_buy();
// warunki_zamkniecia_sell();
// wejscia_specjalne();          //wejscia niezalezne od rodzaju trwendu
// wejscia_ketler();

   rtrend_15m=-1;                //teoretycznie powinno byc to zerowanie trendu, ale pogarsza wyniki. Zweryfikowac jeszcze
   rtrend_1h=-1;
   rtrend_4h=-1;
   rtrend_1d=-1;

   spr_trend_boczny_15m();    
   spr_trend_rosnacy_15m();    
   spr_trend_malejacy_15m();  

 if (newBar==1)
 {
   spr_trend_boczny_1h();     
   spr_trend_rosnacy_1h();     
   spr_trend_malejacy_1h();   
   spr_trend_boczny_4h();     
   spr_trend_rosnacy_4h();     
   spr_trend_malejacy_4h();   
   spr_trend_boczny_1d();     
   spr_trend_rosnacy_1d();     
   spr_trend_malejacy_1d();   
   punktacja();  //to chyba mozna chyba wyremowac
}

//if (sredni_kat_ketlera_p28<10 && sredni_kat_ketlera_p28>-10) rtrend_15m=0;
//if (sredni_kat_ketlera_p28>10) rtrend_15m=1;
//if (sredni_kat_ketlera_p28<-10) rtrend_15m=2;

   przydziel_ticket();  //
 // if (wejscia_specjalne()         == OP_BUY)  if (orders_total(OP_BUY ) < max_oneway_orders) if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0) if (stoploss_bar(OP_BUY ) > wait_bars){CRC3="Buy1";CRC2=1;ustaw_pierwotny_sl_buy();order_send(OP_BUY );}
 // if (wejscia_specjalne()         == OP_SELL) if (orders_total(OP_SELL) < max_oneway_orders) if (history_bar(OP_SELL) != 0 && actual_bar(OP_SELL) != 0) if (stoploss_bar(OP_SELL) > wait_bars){CRC3="Sell1";CRC2=2;ustaw_pierwotny_sl_sell();order_send(OP_SELL);}
  
  
  if (total_orders>0) 
  {
    wskaznik_zamkniecia();        //wartosci TSI_short dla Close
    if (orders_total(OP_BUY ) > 0) if (warunki_zamkniecia_buy()    == OP_BUY)  if ((FI7_p1< +75*0.001  &&  FI7_p1> -75*0.001)) order_close(OP_BUY);
    if (orders_total(OP_SELL) > 0) if (warunki_zamkniecia_sell()   == OP_SELL) if ((FI7_p1> -75*0.001  &&  FI7_p1< +75*0.001)) order_close(OP_SELL);
   /* 
    if (orders_total(OP_BUY ) > 0) if (warunki_zamkniecia_buy()    == OP_BUY) 
    {
      if ((FI7_p1< +75*0.001  &&  FI7_p1> -75*0.001 && WynikTR_buy<55) //|| WynikTR_buy>0... || WynikTr_buy<0...
       || (WynikTR_buy>55)) 
         order_close(OP_BUY);
     } 
      if (orders_total(OP_SELL) > 0) if (warunki_zamkniecia_sell()   == OP_SELL)  
      { 
       if ((FI7_p1> -75*0.001  && FI7_p1< +75*0.001 && WynikTR_sell<55)
        || (WynikTR_sell>55))
           order_close(OP_SELL);
           
      }
*/
  }


//wywolanie wejsc  specjanych nie powinny miec dodatkowych war. 


if (total_orders<=max_orders)
 {
 //otwarcie pozycji buy
   if (stoploss_bar(OP_BUY ) > wait_bars) 
   if ((orders_total(OP_BUY ) == 0
 
   &&  WynikTR_sell > 25 && WynikTR_sell < 90 && WynikTR_sell+bilans_poz_buy>=WynikTR_sell*0.65 ) 
   || (WynikTR_sell > 90 && WynikTR_sell+bilans_poz_buy>=WynikTR_sell*0.80)  //ten war. ogranicza otwieranie poz. buy gdy nie ma sell!!!! dodac OR (orders_total(OP_BUY ) == 0 && orders_total(OP_SELL ) == 0)
   || (orders_total(OP_SELL ) == 0 && orders_total(OP_BUY ) ==0)) //dlatego jest dodany OR
      { 
       // if (ketler_kat_dn<=55 && ketler_kat_dn >=-50)
       if  (sredni_kat_ketlera_p14>-20 && ketler_trend_dn<28)// ma to na celu ograniczenie otwierania pozycji np. sell podczas wyraznego trendu buy
      // if   (( ketler_trend_dn<28)) 
         // || ( ketler_trend_dn>28 && sredni_kat_ketlera_p3>-55 && WynikTR_sell<50))
         {
         if (wejscia_specjalne()         == OP_BUY)  if (orders_total(OP_BUY ) < max_oneway_orders) if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0) if (stoploss_bar(OP_BUY ) > wait_bars){CRC3="Buy1";CRC2=1;ustaw_pierwotny_sl_buy();order_send(OP_BUY );}
    
         if ((rtrend_15m==0) && (rtrend_1h!=22)) if (wejscia_trend_boczny_buy()  == OP_BUY)  if (orders_total(OP_BUY ) < max_oneway_orders) if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0) if (stoploss_bar(OP_BUY ) > wait_bars) {CRC3="Buy2";CRC2=3;ustaw_pierwotny_sl_buy();order_send(OP_BUY );} //rtrend_15m==0) && (rtrend_1h==0
         if ((rtrend_15m==1) && (rtrend_1h!=22)) if (wejscia_trend_rosnacy()     == OP_BUY)  if (orders_total(OP_BUY ) < max_oneway_orders) if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0) if (stoploss_bar(OP_BUY ) > wait_bars) {CRC3="Buy3";CRC2=5;ustaw_pierwotny_sl_buy();order_send(OP_BUY );} //rtrend_15m==1) && (rtrend_1h!=2)
         if ((rtrend_15m==2) && (rtrend_1h!=22)) if (wejscia_trend_malejacy()    == OP_BUY)  if (orders_total(OP_BUY ) < max_oneway_orders) if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0) if (stoploss_bar(OP_BUY ) > wait_bars) {CRC3="Buy4";CRC2=7;ustaw_pierwotny_sl_buy();order_send(OP_BUY );} //rtrend_15m==2) && (rtrend_1h==2
  
        }
       } 
 //otwarcie pozycji sell
   if (stoploss_bar(OP_SELL) > wait_bars) 
       if ((orders_total(OP_SELL) == 0 
          && WynikTR_buy > 25 && WynikTR_buy < 90 && WynikTR_buy+bilans_poz_sell>=WynikTR_buy*0.65)// WynikTR_buy-WynikTR_buy*0.90>=WynikTR_buy*0.10
          || (WynikTR_buy > 90 && WynikTR_buy+bilans_poz_sell>=WynikTR_buy*0.80)
          || (orders_total(OP_SELL ) == 0 && orders_total(OP_BUY ) ==0))
        {
       if  (sredni_kat_ketlera_p14<20 && ketler_trend_up<28)  
      //   if (ketler_kat_dn>=-55 && ketler_kat_dn <=50 )
     //if ((ketler_trend_up<28)) 
        // || (ketler_trend_up>28 && sredni_kat_ketlera_p3 < 55 && WynikTR_buy <50))
     {
         if (wejscia_specjalne()         == OP_SELL) if (orders_total(OP_SELL) < max_oneway_orders) if (history_bar(OP_SELL) != 0 && actual_bar(OP_SELL) != 0) if (stoploss_bar(OP_SELL) > wait_bars){CRC3="Sell1";CRC2=2;ustaw_pierwotny_sl_sell();order_send(OP_SELL);}
 // TE WAR ODNOSZACE SIE DO TRENDU SA CHYBA BEZ SENSU. ZROBIC ZE JESLI = SIE DANY TREND TO WYKONAC ZLECENIE BO INACZEJ TO PO CO SA ONE SPRAWDZANE
         if ((rtrend_15m==0) && (rtrend_1h!=11)) if (wejscia_trend_boczny_sell() == OP_SELL) if (orders_total(OP_SELL) < max_oneway_orders) if (history_bar(OP_SELL) != 0 && actual_bar(OP_SELL) != 0) if (stoploss_bar(OP_SELL) > wait_bars){CRC3="Sell2";CRC2=4;ustaw_pierwotny_sl_sell();order_send(OP_SELL);} //rtrend_15m==0) && (rtrend_1h==0)
         if ((rtrend_15m==1) && (rtrend_1h!=11)) if (wejscia_trend_rosnacy()     == OP_SELL) if (orders_total(OP_SELL) < max_oneway_orders) if (history_bar(OP_SELL) != 0 && actual_bar(OP_SELL) != 0) if (stoploss_bar(OP_SELL) > wait_bars){CRC3="Sell3";CRC2=6;ustaw_pierwotny_sl_sell();order_send(OP_SELL);} //rtrend_15m==1) && (rtrend_1h==1
         if ((rtrend_15m==2) && (rtrend_1h!=11)) if (wejscia_trend_malejacy()    == OP_SELL) if (orders_total(OP_SELL) < max_oneway_orders) if (history_bar(OP_SELL) != 0 && actual_bar(OP_SELL) != 0) if (stoploss_bar(OP_SELL) > wait_bars){CRC3="Sell4";CRC2=8;ustaw_pierwotny_sl_sell();order_send(OP_SELL);} //rtrend_15m==2) && (rtrend_1h!=1
       }
      } 

} //koniec if max_orders 
 
//   zapis_zmiennych_new_transaction(); //wywolanie z order_send
//   reset_zmiennych_new_transaction(); //wywowalnie z order_send



 // if (activate_be >= 0) break_even();                       // aktywne gdy activate_be >= 0
 // if (activate_ts >= 0) trailing_stop();   //ZWERYFIKOWAC, BO POKI CO KOLIDUJE Z FUNKCJA SET.stop_LOSS() - ustawiane sa 2 rozne poiomy // aktywne gdy activate_ts >= 0

  if (stop_loss >= 0) set_stop_loss();                    // aktywne gdy stop_loss >= 0. Dynamiczny StopLoss w oparciu o linie keltnera
 //# if (take_profit >= 0)  set_take_profit();                  // aktywne gdy take_profit >= 0
  if (hide_sl >= 0) hide_stop_loss();                   // aktywne gdy hide_sl >= 0
  if (hide_tp >= 0) hide_take_profit();                 // aktywne gdy hide_tp >= 0
   
  wyznacz_wysokosc_trendu_now_15m();   // podobna funkcja ale dla wczesniejszych okresow uruchamiana jest z poziomu save_ketler
  if (newBar==1)  wyznacz_wysokosc_trendu_now_1h();   // podobna funkcja ale dla wczesniejszych okresow uruchamiana jest z poziomu save_ketler
  if (newBar==1) ilosc_poz_stratnych();
  if (total_orders==0){bilans_poz_buy=0;ilosc_last_buy=0;bilans_poz_sell=0;ilosc_last_sell=0;}  //zerowanie zmiennych jesli nie ma zadnych otwartych pozycji
  if (newBar==1) debuger();
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////// F U N K C J E /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
double RSI7_Min_4h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_4h_p[ArrayMinimum(RSI7_4h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}
*/

void ilosc_poz_stratnych()
 {
   int x;
   int OrdHistory=OrdersHistoryTotal();
   int maxIloscSprZlec =3;
   Strata=0;
   Ilosc=0;
   ilosc_last_buy=0;
   ilosc_last_sell=0;
   
   bilans_poz_buy =0;
   bilans_poz_sell =0;
   
  // bool end_loop;
   
   
 if (total_orders>0)
 {
  //zliczanie ilosci stratnych buy dla kolejnej petli      
  
   for(x=0; x<=10;x++)
   {
    if (OrdersHistoryTotal() == 0) break;
      OrderSelect(OrdersHistoryTotal()-x, SELECT_BY_POS, MODE_HISTORY);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number )
         {
         if(OrderSelect(OrdHistory-x,SELECT_BY_POS,MODE_HISTORY) && OrderType() == OP_BUY && OrderOpenTime()>czas_otwarcia_sell) 
           {
            
            ilosc_last_buy++;
            bilans_poz_buy = (bilans_poz_buy + (OrderClosePrice()-OrderOpenPrice())*points);
          // if (orders_total(OP_BUY ) == 1 && OrderSelect(1,SELECT_BY_POS,MODE_HISTORY) && OrderType() == OP_BUY){bilans_poz_buy =0;ilosc_last_buy=0;}
           }
       //  if(OrderSelect(OrdHistory-x,SELECT_BY_POS,MODE_HISTORY) && OrderType() == OP_SELL) {break;}
         }
    }
  

 //zliczanie ilosci stratnych sell dla kolejnej petli
  for(x=0; x<=10;x++)
   {              
    if (OrdersHistoryTotal() == 0) break;
      OrderSelect(OrdersHistoryTotal()-x, SELECT_BY_POS, MODE_HISTORY);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number )
         {
            if(OrderSelect(OrdHistory-x,SELECT_BY_POS,MODE_HISTORY) && OrderType() == OP_SELL && OrderOpenTime()>czas_otwarcia_buy) 
            {
              ilosc_last_sell++;
              bilans_poz_sell = (bilans_poz_sell + (OrderOpenPrice()-OrderClosePrice())*points);
             // if (orders_total(OP_SELL ) == 1 && OrderSelect(1,SELECT_BY_POS,MODE_HISTORY) && OrderType() == OP_SELL) {bilans_poz_sell =0; ilosc_last_sell=0;}
            }
       //     if(OrderSelect(OrdHistory-x,SELECT_BY_POS,MODE_HISTORY) && OrderType() == OP_BUY) {break;}
        //  if(OrderSelect(OrdHistory-x,SELECT_BY_POS,MODE_HISTORY) && OrderType() == OP_SELL && OrderProfit() <0) {ilosc_last_sell++;end_loop=true;break;}   
         }
    }   
  } //koniec total_order
 }// koniec f.ilosc_poz_stratnych()
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void punktacja()
 {
      factor_buy=0;
      factor_sell=0;
      factor_buy_close=0;
      factor_sell_close=0;
// punktacja dla sygnalu wejscia
    
      if (rtrend_15m==1) factor_buy+=4;
    //if (rtrend_15m==0) factor_buy+=0;
      if (rtrend_short_15m==1) factor_buy+=8;
    //5 3 8       
      if (rtrend_1h==1) factor_buy+=3;
    //if (rtrend_1h==0) factor_buy+=0;
      if (rtrend_short_1h==1) factor_buy+=6;
    //13 8 21
      if (rtrend_4h==1) factor_buy+=2;
    //if (rtrend_4h==0) factor_buy+=8;
      if (rtrend_short_4h==1) factor_buy+=4;
    
    // 2 1 3
      if (rtrend_1d==1) factor_buy+=1;
    //if (rtrend_1d==0) factor_buy+=1;
      if (rtrend_short_1d==1) factor_buy+=2;
     
    
      if (rtrend_15m==2) factor_sell+=4;
    //if (rtrend_15m==0) factor_sell+=0;
      if (rtrend_short_15m==2) factor_sell+=8;
    //5 3 8    
      if (rtrend_1h==2) factor_sell+=3;
     // if (rtrend_1h==0) factor_sell+=0;
      if (rtrend_short_1h==2) factor_sell+=6;
    //13 8 21
      if (rtrend_4h==2) factor_buy+=2;
    //if (rtrend_4h==0) factor_buy+=0;
      if (rtrend_short_4h==2) factor_buy+=4;
    // 2 1 3
      if (rtrend_1d==2) factor_sell+=1;
    //if (rtrend_1d==0) factor_sell+=0;
      if (rtrend_short_1d==2) factor_sell+=2;

// punktacja dla sygnalu zamkniecia  
      if (rtrend_15m==1) factor_buy_close+=4;
   // if (rtrend_15m==0) factor_buy_close+=0;
      if (rtrend_short_15m==1) factor_buy_close+=8;
      
      if (rtrend_1h==1) factor_buy_close+=3;
   // if (rtrend_1h==0) factor_buy_close+=0;
      if (rtrend_short_1h==1) factor_buy_close+=6;
   // 13 8 21
      if (rtrend_4h==1) factor_buy_close+=2;
   // if (rtrend_4h==0) factor_buy_close+=0;
      if (rtrend_short_4h==1) factor_buy_close+=4;
    // 2 1 3
      if (rtrend_1d==1) factor_buy_close+=1;
   // if (rtrend_1d==0) factor_buy_close+=0;
      if (rtrend_short_1d==1) factor_buy_close+=2;
     
      if (rtrend_15m==2) factor_sell_close+=4;
   // if (rtrend_15m==0) factor_sell_close+=0;
      if (rtrend_short_15m==2) factor_sell_close+=8;
    //5 3 8    
      if (rtrend_1h==2) factor_sell_close+=3;
   // if (rtrend_1h==0) factor_sell_close+=0;
      if (rtrend_short_1h==2) factor_sell_close+=6;
    //13 8 21
      if (rtrend_4h==2) factor_buy_close+=2;
   // if (rtrend_4h==0) factor_buy_close+=0;
      if (rtrend_short_4h==2) factor_buy_close+=4;
    // 2 1 3
      if (rtrend_1d==2) factor_sell_close+=1;
   // if (rtrend_1d==0) factor_sell_close+=0;
      if (rtrend_short_1d==2) factor_buy_close+=2;

  
   }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void formacje_15m()
 {
      line_3r_up_15m = (R_c_15m[0]>R_c_15m[1] && R_c_15m[1]>R_c_15m[2]);   //    formacja Resist dla trendu rosnacego
      line_3s_up_15m = (S_c_15m[0]>S_c_15m[1] && S_c_15m[1]>S_c_15m[2]);   //    formacja Support dla trendu rosnacego
      line_3r_dn_15m = (R_c_15m[0]<R_c_15m[1] && R_c_15m[1]<R_c_15m[2]);   //    formacja Resist  dla trendu dolnego   
      line_3s_dn_15m = (S_c_15m[0]<S_c_15m[1] && S_c_15m[1]<S_c_15m[2]);   //    formacja Support dla trendu dolnego
 
      hak_r_up_15m   = (R_c_15m[0]<R_c_15m[1] && R_c_15m[1]>R_c_15m[2] && R_c_15m[2]>R_c_15m[3]);        // zakonczenie formacji rosnacej Resist
      hak_s_up_15m   = (S_c_15m[0]<S_c_15m[1] && S_c_15m[1]>S_c_15m[2] && S_c_15m[2]>S_c_15m[3]);        // zakonczenie formacji rosnacej Support

      hak_r_dn_15m   = (R_c_15m[0]>R_c_15m[1] && R_c_15m[1]<R_c_15m[2] && R_c_15m[2]<R_c_15m[3]);        // zakonczenie formacji spadkowej Resist
      hak_s_dn_15m   = (S_c_15m[0]>S_c_15m[1] && S_c_15m[1]<S_c_15m[2] && S_c_15m[2]<S_c_15m[3]);        // zakonczenie formacji spadkowej Support
 }
 
 void formacje_1h()
 {
      line_3r_up_1h = (R_c_1h[0]>R_c_1h[1] && R_c_1h[1]>R_c_1h[2]);   //    formacja Resist dla trendu rosnacego
      line_3s_up_1h = (S_c_1h[0]>S_c_1h[1] && S_c_1h[1]>S_c_1h[2]);   //    formacja Support dla trendu rosnacego
      line_3r_dn_1h = (R_c_1h[0]<R_c_1h[1] && R_c_1h[1]<R_c_1h[2]);   //    formacja Resist  dla trendu dolnego   
      line_3s_dn_1h = (S_c_1h[0]<S_c_1h[1] && S_c_1h[1]<S_c_1h[2]);   //    formacja Support dla trendu dolnego
 
      hak_r_up_1h   = (R_c_1h[0]<R_c_1h[1] && R_c_1h[1]>R_c_1h[2] && R_c_1h[2]>R_c_1h[3]);        // zakonczenie formacji rosnacej Resist
      hak_s_up_1h   = (S_c_1h[0]<S_c_1h[1] && S_c_1h[1]>S_c_1h[2] && S_c_1h[2]>S_c_1h[3]);        // zakonczenie formacji rosnacej Support

      hak_r_dn_1h   = (R_c_1h[0]>R_c_1h[1] && R_c_1h[1]<R_c_1h[2] && R_c_1h[2]<R_c_1h[3]);        // zakonczenie formacji spadkowej Resist
      hak_s_dn_1h   = (S_c_1h[0]>S_c_1h[1] && S_c_1h[1]<S_c_1h[2] && S_c_1h[2]<S_c_1h[3]);        // zakonczenie formacji spadkowej Support
  }    
  
void formacje_4h()
 {
      line_3r_up_4h = (R_c_4h[0]>R_c_4h[1] && R_c_4h[1]>R_c_4h[2]);   //    formacja Resist dla trendu rosnacego
      line_3s_up_4h = (S_c_4h[0]>S_c_4h[1] && S_c_4h[1]>S_c_4h[2]);   //    formacja Support dla trendu rosnacego
      line_3r_dn_4h = (R_c_4h[0]<R_c_4h[1] && R_c_4h[1]<R_c_4h[2]);   //    formacja Resist  dla trendu dolnego   
      line_3s_dn_4h = (S_c_4h[0]<S_c_4h[1] && S_c_4h[1]<S_c_4h[2]);   //    formacja Support dla trendu dolnego
 
      hak_r_up_4h   = (R_c_4h[0]<R_c_4h[1] && R_c_4h[1]>R_c_4h[2] && R_c_4h[2]>R_c_4h[3]);        // zakonczenie formacji rosnacej Resist
      hak_s_up_4h   = (S_c_4h[0]<S_c_4h[1] && S_c_4h[1]>S_c_4h[2] && S_c_4h[2]>S_c_4h[3]);        // zakonczenie formacji rosnacej Support

      hak_r_dn_4h   = (R_c_4h[0]>R_c_4h[1] && R_c_4h[1]<R_c_4h[2] && R_c_4h[2]<R_c_4h[3]);        // zakonczenie formacji spadkowej Resist
      hak_s_dn_4h   = (S_c_4h[0]>S_c_4h[1] && S_c_4h[1]<S_c_4h[2] && S_c_4h[2]<S_c_4h[3]);        // zakonczenie formacji spadkowej Support
  }    

void formacje_1d()
 {
      line_3r_up_1d = (R_c_1d[0]>R_c_1d[1] && R_c_1d[1]>R_c_1d[2]);   //    formacja Resist dla trendu rosnacego
      line_3s_up_1d = (S_c_1d[0]>S_c_1d[1] && S_c_1d[1]>S_c_1d[2]);   //    formacja Support dla trendu rosnacego
      line_3r_dn_1d = (R_c_1d[0]<R_c_1d[1] && R_c_1d[1]<R_c_1d[2]);   //    formacja Resist  dla trendu dolnego   
      line_3s_dn_1d = (S_c_1d[0]<S_c_1d[1] && S_c_1d[1]<S_c_1d[2]);   //    formacja Support dla trendu dolnego
 
      hak_r_up_1d   = (R_c_1d[0]<R_c_1d[1] && R_c_1d[1]>R_c_1d[2] && R_c_1d[2]>R_c_1d[3]);        // zakonczenie formacji rosnacej Resist
      hak_s_up_1d   = (S_c_1d[0]<S_c_1d[1] && S_c_1d[1]>S_c_1d[2] && S_c_1d[2]>S_c_1d[3]);        // zakonczenie formacji rosnacej Support

      hak_r_dn_1d   = (R_c_1d[0]>R_c_1d[1] && R_c_1d[1]<R_c_1d[2] && R_c_1d[2]<R_c_1d[3]);        // zakonczenie formacji spadkowej Resist
      hak_s_dn_1d   = (S_c_1d[0]>S_c_1d[1] && S_c_1d[1]<S_c_1d[2] && S_c_1d[2]<S_c_1d[3]);        // zakonczenie formacji spadkowej Support
  }    

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
//WARUNKI OTWARCIA
int open_signal()
{
   if (rsi(rsi_shift + 1) <= rsi_open_long  && rsi(rsi_shift + 0) >= rsi_open_long ) return(OP_BUY );
   if (rsi(rsi_shift + 1) >= rsi_open_short && rsi(rsi_shift + 0) <= rsi_open_short) return(OP_SELL);
   return(-1);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//WARUNKI ZAMKNIECIA
int close_signal()
{
   if (rsi(rsi_shift + 1) >= rsi_close_long  && rsi(rsi_shift + 0) <= rsi_close_long ) return(OP_BUY );
   if (rsi(rsi_shift + 1) <= rsi_close_short && rsi(rsi_shift + 0) >= rsi_close_short) return(OP_SELL);
   return(-1);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//FUNKCJE POMOCNICZE DLA WAR OTWARCIA
double rsi(int shift)
{
   return(iRSI(Symbol(),Period(),rsi_period,rsi_price,shift));
}
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja zliczjaca ilosc otwrtych zlecen
int orders_total(int order_type)
{
   RefreshRates();
   int sum = 0;
   for (int i = OrdersTotal() - 1;i >= 0;i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber() && order_type == OrderType()) sum++;
   }
   return(sum);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja zamykajaca pozycje
void order_close(int order_type)
{
   RefreshRates();
   for (int i = OrdersTotal() - 1;i >= 0;i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber() && order_type == OrderType())
      {
         bool ticket = true;
         if (OrderType() == OP_BUY ) ticket = OrderClose(OrderTicket(),OrderLots(),Bid,3,Blue);
         if (OrderType() == OP_SELL) ticket = OrderClose(OrderTicket(),OrderLots(),Ask,3,Red );
         if (OrderType() >  OP_SELL) ticket = OrderDelete(OrderTicket());
         if (ticket == false) Print("Error close "+GetLastError());
      }
   }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja wysylajaca zlecenia
void order_send(int order_type)
{
   RefreshRates();
 /*  if (next_step >= 0)
   {
      if (order_type == OP_BUY ) if (orders_total(OP_BUY ) > 0) if (open_price(OP_BUY ) - Ask < next_step * Point) return;
      if (order_type == OP_SELL) if (orders_total(OP_SELL) > 0) if (Bid - open_price(OP_SELL) < next_step * Point) return;
   }
 */
   sl = 0;
   tp = 0;
   if (!ecn_stp)
   {
      if (stop_loss >= 0)
      { 
         sl = stop_loss;
         if (sl < MarketInfo(Symbol(),MODE_STOPLEVEL)) sl = MarketInfo(Symbol(),MODE_STOPLEVEL);
         if (order_type == OP_BUY ) sl = Ask - sl * Point;
         if (order_type == OP_SELL) sl = Bid + sl * Point;
      }
      if (take_profit >= 0)
      { 
         tp = take_profit;
         if (tp < MarketInfo(Symbol(),MODE_STOPLEVEL)) sl = MarketInfo(Symbol(),MODE_STOPLEVEL);
         if (order_type == OP_BUY ) tp = Ask + tp * Point;
         if (order_type == OP_SELL) tp = Bid - tp * Point;
      }
   }
   int ticket = 0;
   if (order_type == OP_BUY ) 
      {
         comment_ea= sp_wejscia_buy + " | " + CRCO + " POS: " + price_from_down + " ZS: " + zamkniecie_sell;
         //comment_ea= sp_wejscia_buy + " | " + CRCO + " ZB: " + zamkniecie_buy + " ZS: " + zamkniecie_sell;
         ticket = OrderSend(Symbol(),order_type,lot_size,Ask,3,sl,tp,comment_ea,magic_number,0,Blue);
         reset_zmiennych_new_trans_buy();
      }

   if (order_type == OP_SELL) 
     {
      comment_ea= sp_wejscia_sell+ " | " + CRCO + " POS: " + price_from_top + " ZS: " + zamkniecie_sell;
    //comment_ea= sp_wejscia_sell+ " | " + CRCO + " ZB: " + zamkniecie_buy + " ZS: " + zamkniecie_sell;
      ticket = OrderSend(Symbol(),order_type,lot_size,Bid,3,sl,tp,comment_ea,magic_number,0,Red ); 
      reset_zmiennych_new_trans_sell();
     }
   if (ticket < 0) Print("Error send "+GetLastError());

   zapis_zmiennych_new_transaction();


}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja przypisujaca token zamkniecia dla pozycji o mniejszym priorytecie

void przydziel_ticket()
{
   RefreshRates();
 
   for (int i = OrdersTotal() - 1;i >= 0;i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber())
      {

//------------------------------------------------------        
      
       //  if (OrderType() == OP_BUY  && MaxZysk_buy > MaxZysk_sell) {ticket_for_close_sell = 1; ticket_for_close_buy = 0;}      // przydzielenie tokenu dla sell poniewaz jest transakcja mniej pewna od buy
       //  if (OrderType() == OP_SELL && MaxZysk_buy < MaxZysk_sell ){ticket_for_close_buy  = 1; ticket_for_close_sell =0;}      // przydzielenie tokenu dla buy poniewaz jest transakcja mniej pewna od sell
         if (orders_total(OP_BUY ) == 0 && ticket_for_close_buy == 1) ticket_for_close_buy =0;     // wyzerowanie ticketu dla buy // moze to kasuje ticket dla buy?
         if (orders_total(OP_SELL) == 0 && ticket_for_close_sell ==1) ticket_for_close_sell =0;    // wyzerowanie ticketu dla sell 
         
         //zresetowanie ticketu dla close, gdy w czasie trzech kolejne linii R(buy) lub S(Sell) nie zostala przekroczonma sr.l.k.
         if (OrderType() == OP_BUY  && ticket_for_close_buy==1 )  if(R_15m_save_for_close_buy !=R_15m[0]) if (R_15m_save_for_close_buy !=R_15m[1]) if (R_15m_save_for_close_buy !=R_15m[1]) ticket_for_close_buy=0; //zresetowanie ticketu dla close, gdy w czasie trzech kolejne linii Resist nie zostala przekroczonma sr.l.k.
         if (OrderType() == OP_SELL && ticket_for_close_sell==1 ) if(S_15m_save_for_close_sell!=S_15m[0]) if (S_15m_save_for_close_sell!=S_15m[1]) if (S_15m_save_for_close_sell!=S_15m[1]) ticket_for_close_sell=0;  //zresetowanie ticketu dla close, gdy w czasie trzech kolejne linii Support nie zostala przekroczonma sr.l.k.
         //&& MaxZysk_buy > MaxZysk_sell
         //&& MaxZysk_buy < MaxZysk_sell
//------------------------------------------------------
         // przydzielanie flagi critical, dla natychmiastowego zxamkniecia poprzez SHORT. Zamykanie nr 7

            
        if (OrderType() == OP_BUY  && WynikTR_buy > WynikTR_sell && Last_S1_15m != S_15m[0]) {ticket_crit_for_sell = 1; ticket_crit_for_buy = 0;}
        if (OrderType() == OP_SELL && WynikTR_buy < WynikTR_sell && Last_R1_15m != R_15m[0]) {ticket_crit_for_buy= 1;   ticket_crit_for_sell =0;}

        if (OrderType() == OP_BUY  && ticket_crit_for_buy == 1 && S_c_15m[0]>OrderOpenPrice()) ticket_crit_for_buy =0; //wyzerowanie ticketu gdy S jest powyzej poziomu otwarcia, bo znaczy to ze zlecenie przeszlo w faze zysku i dobrze rokuje
        if (OrderType() == OP_SELL && ticket_crit_for_sell== 1 && R_c_15m[0]<OrderOpenPrice()) ticket_crit_for_sell=0;
      //NOWE - PRZETESTOWAC
      //  if (OrderType() == OP_BUY  && ticket_crit_for_buy == 1 && WynikTR_buy>50) ticket_crit_for_buy =0;
      //  if (OrderType() == OP_SELL && ticket_crit_for_sell== 1 && WynikTR_sell>50) ticket_crit_for_sell=0;
 
//------------------------------------------------------
      // Nadawanie flagi dla zlecen ktorych cena zeszla ponizej poziomu otwarcia. Pierwsze takei zjescie nadaje flage, a przy podwojnej fladze zamkniecie zamykane jest przez short
      // przy zamk. #8 dodac warunek aby nie zamykal gdy jest flat, bo wtedy takie flagi pojawia sie dosc szybko   
        if (OrderType() == OP_BUY  && WynikTR_buy <= 0 && S_15m[0]<OrderOpenPrice()) 
            {
              if (ticket_crit_for_buy2==0 && Last_S1_15m != S_15m[0]) // porownanie czy aby bie¿¹ca linia S nie jest t¹ która ju¿ istania³a w momencie zakupu
               {
                  save_s0_for_crit_close=S_15m[0];
                  ticket_crit_for_buy2=1;
                }  
                  else if (save_s0_for_crit_close != S_15m[0] && Last_S1_15m != S_15m[0] && Last_S1_15m != S_15m[1]) ticket_crit_for_buy2=2;
             }
        if (OrderType() == OP_SELL  && WynikTR_sell <= 0 && R_15m[0]>OrderOpenPrice()) 
             {
              if (ticket_crit_for_sell2==0 && Last_R1_15m != R_15m[0]) 
               {
                  save_r0_for_crit_close=R_15m[0];
                  ticket_crit_for_sell2=1;
                }  
                 else if (save_r0_for_crit_close != R_15m[0] && Last_R1_15m != R_15m[0] && Last_R1_15m != R_15m[1]) ticket_crit_for_sell2=2;      
             }
      
      if (OrderType() == OP_BUY  && ticket_crit_for_buy2>=1  && S_c_15m[0]>OrderOpenPrice()) ticket_crit_for_buy2 =0;   //zerowanie flagi, gdy S znajduje sie powyzej ceny otwarcia
      if (OrderType() == OP_SELL && ticket_crit_for_sell2>=1 && R_c_15m[0]<OrderOpenPrice()) ticket_crit_for_sell2=0;   //zerowanie flagi, gdy R znajduje sie ponizej ceny otwarcia
      // -- koniec flagi dla zamkniec ponizej poziomu otwarcia 
 //------------------------------------------------------     
 /*
// zamykanie zlecen majacych zysk np. 100 pipsow i wpadajacyh na sr.l.k, a nastepnie przynanie flagi aby kolejne zlecenie bylo zamykane bezwzledni eprzez short
 if (OrderType() == OP_BUY)  if (MaxZysk_buy>=70)  {ticket_close_sr_buy=1; } // ticket_after_close_sr_buy=1;
 if (OrderType() == OP_SELL) if (MaxZysk_sell>=70) {ticket_close_sr_sell=1;} //ticket_after_close_sr_sell=1;
 
 if (OrderType() == OP_BUY)  if (MaxZysk_buy<70)  ticket_close_sr_buy=0;  
 if (OrderType() == OP_SELL) if (MaxZysk_sell<70) ticket_close_sr_sell=0; 
 
 //-----------------------------------
*/
      // Przydzielenie flagi critical dla transakcji powy¿ej FI>300 aby zamykac na gorce
      // lub przydzielac flage zleceniom specjalnym otwartym na podstawie FI aby je szybko zamknac gdy otwarte byly pod prad
      //DOPRACOWAC TO - ZAMIENIÆ FI NA WYSOKOSC TRENDU M15
      //#     if (OrderType() == OP_SELL && FI7_f<-300) ticket_crit_for_sell3 = 1;
      //#     if (OrderType() == OP_BUY  && FI7_f>300)  ticket_crit_for_buy3 = 1;
   
//------------------------------------------------------
// przydzielenie flagi wykonania hide SL - wykorzystane jako ukryte BE. Zamk #12

if (OrderType() == OP_BUY  && MaxZysk_buy >=50) ticket_be_buy=1;
if (OrderType() == OP_SELL && MaxZysk_sell>=50) ticket_be_sell=1;
if (orders_total(OP_BUY ) == 0 && ticket_be_buy >=0)  ticket_be_buy =-1;     // wyzerowanie ticketu dla buy // moze to kasuje ticket dla buy?
if (orders_total(OP_SELL) == 0 && ticket_be_sell>=0)  ticket_be_sell=-1;     // wyzerowanie ticketu dla sell 

//------------------------------------------------------------------------------------------------------------------------------------
// Nadawanie flagi bezwzglednego zamykania przez srodkowa linie keltnera w momencie gdy cena dochodzi w okolice gornej lub dolnej linii keltnera
 //SPROBOWAC ZMODYFIKOWAC TA FUNKCJE I ZAMIAST ZAMYKAC PRZEZ SRODKOWA TO WLACZAC BE
/*
   if  (OrderType() == OP_BUY  && odleglosc_proc_od_KU_15m_now<10 && S_c_15m[0]<KMS_c_15m[0]) ticket_close_buy_sr_ket=1;
   if  (OrderType() == OP_SELL && odleglosc_proc_od_KD_15m_now<10 && R_c_15m[0]>KMR_c_15m[0]) ticket_close_sell_sr_ket=1;
   //reset flagi

   if  ((OrderType() == OP_BUY  && ticket_close_buy_sr_ket==1) 
       && (save_s0_for_crit_close!=S_15m[0] || save_s0_for_crit_close!=S_15m[1])) ticket_close_buy_sr_ket=0;
 
   if  ((OrderType() == OP_SELL && ticket_close_sell_sr_ket==1)
       && (save_r0_for_crit_close!=R_15m[0] || save_r0_for_crit_close!=R_15m[1])) ticket_close_sell_sr_ket=0;
*/
//--------------------------------------------------------------------------------------------------------------------------
//zamykanie zlecen poprzez sort gdy nie osiagna zysku 50pips i wymuszanie otwarcia nowego zlecenia
//zamk #4A
/*
if (OrderType() == OP_BUY  && WynikTR_buy <=50 && MaxZysk_buy>50)       {ticket_close_short_buy=1;}
if (OrderType() == OP_SELL && WynikTR_sell<=50 && MaxZysk_sell>50)      {ticket_close_short_sell=1;}

//reset ticketow
if (OrderType() == OP_BUY  && WynikTR_buy >50) {ticket_close_short_buy=0; ticket_open_short_buy=0;}
if (OrderType() == OP_SELL && WynikTR_sell>50) {ticket_close_short_sell=0; ticket_open_short_sell=0;}
*/
//------------------------------------------------------------------------------------------------------------------------------------



     } // koniec wyboru magic number
   
   
   
   } // koniec petli
   // dla zamk #7
   if (total_orders <= 0) {ticket_crit_for_buy =0; ticket_crit_for_sell =0;}    // wyzerowanie ticketu dla buy // moze to kasuje ticket dla buy?
   if (orders_total(OP_SELL) <= 0) {ticket_crit_for_buy =0; ticket_crit_for_sell =0;}    // wyzerowanie ticketu dla sell 
   if (orders_total(OP_BUY)  <= 0) {ticket_crit_for_buy =0; ticket_crit_for_sell =0;}    // wyzerowanie ticketu dla sell 
          

} // koniec f. przydzielania ticketu




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja ustawiajaca sl
// dynamiczny stop loss jest rowny z dolna/gorna linia ketlnera
void set_stop_loss()
{
   RefreshRates();
   if (stop_loss >= 0)
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      
      if (Symbol()== OrderSymbol() && magic_number == OrderMagicNumber())
      {
      
         if (OrderStopLoss() == 0)        //zapamietanie poziomu Support i Resist w momencie pierwszego ustawiania S/L. Na potrzeby sprawdzenia czy do czasu pojawienia sie nowej S/R poziom S/L jest nie mniejszy niz 15 pips
            {  
               first_open_support_15m=S_15m[0];
               first_open_resist_15m=R_15m[0];
             }
  
   
   sl=0;
   sl_buy=0;
   sl_sell=0;
   
  
   
         sl = stop_loss;  //czy ta zmienna na pewno ma byc?
         
       //czy ponizej to  Close[0]>KD_15m) musi byc?
         if (OrderType() == OP_BUY  && Close[0]>KD_15m) sl_buy = NormalizeDouble(Ask - KD_15m,Digits)*points2;   //obl. rozniczy pomiêdzy cen¹ wyjscia a doln¹ linia keltera
         if (OrderType() == OP_SELL && Close[0]<KU_15m) sl_sell= NormalizeDouble(KU_15m - Bid,Digits)*points2;
     
       // ponizsze 2 jesli S/L ma przeskoczyc na srodkowa linie ketlera przy zysku ok 100 pips
    //    if (MaxZysk_buy>=100)  if (OrderType() == OP_BUY  && Close[0]>KM_15m) sl_buy = NormalizeDouble(Ask - KM_15m,Digits)*points2; 
    //    if (MaxZysk_sell>=100) if (OrderType() == OP_SELL && Close[0]<KM_15m) sl_sell= NormalizeDouble(KM_15m - Bid,Digits)*points2;
       //  if (OrderType() == OP_SELL && Close[0]<KU_15m) sl_sell= MathAbs(NormalizeDouble(KU_15m - OrderOpenPrice(),Digits)*points2);
    
    
       //gdy SL jest mniejszy niz dynamic_stop_loss_min (czyli zwykle 1/2 stop_loss, ale nie uzywaj takiego zapisu bo zmienna stop_loss zmienia sie w zaleznosci od ilosci zer po przecinku, a tu trzeba odwolac sie do wyniku transakcji) 
         if (OrderType() == OP_BUY)  if (WynikTR_buy< dynamic_stop_loss_min) if (NormalizeDouble(OrderOpenPrice()-KD_15m,Digits)*points2  <= NormalizeDouble((stop_loss/1.5),Digits))  sl_buy = stop_loss/1.5-(NormalizeDouble(OrderOpenPrice()-Ask,Digits)*points2); // buy ok 
    //     if (MaxZysk_buy>=100)if (OrderType() == OP_BUY)  if (WynikTR_buy< dynamic_stop_loss_min) if (NormalizeDouble(OrderOpenPrice()-KM_15m,Digits)*points2  <= NormalizeDouble((stop_loss/1.5),Digits))  sl_buy = stop_loss/1.5-(NormalizeDouble(OrderOpenPrice()-Ask,Digits)*points2); // buy ok 
          
         if (OrderType() == OP_SELL) if (WynikTR_sell<dynamic_stop_loss_min) if (NormalizeDouble(KU_15m-OrderOpenPrice(),Digits)*points2  <= NormalizeDouble((stop_loss/1.5),Digits))  sl_sell=stop_loss/1.5-(NormalizeDouble(Bid-OrderOpenPrice(),Digits)*points2);
     //    if (MaxZysk_sell>=100)if (OrderType() == OP_SELL) if (WynikTR_sell<dynamic_stop_loss_min) if (NormalizeDouble(KM_15m-OrderOpenPrice(),Digits)*points2  <= NormalizeDouble((stop_loss/1.5),Digits))  sl_sell=stop_loss/1.5-(NormalizeDouble(Bid-OrderOpenPrice(),Digits)*points2);
       
       //gdy SL jest wiekszy niz 45
         if (OrderType() == OP_BUY)  if (NormalizeDouble(OrderOpenPrice()-KD_15m,Digits)*points2 >stop_loss*1.5) sl_buy =stop_loss*1.5-(NormalizeDouble(OrderOpenPrice()-Bid,Digits)*points2);
         if (OrderType() == OP_SELL) if (NormalizeDouble(KU_15m-OrderOpenPrice(),Digits)*points2 >stop_loss*1.5) sl_sell=stop_loss*1.5-(NormalizeDouble(Ask-OrderOpenPrice(),Digits)*points2);
            // ponizsze 2 jesli S/L ma przeskoczyc na srodkowa linie ketlera przy zysku ok 100 pips  
     //    if (MaxZysk_buy>=100) if (OrderType() == OP_BUY)  if (NormalizeDouble(OrderOpenPrice()-KM_15m,Digits)*points2 >stop_loss*1.5) sl_buy =stop_loss*1.5-(NormalizeDouble(OrderOpenPrice()-Bid,Digits)*points2);
     //    if (MaxZysk_sell>=100) if (OrderType() == OP_SELL) if (NormalizeDouble(KM_15m-OrderOpenPrice(),Digits)*points2 >stop_loss*1.5) sl_sell=stop_loss*1.5-(NormalizeDouble(Ask-OrderOpenPrice(),Digits)*points2);
          
      //POWINNO BYC CHYBA ROZDZIELENIE NA KOLEJNE DWA WARUNKI - JEDNE W ZYSKU DRUGIE PONIZEJ ALBO OGRANICZENIE DO WARTOSCI UJEMNYCH
      
      // okres ochronny 
       if (OrderType() == OP_BUY)  if ((first_open_resist_15m ==R_15m[0]) || (first_open_resist_15m ==R_15m[1])) sl_buy =stop_loss*1.5-(NormalizeDouble(OrderOpenPrice()-Bid,Digits)*points2);  // ustawienie max_(1.5 razy od normalnego poziomu) poziomu S/L w momencie gdy po raz pierwszy ustawiany jest S/L
       if (OrderType() == OP_SELL) if ((first_open_support_15m==S_15m[0]) || (first_open_support_15m==S_15m[1])) sl_sell=stop_loss*1.5+(NormalizeDouble(OrderOpenPrice()-Ask,Digits)*points2);
//-----Opoznianie S/L o 20 pips gdy wystapi duze wybicie ----------------------------  
      // if (FI7_f<-200*0.001 ) opoznij_close_buy=1;
      // if (FI7_f>+200*0.001 ) opoznij_close_sell=1;
      // if (TSI_2b>0) opoznij_close_buy=0;
      // if (TSI_2b<0) opoznij_close_sell=0;
       
      if (TSI_1v<0 && WynikTR_buy>0)  opoznij_close_buy=1;
      if (TSI_1v>0 && WynikTR_sell>0) opoznij_close_sell=1;  
    
      if (TSI_1v>0 || WynikTR_buy<0 ) opoznij_close_buy=0;
      if (TSI_1v<0 || WynikTR_sell<0) opoznij_close_sell=0;

   //   if (opoznij_close_buy==1)  sl_buy  = sl_buy  + NormalizeDouble(100,Digits);
   //   if (opoznij_close_sell==1) sl_sell = sl_sell + NormalizeDouble(100,Digits);
// ------------------------------
 
         if (sl < MarketInfo(Symbol(),MODE_STOPLEVEL)) sl = MarketInfo(Symbol(),MODE_STOPLEVEL);  //jezeli ustwiony SL jest mniejszy niz rynek zezwala, to przyjmij najmniejszy dozwolony
         if  (OrderType() == OP_BUY  && sl_buy  < MarketInfo(Symbol(),MODE_STOPLEVEL)) sl_buy = MarketInfo(Symbol(),MODE_STOPLEVEL);  //jezeli ustwiony SL jest mniejszy niz rynek zezwala, to przyjmij najmniejszy dozwolony
         if  (OrderType() == OP_SELL && sl_sell < MarketInfo(Symbol(),MODE_STOPLEVEL)) sl_sell = MarketInfo(Symbol(),MODE_STOPLEVEL);  //jezeli ustwiony SL jest mniejszy niz rynek zezwala, to przyjmij najmniejszy dozwolony
     
         if (OrderType() == OP_BUY   && NormalizeDouble(Ask - sl_buy * Point,Digits) != OrderStopLoss())                          // zapobiega przed error 1 - ustawienie S/L na tym samym poziomie co wczesniej (slabo zweryfikowane)
         if (OrderType() == OP_BUY   && NormalizeDouble(Ask - OrderStopLoss(),Digits) != NormalizeDouble(sl_buy *Point,Digits))   //sprawdzanie aby nie probowal wysylac SL na tym samym poziomie. Powododwa³oby to pojawienie sie b³êdu ordermodify error 1
             OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask - sl_buy * Point,Digits),OrderTakeProfit(),OrderExpiration(),CLR_NONE);
 //&& sl_buy <300        
         if (OrderType() == OP_SELL && NormalizeDouble(Bid + sl_sell * Point,Digits) != OrderStopLoss())                          // zapobiega przed error 1 - ustawienie S/L na tym samym poziomie co wczesniej (slabo zweryfikowane)
         if (OrderType() == OP_SELL && NormalizeDouble(OrderStopLoss() - Bid,Digits) != NormalizeDouble(sl_sell *Point,Digits))
             OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid + sl_sell * Point,Digits),OrderTakeProfit(),OrderExpiration(),CLR_NONE);
//&& sl_sell<300

      }
   }

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// na ktorej swiecy w stecz bylo otwrte ostatnie zamkniete zlecenie na stoploss
int stoploss_bar(int order_type)
{
   RefreshRates();
   for (int i = OrdersHistoryTotal() - 1;i >= 0;i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) continue;
      if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber() && order_type == OrderType()) 
      {
         if (OrderType() ==  OP_BUY  && OrderClosePrice() >= OrderStopLoss()) return(iBarShift(Symbol(),Period(),OrderCloseTime()));
         else
         if (OrderType() ==  OP_SELL && OrderClosePrice() <= OrderStopLoss()) return(iBarShift(Symbol(),Period(),OrderCloseTime()));
         else break;
      }
   }
   return(wait_bars + 1);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// na ktorej swiecy w stecz bylo otwrte ostatnie zamkniete zlecenie
int history_bar(int order_type)
{
   RefreshRates();
   for (int i = OrdersHistoryTotal() - 1;i >= 0;i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) continue;
      if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber() && order_type == OrderType()) return(iBarShift(Symbol(),Period(),OrderOpenTime()));
   }
   return(-1);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// na ktorej swiecy w stecz bylo otwrte ostatnie otwarte zlecenie
int actual_bar(int order_type)
{
   RefreshRates();
   for (int i = OrdersTotal() - 1;i >= 0;i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber() && order_type == OrderType()) return(iBarShift(Symbol(),Period(),OrderOpenTime()));
   }
   return(-1);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//cena otwarcia ostatnie transkacji
double open_price(int order_type)
{
   RefreshRates();
   for (int i = OrdersTotal() - 1;i >= 0;i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber() && order_type == OrderType()) return(OrderOpenPrice());
   }
   return(-1);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja zamykajaca zlecenia na okreslonej stracie w pisach
void hide_stop_loss()
{
   RefreshRates();
   if (hide_sl >= 0)
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol()== OrderSymbol() && magic_number == OrderMagicNumber())
      {
         if (OrderType() == OP_BUY  && NormalizeDouble(OrderOpenPrice() - Ask,Digits) >= hide_sl * Point) OrderClose(OrderTicket(),OrderLots(),Bid,3,CLR_NONE);
         if (OrderType() == OP_SELL && NormalizeDouble(Bid - OrderOpenPrice(),Digits) >= hide_sl * Point) OrderClose(OrderTicket(),OrderLots(),Ask,3,CLR_NONE);
      }
   }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja zamykajaca zlecenia na okreslonym zysku w pisach
void hide_take_profit()
{
   RefreshRates();
   if (hide_tp >= 0)
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol()== OrderSymbol() && magic_number == OrderMagicNumber())
      {
         if (OrderType() == OP_BUY  && NormalizeDouble(Bid - OrderOpenPrice(),Digits) >= hide_tp * Point) OrderClose(OrderTicket(),OrderLots(),Bid,3,CLR_NONE);
         if (OrderType() == OP_SELL && NormalizeDouble(OrderOpenPrice() - Ask,Digits) >= hide_tp * Point) OrderClose(OrderTicket(),OrderLots(),Ask,3,CLR_NONE);
      }
   }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja obliczajaca aktualny zysk dla danej transakcji

//double WynikkTR()
void WynikkTR()
{

   //double WynikTR2;
   RefreshRates();
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol()== OrderSymbol() && magic_number == OrderMagicNumber())
      {
         //if (OrderType() == OP_BUY)  WynikTR = NormalizeDouble(Bid - OrderOpenPrice(),Digits);
         //if (OrderType() == OP_SELL) WynikTR = NormalizeDouble(OrderOpenPrice() - Ask,Digits);
         if (OrderType() == OP_BUY)   WynikTR_buy = NormalizeDouble(Bid - OrderOpenPrice(),Digits)*points;
         if (OrderType() == OP_SELL)  WynikTR_sell= NormalizeDouble(OrderOpenPrice() - Ask,Digits)*points;
         //if (Digits == 3 || Digits == 5) WynikTR*=100 ;
         //if (Digits == 3 || Digits == 5) WynikTR_buy*=100 ;
         //if (Digits == 3 || Digits == 5) WynikTR_sell*=100 ;
      }


   }
//return (WynikTR2);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja obliczajaca maksymalny zysk dla danej transakcji

//double MaxxZysk()
void MaxxZysk()
{
   //double makszysk2;
   RefreshRates();
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol()== OrderSymbol() && magic_number == OrderMagicNumber())
      {
         if (OrderType() == OP_BUY)  
          {
           if (Bid> maksprice_buy) maksprice_buy = Bid;
           MaxZysk_buy= NormalizeDouble(maksprice_buy - OrderOpenPrice(),Digits)*points;
           //if (Digits == 3 || Digits == 5) MaxZysk_buy*=100 ;
          }
         
         if (OrderType() == OP_SELL) 
          {
             if (Ask< maksprice_sell) maksprice_sell=Ask;
             MaxZysk_sell = NormalizeDouble(OrderOpenPrice() - maksprice_sell,Digits)*points;
             //if (Digits == 3 || Digits == 5) MaxZysk_sell*=100 ;
          }
       }
    }   
 //return (maksprice);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//bada czy wystapil wczesniej wysoki wierzcholek, wskazujacy na silny trend
void silny_szczyt()
{
   
 /*  zastapiono wskaznikiem FI  
   trend0_rsi=iCustom(NULL,PERIOD_M15,"SW_hull_RSI",0,0);
   trend1_rsi=iCustom(NULL,PERIOD_M15,"SW_hull_RSI",1,0);
   trend2_rsi=iCustom(NULL,PERIOD_M15,"SW_hull_RSI",2,0);

   trend0_rsi_p[0]=trend0_rsi; //zaktualizowanie ostatniej wartoœci RSI
   trend1_rsi_p[0]=trend1_rsi; //zaktualizowanie ostatniej wartoœci RSI
   trend2_rsi_p[0]=trend2_rsi; //zaktualizowanie ostatniej wartoœci RSI

   if (trend0_rsi_p[0]!=trend1_rsi_p[0] && trend0_rsi_p[0]!=trend2_rsi_p[0]) {trendup0_rsi=false;trenddn0_rsi=false;trendstp0_rsi=true;}
   if (trend0_rsi_p[0]==trend1_rsi_p[0])  {trendup0_rsi=true;trenddn0_rsi=false;trendstp0_rsi=false;}
   if (trend0_rsi_p[0]==trend2_rsi_p[0])  {trendup0_rsi=false;trenddn0_rsi=true;trendstp0_rsi=false;}
*/
//-----
int lvl_1;
lvl_1=25;
   if (FI21_p0 < lvl_1*0.001   && FI21_p0 > -lvl_1*0.001) {trendup0_rsi=false;trenddn0_rsi=false;trendstp0_rsi=true;}
   if (FI21_p2 > lvl_1*0.001   && FI21_p0 <  lvl_1*0.001) {trendup0_rsi=false;trenddn0_rsi=false;trendstp0_rsi=true;}
   if (FI21_p2 <-lvl_1*0.001   && FI21_p0 > -lvl_1*0.001) {trendup0_rsi=false;trenddn0_rsi=false;trendstp0_rsi=true;}
    
   
   if (FI21_p0 >  lvl_1*0.001  && FI21_p2 >  lvl_1*0.001)  {trendup0_rsi=true; trenddn0_rsi=false;trendstp0_rsi=false;}
   if (FI21_p0 < -lvl_1*0.001  && FI21_p2 < -lvl_1*0.001)  {trendup0_rsi=false;trenddn0_rsi=true; trendstp0_rsi=false;}
/// dla P2, aby zachowac zgodnoc z czesniejszy rozwiazaniem
//trend flat 
   if (FI21_p2 <  lvl_1*0.001  && FI21_p2 > -lvl_1*0.001) {trendup2_rsi=false;trenddn2_rsi=false;trendstp2_rsi=true;}
   if (FI21_p4 >  lvl_1*0.001  && FI21_p2 <  lvl_1*0.001) {trendup2_rsi=false;trenddn2_rsi=false;trendstp2_rsi=true;}
   if (FI21_p4 < -lvl_1*0.001  && FI21_p2 > -lvl_1*0.001) {trendup2_rsi=false;trenddn2_rsi=false;trendstp2_rsi=true;}
    
   
   if (FI21_p2 >  lvl_1*0.001  && FI21_p4 > lvl_1*0.001)  {trendup2_rsi=true; trenddn2_rsi=false;trendstp2_rsi=false;}
   if (FI21_p2 < -lvl_1*0.001  && FI21_p4 <-lvl_1*0.001)  {trendup2_rsi=false;trenddn2_rsi=true; trendstp2_rsi=false;}





}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Kat dolenj linii ketlera 
void ketler_angle()
{
    int k;
    ketler_kat_dn = iCustom(NULL,PERIOD_M15,"angle2",1,0); // gorny kanal
   
    
    
  //  if (newBar==1)
  //    if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0)
   //      {
  if (ketler_kat_p[0] != ketler_kat_dn)
  {
   ketler_kat_tmp =ketler_kat_dn;
    
   
           for(  k =22; k>=0; k--) ketler_kat_p[k] =ketler_kat_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           ketler_kat_p[0]=ketler_kat_tmp; //zaktualizowanie ostatniej wartoœci RSI
           if (ketler_kat_p[0]>0) { ketler_trend_up = ketler_trend_up+1;  if (ketler_kat_p[0]>10) ketler_trend_dn=0; }
           if (ketler_kat_p[0]<0) { ketler_trend_dn = ketler_trend_dn+1;  if (ketler_kat_p[0]<-10) ketler_trend_up=0; }
          
           
           sredni_kat_ketlera=0;
         //  for(  k =29; k>0; k--) sredni_kat_ketlera+=ketler_kat_p[k]; sredni_kat_ketlera=0 ;
           for(  k =3;  k>0; k--) sredni_kat_ketlera+=ketler_kat_p[k]; sredni_kat_ketlera_p3 = sredni_kat_ketlera / 3;  sredni_kat_ketlera=0;
           for(  k =7;  k>0; k--) sredni_kat_ketlera+=ketler_kat_p[k]; sredni_kat_ketlera_p7 = sredni_kat_ketlera / 7;  sredni_kat_ketlera=0;
           for(  k =14; k>0; k--) sredni_kat_ketlera+=ketler_kat_p[k]; sredni_kat_ketlera_p14= sredni_kat_ketlera / 14; sredni_kat_ketlera=0;
           for(  k =21; k>0; k--) sredni_kat_ketlera+=ketler_kat_p[k]; sredni_kat_ketlera_p21= sredni_kat_ketlera / 21; sredni_kat_ketlera=0;
           for(  k =27; k>0; k--) sredni_kat_ketlera+=ketler_kat_p[k]; sredni_kat_ketlera_p28= sredni_kat_ketlera / 28; sredni_kat_ketlera=0;
           for(  k =100; k>0; k--) sredni_kat_ketlera+=ketler_kat_p[k]; sredni_kat_ketlera_p100= sredni_kat_ketlera / 100; sredni_kat_ketlera=0;
       }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNKCJA ZARZ¥DZAJ¥CA

void kanal_ketlera_15m()
{
      KU_15m = iCustom(NULL,PERIOD_M15,"keltner",0,0); // gorny kanal
      KM_15m = iCustom(NULL,PERIOD_M15,"keltner",1,0); // srodkowy
      KD_15m = iCustom(NULL,PERIOD_M15,"keltner",2,0); // dolny

      //Czy nie lepiej to przerobic w tablice i porownywac nie z 2 lecz np z 3 okreesow?
      KU2_15m = iCustom(NULL,PERIOD_M15,"keltner",0,2); // gorny kanal
    //KM2_15m = iCustom(NULL,PERIOD_M15,"keltner",1,2); // srodkowy  /niewykorzystywane
      KD2_15m = iCustom(NULL,PERIOD_M15,"keltner",2,2); // dolny
 }

//  if (rtrend_15m==1 || rtrend_15m==2) RSI3_1=iRSI(NULL, PERIOD_M15, 7, PRICE_CLOSE, 1);  //dla wejsc podczas trendu dol lub rosnacego

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void kanal_ketlera_1h()
{
      KU_1h = iCustom(NULL,PERIOD_H1,"keltner",0,0); // gorny kanal
      KM_1h = iCustom(NULL,PERIOD_H1,"keltner",1,0); // srodkowy
      KD_1h = iCustom(NULL,PERIOD_H1,"keltner",2,0); // dolny

      //Czy nie lepiej to przerobic w tablice i porownywac nie z 2 lecz np z 3 okreesow?
      KU2_1h = iCustom(NULL,PERIOD_H1,"keltner",0,2); // gorny kanal
    //KM2_1h = iCustom(NULL,PERIOD_H1,"keltner",1,2); // srodkowy  /niewykorzystywane
      KD2_1h = iCustom(NULL,PERIOD_H1,"keltner",2,2); // dolny
 }

//  if (rtrend_1h==1 || rtrend_1h==2) RSI3_1=iRSI(NULL, PERIOD_H1, 7, PRICE_CLOSE, 1);  //dla wejsc podczas trendu dol lub rosnacego  
      
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     void kanal_ketlera_4h()
{
      KU_4h = iCustom(NULL,PERIOD_H4,"keltner",0,0); // gorny kanal
      KM_4h = iCustom(NULL,PERIOD_H4,"keltner",1,0); // srodkowy
      KD_4h = iCustom(NULL,PERIOD_H4,"keltner",2,0); // dolny

      //Czy nie lepiej to przerobic w tablice i porownywac nie z 2 lecz np z 3 okreesow?
      KU2_4h = iCustom(NULL,PERIOD_H4,"keltner",0,2); // gorny kanal
    //KM2_4h = iCustom(NULL,PERIOD_H4,"keltner",1,2); // srodkowy  /niewykorzystywane
      KD2_4h = iCustom(NULL,PERIOD_H4,"keltner",2,2); // dolny
 }

//  if (rtrend_4h==1 || rtrend_4h==2) RSI3_1=iRSI(NULL, PERIOD_H4, 7, PRICE_CLOSE, 1);  //dla wejsc podczas trendu dol lub rosnacego 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void kanal_ketlera_1d()
{
      KU_1d = iCustom(NULL,PERIOD_D1,"keltner",0,0); // gorny kanal
      KM_1d = iCustom(NULL,PERIOD_D1,"keltner",1,0); // srodkowy
      KD_1d = iCustom(NULL,PERIOD_D1,"keltner",2,0); // dolny

      //Czy nie lepiej to przerobic w tablice i porownywac nie z 2 lecz np z 3 okreesow?
      KU2_1d = iCustom(NULL,PERIOD_D1,"keltner",0,2); // gorny kanal
    //KM2_1d = iCustom(NULL,PERIOD_D1,"keltner",1,2); // srodkowy  /niewykorzystywane
      KD2_1d = iCustom(NULL,PERIOD_D1,"keltner",2,2); // dolny
 }

//  if (rtrend_1d==1 || rtrend_1d==2) RSI3_1=iRSI(NULL, PERIOD_D1, 7, PRICE_CLOSE, 1);  //dla wejsc podczas trendu dol lub rosnacego
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void price_min4()
{

 int k;


  //  RSI7_15m   = iRSI(NULL, PERIOD_M15, 7, PRICE_CLOSE, 0);
  //  RSI14_15m  = iRSI(NULL, PERIOD_M15, 14, PRICE_CLOSE, 0);
  //  rsi7_tmp =RSI7_15m; rsi14_tmp=RSI14_15m;
    
    //price_min4_tmp=Bid;  
  
    if (newBar==1)
     // if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0)
         {
           price_max_ask_tmp=Ask; //wyzerowanie 
           price_max_bid_tmp=Bid;
           for(  k =6; k>0; k--) price_min_p[k] =price_min_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           for(  k =6; k>0; k--) price_max_p[k] =price_max_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje        
         }
         if (Ask> price_max_ask_tmp) price_max_ask_tmp = Ask;  //pobranie najwiekszej wartosci z aktualnej swiecy
         if (Bid< price_max_bid_tmp) price_max_bid_tmp = Bid;
           
           price_min_p[0]=price_max_bid_tmp; //zaktualizowanie ostatniej wartoœci RSI
           price_max_p[0]=price_max_ask_tmp; //zaktualizowanie ostatniej wartoœci RSI
         
           price_min4  =  price_min_p[ArrayMinimum( price_min_p,6,0)];   //wybranie najwiekszej wartosci z tablicy
           price_max4  =  price_max_p[ArrayMaximum( price_max_p,6,0)];   //odwtornie do jw.
           price_from_top = (price_max4-Bid) *points;
           price_from_down = (Ask - price_min4) *points;
           
           
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void odleglosc_sr_w_rsi_15m()
{

 int k;

 //   if (rsi100_game==1) RSI100 = iRSI(NULL, PERIOD_M15, 100, PRICE_CLOSE, 0); // na potrzeby analizy wyprzedazy rynku poprzez RSI100
 // Poziom sygnalu RSI nie jest uwzgledniany na podstawie rodzaju trendu ale pozycji S/R w kanale keltera)
 // RSI14 na potrzeby wyznaczania wielkosci szczytow wzgledem innych 
 
    RSI7_15m   = iRSI(NULL, PERIOD_M15, 7, PRICE_CLOSE, 0);
    RSI14_15m  = iRSI(NULL, PERIOD_M15, 14, PRICE_CLOSE, 0);
    rsi7_tmp =RSI7_15m; rsi14_tmp=RSI14_15m;
    RSI7_15m_p[0]=RSI7_15m; RSI14_15m_p[0]=RSI14_15m;  
   
    if (newBar==1)
      if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0)
         {
           for(  k =6; k>0; k--) RSI7_15m_p[k] =RSI7_15m_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           for(  k =6; k>0; k--) RSI14_15m_p[k]=RSI14_15m_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           RSI7_15m_p[0]=rsi7_tmp; //zaktualizowanie ostatniej wartoœci RSI
           RSI14_15m_p[0]=rsi14_tmp; //zaktualizowanie ostatniej wartoœci RSI
      
           RSI7_max_15m  = RSI7_15m_p [ArrayMaximum(RSI7_15m_p,6,0)];   //wybranie najwiekszej wartosci z tablicy
           RSI7_Min_15m  = RSI7_15m_p [ArrayMinimum(RSI7_15m_p,6,0)];   //odwtornie do jw.
      
           RSI14_Min_15m = RSI14_15m_p[ArrayMinimum(RSI14_15m_p,6,0)];
           RSI14_max_15m = RSI14_15m_p[ArrayMaximum(RSI14_15m_p,6,0)];
           
           // Print ("RSI_0=",RSI7_15m_p[0], "  RSI_1=",RSI7_15m_p[1], "  RSI_2=",RSI7_15m_p[2], "  RSI_3=",RSI7_15m_p[3], "  RSI_4=",RSI7_15m_p[4], "  RSI_5=",RSI7_15m_p[5], "  RSI_6=",RSI7_15m_p[6], "  RSI_7=",RSI7_15m_p[7]);
           // Print ("MaxRSI=",RSI7_max_15m, "   RSI7_max_15m(4)=",RSI7_max_15m(4),  "   RSI7_Min_15m(4)=",RSI7_Min_15m(4));
           // Print ("RSI_0=",RSI14_p[0], "  RSI_1=",RSI14_p[1], "  RSI_2=",RSI14_p[2], "  RSI_3=",RSI14_p[3], "  RSI_4=",RSI14_p[4], "  RSI_5=",RSI14_p[5], "  RSI_6=",RSI14_p[6], "  RSI_7=",RSI14_p[7]);
           // Print ("MaxRSI=",RSI14_max_15m, "   RSI7_max_15m(4)=",RSI14_max_15m(4),  "   RSI7_Min_15m(4)=",RSI14_Min_15m(4));
          }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void odleglosc_sr_w_rsi_1h()
{

 int k;

 //   if (rsi100_game==1) RSI100 = iRSI(NULL, PERIOD_M15, 100, PRICE_CLOSE, 0); // na potrzeby analizy wyprzedazy rynku poprzez RSI100
 // Poziom sygnalu RSI nie jest uwzgledniany na podstawie rodzaju trendu ale pozycji S/R w kanale keltera)
 // RSI14 na potrzeby wyznaczania wielkosci szczytow wzgledem innych 
 
   RSI7_1h    =  iRSI(NULL, PERIOD_H1, 7, PRICE_CLOSE, 0);
   RSI14_1h   =  iRSI(NULL, PERIOD_H1, 14, PRICE_CLOSE, 0);
        
    rsi7_tmp_1h = RSI7_1h; rsi14_tmp_1h=RSI14_1h;
    RSI7_1h_p[0]= RSI7_1h; RSI14_1h_p[0]=RSI14_1h;  
   

    
    
    if (newBar==1)
      if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0)
         {

           for(  k =6; k>0; k--) RSI7_1h_p[k] =RSI7_1h_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           for(  k =6; k>0; k--) RSI14_1h_p[k]=RSI14_1h_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           RSI7_1h_p[0]=rsi7_tmp_1h; //zaktualizowanie ostatniej wartoœci RSI
           RSI14_1h_p[0]=rsi14_tmp_1h; //zaktualizowanie ostatniej wartoœci RSI
      
           RSI7_max_1h  = RSI7_1h_p [ArrayMaximum(RSI7_1h_p,6,0)];   //wybranie najwiekszej wartosci z tablicy
           RSI7_Min_1h  = RSI7_1h_p [ArrayMinimum(RSI7_1h_p,6,0)];   //odwtornie do jw.
      
           RSI14_Min_1h = RSI14_1h_p[ArrayMinimum(RSI14_1h_p,6,0)];
           RSI14_max_1h = RSI14_1h_p[ArrayMaximum(RSI14_1h_p,6,0)];
     
         }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void odleglosc_sr_w_rsi_4h()
{

 int k;

    if (rsi100_game==1) RSI100 = iRSI(NULL, PERIOD_M15, 100, PRICE_CLOSE, 0); // na potrzeby analizy wyprzedazy rynku poprzez RSI100
 // Poziom sygnalu RSI nie jest uwzgledniany na podstawie rodzaju trendu ale pozycji S/R w kanale keltera)
 // RSI14 na potrzeby wyznaczania wielkosci szczytow wzgledem innych 
 
    RSI7_4h   = iRSI(NULL, PERIOD_H4, 7, PRICE_CLOSE, 0);
    RSI14_4h  = iRSI(NULL, PERIOD_H4, 14, PRICE_CLOSE, 0);
    rsi7_tmp_4h =RSI7_4h; rsi14_tmp_4h = RSI14_4h;
    RSI7_4h_p[0]=RSI7_4h;    RSI14_4h_p[0] = RSI14_4h;  

    if (newBar==1)
      if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0)
         {
           for(  k =6; k>0; k--) RSI7_4h_p[k] =RSI7_4h_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           for(  k =6; k>0; k--) RSI14_4h_p[k]=RSI14_4h_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           RSI7_4h_p[0] =rsi7_tmp_4h; //zaktualizowanie ostatniej wartoœci RSI
           RSI14_4h_p[0]=rsi14_tmp_4h; //zaktualizowanie ostatniej wartoœci RSI
      
           RSI7_max_4h  = RSI7_4h_p[ArrayMaximum(RSI7_4h_p,6,0)];   //wybranie najwiekszej wartosci z tablicy
           RSI7_Min_4h  = RSI7_4h_p[ArrayMinimum(RSI7_4h_p,6,0)];   //odwtornie do jw.
      
           RSI14_Min_4h = RSI14_4h_p[ArrayMinimum(RSI14_4h_p,6,0)];
           RSI14_max_4h = RSI14_4h_p[ArrayMaximum(RSI14_4h_p,6,0)];
     
          }

}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void odleglosc_sr_w_rsi_1d()
{
 int k;

    if (rsi100_game==1) RSI100 = iRSI(NULL, PERIOD_M15, 100, PRICE_CLOSE, 0); // na potrzeby analizy wyprzedazy rynku poprzez RSI100
 // Poziom sygnalu RSI nie jest uwzgledniany na podstawie rodzaju trendu ale pozycji S/R w kanale keltera)
 // RSI14 na potrzeby wyznaczania wielkosci szczytow wzgledem innych 
 
    RSI7_1d   = iRSI(NULL, PERIOD_D1, 7, PRICE_CLOSE, 0);
    RSI14_1d  = iRSI(NULL, PERIOD_D1, 14, PRICE_CLOSE, 0);
    rsi7_tmp_1d =RSI7_1d; rsi14_tmp_1d=RSI14_1d;
    RSI7_1d_p[0]=RSI7_1d; RSI14_1d_p[0]=RSI14_1d;  
   
    if (newBar==1)
      if (history_bar(OP_BUY ) != 0 && actual_bar(OP_BUY ) != 0)
         {
           for(  k =6; k>0; k--) RSI7_1d_p[k] =RSI7_1d_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           for(  k =6; k>0; k--) RSI14_1d_p[k]=RSI14_1d_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
           
           RSI7_1d_p[0]=rsi7_tmp_1d; //zaktualizowanie ostatniej wartoœci RSI
           RSI14_1d_p[0]=rsi14_tmp_1d; //zaktualizowanie ostatniej wartoœci RSI
      
           RSI7_max_1d  = RSI7_1d_p [ArrayMaximum(RSI7_1d_p,6,0)];   //wybranie najwiekszej wartosci z tablicy
           RSI7_Min_1d  = RSI7_1d_p [ArrayMinimum(RSI7_1d_p,6,0)];   //odwtornie do jw.
      
           RSI14_Min_1d = RSI14_1d_p[ArrayMinimum(RSI14_1d_p,6,0)];
           RSI14_max_1d = RSI14_1d_p[ArrayMaximum(RSI14_1d_p,6,0)];
           
          }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void wyznacz_wysokosc_trendu_now_15m()
{
   //int k;

      // KU+KD=",NormalizeDouble(KU_15m+KD_15m,Digits),"   KU_15m - R= ",NormalizeDouble(KU_15m-R_c_15m[0],Digits)*points

      odleglosc_pips_od_KU_15m = NormalizeDouble (NormalizeDouble (KU_15m-R_c_15m[0],Digits)*points,1);
      odleglosc_pips_od_KD_15m = NormalizeDouble (NormalizeDouble (S_c_15m[0]-KD_15m,Digits)*points,1);
      wysokosc_keltera_15m     = NormalizeDouble (NormalizeDouble (KU_15m-KD_15m,Digits)*points,1);
      odleglosc_proc_od_KU_15m = NormalizeDouble (((odleglosc_pips_od_KU_15m / wysokosc_keltera_15m)* 100),1); //*100 to jest razy 100% i nie ma nic wspolnego z iloscia pipsow po przecinku
      odleglosc_proc_od_KD_15m = NormalizeDouble (((odleglosc_pips_od_KD_15m / wysokosc_keltera_15m)* 100),1);
      wysokosc_trendu_15m      = NormalizeDouble (100-(odleglosc_proc_od_KU_15m + odleglosc_proc_od_KD_15m),1);


      if (R_c_15m[0]<Close[0]) odleglosc_pips_od_KU_15m_now=NormalizeDouble(KU_15m-Close[0],Digits)*points; else odleglosc_pips_od_KU_15m_now=NormalizeDouble(NormalizeDouble(KU_15m-R_c_15m[0],Digits)*points,1);
      if (S_c_15m[0]>Close[0]) odleglosc_pips_od_KD_15m_now=NormalizeDouble(Close[0]-KD_15m,Digits)*points; else odleglosc_pips_od_KD_15m_now=NormalizeDouble(NormalizeDouble(S_c_15m[0]-KD_15m,Digits)*points,1);
      odleglosc_proc_od_KU_15m_now= NormalizeDouble(((odleglosc_pips_od_KU_15m_now/wysokosc_keltera_15m)* 100),1); //*100 to jest razy 100% i nie ma nic wspolnego z iloscia pipsow po przecinku
      odleglosc_proc_od_KD_15m_now= NormalizeDouble(((odleglosc_pips_od_KD_15m_now/wysokosc_keltera_15m)* 100),1);
      wysokosc_trendu_15m_now=      NormalizeDouble(100-(odleglosc_proc_od_KU_15m_now+odleglosc_proc_od_KD_15m_now),1);

      wielkosc_poslizgu= wysokosc_keltera_15m/6;   //dopuszczalna roznica pomiedzy lokalnym ekstremum a momemntem kupna. Umieszczone tu ze wzgledu na szybkosc odswiezania wysokosc_keltnera_15m
     
//price_from_top<= wielkosc_poslizgu  //filtr dla sell do warunkow kupna
//price_from_down<= wielkosc_poslizgu //filtr dla sel
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void wyznacz_wysokosc_trendu_15m()
{
int k;
   if (wysokosc_trendu_15m_t[0]!=wysokosc_trendu_15m)
         {
            //if (R_15m[0]!=Resist_15m)
           for(  k =6; k>0; k--) wysokosc_trendu_15m_t[k]=wysokosc_trendu_15m_t[k-1];
           wysokosc_trendu_15m_t[0]=wysokosc_trendu_15m;

           srednia_wysokosc_trendu_15m=0;
           for(  k =6; k>0; k--) srednia_wysokosc_trendu_15m+=wysokosc_trendu_15m_t[k];
           //ponizsza linia zostala przerzucona do funkcji wyznacz_wysokosc_trendu_15m_NOW, dzieki czemu zmienna wysokosc_trendu_15m_now ktora jest tu wykorzystywana, bêdzie mia³a bardziej aktualn¹ wartoœæ
           srednia_wysokosc_trendu_15m=NormalizeDouble((srednia_wysokosc_trendu_15m+wysokosc_trendu_15m_now)/8,0);

         }
          HighRSI7_15m  = RSI7_R_15m - RSI7_S_15m;  
          HighRSI7_15m_srednia_tmp  = HighRSI7_15m;
        //HighRSI7_15m_srednia_t[0] = HighRSI7_15m;
  
  
         if (HighRSI7_15m_srednia_t[0]!=HighRSI7_15m)
         {
            //if (R_15m[0]!=Resist_15m)
           for(  k =6; k>0; k--) HighRSI7_15m_srednia_t[k]=HighRSI7_15m_srednia_t[k-1];
           HighRSI7_15m_srednia_t[0]=HighRSI7_15m_srednia_tmp;

           HighRSI7_15m_srednia=0;
           for(  k =6; k>0; k--) HighRSI7_15m_srednia+=HighRSI7_15m_srednia_t[k];
           HighRSI7_15m_srednia=HighRSI7_15m_srednia/6;

         }
}        

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void wyznacz_wysokosc_trendu_now_1h()
{
   //int k;

      // KU+KD=",NormalizeDouble(KU_1h+KD_1h,Digits),"   KU_1h - R= ",NormalizeDouble(KU_1h-R_c_1h[0],Digits)*100

      odleglosc_pips_od_KU_1h = NormalizeDouble (NormalizeDouble (KU_1h-R_c_1h[0],Digits)*points,1);
      odleglosc_pips_od_KD_1h = NormalizeDouble (NormalizeDouble (S_c_1h[0]-KD_1h,Digits)*points,1);
      wysokosc_keltera_1h     = NormalizeDouble (NormalizeDouble (KU_1h-KD_1h,Digits)*points,1);
      odleglosc_proc_od_KU_1h = NormalizeDouble (((odleglosc_pips_od_KU_1h / wysokosc_keltera_1h)* 100),1); //*100 to jest razy 100% i nie ma nic wspolnego z iloscia pipsow po przecinku
      odleglosc_proc_od_KD_1h = NormalizeDouble (((odleglosc_pips_od_KD_1h / wysokosc_keltera_1h)* 100),1);
      wysokosc_trendu_1h      = NormalizeDouble (100-(odleglosc_proc_od_KU_1h + odleglosc_proc_od_KD_1h),1);


      if (R_c_1h[0]<Close[0]) odleglosc_pips_od_KU_1h_now=NormalizeDouble(KU_1h-Close[0],Digits)*points; else odleglosc_pips_od_KU_1h_now=NormalizeDouble(NormalizeDouble(KU_1h-R_c_1h[0],Digits)*points,1);
      if (S_c_1h[0]>Close[0]) odleglosc_pips_od_KD_1h_now=NormalizeDouble(Close[0]-KD_1h,Digits)*points; else odleglosc_pips_od_KD_1h_now=NormalizeDouble(NormalizeDouble(S_c_1h[0]-KD_1h,Digits)*points,1);
      odleglosc_proc_od_KU_1h_now= NormalizeDouble(((odleglosc_pips_od_KU_1h_now/wysokosc_keltera_1h)* 100),1); //*100 to jest razy 100% i nie ma nic wspolnego z iloscia pipsow po przecinku
      odleglosc_proc_od_KD_1h_now= NormalizeDouble(((odleglosc_pips_od_KD_1h_now/wysokosc_keltera_1h)* 100),1);
      wysokosc_trendu_1h_now=      NormalizeDouble(100-(odleglosc_proc_od_KU_1h_now+odleglosc_proc_od_KD_1h_now),1);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void wyznacz_wysokosc_trendu_1h()
{
int k;
   if (wysokosc_trendu_1h_t[0]!=wysokosc_trendu_1h)
         {
            //if (R_1h[0]!=Resist_1h)
           for(  k =6; k>0; k--) wysokosc_trendu_1h_t[k]=wysokosc_trendu_1h_t[k-1];
           wysokosc_trendu_1h_t[0]=wysokosc_trendu_1h;

           srednia_wysokosc_trendu_1h=0;
           for(  k =6; k>0; k--) srednia_wysokosc_trendu_1h+=wysokosc_trendu_1h_t[k];
           //ponizsza linia zostala przerzucona do funkcji wyznacz_wysokosc_trendu_1h_NOW, dzieki czemu zmienna wysokosc_trendu_1h_now ktora jest tu wykorzystywana, bêdzie mia³a bardziej aktualn¹ wartoœæ
           srednia_wysokosc_trendu_1h=NormalizeDouble((srednia_wysokosc_trendu_1h+wysokosc_trendu_1h_now)/8,0);

         }
   
}        


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LINIE WSPARCIA I OPORU

 void wyznacz_linie_sr()
 {
  
      Resist_15m = iCustom(NULL,PERIOD_M15,"SR_Barry_v5",0,0);
      Support_15m= iCustom(NULL,PERIOD_M15,"SR_Barry_v5",1,0);
     // Resist_15m = iCustom(NULL,PERIOD_M15,"MTF_BARRY",0,0);
     // Support_15m= iCustom(NULL,PERIOD_M15,"MTF_BARRY",1,0);
      
      Resist_15m = NormalizeDouble(Resist_15m,3);
      Support_15m= NormalizeDouble(Support_15m,3);
/*
if (newBar==1)
  { 
      Resist_1h  = iCustom(NULL,PERIOD_H1,"MTF_BARRY",2,0);
      Support_1h = iCustom(NULL,PERIOD_H1,"MTF_BARRY",3,0);
  
      Resist_4h  = iCustom(NULL,PERIOD_H4,"MTF_BARRY",4,0);
      Support_4h = iCustom(NULL,PERIOD_H4,"MTF_BARRY",5,0);
  
      Support_1d = iCustom(NULL,PERIOD_D1,"MTF_BARRY",6,0);
      Resist_1d  = iCustom(NULL,PERIOD_D1,"MTF_BARRY",7,0);   
   
 //     Resist_15m = NormalizeDouble(Resist_15m,3);
 //     Support_15m= NormalizeDouble(Support_15m,3);

      Resist_1h  = NormalizeDouble(Resist_1h,3);
      Support_1h = NormalizeDouble(Support_1h,3);

      Resist_4h  = NormalizeDouble(Resist_4h,3);
      Support_4h = NormalizeDouble(Support_4h,3);

      Resist_1d  = NormalizeDouble(Resist_1d,3);
      Support_1d = NormalizeDouble(Support_1d,3);
      // Print ("R1_15m=",R1_15m, "  S1_15m=", S1_15m,"  R1_1h=", R1_1h," S1_1h=",S1_1h," R1_4h=", R1_4h," V=", News5," S1_1d=", S1_1d," R1_1d=", R1_1d);
   }
*/
      if (R_15m[0]!=Resist_15m)
          {
         //   if (ustaw_Sell_SL==1) MoveTrailingStop();
            //zapamietanie wartosci kanalu ketlera w momencie wystapienia linii Resist, w celu porownania ich wzajemnych wart.
            save_keltner_resist_15m();
            wyznacz_wysokosc_trendu_15m();
            wyznacz_wysokosc_trendu_1h();
         
           }   
      if (S_15m[0] != Support_15m)
          {
         //   if (ustaw_Buy_SL==1) MoveTrailingStop();
            save_keltner_support_15m();
            wyznacz_wysokosc_trendu_15m();
            wyznacz_wysokosc_trendu_1h();
          }
   
 
      if (R_1h[0] != Resist_1h)  save_keltner_resist_1h();
      if (S_1h[0] != Support_1h) save_keltner_support_1h();
   
      if (R_4h[0] != Resist_4h)  save_keltner_resist_4h();
      if (S_4h[0] != Support_4h) save_keltner_support_4h();
 
      if (R_1d[0] != Resist_1d)  save_keltner_resist_1d();
      if (S_1d[0] != Support_1d) save_keltner_support_1d();
 

 
   // wskaznik SR_Barry_Close --

      Resist_C_15m  = iCustom(NULL,PERIOD_M15,"SR_Barry_Close",0,0);
      Support_C_15m = iCustom(NULL,PERIOD_M15,"SR_Barry_Close",1,0);
      Resist_C_15m  = NormalizeDouble(Resist_C_15m ,3);
      Support_C_15m = NormalizeDouble(Support_C_15m,3);
  
  
  if (newBar==1)
  { 
    Resist_C_1h  = iCustom(NULL,PERIOD_H1,"SR_Barry_Close",0,0);
    Support_C_1h = iCustom(NULL,PERIOD_H1,"SR_Barry_Close",1,0);
    Resist_C_1h  = NormalizeDouble(Resist_C_1h,3);
    Support_C_1h = NormalizeDouble(Support_C_1h,3);
   
    Resist_C_4h  = iCustom(NULL,PERIOD_H4,"SR_Barry_Close",0,0);
    Support_C_4h = iCustom(NULL,PERIOD_H4,"SR_Barry_Close",1,0);
    Resist_C_4h  = NormalizeDouble(Resist_C_4h,3);
    Support_C_4h = NormalizeDouble(Support_C_4h,3);
   
    Resist_C_1d  = iCustom(NULL,PERIOD_D1,"SR_Barry_Close",0,0);
    Support_C_1d = iCustom(NULL,PERIOD_D1,"SR_Barry_Close",1,0);
    Resist_C_1d  = NormalizeDouble(Resist_C_1d,3);
    Support_C_1d = NormalizeDouble(Support_C_1d,3);
   }
 
   
      if (R_c_15m[0] != Resist_C_15m)
         {
           //Print ("R_c_15m[0]=",R_c_15m[0],"   R_c_15m[1]=",R_c_15m[1] );
            //zapamietanie wartosci kanalu ketlera w momencie wystapienia linii SR, w celu porownania ich wzajemnych wart.
            save_keltner_resist_close_15m();
            wyznacz_wysokosc_trendu_15m();
            wyznacz_wysokosc_trendu_1h();
          }
   
       if (S_c_15m[0] != Support_C_15m)
          {
           // Print ("S_c_15m[0]=",S_c_15m[0],"   S_c_15m[1]=",S_c_15m[1] );
            save_keltner_support_close_15m();
            wyznacz_wysokosc_trendu_15m();
            wyznacz_wysokosc_trendu_1h();
          } 
  if (newBar==1) 
    {
       if (R_c_1h[0] != Resist_C_1h)  save_keltner_resist_close_1h();
       if (S_c_1h[0] != Support_C_1h) save_keltner_support_close_1h();
 
       if (R_c_4h[0] != Resist_C_4h)  save_keltner_resist_close_4h();
       if (S_c_4h[0] != Support_C_4h) save_keltner_support_close_4h();
 
       if (R_c_1d[0] != Resist_C_1d)  save_keltner_resist_close_1d();
       if (S_c_1d[0] != Support_C_1d) save_keltner_support_close_1d();
    }
 }
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// WSKA¯NIK WEJSCIA
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void wskaznik_wejscia()
  {

      //if (newBar==1) 
     FI7_p2 = iForce(NULL, PERIOD_M15, 3, MODE_SMA, PRICE_CLOSE, Current + 2);
     FI7_p1 = iForce(NULL, PERIOD_M15, 2, MODE_SMA, PRICE_CLOSE, Current + 2);
     FI21_p0= iForce(NULL, PERIOD_M15, 7, MODE_SMA, PRICE_CLOSE, Current + 0);
     FI21_p2= iForce(NULL, PERIOD_M15, 7, MODE_SMA, PRICE_CLOSE, Current + 2);
     //FI7_p5= iForce(NULL, PERIOD_M15, 7, MODE_SMA, PRICE_CLOSE, Current + 8);
     if (newBar==1) FI21_p4= iForce(NULL, PERIOD_M15, 7, MODE_SMA, PRICE_CLOSE, Current + 4);  //zdjaz newbar gdy bedzie wykorzystywana ta funkcjonalnosc
      //FI7_f  = iForce(NULL, PERIOD_M15, 1, MODE_SMA, PRICE_CLOSE, Current );
      //FI7_f=FI7_p2;  // rozpoznawanie sily rynku i dobieranie odpowiedniego TSI - Short lub V-Short
      //=MathMax(MathAbs(FI7_p1),MathAbs(FI7_p2));
     // if (newBar==1) 
     
 
      if (token_high_buy==1 || token_high_sell==1) wejscie_TSI_vShort(); //dl_wejscia=0;
  //zamiast tej na dole v1
      if ((token_high_buy==0) 
         && (token_high_sell==0))
            {
           
            // Ustalenie pozimu wejscia RSI w okresie aktywnym
               if (S_c_15m[0]<KDS_c_15m[0]) RSI_Buy =30;                            // ponizej dolnej     25/30
               if (S_c_15m[0]>KDS_c_15m[0] && S_c_15m[0]<KMS_c_15m[0]) RSI_Buy =35; // powyzej dolnej     30/35
               if (S_c_15m[0]>KMS_c_15m[0] && S_c_15m[0]<KUS_c_15m[0]) RSI_Buy =45; // powyzej srodkowej  45 40 48 35 45
               if (S_c_15m[0]>KUS_c_15m[0]) RSI_Buy =50;                            // powyzej gornej     55 45 50

            // zgoda na Sell jesli RSI jest powyzej RSI_Sell
               if (R_c_15m[0]>KUR_c_15m[0]) RSI_Sell =70;                            // powyzej gornej    70/75 70
               if (R_c_15m[0]<KUR_c_15m[0] && R_c_15m[0]>KMR_c_15m[0]) RSI_Sell =65; // powyzej srodkowej 70/65
               if (R_c_15m[0]<KMR_c_15m[0] && R_c_15m[0]>KDR_c_15m[0]) RSI_Sell =55; // powyzej dolnej    50 60 52 65 55
               if (R_c_15m[0]<KDR_c_15m[0]) RSI_Sell =50;                            // ponizej dolnej    45 55 50

             if (((FI7_p2>-100*0.001)) && ((FI7_p2<100*0.001))) {token_short_buy=0;token_short_sell=0; wejscie_TSI_Short();} 
             if (FI7_p2<-100*0.001)  {token_short_sell=0; token_short_buy=1 ;wejscie_TSI_vShort();}    //wejscia buy przy duzym indeksie ale tylko w przeciwnym kierunku(tr.dolny) (³apanie korekty)
             if (FI7_p2>+100*0.001)  {token_short_buy=0;  token_short_sell=1;wejscie_TSI_vShort();}    //wejscia sell przy duzym indeksie ale tylko w przeciwnym kierunku(tr.gorny) (³apanie korekty)
             if (ticket_open_short_buy==1 || ticket_open_short_sell==1)wejscie_TSI_vShort();
            // if ((FI7_p2<-100*0.001) || (R_c_15m[0]>KUR_c_15m[0] && S_c_15m[0]<KUS_c_15m[0] && FI7_p2>-100*0.001))    {token_short_sell=0; token_short_buy=1 ;wejscie_TSI_vShort();}    //wejscia buy przy duzym indeksie ale tylko w przeciwnym kierunku(tr.dolny) (³apanie korekty)
            //  if ((FI7_p2>+100*0.001) || (R_c_15m[0]>KDR_c_15m[0] && S_c_15m[0]<KDS_c_15m[0] && FI7_p2<+100*0.001))    {token_short_buy=0;  token_short_sell=1;wejscie_TSI_vShort();}    //wejscia sell przy duzym indeksie ale tylko w przeciwnym kierunku(tr.gorny) (³apanie korekty)
              
             
             
            } //end of shorttsi     
      /* 
         if (ticket_open_short_buy==1)
         {
            // RSI_Buy =90; //norma 30                   //BYC MOZE PRZYWROCIC DO POZIOMOW 50/50?
             wejscie_TSI_vShort(); 
          }
         if (ticket_open_short_sell==1)
         {
           // RSI_Sell=10; // norma 70
            wejscie_TSI_vShort(); 
         }    
      */ 
        
         if (wysokosc_trendu_15m_now<=25 && wysokosc_trendu_15m<=25)
//#      if ((powertrend_15m_stp2==1 && powertrend_15m_stp0==1)) //jezeli utrzymuje sie flat
            //||(HighRSI7_15m<15))
            //|| (powertrend_15m_stp2==1 && powertrend_15m_up0==1) // lub przejscie z flat w malejacy   Short?
            //|| (powertrend_15m_stp2==1 && powertrend_15m_dn0==1)) // lub przejscie z flat w rosnacy   short?
               {
                  wejscie_TSI_Long();
                 //Ustalenie pozimu wejscia RSI w plaskim trendzie
                  RSI_Buy =60; //norma 30                   //BYC MOZE PRZYWROCIC DO POZIOMOW 50/50?
                  RSI_Sell=40; // norma 70
                  HighRSI7_15m  = RSI7_R_15m - RSI7_S_15m;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
                  HighRSI14_15m = RSI14_R_15m-RSI14_S_15m; // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist
               } //end of long

 //#1   } //end of long i short

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// USTAWIENIE FLAGI BUY/SEL DLA HighRSI7_15m/14  -----------------------
// zmienna HighRSI wyznacza roznice poziomu RSI pomiedzy S/R lecz nie okresla kierunku mozliwego zlecenia , jak to mialo miejsce poprzez RSI30/70  dlatego potrzebna jest dodatkowa flaga
// wszystkie ponizej odwolania do HighRSI14_15m/RSI_14_S/R mozna juz raczej wywalic, bo wyznaczanie kierunku opiera sie tylko na RSI7
// odswiezenie wartosci RSI7_R_15m na wypadek gdyby nie zarysowala sie S/R
void flaga_rsi()
{
   
      HighRSI7_15m  = RSI7_R_15m - RSI7_S_15m;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_15m = RSI14_R_15m-RSI14_S_15m; // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

      tmp_resist_price7 =  MathAbs(R_c_15m[0]-Bid); //obliczenie ilosci pips pomiedzy akt cena a zapmietana cena z poziomu RSI Resist w odniesieniu do RSI
      tmp_support_price7 = MathAbs(S_c_15m[0]-Bid); //obliczenie ilosci pips pomiedzy akt cena a RSI Support w odniesieniu do RSI

      if (tmp_resist_price7>tmp_support_price7) //porownanie czy aktualnej cenie jest blizej do RSI Support czy Resist
         { 
            BuyHighRSI7_15m=1; //ustawienie flagi dla High_RSI7 na zezwolenie dla buy
            SellHighRSI7_15m=0; //wyzerowanie flagi dla High_RSI7 na zezwolenie dla sell
         } 
         else   
            {  
               BuyHighRSI7_15m=0; 
               SellHighRSI7_15m=1;
             }

      tmp_resist_price14 = R_c_15m[0]-Bid; //obliczenie ilosci pips pomiedzy akt cena a zapmietana cena z poziomu RSI Resist w odniesieniu do RSI
      tmp_support_price14 =S_c_15m[0]-Bid; //obliczenie ilosci pips pomiedzy akt cena a RSI Support w odniesieniu do RSI
      /*
      if (tmp_resist_price14>tmp_support_price14) //porownanie czy aktualnej cenie jest blizej do RSI Support czy Resist
         { 
            BuyHighRSI14_15m=0; //ustawienie flagi dla High_RSI7 na zezwolenie dla buy
            SellHighRSI14_15m=1; //wyzerowanie flagi dla High_RSI7 na zezwolenie dla sell
         }
        else  
         {  
            BuyHighRSI14_15m=1;
            SellHighRSI14_15m=0;
         }
      */    
 }  
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//debugerr
void debuger()
   {
// Comment("KMS1=",KMS_c_15m[0], "  KMS2=",KMS_c_15m[1], "  KMR1=", KMR_c_15m[0], " KMR2=",KMR_c_15m[1], "  R_c_15m[0]=",R_c_15m[0],"  S_c_15m[0]=",S_c_15m[0],"     TREND= ",rtrend_15m,  " TSI VShort: ",dl_wejscia,"     OPENB: ", otwarcie_buy, "   CLOSEB: ",zamkniecie_buy, "  token_high_buy=",token_high_buy, "  Token high Sell= ",token_high_sell,"  token_short_buy=",token_short_buy, "  Token short Sell= ",token_short_sell,"  WEJ_B: ", sp_wejscia_buy," \n RSI_Buy=",RSI_Buy, "   RSI_Sell=",RSI_Sell,"  /RSI7S= ",RSI7_S_15m," / ",RSI7_R_15m, "     RSI14_S_15m/R=",RSI14_S_15m," / ",RSI14_R_15m, "  BuyHighRSI7_15m=",BuyHighRSI7_15m,"  SellHighRSI7_15m=",SellHighRSI7_15m, "  HighRSI7_15m=",HighRSI7_15m,  "   HighRSI14_15m= ",HighRSI14_15m, "  DoubleS_15m=",DoubleS_15m,"  DoubleR_15m=",DoubleR_15m, " \n StopLoss=", StopLoss, "   tmp_Stop_Loss=",tmp_StopLoss, "  ustaw_Buy_SL=",ustaw_Buy_SL, "   ustaw_Sell_SL=",ustaw_Sell_SL, "  opisSL=",opisSL); 
 //####if (newBar==1) Comment("FI21_p2=",FI21_p2, "<=",35*0.001, "     RSI14_max_15m=", RSI14_max_15m, "    RSI14_max_15m=", RSI14_max_15m, "   RSI14_Min_15m(6)=", RSI14_Min_15m(6), "   RS14_min15=", RSI14_Min_15m, "   Price_RSI7_S_15m=",Price_RSI7_S_15m,"   Price_RSI7_R_15m=",Price_RSI7_R_15m, "   S_c_15m[0]=",S_c_15m[0],"   S_c_15m[1]=",S_c_15m[1],"   Support_C_15m=",Support_C_15m,"   R_c_15m[0]=",R_c_15m[0],"   R_c_15m[1]=",R_c_15m[1], "   Resit_C=",Resist_C_15m," RSI7S= ",RSI7_S_15m," /n ",RSI7_R_15m, "     RSI14_S_15m/R=",RSI14_S_15m," / ",RSI14_R_15m);
//# if (newBar==1)Comment("Strata=",Strata, "   Ilosc=",Ilosc, "  Point=",Point, "  digits=", Digits, "   bilans_poz_buy=",bilans_poz_buy,"    bilans_poz_sell=",bilans_poz_sell, "    ilosc_last_buy=",ilosc_last_sell,"    ilosc_last_sell=",ilosc_last_sell, "  WynikTR_buy=",WynikTR_buy, "   WynikTR_sell=",WynikTR_sell , "   WynikTR_sell+bilans_poz_buy   ",WynikTR_sell+bilans_poz_buy, ">", WynikTR_sell*0.80,"   WynikTR_sell*0.80", "                   WynikTR_buy+bilans_poz_sell   ",WynikTR_buy+bilans_poz_sell,">=",WynikTR_buy*0.80,"   WynikTR_buy*0.80");

 //##if (newBar==1) Comment("TSI VShort: ",dl_wejscia,"   Zlecen= ",total_orders,"\n Buy: ", otwarcie_buy, "  Buy2: ", sp_wejscia_buy, "   CLOSE_Buy: ",zamkniecie_buy,"        Sell: ", otwarcie_sell, "  Sell2: ", sp_wejscia_sell, "   CLOSE_Sell: ",zamkniecie_sell, "    CRC=",CRC, " \n RSI_Buy=",RSI_Buy, "   RSI_Sell=",RSI_Sell, "  DoubleS_15m=",DoubleS_15m,"  DoubleR_15m=",DoubleR_15m,"\n TREND15= ",rtrend_15m,"  TREND1h= ",rtrend_1h,"  TREND4h= ",rtrend_4h,"  TREND1d= ",rtrend_1d,"/n  TicketBuy=",ticket_for_close_buy,"   TicketSell=",ticket_for_close_sell, "  Crit_buy=",ticket_crit_for_buy,"  Crit_buy2=",ticket_crit_for_buy3,"  Crit_buy3=",ticket_crit_for_buy3,"  Crit_buy.BE=",ticket_close_buy_sr_ket,"  Crit_sell=",ticket_crit_for_sell,"  Crit_sell2=",ticket_crit_for_sell2,"  Crit_sell3=",ticket_crit_for_sell3,"  Tik_sell.BE=",ticket_close_sell_sr_ket,"   WynikTR_buy=",WynikTR_buy, "   MaxZyskBuy=",MaxZysk_buy, "  WynikTR_sell=",WynikTR_sell,"   MaxZysk_sell=",MaxZysk_sell,"  CR=",CRCO);
 //###if (newBar==1) Comment("Zamk buy: ",zamkniecie_buy,"  Zamk_sell=",zamkniecie_sell, "  ticket_sr_buy=",ticket_close_sr_buy, "  ticket_after_buy=",ticket_after_close_sr_buy, "     ticket_sr_sell=",ticket_close_sr_sell,"  ticket_after_sell=", ticket_after_close_sr_sell ,"   WynikTR_buy=",WynikTR_buy, "   MaxZyskBuy=",MaxZysk_buy, "  WynikTR_sell=",WynikTR_sell,"   MaxZysk_sell=",MaxZysk_sell,"\n TREND15= ",rtrend_15m,"  TREND1h= ",rtrend_1h,"  TREND4h= ",rtrend_4h,"  TREND1d= ",rtrend_1d  , "  Sell2: ", sp_wejscia_sell,"  Buy:", sp_wejscia_buy);

//if (newBar==1) Comment("buy=",all_token_buy, "  sell=",all_token_sell,  " op_buy=",orders_total(OP_BUY),  "  op_sell=",orders_total(OP_SELL),"   Zlecen= ",total_orders, "  CRC=",CRC3);
//ponizsze dobre dla wylaptuwaniu bledow zwiazanych z kwotowaniem po przecinku
//Comment("stop_loss=",stop_loss,"  take_profit=",take_profit, "  activate_be=",activate_be,"  step_be=",step_be, "  activate_ts=",activate_ts,"  step_ts=",step_ts,"  stop_loss_ts=",stop_loss_ts,"  next_step=",next_step,"  hide_sl=",hide_sl,"  hide_tp=",hide_tp,"  sl_buy=",sl_buy,"  sl_sell=",sl_sell, "\n WyniktTR_buy=",WynikTR_buy, "  WynikTR_sell=",WynikTR_sell, "  MaxZysk_buy=",MaxZysk_buy,"  odleglosc_pips_od_KU_15m=",odleglosc_pips_od_KU_15m, "  wysokosc_keltera_15m=",wysokosc_keltera_15m,  "  wysokosc_trendu_15m_now=",wysokosc_trendu_15m_now, "  sl_tmp2=",sl_tmp2, "  pips od KU.now=",odleglosc_pips_od_KU_15m_now,"  %KU.now=",odleglosc_proc_od_KU_15m_now,"   pips.od.KD.now=",odleglosc_pips_od_KD_15m_now,"    %KD.now=",odleglosc_proc_od_KD_15m_now);



//,"\n S_15m_save=",save_s0_for_crit_close,"   R_15m_save=",save_r0_for_crit_close, "  Rc15=",R_15m[0]
//factor_buy=",factor_buy,"  factor_sell=",factor_sell, "   SignalBar=",signalBar, " S_15m_save_for_close_sell, "  R_15.save=",R_15m_save_for_close_buy ," RSI7S/R= ",RSI7_S_15m," / ",RSI7_R_15m

//Comment ("RSI7_R_15m=",RSI7_R_15m,"    RSI7_S_15m=",RSI7_S_15m,"   HighRSI7=",HighRSI7_15m,  "   P0= ",HighRSI7_15m_srednia_t[0], "    ",HighRSI7_15m_srednia_t[1], "    ",HighRSI7_15m_srednia_t[2], "    ",HighRSI7_15m_srednia_t[3], "    ",HighRSI7_15m_srednia_t[4], "    ",HighRSI7_15m_srednia_t[5], "    ",HighRSI7_15m_srednia_t[6], "     srednia=",HighRSI7_15m_srednia);
//Comment ("pips od KU.now=",odleglosc_pips_od_KU_15m_now,"  %KU.now=",odleglosc_proc_od_KU_15m_now,"   pips.od.KD.now=",odleglosc_pips_od_KD_15m_now,"    %KD.now=",odleglosc_proc_od_KD_15m_now, "\n trend_15m_now;=",wysokosc_trendu_15m_now, "     trend_1h_now;=",wysokosc_trendu_1h_now, "        pips od KU=",odleglosc_pips_od_KU_15m,"  %KU=",odleglosc_proc_od_KU_15m,"   pips.od.KD=",odleglosc_pips_od_KD_15m,"    %KD=",odleglosc_proc_od_KD_15m, "\n wys_trendu_15m=",wysokosc_trendu_15m, "    wys_trendu_1h=",wysokosc_trendu_1h, "\n t0=",wysokosc_trendu_15m_t[0],"  t1=",wysokosc_trendu_15m_t[1], "  t2=",wysokosc_trendu_15m_t[2],"   t3=",wysokosc_trendu_15m_t[3], "   t4=",wysokosc_trendu_15m_t[4], "   t5=",wysokosc_trendu_15m_t[5], "  t6=",wysokosc_trendu_15m_t[6], "   srednia_15m=",srednia_wysokosc_trendu_15m, "   srednia_1h=",srednia_wysokosc_trendu_1h,"/n  TicketBuy=",ticket_for_close_buy,"   TicketSell=",ticket_for_close_sell, "  Crit_buy=",ticket_crit_for_buy,"  Crit_buy2=",ticket_crit_for_buy3,"  Crit_buy3=",ticket_crit_for_buy3,"  Crit_sell=",ticket_crit_for_sell,"  Crit_sell2=",ticket_crit_for_sell2,"  Crit_sell3=",ticket_crit_for_sell3, "   CLOSE_Sell: ",zamkniecie_sell, " Sv_15m=",S_15m_save_for_close_sell, " S=",S_15m[0],  ); // ((((KU_15m- R_c_15m[0])*100)+ ((S_c_15m[0]-KD_15m)*100)))/2;
//#Comment ("pips od KU.now=",odleglosc_pips_od_KU_15m_now,"  %KU.now=",odleglosc_proc_od_KU_15m_now,"   pips.od.KD.now=",odleglosc_pips_od_KD_15m_now,"    %KD.now=",odleglosc_proc_od_KD_15m_now, "\n trend_15m_now;=",wysokosc_trendu_15m_now, "        pips od KU=",odleglosc_pips_od_KU_15m,"  %KU=",odleglosc_proc_od_KU_15m,"   pips.od.KD=",odleglosc_pips_od_KD_15m,"    %KD=",odleglosc_proc_od_KD_15m, "\n wys_trendu_15m=",wysokosc_trendu_15m, "\n t0=",wysokosc_trendu_15m_t[0],"  t1=",wysokosc_trendu_15m_t[1], "  t2=",wysokosc_trendu_15m_t[2],"   t3=",wysokosc_trendu_15m_t[3], "   t4=",wysokosc_trendu_15m_t[4], "   t5=",wysokosc_trendu_15m_t[5], "  t6=",wysokosc_trendu_15m_t[6], "   srednia_15m=",srednia_wysokosc_trendu_15m,"/n  TicketBuy=",ticket_for_close_buy,"   TicketSell=",ticket_for_close_sell, "  Crit_buy=",ticket_crit_for_buy,"  Crit_buy2=",ticket_crit_for_buy3,"  Crit_buy3=",ticket_crit_for_buy3,"  Crit_sell=",ticket_crit_for_sell,"  Crit_sell2=",ticket_crit_for_sell2,"  Crit_sell3=",ticket_crit_for_sell3, "   CLOSE_Sell: ",zamkniecie_sell, "   WynikTR_buy=",WynikTR_buy, "   MaxZyskBuy=",MaxZysk_buy, "  WynikTR_sell=",WynikTR_sell,"   MaxZysk_sell=",MaxZysk_sell   ); // ((((KU_15m- R_c_15m[0])*100)+ ((S_c_15m[0]-KD_15m)*100)))/2;

//srednia_wysokosc_trendu_15m
//wysokosc_trendu_15m_now




// Comment("rtrend_15m=",wejscia_trend_boczny_buy(), "    MaxZysk=",MaxZysk, "  WynikTR=",WynikTR, "  maksprice=",maksprice , "   OPBuy=",OP_BUY, "    OP_SELL=",OP_SELL, "   CRC=",CRC);
//Comment("war.zamk_buy= ",warunki_zamkniecia_buy(),"   war.zamk_sell= ",warunki_zamkniecia_sell(),"   wej.spec= ",wejscia_specjalne(),"  wej.trend_boczny_buy= ",wejscia_trend_boczny_buy(),"   wej.trend_boczny_sell= ",wejscia_trend_boczny_sell(),"   wejscia_trend_rosnacy=",wejscia_trend_rosnacy(),"  wejscia_trend_malejacy=",wejscia_trend_malejacy(), "   CRC= ",CRC,  "\n RSI7_R_15m ",RSI7_R_15m," > ", RSI_Sell,"   rtrend_15m= ", rtrend_15m,   "  RSI7_R_15m= ", RSI7_R_15m, "  RSI7_S_15m=",RSI7_S_15m,"  RSI_Sell= ",RSI_Sell,"  RSI7_Buy=", RSI_Buy, "    TSI_0b= ", TSI_0b,  "   TSI_1b= ", TSI_1b, "   d³.wej= ",dl_wejscia, "  Long=", Long, "  sp_wej_buy=", sp_wejscia_buy, "  sp_wej_sell=", sp_wejscia_sell, "  CRC2= ",CRC2, "   CRCO=", CRCO); 
//##Comment ("ketler_kat_dn=",ketler_kat_dn,"    open_SELL= ",ticket_open_short_sell, "    close_SELL= ",ticket_close_short_sell,"         open_BUY= ",ticket_open_short_buy,"    close_SELL= ",ticket_open_short_sell , "      sp_wej_buy=", sp_wejscia_buy, "  sp_wej_sell=", sp_wejscia_sell); 
//#Comment ("ketler_kat_dn=",ketler_kat_dn,"   ketler_trend_up=", ketler_trend_up , "   ketler_trend_dn=", ketler_trend_dn , "    ketler_kat_p[0]=",ketler_kat_p[0], "    ketler_kat_p[1]=",ketler_kat_p[1], "    ketler_kat_p[2]=",ketler_kat_p[2], "    ketler_kat_p[3]=",ketler_kat_p[3], "    ketler_kat_p[4]=",ketler_kat_p[4], "    ketler_kat_p[5]=",ketler_kat_p[5], "       Sredni_kat_ketlera_p3=",sredni_kat_ketlera_p3, "       Sredni_kat_ketlera_p7=",sredni_kat_ketlera_p7, "       Sredni_kat_ketlera_p28=",sredni_kat_ketlera_p28);
//Comment ("price_min_p0=",price_min_p[0], "   price_min_p1=",price_min_p[1], "     price_min_p2=",price_min_p[2], "     price_max_p0=",price_max_p[0], "   price_min_p1=",price_max_p[1], "   price_max_p2=",price_max_p[2],   "   price_min4=",price_min4, "    price_max4=",price_max4,  "   Bid=",Bid,"   Ask=",Ask, "     price_from_down=",price_from_down, "   price_from_top=", price_from_top,   "wysokosc_keltera_15m=",wysokosc_keltera_15m, "   poslizg=",wielkosc_poslizgu);  
Comment ("Digits= ", Digits, "   Point= ",Point);
//RSI7_R_15m > RSI_Sell
// Comment("R3.UP=",line_3r_up_15m,"   3S.UP=",line_3s_up_15m, "  3S.DN=",line_3s_dn_15m, "   R3.DN=",line_3r_dn_15m,  "  hak_r_up=",hak_r_up_15m, "    hak_s_up=",hak_s_up_15m, "   hak_r_dn=", hak_r_dn_15m,  "   hak_s_dn=",hak_s_dn_15m, "\n TREND=",rtrend_15m);
   }
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          W A RU N K I  Z A M K N I ÊC I A
//-----------------------------------------------------------------------------------

int warunki_zamkniecia_buy()
{

 //----------------------------------------------
 //##1   ZAMKNIECIE POPRZEZ S/R (WYJ¥TEK)DLA BUY
 // --------------------------------------------- 
 // poni¿sze zamkniecia ma false positive. dopoki jest niedopracowane, lepiej oprzec sie na zamknieciu poprzez sr.l.k ew. gorna. (zrobic screena gdy zajdzie przypadek w ktorym powinno to zamk. wystapic)
 // zamkniecia gdy short close nie wchodzi bo jest w trakcie trendu rosnacego, natomiast po powrocie do trendu bocznego nie jest zamykany ze wzgledu na brak trendu rsi
 /*
   if ((R_c_15m[0]<R_c_15m[1] && R_c_15m[1]>R_c_15m[2] && R_c_15m[2]>R_c_15m[3] && S_c_15m[0]>S_c_15m[1] && S_c_15m[1]>S_c_15m[2] && Close[0]<S_c_15m[0]-0*pt&& Close[0]>OrderOpenPrice() && HighRSI7_15m>15 && time!=Time[0] && MaxZysk>15*pt)) 
         {
            //Order = SIGNAL_CLOSEBUY;
            zamkniecie_buy="OK_CLOSE_BUY_S/R WYJATEK";
          //Print (" CloseBuy S/R wyjatek");
            CRC="CRC1";
            return(OP_BUY);         
         }
 */

//---------------------------------------------------------
//##2  ZAMKNIECIE POPRZEZ ŒRODKOW¥ LINIÊ KELTERA  DLA BUY
//--------------------------------------------------------- 
//KMR_c_15m zamiast KM_15m - bardziej dokladne
  if (((R_c_15m[0]>KMR_c_15m[0] && S_c_15m[0]>KMS_c_15m[0] && Close[1]<KM_15m && Close[0]<KM_15m && time!=Time[0])  //gdy obie S i R sa powyzej sr.l.k. ale cena jest juz ponizej œr.l.k
     //&& (opoznij_close_buy==0)  //nie ma wplywu na wynik v1
     || ( Close[1]<KM_15m && Close[2]>KM_15m && ticket_for_close_buy==1))
     && (MaxZysk_buy>15*pt) //jezeli max zysk jest nie mniejszy niz..
     && (opoznij_close_buy==0)
   //  && (TSI_2v<0 && TSI_0v>0 )
     && (WynikTR_buy>15*pt)) // i wynik z transakcji nie jest w fazie lekkiej(do 20pips) straty
     //&& ((WynikTR_buy>15*pt) || (WynikTR_buy<-15*pt))) 
           { 
               
             //Print ("zamk SR. LINIA KELTERA");
               CRC="CRC3";
               if (ticket_for_close_buy==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                  {
                     R_15m_save_for_close_buy=Resist_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                     ticket_for_close_buy+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                  }
                 else if (R_15m_save_for_close_buy!=Resist_15m) ticket_for_close_buy+=1;
                  if (ticket_for_close_buy>=2)
                    {
                      zamkniecie_buy="OK SR. LINIA KELTERA";  // dla debugera
                      return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
                    }
             }
         
//---------------------------------------------------------
//##2  ZAMKNIECIE POPRZEZ ŒRODKOW¥ LINIÊ KELTERA  DLA BUY
//--------------------------------------------------------- 
//KMR_c_15m zamiast KM_15m - bardziej dokladne
/*
  if ((Close[0]<KM_15m)// && time!=Time[0])
  //((R_c_15m[1]<KMR_c_15m[1] && S_c_15m[1]<KMS_c_15m[1] && Close[1]<KM_15m && Close[0]<KM_15m && time!=Time[0])  //gdy obie S i R sa powyzej sr.l.k. ale cena jest juz ponizej œr.l.k
     //&& (opoznij_close_buy==0)  //nie ma wplywu na wynik v1
     //|| ( Close[1]<KM_15m && Close[2]>KM_15m && ticket_for_close_buy==1))
     && (TSI_0v>0 && TSI_1<0) 
     //&& (TSI_0v<TSI_1v && TSI_2v>0 && TSI_1v>0 && TSI_0v<0 && time!=Time[0])
     && (MaxZysk_buy>100*pt) //jezeli max zysk jest nie mniejszy niz..
     //&& (opoznij_close_buy==0)
     && ((WynikTR_buy>50*pt)))
     //&& (R_c_15m[2]>KMR_c_15m[2] && S_c_15m[2]>KMS_c_15m[2])) // i wynik z transakcji nie jest w fazie lekkiej(do 20pips) straty
           { 
                       
             //Print ("zamk SR. LINIA KELTERA");
               CRC="B#2";
               zamkniecie_buy="#2";  // dla debugera
               return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
            
            /*  
               if (ticket_for_close_buy==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                  {
                     R_15m_save_for_close_buy=Resist_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                     ticket_for_close_buy+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                  }
                 else if (R_15m_save_for_close_buy!=Resist_15m) ticket_for_close_buy+=1;
                  if (ticket_for_close_buy>=2)
                    {
                      zamkniecie_buy="#2";  // dla debugera
                      lp_closebuy2+=1;
                      return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
                    }
            */
   //          }


/*
//----------------------------------------------
 //##3   ZAMKNIECIE POPRZEZ S/R DLA BUY
 // --------------------------------------------- 
 // ZASTANOWIC SIE CZY NIE RYREMOWAC BO POTRAFI WSKOCZYC FALSE POSITIVE - I ZAMKNAC ZYSK OTW. W DL. TRENDZIE GDY CLOSE0 NIE PRZEKROCZY JESZCZE SR.L.K.       
   if (((rtrend_15m==1) || (rtrend_15m==2))  //jezeli w trendzie keltera
      && (Close[0]>OrderOpenPrice()) // i jest w fazie zysku
      && (!(powertrend_15m_stp2==1 && powertrend_15m_stp0==1)) // i we flat trendzie
      && (R_15m[0]<R_15m[1])
     // && (opoznij_close_buy==0)
      // && (Close[0]<KM) //--last
      && ((WynikTR_buy>15*pt) || (WynikTR_buy<-15*pt)))// nie zamykaj jesli strata lub zysk jest mniejsza od 15 pips
      //&& (HighRSI7_15m>10))
      //&& (RSI7_p[1]>RSI7_p[2]))
      //&& (Close[0]>Open[0]))
      {
         if ((Close[0]<(Support_15m-0*pt) && MaxZysk_buy>=10*pt && time!=Time[0]))
            {
               //Print ("WSZEDL S/R CLOSE - Last_s1=", Last_S1);
               CRC="S#2";
                if (ticket_for_close_buy==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                {
                  R_15m_save_for_close_buy=Resist_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                  ticket_for_close_buy+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                 }
                  else if (R_15m_save_for_close_buy!=Resist_15m) ticket_for_close_buy+=1;
                if (ticket_for_close_buy>=2) 
                  {
                    zamkniecie_buy="#3";     
                    lp_closebuy3+=1;
                    return(OP_BUY);
                   }
            }
       }   
      //if (Close[0]>Last_S1 && WynikTR<0.10 && Order == SIGNAL_CLOSEBUY && OrderType() == OP_BUY) Order=SIGNAL_NONE; // Zerownie zamkniecie do momentu Open_SR
      //if (Close[0]<Last_S1 && WynikTR<0.10 && OrderType() == OP_BUY) Order=SIGNAL_CLOSEBUY; //zamkniecie pozniej Open_SR
*/

//-------------------------------------------------------------------------------------
// 4A SZYBKIE ZAMKNIECIE I WYMUSZENIE SZYBKIEGO OTWARCIA (aktualnie flaga ticket_close_short_buy nie jest przydzielana)
//-----------------------------------------------------------

if ((ticket_close_short_buy ==1)
    && (MaxZysk_buy>=10*pt) 
    && (WynikTR_buy>2*pt))
 {
   if ((TSI_0< TSI_2 && TSI_2>0 && TSI_1>0 && TSI_0<0 && Close[0]<Close[1] && time!=Time[0])) //short
      //warunek TSI z #4 nie jest identyczny z war #4 w sell!!
      {
         CRC="B#4A";
         zamkniecie_buy="#4A";     
         ticket_open_short_buy=1; // szybkie wymuszenie nowego zlecenia
         return(OP_BUY);
       }
  }

//---------------------------------------------------------
//##4 ZAMKNIECIE POPRZEZ SHORT DLA BUY|| Long_C (dodac Long_C)
//---------------------------------------------------------  
//rtrend_15m 0 lub 2
 
   if ((rtrend_15m==0 || rtrend_15m==2) //jezeli jest trend boczny lub malejacy w kanale keltera
       // && (opoznij_close_buy==0)
        && (R1_trendup==1) //jezeli wystapil wczesniej silny trend rosnacy 
        && (Close[0]>OrderOpenPrice()) //i jezeli jest w fazie zysku
        && (MaxZysk_buy>=15*pt)  
        && (FI21_p2<=35*0.001)
       //% && (trendstp0_rsi==1) // i jesli obecnie nie ma trendu HW_hull(aby Short nie zamykal w trakcie trwania trendu ustawiajac s/l na najblizszym S/R)
        && ((WynikTR_buy>15*pt) || (WynikTR_buy<-15*pt)) // nie zamykaj jesli strata lub zysk jest mniejsza od 15 pips
        && (DoubleR_15m==0))
      //&& (RSI7_p[1]>RSI7_p[2]))
      //&& (Close[0]>Open[0]))
           {
              // zamkniecie_buy="READY_SHORT_CLOSE_BUY";
             //Print ("WSZED£ SHORT_CLOSE BUY, ASK:",Ask, " Bid:",Bid);
                  if ((TSI_0< TSI_2 && TSI_2>0 && TSI_1>0 && TSI_0<0 && Close[0]<Close[1] && time!=Time[0])) //short
                   //||(TSI_0b< TSI_2b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && Close[0]<Close[1] && time!=Time[0]) // lub long_c (poprawi zmienna bo ta odwoluje sie do tsi start)
                        {
                           //Print ("WSZED£ ORDER SHORT_CLOSE BUY, ASK:",Ask, " Bid:",Bid);
                           
                           CRC="B#4";
                           if (ticket_for_close_buy==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                              {
                                 R_15m_save_for_close_buy=Resist_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                                 ticket_for_close_buy+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                              }
                               else if (R_15m_save_for_close_buy!=Resist_15m) ticket_for_close_buy+=1;
                           if (ticket_for_close_buy>=2) 
                              {
                                 zamkniecie_buy="#4";      
                                 lp_closebuy4+=1;
                                 return(OP_BUY);
                              }
                        }      
            }
            
//---------------------------------------------------------
//##5 ZAMKNIECIE POPRZEZ GORNA LINIE KELTNERA DLA BUY
//---------------------------------------------------------  
//(R_c_15m[0]>KUR_c_15m[0] && Close[0]>KM ) //jesli R1 jest nad gorna linia keltnera a cena ponizej

   if (token_game==0) // aktywacja zamkniecia gdy wlaczoen jest zamykanie na podstawie tokenu
      {
        if ((((Close[2]>KU2_15m) || (Close[1]>KU_15m)) && (Close[0]<KU_15m)) //lub cena z P1 lub P2 jest pozwyzej a obecna P0 pozniej g.l.k.
         //&& (!(powertrend_15m_stp2==1 && powertrend_15m_stp0==1))// i wystepuje flat trend
          // && (opoznij_close_buy==0)
           //&& (WynikTR_buy<50*pt)
           && (MaxZysk_buy>=30*pt) 
           && ((WynikTR_buy>30*pt)|| (OrderOpenPrice()<KMO_15m)) // i aktualny zysk jest nie mniejszy niz...
           && (TSI_1v<0))
           
         //&& (open_by_token==0))
               {
                 //if (S_c_15m[0]>KMS_c_15m[0]) 
                  CRC="B#5";
                  //#if (WynikTR_buy>2*pt) token_high_buy=1;  //przydzielenie tokenu wymuszenia kupna, tylko gdy odnotowano zysk
                  if (wysokosc_trendu_15m_now>=25 && wysokosc_trendu_15m>=25 && ticket_for_close_buy<=0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                     {
                        R_15m_save_for_close_buy=R_15m[0];      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                        ticket_for_close_buy+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                     }
                  else if (wysokosc_trendu_15m_now>=25 && wysokosc_trendu_15m>=25 && R_15m_save_for_close_buy!=R_15m[0]) ticket_for_close_buy+=1;
                  //&& R_15m_save_for_close_buy!=R_15m[1]
                  if (ticket_for_close_buy>=3)
                     {
                        zamkniecie_buy="#5";
                        lp_closebuy5+=1;
                        return(OP_BUY);
                     }
               }
        }

//---------------------------------------------------------
//##6 ZAMKNIECIE POPRZEZ TOKEN SHORT  DLA BUY
//---------------------------------------------------------  
//(R_c_15m[0]>KUR_c_15m[0] && Close[0]>KM ) //jesli R1 jest nad gorna linia keltnera a cena ponizej

   if (token_short_game==1) // aktywacja zamkniecia gdy wlaczoen jest zamykanie na podstawie tokenu
      {
        if ((MaxZysk_buy>=15*pt)
          // && (opoznij_close_buy==0)
           && (RSI14_R_15m>70))
         //&& ((WynikTR>15*pt) || (WynikTR<-15*pt))
         //&& (TSI_1v<0)
         //&& (rtrend_15m==0))
         //&& (open_by_token==0))
               {
                  CRC="CRC6";
                  if ((TSI_0< TSI_2 && TSI_2>0 && TSI_1>0 && TSI_0<0 && Close[0]<Close[1] && time!=Time[0])) //short
                     {
                        
                        if (WynikTR_buy>2*pt) token_short_buy=1;  //przydzielenie tokenu wymuszenia kupna, tylko gdy odnotowano zysk         
                        if (ticket_for_close_buy==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                           {
                              R_15m_save_for_close_buy=Resist_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                              ticket_for_close_buy+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                           }
                              else if (R_15m_save_for_close_buy!=Resist_15m) ticket_for_close_buy+=1;
                        if (ticket_for_close_buy>=2)
                           {
                              zamkniecie_buy="#6";      
                              lp_closebuy6+=1;
                              return(OP_BUY);   //pozwol zamknac dopiero przy drugim razie
                            }
                      }
               }
       }
       
//---------------------------------------------------------
//##7 ZAMKNIECIE POPRZEZ NATYCHMIASTOWY SHORT DLA BUY - gdy SELL ma duzy zysk
//---------------------------------------------------------  

 if (ticket_crit_for_buy==1)
   {  
                  if ((TSI_0< TSI_2 && TSI_2>0 && TSI_1>0 && TSI_0<0 && Close[0]<Close[1] && time!=Time[0]) //short
                    //&& (opoznij_close_buy==0)
                  //   && (MaxZysk_buy>50)  //nowe
                   //  && (WynikTR_buy<50*pt)  //moze nieco wiecej niz 50? //nowe
                     && (WynikTR_buy>2*pt))
                    
                      {
                        zamkniecie_buy="#7";
                        CRC="#7";
                        lp_closebuy7+=1;
                        return(OP_BUY);
                       }
       
   }

//---------------------------------------------------------
//##8 ZAMKNIECIE POPRZEZ NATYCHMIASTOWY SHORT DLA BUY - flaga zlecnie pozniej ceny otwarcia
//---------------------------------------------------------  

 if (ticket_crit_for_buy2>=2 ) //testowane && WynikTR_buy<=20 //sprobowac aby zamykanie w tym przypadku bylo przez vshort
   {  
                  if ((TSI_0< TSI_2 && TSI_2>0 && TSI_1>0 && TSI_0<0 && Close[0]<Close[1] && time!=Time[0]) //short
                   //&& (opoznij_close_buy==0)
                     &&  (WynikTR_buy>2*pt))
                      {
                        zamkniecie_buy="#8";
                        CRC="#8";
                        lp_closebuy8+=1;
                        return(OP_BUY);
                       }
       
   }

//---------------------------------------------------------
//##9 ZAMKNIECIE POPRZEZ NATYCHMIASTOWY SHORT DLA BUY - flaga dla zlecen z powyzej FI>150
//---------------------------------------------------------  
/*
 if (ticket_crit_for_buy3>=1)
   {  
                  if ((TSI_0< TSI_2 && TSI_2>0 && TSI_1>0 && TSI_0<0 && Close[0]<Close[1] && time!=Time[0]) //short
                   // && (opoznij_close_buy==0)
                    &&  (WynikTR_buy>2*pt))
                      {
                        zamkniecie_buy="#9";
                        CRC="#9";
                        lp_closebuy9+=1;
                        return(OP_BUY);
                       }
       
   }
*/

//---------------------------------------------------------
//##10  ZAMKNIECIE NATYCHMIASTOWE POPRZEZ ŒRODKOW¥ LINIÊ KELTERA  - na podstawie flagi przyznawanej gdy cena dotrze w okolice gornej linii keltnera
//--------------------------------------------------------- 
//KMR_c_15m zamiast KM_15m - bardziej dokladne
//// ten filtr jest swiezy && Ask>Close[0] - sprawdzic

  if (((R_c_15m[0]>KMR_c_15m[0] && S_c_15m[0]>KMS_c_15m[0] && Close[1]<KM_15m && Close[0]<KM_15m && Ask<Close[0]&& time!=Time[0])  //gdy obie S i R sa powyzej sr_l_k_ ale cena jest juz ponizej œr_l_k
     || ( Close[1]<KM_15m && Close[2]>KM_15m))
   //&& (opoznij_close_buy==0)
     && (WynikTR_buy>2*pt)) 
     //&& WynikTR_buy<60*pt))
           { 
               CRC="B#10";
               zamkniecie_buy="#10";  // dla debugera
               //zamkniecie_buy2="#10  Z.NATYCHMIASTOWE POPRZEZ ŒRODKOW¥ LINIÊ KELTERA  - na podstawie flagi przyznawanej gdy cena dotrze w okolice gornej linii keltnera"
               lp_closebuy10+=1;
               if (ticket_close_buy_sr_ket==1) return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
                    
             }
 
//---------------------------------------------------------
//##11  ZAMKNIECIE POPRZEZ BE  - na podstawie flagi przyznawanej gdy cena dotrze w okolice gornej linii keltnera
//--------------------------------------------------------- 
//KMR_c_15m zamiast KM_15m - bardziej dokladne
 
  if  (Close[0]<Close[2] && ticket_close_buy_sr_ket==1 && WynikTR_buy<2*pt && MaxZysk_buy>=15*pt  ) // && opoznij_close_buy==0
           { 
               CRC="B#11";
               zamkniecie_buy="#11";  // dla debugera
               lp_closebuy11+=1;
               return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
                    
             } 
            
//---------------------------------------------------------
//##12  ZAMKNIECIE POPRZEZ BE - gdy osiagnie zysk 50 pips
//--------------------------------------------------------- 
//KMR_c_15m zamiast KM_15m - bardziej dokladne
 
  if   (ticket_be_buy==1 && WynikTR_buy<=3 )
           { 
               CRC="B#12";
               zamkniecie_buy="#12 ";  // dla debugera
               lp_closebuy12+=1;
               return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
                    
             } 
/*
//---------------------------------------------------------- 
//##13  ZAMKNIECIE SR.L.K dla buy 
//-----------------------------------------------------------
if (ticket_close_sr_buy==1 && Close[0]<KM_15m && time!=Time[0])
    {
      //ticket_close_sr_buy=0;
      ticket_after_close_sr_buy=1;
      CRC="B#13";
      lp_closebuy13+=1;
      zamkniecie_buy="#13";
      return(OP_BUY); 
     }
//------------------------------------------------------------    
//##14  ZAMKNIECIE SHORT AFTER SR.L.K
//-----------------------------------------------------------

   
if ((ticket_after_close_sr_buy==1 && ticket_close_sr_buy==0 && TSI_0< TSI_2 && TSI_2>0 && TSI_1>0 && TSI_0<0 && Close[0]<Close[1] && time!=Time[0]) //short
                   // && (opoznij_close_buy==0)
                      &&  ((WynikTR_buy>15*pt) || (WynikTR_buy<-15*pt)))
                      {
                        zamkniecie_buy="#14";
                        CRC="B#14";
                        lp_closebuy14+=1;
                        ticket_after_close_sr_buy=0;
                        return(OP_BUY);
                       } 
 //-----------------------------------------------------------------------
 */
 /*
//----------------------------------------------------------
//##15  ZAMKNIECIE poprzez skrajne linie ketlera
//----------------------------------------------------------
if ((WynikTR_buy>50*pt && WynikTR_buy<150*pt)
   //&& (opoznij_close_sell==0)
   //&& (TSI_1v>0 && TSI_0v<0 )
 //   && (TSI_0v>0 && TSI_1v<0 && Close[0]<KM_15m  )
   && (Close[0]<KD_15m && time!=Time[0])
   || (MaxZysk_buy>=150*pt && WynikTR_buy<50 && Close[0]<KD_15m && time!=Time[0]))
 
  {
               CRC="B#15";
               zamkniecie_buy="#15";
               lp_closebuy15+=1;
               return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
              
   }

//----------------------------------------------------------
//##16  ZAMKNIECIE poprzez srodkowa linie ketlera dla BUY
//----------------------------------------------------------
if ((WynikTR_buy>10*pt)  //zmiana ze 150  /zamiana ze 100
   && (MaxZysk_buy>200)
   //&& (opoznij_close_sell==0)
   //&& (TSI_0v>0 && TSI_1v<0 && Close[0]<KM_15m  )
   && (R_c_15m[0]>KMR_c_15m[0] && S_c_15m[1]>KMS_c_15m[1])
   && (Close[0]<KM_15m && Close[2]>KM_15m && time!=Time[0]))
  { 
               CRC="B#16";
               zamkniecie_buy="#16";
            //   lp_closebuy16+=1;
               return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
              
   }
   */
//----------------------------------------------------------
//##17 // Nadawanie flagi bezwzglednego zamykania przez srodkowa linie keltnera w momencie gdy cena dochodzi w okolice gornej lub dolnej linii keltnera
 //SPROBOWAC ZMODYFIKOWAC TA FUNKCJE I ZAMIAST ZAMYKAC PRZEZ SRODKOWA TO WLACZAC BE
/*
//&& (sredni_kat_ketlera_p28<10 && sredni_kat_ketlera_p28>-10)
//&& WynikTR.buy< wysokosc_keltera_15m
//cena otwarcia nie moze przekroczyc 20% od linii - OrderOpenPrice
//if (OrderType() == OP_BUY  &&  cena ]<OrderOpenPrice())

   if  (OrderType() == OP_BUY  && odleglosc_proc_od_KU_15m_now<10 && S_c_15m[0]<KMS_c_15m[0]) ticket_close_buy_sr_ket=1;
   if  (OrderType() == OP_SELL && odleglosc_proc_od_KD_15m_now<10 && R_c_15m[0]>KMR_c_15m[0]) ticket_close_sell_sr_ket=1;
   //reset flagi

   if  ((OrderType() == OP_BUY  && ticket_close_buy_sr_ket==1) 
       && (save_s0_for_crit_close!=S_15m[0] || save_s0_for_crit_close!=S_15m[1])) ticket_close_buy_sr_ket=0;
 
   if  ((OrderType() == OP_SELL && ticket_close_sell_sr_ket==1)
       && (save_r0_for_crit_close!=R_15m[0] || save_r0_for_crit_close!=R_15m[1])) ticket_close_sell_sr_ket=0;
*/
//------------------------------------
   if (WynikTR_buy<60*pt && WynikTR_buy>20*pt  ///&& WynikTR.buy< wysokosc_keltera_15m
       && sredni_kat_ketlera_p28<10 && sredni_kat_ketlera_p28>-10
       && odleglosc_proc_od_KU_15m_now<10
       && OrderOpenPrice()<KM_15m
       && Close[0]>KM_15m
       && time!=Time[0])
   
  {
      
      wejscie_TSI_vShort();  //wymuszenie pobrania danych dla zamkniecia poprzez TSI_Vshort, normalnie inicjowane sa tylko przez FI
         if (TSI_0b<0 && TSI_1b>0 && TSI_2b>0) 
            {
               CRC="B#17";
               zamkniecie_buy="#17";
               //lp_closebuy15+=1;
               return(OP_BUY); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
            }              
   }



// ponizszy return wpolny dla wszystkich funkcji (gdy zaden warunek nie zostal spelniony)
 return(-1);
 } //koniec funkcji warunki_zamkniecia
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



int warunki_zamkniecia_sell()
{
 


 //-------------------------------------------------------
 //##1          ZAMYKANIE "S/R WYJ¥TEK"
 //-------------------------------------------------------
 // poni¿sze zamkniecia ma false positive. dopoki jest niedopracowane, lepiej oprzec sie na zamknieciu poprzez sr.l.k ew. gorna. (zrobic screena gdy zajdzie przypadek w ktorym powinno to zamk. wystapic)
 // zamkniecia gdy short close nie wchodzi bo jest w trakcie trendu rosnacego, natomiast po powrocie do trendu bocznego nie jest zamykany ze wzgledu na brak trendu rsi
 // wersja dla sell nie byla weryfikowana
 /*
     if (S_c_15m[0]>S_c_15m[1] && S_c_15m[1]<S_c_15m[2] && S_c_15m[2]<S_c_15m[3] && R_c_15m[0]<R_c_15m[1] && R_c_15m[1]<R_c_15m[2] && Close[0]>R_c_15m[0]+0*pt && Close[0]<OrderOpenPrice() && time!=Time[0] && MaxZysk>=15*pt) 
        {
           zamkniecie_sell="Sell S/R wyjatek";
           CRC="CRC7";
           return(OP_SELL);
         //Print (" CloseSell S/R wyjatek");
        }
  */    
 
 //--------------------------------------------------------
 //##2          ZAMYKANIE DLA SELL "ŒRODKOWA LINIA KELTERA" SELL
 //--------------------------------------------------------

     if (((R_c_15m[0]<KMR_c_15m[0] && S_c_15m[0]<KMS_c_15m[0] && Close[1]>KM_15m && Close[0]>KM_15m && time!=Time[0])
        // && (opoznij_close_sell==0)
         || ( Close[1]>KM_15m && Close[2]<KM_15m && ticket_for_close_sell==1))    // brak wymogu aby S/R byla pomiedzy sr.l.k. dla zlecenia z ticketem ( pod koniec zlecen SR zwykle sa juz pomiedzy sr.lina)
         
         && ( MaxZysk_sell >15*pt)  //spr bo bez Mathzysk nie dziala!!
         && (opoznij_close_sell==0)
      //   && (TSI_2v>0 && TSI_0v<0 )
         && (WynikTR_sell> 15*pt)) //zamknij gdy jest w fazie zysku lub z duza starta
      //   && ((WynikTR_sell> 15*pt)|| (WynikTR_sell<-15*pt))) //zamknij gdy jest w fazie zysku lub z duza starta
     
       //&& ((WynikTR_sell<-1*pt)|| (WynikTR_sell> 20*pt))) //zamknij gdy jest w fazie zysku lub z duza starta
            { 
             
               CRC="CRC8";
               if (ticket_for_close_sell==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
               {
                  S_15m_save_for_close_sell=Support_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                  ticket_for_close_sell+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
               }
                  else if (S_15m_save_for_close_sell!=Support_15m) ticket_for_close_sell+=1;
               if (ticket_for_close_sell>=2)
                  {
                    zamkniecie_sell="OK SR. LINIA KELTERA";
                    return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
                  }
            }

 //--------------------------------------------------------
 //##2          ZAMYKANIE DLA SELL "ŒRODKOWA LINIA KELTERA"
 //--------------------------------------------------------
/*
     if(( Close[0]>KM_15m)  //&& time!=Time[0]
     //((R_c_15m[1]>KMR_c_15m[1] && S_c_15m[1]>KMS_c_15m[1] && Close[1]>KM_15m && Close[0]>KM_15m && time!=Time[0])
        // && (opoznij_close_sell==0)
      //#   || ( Close[1]>KM_15m && Close[2]<KM_15m && ticket_for_close_sell==1))    // brak wymogu aby S/R byla pomiedzy sr.l.k. dla zlecenia z ticketem ( pod koniec zlecen SR zwykle sa juz pomiedzy sr.lina)
         && ( MaxZysk_sell >100*pt)  //spr bo bez Mathzysk nie dziala!!
         && (TSI_1v>0 && TSI_0v<0 )
       //  && (TSI_1v>TSI_2v && TSI_2v<0 && TSI_1v<0 && TSI_0b>0 && time!=Time[0])
        // && (opoznij_close_sell==0)
        // && (R_c_15m[2]<KMR_c_15m[2] && S_c_15m[2]<KMS_c_15m[2]) //zamknij gdy jest w fazie zysku lub z duza starta
         && ((WynikTR_sell>50*pt))) //zamknij gdy jest w fazie zysku lub z duza starta
            { 
               CRC="S#2";
               zamkniecie_sell="#2";
               return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
               
         /*
               if (ticket_for_close_sell==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
               {
                  S_15m_save_for_close_sell=Support_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                  ticket_for_close_sell+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
               }
                  else if (S_15m_save_for_close_sell!=Support_15m) ticket_for_close_sell+=1;
               if (ticket_for_close_sell>=2)
                  {
                    zamkniecie_sell="#2";
                    lp_closesell2+=1;
                    return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
                  }
           */
     //     }

/*
 //---------------------------------------------------------
 //##3          ZAMYKANIE "S/R" DLA SELL - i jesli wiekszy od resist!!!
 //---------------------------------------------------------
 // TAK NAPRAWDE TO CHYBA JEST AKTYWOWANE GDY WYSTAPI TYLKO FORMACJA
 // ZASTANOWIC SIE CZY NIE RYREMOWAC BO POTRAFI WSKOCZYC FALSE POSITIVE - I ZAMKNAC ZYSK OTW. W DL. TRENDZIE GDY CLOSE0 NIE PRZEKROCZY JESZCZE SR.L.K.       
      if (((rtrend_15m==1) || (rtrend_15m==2)) //jezeli t. rosnacy lub malejacy
         //&& (opoznij_close_sell==0)
         && (Close[0]<OrderOpenPrice()) // i jest w fazie zysku
         && (!(powertrend_15m_stp2==1 && powertrend_15m_stp0==1)) // i we flat trendzie
         && (S_15m[0]>S_15m[1]) //i wystepuje zalamanie formacji
      // && (Close[0]>KM) //dodano last
         && ((WynikTR_sell>15*pt) || (WynikTR_sell<-15*pt)))
       
       //&& (HighRSI7_15m>10))
       //&& (RSI7_p[1]<RSI7_p[2]))
       //&& (Close[0]<Open[0]))
            {
               CRC="S#3";
               //zamkniecie_sell="Ready_SELL_CLOSE S/R";
               //Print ("WSZED£ ZWYKLY CLOSE S/R");
               if (Close[0]>(Resist_15m+0*pt) && MaxZysk_sell>=10*pt && time!=Time[0]) 
                 {
                     if (ticket_for_close_sell==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                      {
                         S_15m_save_for_close_sell=Support_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                         ticket_for_close_sell+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                      }
                         else if (S_15m_save_for_close_sell!=Support_15m) ticket_for_close_sell+=1;
                     if (ticket_for_close_sell>=2) 
                      {
                         zamkniecie_sell="OK_SELL_CLOSE S/R";
                         lp_closesell3+=1;
                         return(OP_SELL);
                      }
                 }               
             }
             //if (Close[0]<Last_R1 && WynikTR>-0.10 && Order == SIGNAL_CLOSESELL && OrderType() == OP_SELL) Order=SIGNAL_NONE;
*/          
 //---------------------------------------------------------------
 //##4A 4 SZYBKIE ZAMKNIECIE I WYMUSZENIE SZYBKIEGO OTWARCIA (aktualnie flaga ticket_close_short_sell nie jest przydzielana)
 //----------------------------------------------------------------
 
 if (( ticket_close_short_sell==1)
   && (MaxZysk_sell>=10*pt) 
   && (WynikTR_sell>2*pt))
   {  
  // if ((TSI_0>TSI_2 && TSI_2<0 && TSI_0>0 && TSI_0<=45 && time!=Time[0] ))  //zieksza skutecznosc ale obniza zyskownosc (why?)
     if ((TSI_0>TSI_2 && TSI_2<0 && TSI_1<0 && TSI_0>0 && Close[0]>Close[1] ))
        
      {
          CRC="S#4A";
          zamkniecie_sell="#4A";
          ticket_open_short_sell=1;
          return(OP_SELL);
       }
    }
          
 //---------------------------------------------------------------
 //##4         ZAMYKANIE "SHORT" DLA SELL    || Long_C (dodac Long_c)
 //----------------------------------------------------------------
     
      if ((rtrend_15m==0 || rtrend_15m==1) //jezeli trend boczny lub rosnacy
          //&& (opoznij_close_sell==0)
         
          && S1_trenddn==1 //jezeli wystapil silny trend opadajacy na SW_hull_RSI
          && Close[0]<OrderOpenPrice() //i jest w fazie zysku
          && MaxZysk_sell>=15*pt //i odnotowany zostal zysk w wy. 15 pips
          && FI21_p2<=35*0.001
       //% && (trendstp0_rsi==1) // i jesli obecnie nie ma trendu HW_hull(aby Short nie zamykal w trakcie trwania trendu ustawiajac s/l na najblizszym S/R)
          && (WynikTR_sell>15*pt || WynikTR_sell<-15*pt) // nie zamykaj jesli strata lub zysk jest mniejsza od 15 pips
          && DoubleS_15m==0)
        //&& (Close[0]<Open[0]))
        //&& (RSI7_p[1]<RSI7_p[2]))   
             {
                //zamkniecie_sell="READY_CLOSE_SHORT_SELL";
                //Print ("WSZED£ CLOSE SHORT sell, !if WynikTR=", WynikTR, "< 150*pt=", 150*pt, "  Zysk1=", MaxZysk, " Ask=",Ask,"  a Bid=",Bid);
                //if (TSI_0>TSI_2 && TSI_2<0 && TSI_0>0 && TSI_0<=5 && Close[0]>Close[1]&& time!=Time[0]) Order = SIGNAL_CLOSESELL; 
               // copy buy
               // Print ("TSI_0: ",TSI_0,">",TSI_2," :TSI2"," && TSI2: ", TSI_2,"<0","  &&  TSI_0: ", TSI_0,">0  && TSI0",TSI_0,"<=45 && time: ", time, " time != ", Time[0], " ASK ", Ask);
                   CRC="S#4";
                       
                 if (( TSI_0>TSI_2 && TSI_2<0 && TSI_1<0 && TSI_0>0 && Close[0]>Close[1] && time!=Time[0]))
                     //|| (TSI_0b>TSI_2 && TSI_2b<0 && TSI_0b>0 && TSI_0b<=45 && time!=Time[0]  ) //lub poprzez long (zmienic zmienna bo ta odpowiada za tsi start)
                       {
                         //Print ("WSZED£ ORDER SELL!  ASK:",Ask, " Bid:",Bid);
                          
                           if (ticket_for_close_sell==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                              {
                                 S_15m_save_for_close_sell=Support_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                                 ticket_for_close_sell+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                              }
                                 else if (S_15m_save_for_close_sell!=Support_15m) ticket_for_close_sell+=1;
                            if (ticket_for_close_sell>=2)
                              {
                                 S1_trenddn=0;   // po co to?
                                 zamkniecie_sell="#4";
                                 lp_closesell4+=1;
                                 return(OP_SELL);
                               }
                         }
               }  
      
//---------------------------------------------------------
//##5 ZAMKNIECIE POPRZEZ DOLNA LINIE KELTNERA DLA SELL
//---------------------------------------------------------  
//( (S_c_15m[0]<KUS_c_15m[0] && Close[0]<KD ) //jesli R1 jest nad gorna linia keltnera a cena ponizej

      if (token_game==0) // aktywacja zamkniecia gdy wlaczoen jest zamykanie na podstawie tokenu
         {
            if  ((((Close[2]<KD2_15m) || (Close[1]<KD_15m)) && (Close[0]>KD_15m)) //lub cena z P1 lub P2 jest pozwyzej a obecna P0 pozniej g.l.k.
               //&& (!(powertrend_15m_stp2==1 && powertrend_15m_stp0==1))// i wystepuje flat trend
                 //&& (opoznij_close_sell==0)
                 //&& (WynikTR_sell<50*pt)
                 && (MaxZysk_sell>=30*pt) //i odnotowany zostal zysk w wy. 15 pips
                 && ((WynikTR_sell>30*pt) || (OrderOpenPrice()>KMO_15m)) // i aktualny zysk jest nie mneijszy niz 10 pips lub zakup byl powyzej sr.l.k.(w przypadku waskiego kanalu i niewielkich cen)
                 && (TSI_1v>0 && time!=Time[0])) // DODAC MOZE JESZCZE || SLABY POZIOM FI (wtedy nie wrozy dalszych wzrostow a TSI_vshort moze nie zawsze zadzialac ok)
               //&& (open_by_token==0))
                    {
                        
                        CRC="S#5";
                      //if (R_c_15m[0]<KMR_c_15m[0]) 
                       //# if (WynikTR_sell<-2*pt) token_high_sell=1;        // przydzielenie tokenu wymuszenia kupna tylko gdy jest zysk   // CO TO JEST?
                        if (wysokosc_trendu_15m_now>=25 && wysokosc_trendu_15m>=25 && ticket_for_close_sell<=0)                     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                           {
                              S_15m_save_for_close_sell=S_15m[0];      // zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                              ticket_for_close_sell+=1;                   // i odnotuj ten fakt zwiekszajac wart_ticketu
                           }
                              else if (wysokosc_trendu_15m_now>=25 && wysokosc_trendu_15m>=25 && S_15m_save_for_close_sell!=S_15m[0]) ticket_for_close_sell+=1;
                              //&& S_15m_save_for_close_sell!=S_15m[1]
                        if (ticket_for_close_sell>=3) 
                           {
                              zamkniecie_sell="#5";
                              lp_closesell5+=1;
                              return(OP_SELL);
                           }
                      }
           }

//---------------------------------------------------------
//##6 ZAMKNIECIE POPRZEZ TOKEN SHORT  DLA SELL
//---------------------------------------------------------  
//(R_c_15m[0]>KUR_c_15m[0] && Close[0]>KM ) //jesli R1 jest nad gorna linia keltnera a cena ponizej

      if (token_short_game==1) // aktywacja zamkniecia gdy wlaczoen jest zamykanie na podstawie tokenu
         {
            if  ((MaxZysk_sell>=15*pt)
                // && (opoznij_close_sell==0)
                 && (RSI14_S_15m<30))
               //&& ((WynikTR>10*pt) || (WynikTR<-10*pt))
               //&& (rtrend_15m==0))
               //&& (open_by_token==0))
                 CRC="S#6";
                 {
                    if (( TSI_0>TSI_2 && TSI_2<0 && TSI_1<0 && TSI_0>0 && Close[0]>Close[1] && time!=Time[0]))
                    //   if ((TSI_0>TSI_2 && TSI_2<0 && TSI_0>0 && TSI_0<=45 && time!=Time[0] ))
                        {
                           
                           if (WynikTR_sell<-2*pt)  token_short_sell=1;  //przydzielenie tokenu wymuszenia kupna, tylko gdy odnotowano zysk         
                           if (ticket_for_close_sell==0)     // warunek ma na celu niezamykanie zlecen na pierwszej gorce, a dopiero na kolejnej ( przy pierwszej czesto jest false positive)
                              {
                                 S_15m_save_for_close_sell=Support_15m;      //zapamietaj wartosc R_c_15 w momencie spelnienia war. zamk.
                                 ticket_for_close_sell+=1;     // i odnotuj ten fakt zwiekszajac wart_ticketu
                              }
                                 else if (S_15m_save_for_close_sell!=Support_15m) ticket_for_close_sell+=1;
                           if (ticket_for_close_sell>=2)
                              {
                                 lp_closesell6+=1;
                                 zamkniecie_sell="#6";
                                 return(OP_SELL);
                             
                              }
                        }
                 }
          }
 
//---------------------------------------------------------
//##7 ZAMKNIECIE POPRZEZ NATYCHMIASTOWE SHORT DLA SELL
//---------------------------------------------------------
  //zastanowic sie czy nie wymuszac otwarcia kolejnego zlecenia sell poprz tsi_vshort
  if (ticket_crit_for_sell>=1)
  
   {
      if ((TSI_0>TSI_2 && TSI_2<0 && TSI_1<0 && TSI_0>0 && Close[0]>Close[1] && time!=Time[0])
      //&& (opoznij_close_sell==0)
        &&  (WynikTR_sell>2*pt)) // && WynikTR_sell<50)
       //  && (MaxZysk_sell>50)) //nowe
        
                     
         {
            zamkniecie_sell="#7";
            CRC="S#7";
            lp_closesell7+=1;
            return(OP_SELL);   
          }
    }
   
//---------------------------------------------------------
//##8 ZAMKNIECIE POPRZEZ NATYCHMIASTOWE SHORT DLA SELL - flaga dla zlecenia pozniej poziomu otwarcia
//---------------------------------------------------------
  
  if (ticket_crit_for_sell2>=2 )//&& WynikTR_sell<=20
  
   {
   if ((TSI_0>TSI_2 && TSI_2<0 && TSI_1<0 && TSI_0>0 && Close[0]>Close[1] && time!=Time[0])  
 
     // && (opoznij_close_sell==0)
     // && (WynikTR_sell<50*pt)
      &&  (WynikTR_sell>2*pt))
         {
            zamkniecie_sell="#8";
            lp_closesell8+=1;
            CRC="S#8";
            return(OP_SELL);   
          }
    }

//---------------------------------------------------------
//##9 ZAMKNIECIE POPRZEZ NATYCHMIASTOWE SHORT DLA SELL - flaga dla zlecenia z FI >150
//---------------------------------------------------------
  /*
  if (ticket_crit_for_sell3>=1)
  
   {
      if ((TSI_0>TSI_2 && TSI_2<0 && TSI_1<0 && TSI_0>0 && Close[0]>Close[1] && time!=Time[0])  
      //&& (opoznij_close_sell==0)
      &&  (WynikTR_sell>2*pt))
         {
            zamkniecie_sell="#9";
            lp_closesell9+=1;
            CRC="S#9";
            return(OP_SELL);   
    }
    }
*/

//---------------------------------------------------------
//##10 ZAMKNIECIE NATYCHMIASTOWE POPRZEZ SRODKOWA LINIE KELTNERA - poprzez flage zamkniecia, gdy cena wybije sie ponad sr.l.k a s/r sa ponizej
//---------------------------------------------------------
// jezeli obie S/R sa ponizej sr.l.k a ceny wyskoczy ponad nia
// ten filtr jest swiezy && Ask>Close[0] 

if (((R_c_15m[0]<KMR_c_15m[0] && S_c_15m[0]<KMS_c_15m[0] && Close[1]>KM_15m && Close[0]>KM_15m && Ask>Close[0] && time!=Time[0])
         || (Close[1]>KM_15m && Close[2]<KM_15m))
         //&& (opoznij_close_sell==0)
         && WynikTR_sell> 2*pt)
         //&& WynikTR_sell< 60*pt)
        
            { 
               CRC="S#10";
               zamkniecie_sell="#10";
               lp_closesell10+=1;
               if (ticket_close_sell_sr_ket==1) return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
              
            }




//---------------------------------------------------------
//##11 ZAMKNIECIE POPRZEZ BE - poprzez flage zamkniecia, gdy cena dotrze w poblize dolnej linii kelnetra
//---------------------------------------------------------

        if (Close[0]>Close[2] && ticket_close_sell_sr_ket==1 && WynikTR_sell<= 2*pt && MaxZysk_sell>=15*pt )  //&& opoznij_close_sell==0 
        
            { 
               CRC="S#11";
               zamkniecie_sell="#11";
               lp_closesell11+=1;
               return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
              
            }

//---------------------------------------------------------
//##12  ZAMKNIECIE POPRZEZ BE dla SELL- gdy osiagnie zysk 50 pips
//--------------------------------------------------------- 
//KMR_c_15m zamiast KM_15m - bardziej dokladne

  if  (WynikTR_sell<=50*pt && ticket_be_sell==1 && WynikTR_sell<=3 )
           { 
               CRC="S#12";
               zamkniecie_sell="#12";  // dla debugera
               lp_closesell12+=1;
               return(OP_SELL); 
                    
             } 
/*
//----------------------------------------------------------
//##13  ZAMKNIECIE POPRZEZ S/R - gdy osiagnie zysk 50 pips SELL
//--------------------------------------------------------- 
 if (ticket_close_sr_sell==1 && Close[0]>KM_15m && time!=Time[0]) 
          {
               CRC="S#13";
               zamkniecie_sell="#13";  // dla debugera
              // ticket_close_sr_sell=0;
               ticket_after_close_sr_sell=1;
               lp_closesell13+=1;
               return(OP_SELL); 
         }

//----------------------------------------------------------
//##14  ZAMKNIECIE after S/R - gdy osiagnie zysk 50 pips dla SELL
//----------------------------------------------------------
if ((ticket_after_close_sr_sell==1 &&  ticket_close_sr_sell==0 && TSI_0>TSI_2 && TSI_2<0 && TSI_1<0 && TSI_0>0 && Close[0]>Close[1] && time!=Time[0])

     &&  ((WynikTR_sell>15*pt) || (WynikTR_sell<-15*pt)))
         //&&  (WynikTR_sell>2*pt))
         {
            zamkniecie_sell="#14";
            CRC="S#14";
            ticket_after_close_sr_sell=0;
            lp_closesell14+=1;
            return(OP_SELL);   
          }
   

*/
/*
//----------------------------------------------------------
//##15  ZAMKNIECIE poprzez gorna linie ketlera przy duzym zysku
//----------------------------------------------------------
if ((WynikTR_sell>50*pt && WynikTR_sell<100*pt)
  //if ((rtrend_15m==2 && rtrend_1h==2)
   //&& (opoznij_close_sell==0)
   //&& (TSI_1v>0 && TSI_0v<0 )
   && (Close[0]>KU_15m && time!=Time[0])
    || (MaxZysk_sell>=150*pt && WynikTR_sell<50 && Close[0]>KU_15m && time!=Time[0]))
  { 
               CRC="S#15";
               zamkniecie_sell="#15";
               lp_closesell15+=1;
               return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
              
   }

//----------------------------------------------------------
//##16  ZAMKNIECIE poprzez srodkowa linie ketlera przy duzym zysku dla SELL
//----------------------------------------------------------

if ((WynikTR_sell>10*pt)  //testowane
    &&(MaxZysk_sell>200)
   //&& (opoznij_close_sell==0)
  // && (TSI_0v<0 && TSI_1v>0 && Close[0]>KM_15m)
   && (R_c_15m[0]<KMR_c_15m[0] && S_c_15m[1]<KMS_c_15m[1])
   && (Close[0]>KM_15m && Close[2]<KM_15m && time!=Time[0]))
  { 
               CRC="S#16";
               zamkniecie_sell="#16";
            //   lp_closesell16+=1;
               return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
              
   }
   */
//----------------------------------------------------------
//## 17

 if (WynikTR_sell<60*pt && WynikTR_sell>20*pt  ///&& WynikTR.buy< wysokosc_keltera_15m
       && sredni_kat_ketlera_p28<10 && sredni_kat_ketlera_p28>-10
       && odleglosc_proc_od_KD_15m_now<10
       && OrderOpenPrice()>KM_15m
       && Close[0]<KM_15m
       && time!=Time[0])
   
  {
   wejscie_TSI_vShort();  //wymuszenie pobrania danych dla zamkniecia poprzez TSI_Vshort, normalnie inicjowane sa tylko przez FI
   if (TSI_0b>0 && TSI_1b<0 && TSI_2b<0) 
       {
               CRC="S#17";
               zamkniecie_sell="#17";
               //lp_closesell15+=1;
               return(OP_SELL); //zamknij jesli zlecenie bylo w fazie wzrostowej (S/R ponad srodkowa linia) ale spadlo ponizej srodkowej
       }       
   }

// ---  ponizszy return wspolny dla wszystkich funkcji
  return (-1);  // jezeli nie zostal spelniony zaden warunke zamkniecia to nadaj -1
}// koniec funkcji warunki_zamkniecia_sell

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  WEJSCIA SPECJALNE - NIEZALEZNE OD RODZAJU TRENDU 
//  WEJSCIA NA PODSTAWIE TOKENU ------

int wejscia_specjalne()
 {
    
     if (token_game==1)    // czy zamykac na podstawie tokenu
         {
           if ((token_high_buy==1)
              && (Close[0]>KM_15m))
           // && (Ask<KU))
               {  
                //(Ask-Open[0]<5*pt && 
                  if (TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) 
                  {
                     open_by_token=1;
                     otwarcie_buy="token_high_buy";
                     sp_wejscia_buy="TOKEN / HIGH / BUY ";
                     CRCO="CRC13";
                     return(OP_BUY);
                   }
                  // przeniesc w miejsce otwierania transakcji
                }
           if ((token_high_sell==1)
                && (Close[0]<KM_15m))
              //&& (Bid>KD))
               {
                 if (TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) 
                   {
                    open_by_token=1;
                    sp_wejscia_sell="TOKEN / HIGH / SELL ";
                    }
                    otwarcie_buy="token_high_sell";
                  //(Ask-Open[0]<5*pt && 
                  //Open[0]-Bid<15*pt && 
                    CRCO="CRC14";
                    return(OP_SELL);
                }
          }//koniec token_game


if (token_short_game==1) 
   {
     if ((token_short_sell==1)
        || (rsi100_game==1 && RSI100<50))
          {
            if (dl_wejscia==1 && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) 
               {
                open_by_token=1;
                sp_wejscia_sell="TOKEN / V-SHORT / SELL ";
                CRCO="CRC15";
                return(OP_SELL); 
               }
                
            if (dl_wejscia==0 && RSI7_R_15m > RSI_Sell && TSI_1b<TSI_2b  && TSI_2b>0 && TSI_3b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-45 && time!=Time[0]) 
               {
                 open_by_token=1;
                 sp_wejscia_sell="TOKEN / SHORT / SELL"; 
                 otwarcie_buy="token_short_sell";
                 CRCO="CRC16";
                 return(OP_SELL);
               }
            }
    }
   
 
  if ((token_short_buy==1)
      &&(rsi100_game==1)
      && (RSI100>50))
       {
            if (dl_wejscia==1 && TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) 
             {
               open_by_token=1; 
               sp_wejscia_buy="TOKEN / SHORT / BUY ";
               otwarcie_buy="token_short_buy1";
               CRCO="CRC17";
               return(OP_BUY);  
              }
            if (dl_wejscia==0 && RSI7_S_15m < RSI_Buy && TSI_1b>TSI_2b && TSI_2b<0 && TSI_3b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=45  && time!=Time[0]) 
              {
               open_by_token=1;
               sp_wejscia_buy="TOKEN / SHORT / BUY "; //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
             //&& TSI_3b<0 
               otwarcie_buy="token_short_buy2_2";
               CRCO="CRC18";
               return(OP_BUY);  
               }
         }    // koniec short_buy
   
 
    
 //#--- wejscia buy poprzez token po mocnym wybiciu na podstawie indeksu FI - zagranie poprzez korekte na wysokim wybiciu   

   if ((token_short_buy==1)
      && (token_short_game==0)
      && (token_game==0))
     //  && !((R_c_15m[0]<KMR_c_15m[0] && S_c_15m[1]<KMS_c_15m[1]) || (R_c_15m[0]>KMR_c_15m[0] && S_c_15m[1]>KMS_c_15m[1]))
       {
            if (dl_wejscia==1 && TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) 
             {
               open_by_token=1; 
               sp_wejscia_buy="TOKEN FI / VSHORT / BUY ";
               otwarcie_buy="token_short_buy1_1";
               CRCO="CRC17_2";
               return(OP_BUY);  
             }
            if (dl_wejscia==0 && TSI_1b>TSI_2b && TSI_2b<0 && TSI_3b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=45  && time!=Time[0]) 
           // if (dl_wejscia==0 && RSI7_S_15m < RSI_Buy && TSI_1b>TSI_2b && TSI_2b<0 && TSI_3b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=45  && time!=Time[0]) 
             {
               open_by_token=1;
               sp_wejscia_buy="TOKEN / SHORT / BUY "; //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
             //&& TSI_3b<0 
               otwarcie_buy="token_short_buy2";
               CRCO="CRC18_2";
               return(OP_BUY);  
             }
          }//koniec buy
 
//#--- wejscia sell poprzez token po mocnym wybiciu na podstawie indeksu FI - zagranie poprzez korekte na wysokim wybiciu
//# token_short_sell==1, po wysokim FI
   if ((token_short_sell==1) 
    && (token_short_game==0) //czy to konieczne, a co jesli ktoras z gier zostnie wlaczona, czy funkcjonalnosc tych wejsc pozostanie?
    && (token_game==0))
    //&& !((R_c_15m[0]<KMR_c_15m[0] && S_c_15m[1]<KMS_c_15m[1]) || (R_c_15m[0]>KMR_c_15m[0] && S_c_15m[1]>KMS_c_15m[1])))
       {  
            if (dl_wejscia==1 && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) 
               {
                open_by_token=1;
                sp_wejscia_sell="TOKEN FI/ V-SHORT / SELL1 ";
                CRCO="CRC15_8";
                return(OP_SELL); 
               }
                
            if (dl_wejscia==0 && TSI_1b<TSI_2b  && TSI_2b>0 && TSI_3b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-45 && time!=Time[0]) 
               {
                 open_by_token=1;
                 sp_wejscia_sell="TOKEN  / SHORT / SELL"; 
                 otwarcie_buy="token_short_sell_token_fi";
                 CRCO="CRC16_8";
                 return(OP_SELL);
               }
        } //koniec dla sell
//----------------------------------------------------------------------------------------------------------------------------------
 //#--- wejscia buy gdy zysk 
 //korelacja zamk #4A
   if (ticket_open_short_buy==1)
     //  && !((R_c_15m[0]<KMR_c_15m[0] && S_c_15m[1]<KMS_c_15m[1]) || (R_c_15m[0]>KMR_c_15m[0] && S_c_15m[1]>KMS_c_15m[1]))
       {
            if (dl_wejscia==1 && TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) 
            {
               
               sp_wejscia_buy="TICKET#1 / VSHORT / BUY1 ";
               otwarcie_buy="ticket_open_short_buy1_1";
               CRCO="CRC17_3";
               return(OP_BUY);  
             }
            if (dl_wejscia==0 && TSI_1b>TSI_2b && TSI_2b<0 && TSI_3b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=45  && time!=Time[0]) 
           // if (dl_wejscia==0 && RSI7_S_15m < RSI_Buy && TSI_1b>TSI_2b && TSI_2b<0 && TSI_3b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=45  && time!=Time[0]) 
             {
               
               sp_wejscia_buy="TICKET#2 / SHORT / BUY "; //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
             //&& TSI_3b<0 
               otwarcie_buy="ticket#1_short_buy2";
               CRCO="CRC18_2";
               return(OP_BUY);  
             }
          }//koniec buy
 
//#--- wejscia sell 

   if (ticket_open_short_sell==1)
    //&& !((R_c_15m[0]<KMR_c_15m[0] && S_c_15m[1]<KMS_c_15m[1]) || (R_c_15m[0]>KMR_c_15m[0] && S_c_15m[1]>KMS_c_15m[1])))
       {  
            if (dl_wejscia==1 && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) 
               {
                open_by_token=1;
                sp_wejscia_sell="TICKET#3/ V-SHORT / SELL2 ";
                CRCO="CRC15_8";
                return(OP_SELL); 
               }
                
            if (dl_wejscia==0 && TSI_1b<TSI_2b  && TSI_2b>0 && TSI_3b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-45 && time!=Time[0]) 
               {
                 open_by_token=1;
                 sp_wejscia_sell="TICKET#4  / SHORT / SELL2"; 
                 otwarcie_buy="token_short_sell_token_fi";
                 CRCO="CRC16_8";
                 return(OP_SELL);
               }
        } //koniec 
//----------------------------------------------------------------------------------------------------------
//   OTWARCIRE ZLECENIA SELL GDY CENA ZBLIZYLA SIE DO GORNEJ LINII KETLERA PODCZAS TRENDU BOCZNEGO
//## korelacja z zamk #17
  if   (orders_total(OP_SELL ) == 0  ///&& WynikTR.buy< wysokosc_keltera_15m
       && sredni_kat_ketlera_p21<10 && sredni_kat_ketlera_p21>-10
       && odleglosc_proc_od_KU_15m_now<10
       && Close[0]>KM_15m
       && time!=Time[0])
   
  {
      
      wejscie_TSI_vShort();  //wymuszenie pobrania danych dla zamkniecia poprzez TSI_Vshort, normalnie inicjowane sa tylko przez FI
         if (TSI_0b<0 && TSI_1b>0 && TSI_2b>0) 
            {
        
               sp_wejscia_sell="HiGH KU.";
               CRCO="CRC20";
               return(OP_SELL);  
            }      
  }
//-----------------------------
//   OTWARCIRE ZLECENIA BUY GDY CENA ZBLIZYLA SIE DO DOLENJ LINII KETLERA PODCZAS TRENDU BOCZNEGO
//## korelacja z zamk #17
  if   (orders_total(OP_BUY ) == 0  ///&& WynikTR.buy< wysokosc_keltera_15m
       && sredni_kat_ketlera_p21<10 && sredni_kat_ketlera_p21>-10
       && odleglosc_proc_od_KD_15m_now<10
       && Close[0]<KM_15m
       && time!=Time[0])
   
  {
      
      wejscie_TSI_vShort();  //wymuszenie pobrania danych dla zamkniecia poprzez TSI_Vshort, normalnie inicjowane sa tylko przez FI
         if (TSI_0b>0 && TSI_1b<0 && TSI_2b<0) 
            {
        
               sp_wejscia_buy="HiGH KD";
               CRCO="CRC21";
               return(OP_BUY);  
            }      
  }
 //-----------------------------


 return(-1);     
} //koniec funkcji wejscia_specjalne



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                        WEJŒCIA W TRENDZIE BOCZNYM
// ============================================================================================================


int wejscia_trend_boczny_buy()
 {
  //Print ("TR boczny 1");
//  if (rtrend_15m==0)
//    {
// ## SIGNAL BUY
  
    
      if (!(S_c_15m[0]<S_c_15m[1] && S_c_15m[2]<S_c_15m[3] && R_c_15m[0]<R_c_15m[1] && R_c_15m[2]<R_c_15m[3])) //Buy o ile nie jest w formacji malejacej
         {
     /*      if ((Ask-Open[0]<15*pt)  //nie otwieraj tr. jesli cena rozni sie powyzej 15 pips od momentu otwarcia swiecy
             && (trenddn0_rsi==0)
             && (RSI7_S_15m < RSI_Buy)
             && (BuyHighRSI7_15m==1))
                 {
                  Print ("Ask-Open=",Ask-Open[0]," < ",15*pt);
                  if ((HighRSI7_15m>25 || Long==1))
                     {
                        if (TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=15 && time!=Time[0]) Order = SIGNAL_BUY; //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                       //&& TSI_3b<0
                      }
      */        
     
              if (token_short_buy==0 && token_short_sell==0 && rsi100_game==0)
                { //Print ("TR boczny 2");
                 if (dl_wejscia==1)  //dla wejscia TSI_vShort
                    {//Print ("TR boczny 3");
                     if (Ask-Open[0]<5*pt && TSI_0b>TSI_1b && TSI_2b<0 && TSI_0b>0 && time!=Time[0]) 
                        {
                          open_by_token=0;
                          sp_wejscia_buy="BOCZNY / V-Short / BUY / 5"; //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                          //&& TSI_1b<0 
                          CRCO="CRC25";
                       // Print ("TR boczny 4");
                       // signalBar       = (TimeS != Time[0]);  TimeS = Time[-2];
                       // if (signalBar==1 && Ask-Open[0]<5*pt)
                          return(OP_BUY);
                         }
                     }
                     else
                        {//Print ("TR boczny 5");
                         if ( Ask-Open[0]<5*pt && TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) 
                           {//Print ("TR boczny 6");
                             open_by_token=0;
                             sp_wejscia_buy="BOCZNY / SHORT / BUY / 5";
                             CRCO="CRC26";
                             //Print ("TR boczny 7");
                             return(OP_BUY);
                             //Order = SIGNAL_BUY; 
                            } //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                       
                          if (RSI7_S_15m < RSI_Buy && TSI_1b>TSI_2b && TSI_3b<0 && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=15 && time!=Time[0])
                            {
                           //Print ("TR boczny 8");
                              open_by_token=0;
                              sp_wejscia_buy="BOCZNY / SHORT / BUY "; //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                            //&& TSI_0b<=15
                              CRCO="CRC27";
                             // Print ("CRC27  ", "RSI7S=", RSI7_S_15m,"  RSI_Buy=", RSI_Buy);
                              return(OP_BUY);
                             }
                         }
                  }
               //zamkniecie ja war. wyzek ale w oparciu o P1
               // if (TSI_1b>TSI_2b && TSI_3b<0 && TSI_2b<0 && TSI_1b>0 && TSI_1b<=15 && time!=Time[0]) Order = SIGNAL_BUY; //} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                    //&& RSI7_S_15m < RSI_Buy
       } // koniec 1go war if
//     }//koniec if trend=0
//Print ("TR boczny 9");
return(-1);
} //koniec wejscia_trend_boczny_buy


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ## SYGNAL SELL 

int wejscia_trend_boczny_sell()
 {
 //  if (rtrend_15m==0)
 //   {
      if ((!(S_c_15m[0]>S_c_15m[1] && S_c_15m[2]>S_c_15m[3] && R_c_15m[0]>R_c_15m[1] && R_c_15m[2]>R_c_15m[3])) //Sell o ile nie jest w formacji rosnacej
          &&  (Open[0]-Bid<15*pt))
        //&& (SellHighRSI7_15m==1))
        //&& (trendup0_rsi==0)
            { 
             // Print ("Open-Bid=",Open[0]-Bid," < ",15*pt);
             // if ((HighRSI7_15m>25 || Long==1))
             //  {
             //    if (RSI7_R_15m > RSI_Sell && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-15 && time!=Time[0]) {Order = SIGNAL_SELL;}

              if (token_short_buy==0 && token_short_sell==0 && rsi100_game==0)
                {
                  if (dl_wejscia==1)
                   {
                      if (Open[0]-Bid<5*pt && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) 
                         {
                            open_by_token=0;
                            sp_wejscia_sell="BOCZNY / V-Short / SHELL /15";
                          //Print ("boczny Vshort sell");
                          //&& TSI_1b>=-15
                            CRCO="CRC28";
                            return(OP_SELL);
                         }
                    }
                else 
                    {
                      if (Open[0]-Bid<5*pt &&RSI7_R_15m >RSI_Sell && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) 
                         {
                            open_by_token=0;
                            sp_wejscia_sell="BOCZNY / SHORT / SHELL / 15";
                            CRCO="CRC29";
                            return(OP_SELL);
                         }
                      if (RSI7_R_15m > RSI_Sell && TSI_1b<TSI_2b && TSI_3b>0 && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-15 && time!=Time[0]) 
                         {  
                            open_by_token=0;
                            sp_wejscia_sell="BOCZNY / SHORT / SHELL"; 
                            //&& TSI_3b>0
                            CRCO="CRC30";
                            return(OP_SELL);
                         }
                      }
 
                  }              
      //sygnal Sell jak war. wyzej ale w oparciu o P1
      // if (TSI_1b<TSI_2b && TSI_3b>0 && TSI_2b>0 && TSI_1b<0 && TSI_1b>=-15 && time!=Time[0] ) {Order = SIGNAL_SELL;}
      //    && RSI7_R_15m > RSI_Sell
       }
//   } //koniec war rtrend_15m=0     
 return (-1);
 } //koniec funkcji wejscia_trend_boczny_sell

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// WEJŒCIA W TRENDZIE ROSN¥CYM

int wejscia_trend_rosnacy()
{

 //  if (rtrend_15m==1)  //jesli trend rosnacy wykonaj wejscie gdy...
 //    {

       if  ((Ask-Open[0]<15*pt))  //nie otwieraj tr. jesli cena rozni sie powyzej 15 pips od momentu otwarcia swiecy
         //&& (trenddn0_rsi==0))
         //#&& ((RSI7_S_15m < RSI_Buy) || (HighRSI7_15m>30)))
         //&&  ((HighRSI7_15m>25) || (Long==1)))
            {

             //### to  if (RSI7_S_15m < RSI_Buy && TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=15 && time!=Time[0]) Order = SIGNAL_BUY; //}

               if (token_short_buy==0 && token_short_sell==0 && rsi100_game==0)
                 {
//                   Print ("TR rosnacy 4");
                   if (dl_wejscia==1)
                      {
  //                      Print ("TR rosnacy 5");
                        if (Ask-Open[0]<5*pt && TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) 
                           {
                            //  Print ("TR rosnacy 6");
                              open_by_token=0; 
                              sp_wejscia_buy="UP / V-Short / BUY /15";
                              CRCO="CRC31";
                              return(OP_BUY);
                           } 
                        //&& TSI_0b<=15
                       }
                      else
                         {
    //                       Print ("TR rosnacy 7");
                           if (Ask-Open[0]<5*pt  && TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) //&& RSI7_S_15m <RSI_Buy
                            {
                             // Print ("TR rosnacy 8");
                              open_by_token=0; 
                              sp_wejscia_buy= "UP / SHORT/ Buy /5";
                              CRCO="CRC32";
                              return(OP_BUY);
                            } 
                           if (RSI7_S_15m < RSI_Buy && TSI_1b>TSI_2b && TSI_3b<0 && TSI_2b<0 && TSI_0b>0 && TSI_0b<=15 && time!=Time[0]) 
                            {
      //                        Print ("TR rosnacy 9");
                              open_by_token=0; 
                              sp_wejscia_buy="UP / SHORT / BUY ";
                              CRCO="CRC33";
                              return(OP_BUY);
                            } 
                         }
                      }
               }
//     }// koniec rtrend
//Print ("TR rosnacy 10");
 return(-1);
} //koniec funkcji wejscia_trend_rosnacy

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// WEJŒCIA W TRENDZIE MALEJ¥CYM
int wejscia_trend_malejacy()
{
// if (rtrend_15m==2)
//  { 
    CRCO=" LVL1";
    if  ((Open[0]-Bid<15*pt))  //nie otwieraj tr. jesli cena rozni sie powyzej 15 pips od momentu otwarcia swiecy 
      //#&& ((RSI7_R_15m > RSI_Sell) || (HighRSI7_15m>30)))
       //&&  ((HighRSI7_15m>25) || (Long==1)))
       //&& (trendup0_rsi==0))
         {
            if (token_short_buy==0 && token_short_sell==0 && rsi100_game==0)
              {
                if (dl_wejscia==1)
                  {
                     if (Open[0]-Bid<5*pt &&TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) 
                        {
                           CRCO=" LVL2";
                           open_by_token=0;
                           sp_wejscia_sell="DOWN / V-Short / SELL";
                           CRCO="CRCO34";
                           return(OP_SELL);
                        }//} //Print ("RSI FILTR ",FI_1f, " ",RSI_filtr);  
                        //&& TSI_0b>=-15
                   }
                 else 
                  {
                    CRCO=" LVL3";
                     //## to if (RSI7_R_15m > RSI_Sell && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-15 && time!=Time[0]) {Order = SIGNAL_SELL;}//} //Print ("RSI FILTR ",FI_1f, " ",RSI_filtr);
                   //TO PONI¯SZE POWINNO BYÆ CHYBA ESPARTE JAKIMŒ DODATKOWYM FILTEREM NP. SILNYM WYBICIEM NA FI
                    if  ((  Open[0]-Bid<5*pt) //jesli wejscie na poczatku swiecy
                         && (RSI7_R_15m > RSI_Sell) 
                         && (TSI_0b<TSI_1b) // TUTAJ RACZEJ TEN WAR. POWINEIEN BYÆ TSI_0b<0 && TSI_0b>=-15
                         && (TSI_2b>0 && TSI_1b>0 && TSI_0b<0) 
                         && (time!=Time[0]))
                        {
                         open_by_token=0;
                         sp_wejscia_sell="DOWN / V-Short /5"; //TO CHYBA NIE JEST V-SHORT?
                         CRCO="CRC35";
                         return(OP_SELL);
                        } 
                     if (RSI7_R_15m > RSI_Sell && TSI_1b<TSI_2b && TSI_3b>0 && TSI_2b>0 && TSI_0b<0 && TSI_0b>=-15 && time!=Time[0]) 
                        {
                          open_by_token=0;
                          sp_wejscia_sell="DOWN / SHORT / SHELL";
                          CRCO="CRC36";
                          return(OP_SELL);
                        } 
                  
                  }     
            //&& TSI_3b>0
            //Print ("Bid-Open2=",Open[0]-Bid," < ",15*pt);
               }
          }
//   } koniec rtrend
 return(-1);
} //koniec wejsc w trendzie malejacym

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// USTAWIENIE PIERWOTNEGO POZIOMU STOP LOSS DLA BUY
void ustaw_pierwotny_sl_buy()
{
    if (UseStopLoss) 
        { 
           if (StopLoss != min_First_OpenSL && StopLoss != min_OpenSL)  //jezeli Stop LOss jest taki sam jak pozostalt zmienne dot SL, to ignoruj (funkcja zmiany SL wylaczona)
            {
               ustaw_Buy_SL=0; //wyzerowanie wczesniejszej flagi przed nowa operacja ustawienia SL
               ustaw_Sell_SL=0;
               StopLoss=oblicz_Buy_SL();    // WYWOLANIE PROCEDURY STOP LOSS    
               if (StopLoss<min_First_OpenSL || StopLoss>31) StopLoss=31;  else {if (StopLoss<25) StopLoss=StopLoss+3;}
             }      
        
           StopLossLevel = Ask - StopLoss * pt;
        }
        else StopLossLevel = 0.0;
 }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// USTAWIENIE PIERWOTNEGO POZIOMU STOP LOSS dla Sell------------
void ustaw_pierwotny_sl_sell()
 {
    if (UseStopLoss) 
      {
         if (StopLoss != min_First_OpenSL && StopLoss != min_OpenSL)  //jezeli Stop LOss jest taki sam jak pozostalt zmienne dot SL, to ignoruj (funkcja zmiany SL wylaczona)
            {
               ustaw_Buy_SL=0;
               ustaw_Sell_SL=0; //wyzerowanie wczesniejszej flagi przed nowa operacja ustawienia SL
               StopLoss=oblicz_Sell_SL();  
               if (StopLoss<min_First_OpenSL || StopLoss>31) StopLoss=31; else {if (StopLoss<25) StopLoss=StopLoss+3;}
            // Print ("Bid=",Bid,"  S_15m[0]=",S_15m[0], "  Wynik Bid-R_15m[0]=",MathAbs((Bid-R_15m[0]))/pt, "   pt=",pt, "    tmp_Stoploss=",tmp_StopLoss);     
             //Print ("StopLoss=",StopLoss, "   S_15m[0]=",S_15m[0],"   R_15m[0]",R_15m[0],  "  R2=",R_15m[1], "      Close[0]=",Close[0]);
            }
           StopLossLevel = Bid + StopLoss * pt;
       }
           else StopLossLevel = 0.0;
} 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void reset_zmiennych_new_trans_buy()
   {
       maksprice_buy=Bid;                   //wyzerowanie zmienniej maksprice dla nowego zlecenia   
       token_high_buy=0;
       if (token_short_buy>0) all_token_buy=all_token_buy+1; //zliczanie przyznanych tokenow - dla celow diagnostycznych
       token_short_buy=0;
       opis="OpenH";
       ticket_for_close_buy=0;
       save_s0_for_crit_close=0;            // na potrzeby przyznawania flagi ticket_crit_for_buy2
       ticket_crit_for_buy2=0;              // dla zamykania zlecen znajdujacych sie pozniej poziomu otwarcia     
       ticket_crit_for_buy3=0;              // reset flagi dla zlecen z FI > 150
       ticket_close_buy_sr_ket=0;           // zezwolenie na bezwzgledne zamykniecie buy poprzez srodkowa linie keltnera gdy cena zblizy sie do gornej linii keltnera
       zamkniecie_buy="erased";
       MaxZysk_buy=0; 
       ticket_be_buy=-1;
       ticket_close_sr_buy=0;
       ticket_open_short_buy=0;
       ticket_close_short_buy=0;
     //  WynikTR=0;
     //  MaxZysk=0;
   
         for (int i = OrdersTotal() - 1;i >= 0;i--)
         {
            if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
            if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber())
            {
                if (OrderType() == OP_BUY) czas_otwarcia_buy=OrderOpenTime(); 
            }
         }
    
    }

void reset_zmiennych_new_trans_sell()
   {
       maksprice_sell=Ask;
       token_high_sell=0; //wyzerowanie tokena
       if (token_short_sell>1) all_token_sell=all_token_sell+1;//zliczanie przyznanych tokenow - dla celow diagnostycznych
       //token_short_buy=0;
       token_short_sell=0;
       opis="OpenH";
       ticket_for_close_sell=0;
       save_r0_for_crit_close=0;
       ticket_crit_for_sell2=0;       
       ticket_crit_for_sell3=0;     // reset flagi dla zlecen z FI > 150  
       ticket_close_sell_sr_ket=0;          // zezwolenie na bezwzgledne zamykniecie sell poprzez srodkowa linie keltnera gdy cena zblizy sie do dolnej linii keltnera
       zamkniecie_sell="erased";
       MaxZysk_sell=0; 
       ticket_be_sell=-1;
       ticket_close_sr_sell=0; 
       ticket_open_short_sell=0;
       ticket_close_short_sell=0;
     //  WynikTR=0;
     //  MaxZysk=0;
      if (OrderType() == OP_SELL) czas_otwarcia_sell=OrderOpenTime(); 
    
            for (int i = OrdersTotal() - 1;i >= 0;i--)
              {
                 if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
                 if (Symbol() == OrderSymbol() && magic_number == OrderMagicNumber())
                 {
                     if (OrderType() == OP_SELL) czas_otwarcia_sell=OrderOpenTime(); 
                 }
              }
    
    }



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void zapis_zmiennych_new_transaction()
  {
   KUO_15m=KU_15m; KMO_15m=KM_15m; KDO_15m=KD_15m;  //zapamietanie poziomu lini keltnera w momencie zakupu
//	maksprice_buy=Bid; //wyzerowanie zmienniej maksprice dla nowego zlecenia
 //  maksprice_sell=Ask;
   Last_S1_15m=S_15m[0]; // Zapamietanie ostatniej lini Wsparcia w momencie zakupu (wezmie raczej pod uwage linie sprzed momentu zakupu)
   Last_R1_15m=R_15m[0]; // Zapamietanie linni oporu

   }




//#################################################################################################################
//------------------------------------        F U N K C J E    ---------------------------------------------------
//#################################################################################################################

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                                  OBLICZANIE PIEROTNEGO POZIOMU STOP LOSS DLA BUY
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 double oblicz_Buy_SL()
    {
      //SL nr 1 - dla trendu wzrostowego - R2 jako SL
      if ((R_15m[0]> S_15m[0] && R_15m[1]>S_15m[0]) //spr czy blizszym R jest wczesiejszy wierzcholek (R2) czy ost. l.wsp S1
      && (R_15m[1]<R_15m[0]) // czy ostatni wierzcholek jest najwyzszy
      && (R_15m[1]<OrderOpenPrice()) //spr czy R2 jest mniejszy od Close 0( bo w tr. maljejacym nie bedzie i odnosnikiem bedzie S1)  
      && (S_15m[0]<OrderOpenPrice()))
       { 
          //spr czy S1 nie jest rowniez w zasiegu 31 pips?
          tmp_StopLoss=MathAbs((OrderOpenPrice()-R_15m[1])/pt);
          tmp_StopLoss=MathFloor(tmp_StopLoss);
          if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
            ||(tmp_StopLoss<min_First_OpenSL))
               {StopLoss=31;ustaw_Buy_SL=1;opisSL="Buy nr1/1-31"; Print("Buy nr1/1-31=",tmp_StopLoss);}
            else {ustaw_Buy_SL=0;opisSL="Buy nr1/2-R2";Print("Buy nr1/2=",tmp_StopLoss);}
          
        }
   
     // SL nr 2 - S1 jako SL
     if ((R_15m[0]>Ask) //jesli cena jest wieksza od ostatniego wierzcholka R
          && (R_15m[1]>R_15m[0] || R_15m[1]==R_15m[0])
          && (R_15m[1]>Ask)
          && (S_15m[0]<Ask))
         { 
            tmp_StopLoss=MathAbs((Ask-S_15m[0])/pt);
            tmp_StopLoss=MathFloor(tmp_StopLoss);
             if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
              || (tmp_StopLoss<min_First_OpenSL))
                {StopLoss=31;ustaw_Buy_SL=1; opisSL="Buy nr2/1-31";Print("Buy nr2/1=",tmp_StopLoss);}
             else {ustaw_Buy_SL=0;opisSL="Buy nr2/2-S_15m[0]";Print("Buy nr2/2=",tmp_StopLoss);}
             
          }
      
      // SL nr 3 - R1 lub S1 jako SL (brak innych odniesien)
      if ((R_15m[0]<Ask)) //jesli cena jest wieksza od ostatniego wierzcholka R
         { 
           //obl. ktora odl jest w zasiegu S1 czy R1       
           tmp_StopLoss=MathAbs((Ask-S_15m[0])/pt);
           tmp_StopLoss=MathFloor(tmp_StopLoss);
          if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
             || (tmp_StopLoss<min_First_OpenSL))
             {StopLoss=31;ustaw_Buy_SL=1;opisSL="Buy nr3/1-31";Print("Buy nr3/1=",tmp_StopLoss);}
              else {ustaw_Buy_SL=0;opisSL="Buy nr3/2-S_15m[0]";Print("Buy nr3/2=",tmp_StopLoss);}
             
          }
           
          
      //SL nr 4 - dla trendu malejacego - S1 jako SL
      if ((R_15m[0]>S_15m[0] && R_15m[1]>S_15m[0])
          && (R_15m[1]>Ask) //charakterystyczne dla trendu malejacego
          && (S_15m[0]<Ask))  // i ost. l.wsparcia znajduje sie ponizej
         { 
           //obl czy odl nie wieksza niz 31 pips    
          tmp_StopLoss=MathAbs((Ask-S_15m[0])/pt);
          tmp_StopLoss=MathFloor(tmp_StopLoss);
          if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
             ||(tmp_StopLoss<min_First_OpenSL))
              { StopLoss=31;ustaw_Buy_SL=1;opisSL="Buy nr4/1-31";Print("Buy nr4/1=",tmp_StopLoss);}
               else {ustaw_Buy_SL=0;opisSL="Buy nr4/2";Print("Buy nr4/2=",tmp_StopLoss);}
         }    
    
      //SL nr 5 - jesli nie zarysowala sie linia wsparcia w tr. malejacym - SL = 31 pips
      if (S_15m[0]> Ask)
      { 
        if (S_15m[1]<Ask) //skoro ie S1 to spr_czy ewentualnie S2 nie mozna wykorzystac jako SL
        {
          tmp_StopLoss=MathAbs((Ask-S_15m[1])/pt);
          tmp_StopLoss=MathFloor(tmp_StopLoss);
           if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
             ||(tmp_StopLoss<min_First_OpenSL))
              { StopLoss=31;ustaw_Buy_SL=1;opisSL="Buy nr5/1-31";Print("Buy nr5/1=",tmp_StopLoss); }
                else {ustaw_Buy_SL=0;opisSL="Buy nr5/2-S_15m[0]";Print("Buy nr5/2=",tmp_StopLoss);}
         }  
         else {ustaw_Buy_SL=1;tmp_StopLoss=31;opisSL="Buy nr5/3-00";Print("Buy nr5/3=",tmp_StopLoss);}
       }
Print("Buy nr6/End=",tmp_StopLoss, "  Ask=",Ask, "  Bid=",Bid,"  R1=",R_15m[0], "  Ustaw_BuySL=",ustaw_Buy_SL);
 return (tmp_StopLoss);
}
      

 //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 //               OBLICZANIE PIERWOTNEGO POZIOMU STOP LOSS dla SELL
 //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
double oblicz_Sell_SL()
 {    
   tmp_StopLoss=0;
      //SL nr 1 - R1 jako SL
  if ((R_15m[0]> S_15m[0]) //&& R_15m[1]>S_15m[0] |spr czy blizszym R jest wczesiejszy wierzcholek (R2) czy ost. l.wsp S1
      //&& (R_15m[1]<R_15m[0]) // czy ostatni wierzcholek jest najwyzszy
      //&& (R_15m[1]<Close[0]) //spr czy R2 jest mniejszy od Close 0( bo w tr. maljejacym nie bedzie i odnosnikiem bedzie S1)  
      && (R_15m[0]>Bid))
       { 
        tmp_StopLoss=MathAbs((Bid-R_15m[0])/pt);
        tmp_StopLoss=MathFloor(tmp_StopLoss);
        if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
           || (tmp_StopLoss<min_First_OpenSL))
            {StopLoss=31;ustaw_Sell_SL=1;opisSL="Sell nr1/1-31";Print ("Sell nr1/1-31=",tmp_StopLoss);}
            else {ustaw_Sell_SL=0;opisSL="Sell nr1/2-R1";Print ("Sell nr1/2=",tmp_StopLoss);} //przekaze rowniez do return wczesniej obliczona wart. tmp_StopLoss (dlatego brak odwolania do niej)
       }
        
  
   //SL nr 2 (5buy) - jesli nie zarysowala sie linia wsparcia w tr. malejacym - SL = 31 pips
  if (R_15m[0]< Bid) //jesli nie zarysowala sie linia oporu R1
      { 
         if (R_15m[1]>Bid) //skoro nie R1 to spr_czy ewentualnie R2 nie mozna wykorzystac jako SL
           {
             tmp_StopLoss=MathAbs((Bid-R_15m[1])/pt);
             tmp_StopLoss=MathFloor(tmp_StopLoss);
               if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
                 ||(tmp_StopLoss<min_First_OpenSL))
                   {StopLoss=31;ustaw_Sell_SL=1;opisSL="Sell nr2/1-31";Print ("Sell nr2/1-31=",tmp_StopLoss);}
                   else {ustaw_Sell_SL=0;opisSL="Sell nr2/2-R2";Print ("Sell nr2/2-31=",tmp_StopLoss);}
            }  
          else {ustaw_Sell_SL=1;opisSL="Sell nr2/3-00";Print ("Sell nr2/3=",tmp_StopLoss);} 
        }
    else{ustaw_Sell_SL=1;tmp_StopLoss=31;opisSL="Sell nr4/1";Print ("Sell nr4/1=",tmp_StopLoss);}// jesli nie zarysowala sie R1 to ustaw staly SL

return(tmp_StopLoss);
}


// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ---                 WEJSCIA TSI                       ---------
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


void wejscie_TSI_vShort()
  {
      TSI_0b  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,0);
      TSI_1b  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,1);
      TSI_2b  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,2);
   //#TSI_3b  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,3);
   //#TSI_5b  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,5);

      
      Long=0;
      dl_wejscia=1;
   }

void wejscie_TSI_Short()
   {
      TSI_0b  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,0);
      TSI_1b  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,1);
      TSI_2b  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,2);
      TSI_3b  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,3);
      //#TSI_5b  = iCustom(NULL,0,"TSI_Short",0,5);
      Long=0; //ustawinie typu otwarcia
      dl_wejscia=0;
      //#Print ("Wszedl short");

   }

void wejscie_TSI_Long()
   {
 
 
      TSI_0b  = iCustom(NULL,PERIOD_M15,"TSI_Long_C",0,0);
      TSI_1b  = iCustom(NULL,PERIOD_M15,"TSI_Long_C",0,1);
      TSI_2b  = iCustom(NULL,PERIOD_M15,"TSI_Long_C",0,2);
      TSI_3b  = iCustom(NULL,PERIOD_M15,"TSI_Long_C",0,3);
   //#TSI_5b  = iCustom(NULL,PERIOD_M15,"TSI_Long_C",0,5);
   //#Print ("wszedl long");
   
      Long=1; //ustawienie typu otwarcia
      dl_wejscia=0;
   }

void wskaznik_zamkniecia()
{
      //TSI_0v  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,0); // - sluzy jako filtr dla zamkniec przez gorna/dolna linie keltnera
      TSI_1v  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,1); // - sluzy jako filtr dla zamkniec przez gorna/dolna linie keltnera
      //TSI_2v  = iCustom(NULL,PERIOD_M15,"TSI_vShort",0,2); // - sluzy jako filtr dla zamkniec przez gorna/dolna linie keltnera
   
      TSI_0  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,0);
      //TSI_1 = TSI_1b; // w realu przywrocic normalny zapis z icustom. zrobione dla przysieszenia testow. gdy kiedys bedzie wykorzystywany token_buy=1 to moze on przybierac wartosc vshort i zmieniac wyniki jesli sie tego nie przywroci
      TSI_1  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,1);
      TSI_2  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,2);
      TSI_3  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,3);
   //#TSI_5  = iCustom(NULL,PERIOD_M15,"TSI_Short",0,5);
 }
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
double RSI7_max_15m (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_15m_p[ArrayMaximum(RSI7_15m_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI7_Min_15m (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_15m_p[ArrayMinimum(RSI7_15m_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_max_15m (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_15m_p[ArrayMaximum(RSI14_15m_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_Min_15m (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_15m_p[ArrayMinimum(RSI14_15m_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
double RSI7_max_1h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_1h_p[ArrayMaximum(RSI7_1h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI7_Min_1h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_1h_p[ArrayMinimum(RSI7_1h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_max_1h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_1h_p[ArrayMaximum(RSI14_1h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_Min_1h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_1h_p[ArrayMinimum(RSI14_1h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
double RSI7_max_4h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_4h_p[ArrayMaximum(RSI7_4h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI7_Min_4h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_4h_p[ArrayMinimum(RSI7_4h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_max_4h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_4h_p[ArrayMaximum(RSI14_4h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_Min_4h (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_4h_p[ArrayMinimum(RSI14_4h_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
double RSI7_max_1d (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_1d_p[ArrayMaximum(RSI7_1d_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI7_Min_1d (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI7_1d_p[ArrayMinimum(RSI7_1d_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_max_1d (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_1d_p[ArrayMaximum(RSI14_1d_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}

double RSI14_Min_1d (int long_rsi)
{
      double rsi_tmp;
        rsi_tmp = RSI14_1d_p[ArrayMinimum(RSI14_1d_p,long_rsi,0)]; //---- Wyszukanie indeksu zawieraj¹cego najwyzsza wartosc RSI
      return (rsi_tmp);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




/*
bool Function_New_Bar()
      {
      static datetime New_Time;
      bool New_Bar = false;
      if (New_Time==0)
         {
         New_Time = Time[0];
         }
      if (New_Time!= Time[0])
         {
         New_Time = Time[0];
         New_Bar = true;
         }
      return(New_Bar);
     }
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_resist_15m()
 {
      int t;
    //zapamietanie wartosci kanalu ketlera w momencie wystapienia linii Resist, w celu porownania ich wzajemnych wart. dla wskaznika Barry_v5 (ver.bez close)
      KUR_15m=KU_15m; 
      KMR_15m=KM_15m;
      KDR_15m=KD_15m;

      for(  t =6; t>0; t--) R_15m[t]=R_15m[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_15m[0]=Resist_15m;

      Price_RSI7_R_15m=Close[0];                      //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_R_15m=Close[0];                     //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)

      if (R_15m[0]==R_15m[2])                     //przetasowanie w przypadku falszywej l.oporu
         {
            KUR_15m=KU_15m;
            KMR_15m=KM_15m;
            KDR_15m=KD_15m;

            for( t =1; t<=3; t++) R_15m[t]=R_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_15m[0]=Resist_15m;

            Price_RSI7_R_15m=Close[0];  //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
            Price_RSI14_R_15m=Close[0]; //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
        
            if (ticket_crit_for_sell2>0) ticket_crit_for_sell2 = ticket_crit_for_sell2-1;   // odjecie jednej flagi dla zlecenia sell z linia R ponizej ceny zakupu, skoro nowa R okazala sie falszywa
        
        }
 }  

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_support_15m()
{

      int t;      
         KUS_15m=KU_15m;
         KMS_15m=KM_15m;
         KDS_15m=KD_15m;
   
      for(  t =6; t>0; t--) S_15m[t]=S_15m[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_15m[0]=Support_15m;

      Price_RSI7_S_15m=Close[0];        // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_S_15m=Close[0];       // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
    
      if (S_15m[0]==S_15m[2])       // przetasowanie w przypadku falszywej l.wsparcia
        {
           for(  t =1; t<=3; t++) S_15m[t]=S_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
           S_15m[0]=Support_15m;
         
           Price_RSI7_S_15m=Close[0];   // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
           Price_RSI14_S_15m=Close[0];  // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_15m ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
   
           if (ticket_crit_for_buy2 >0) ticket_crit_for_buy2 = ticket_crit_for_buy2-1;   // odjecie jednej flagi dla zlecenia sell z linia S ponizej ceny zakupu, skoro nowa S okazala sie falszywa
     }
 }
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void save_keltner_resist_close_15m()
{
      int t;
      for( t =6; t>0; t--) KUR_c_15m[t]=KUR_c_15m[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUR_c_15m[0]=KU_15m;
      
      for( t =6; t>0; t--) KMR_c_15m[t]=KMR_c_15m[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMR_c_15m[0]=KM_15m;

      for(  t =6; t>0; t--) KDR_c_15m[t]=KDR_c_15m[t-1];    //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDR_c_15m[0]=KD_15m;

      //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
      RSI7_R_15m_Last = RSI7_R_15m; //zapamietanie aktualnej wart. RSI7_R_15m aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_S_15m_Last = RSI7_S_15m; //zapamietanie aktualnej wart. RSI7_S_15m aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_R_15m      = RSI7_max_15m(4);
      RSI14_R_15m     = RSI14_max_15m(4);

      HighRSI7_15m  = RSI7_R_15m - RSI7_S_15m;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_15m = RSI14_R_15m-RSI14_S_15m;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

      // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      R1_trendup=trendup2_rsi;
      R1_trenddn=trenddn2_rsi;
      R1_trendstp=trendstp2_rsi;

      for( t =6; t>0; t--) R_c_15m[t]=R_c_15m[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_c_15m[0]=Resist_C_15m;

      DoubleS_15m=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      if (R_c_15m[0]>R_c_15m[1] && R_c_15m[1]>KMR_c_15m[1] ) DoubleR_15m=DoubleR_15m+1;   //&& R_c_15m[1]>KMR_c_15m[1] licznik kolejnych R - wyzerowanie licznika w momencie nowej S

//--------"PRZETASOWANIE" w przypadku falszywej l.oporu--------------------------
      if (R_c_15m[0]==R_c_15m[2]) 
         {
            for(  t =1; t<=3; t++) KUR_c_15m[t]=KUR_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KUR_c_15m[0]=KU_15m;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KMR_c_15m[t]=KMR_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KMR_c_15m[0]=KM_15m;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KDR_c_15m[t]=KDR_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KDR_c_15m[0]=KD_15m;// czy to ma byc?

            for(  t =1; t<=3; t++) R_c_15m[t]=R_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_c_15m[0]=Resist_C_15m; // czy to ma byc?

          //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
            RSI7_R_15m  = RSI7_S_15m_Last;   //RSI7_max_15m(4);
            RSI14_R_15m = RSI14_R_15m_Last; //RSI14_max_15m(4);

            HighRSI7_15m  = RSI7_R_15m - RSI7_S_15m;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
            HighRSI14_15m = RSI14_R_15m- RSI14_S_15m;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

         // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
            R1_trendup=trendup2_rsi;
            R1_trenddn=trenddn2_rsi;
            R1_trendstp=trendstp2_rsi;

            DoubleR_15m=0;   //licznik kolejnych R - wyzerowanie licznika w momencie nowej S
            if (S_c_15m[0]<S_c_15m[1]&& S_c_15m[1]<KMS_c_15m[1])DoubleS_15m=DoubleS_15m+1;  // && S_c_15m[1]<KMS_c_15m[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
  
         }
 }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


void save_keltner_support_close_15m()
{
      int t;
      for( t =6; t>0; t--) KUS_c_15m[t]=KUS_c_15m[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUS_c_15m[0]=KU_15m;

      for( t =6; t>0; t--) KMS_c_15m[t]=KMS_c_15m[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMS_c_15m[0]=KM_15m;
      
      for( t =6; t>0; t--) KDS_c_15m[t]=KDS_c_15m[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDS_c_15m[0]=KD_15m;

   // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      S1_trendup = trendup2_rsi;
      S1_trenddn = trenddn2_rsi;
      S1_trendstp= trendstp2_rsi;

      RSI7_S_15m    = RSI7_Min_15m(4);
      RSI14_S_15m   = RSI14_Min_15m(4);
      HighRSI7_15m  = RSI7_R_15m - RSI7_S_15m;       // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_15m = RSI14_R_15m- RSI14_S_15m;      // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

      for( t =6; t>0; t--) S_c_15m[t]=S_c_15m[t-1]; // przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_c_15m[0]=Support_C_15m;

      if (S_c_15m[0]<S_c_15m[1]&& S_c_15m[1]<KMS_c_15m[1] ) DoubleS_15m=DoubleS_15m+1;  //&& S_c_15m[1]<KMS_c_15m[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      DoubleR_15m=0;                                 // licznik kolejnych R - wyzerowanie licznika w momencie nowej S

      if (S_c_15m[0]==S_c_15m[2])                    // "PRZETASOWANIE" w przypadku falszywej l.wsparcia
          {
               for(  t =1; t<=3; t++) KUS_c_15m[t]=KUS_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KUS_c_15m[0]=KU_15m;// czy to ma byc?

               for(  t =1; t<=3; t++) KMS_c_15m[t]=KMS_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KMS_c_15m[0]=KM_15m;// czy to ma byc?

               for(  t =1; t<=3; t++) KDS_c_15m[t]=KDS_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KDS_c_15m[0]=KD_15m;// czy to ma byc?

            // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
               S1_trendup=trendup2_rsi;
               S1_trenddn=trenddn2_rsi;
               S1_trendstp=trendstp2_rsi;

            // wybierz najmnizszy RSI sposrod RSI P1-3
               RSI7_S_15m = RSI7_S_15m_Last;  //RSI7_Min_15m(3);
               RSI14_S_15m= RSI14_S_15m_Last; //RSI14_Min_15m(3); 

               HighRSI7_15m  = RSI7_R_15m - RSI7_S_15m;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
               HighRSI14_15m = RSI14_R_15m-RSI14_S_15m;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

               for(  t =1; t<=3; t++) S_c_15m[t]=S_c_15m[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               S_c_15m[0]=Support_C_15m;

               DoubleS_15m=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
               if (R_c_15m[0]>R_c_15m[1] && R_c_15m[1]>KMR_c_15m[1])DoubleR_15m=DoubleR_15m+1;   //&& R_c_15m[1]>KMR_c_15m[1]  licznik kolejnych R - wyzerowanie licznika w momencie nowej S

           } 
} 
//---koniec save_keltner_support_close_15m-----------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_resist_1h()
 {
      int t;
    //zapamietanie wartosci kanalu ketlera w momencie wystapienia linii Resist, w celu porownania ich wzajemnych wart. dla wskaznika Barry_v5 (ver.bez close)
      KUR_1h=KU_1h; 
      KMR_1h=KM_1h;
      KDR_1h=KD_1h;

      for(  t =6; t>0; t--) R_1h[t]=R_1h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_1h[0]=Resist_1h;

      Price_RSI7_R_1h=Close[0];                      //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_R_1h=Close[0];                     //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)

      if (R_1h[0]==R_1h[2])                     //przetasowanie w przypadku falszywej l.oporu
         {
            KUR_1h=KU_1h;
            KMR_1h=KM_1h;
            KDR_1h=KD_1h;

            for( t =1; t<=3; t++) R_1h[t]=R_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_1h[0]=Resist_1h;

            Price_RSI7_R_1h=Close[0];  //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
            Price_RSI14_R_1h=Close[0]; //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
        }
 }  

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_support_1h()
{

      int t;      
         KUS_1h=KU_1h;
         KMS_1h=KM_1h;
         KDS_1h=KD_1h;
   
      for(  t =6; t>0; t--) S_1h[t]=S_1h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_1h[0]=Support_1h;

      Price_RSI7_S_1h=Close[0];        // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_S_1h=Close[0];       // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
    
      if (S_1h[0]==S_1h[2])       // przetasowanie w przypadku falszywej l.wsparcia
        {
           for(  t =1; t<=3; t++) S_1h[t]=S_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
           S_1h[0]=Support_1h;
         
           Price_RSI7_S_1h=Close[0];   // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
           Price_RSI14_S_1h=Close[0];  // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
     }
 }
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void save_keltner_resist_close_1h()
{     
      int t;
      for( t =6; t>0; t--) KUR_c_1h[t]=KUR_c_1h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUR_c_1h[0]=KU_1h;
      
      for( t =6; t>0; t--) KMR_c_1h[t]=KMR_c_1h[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMR_c_1h[0]=KM_1h;

      for(  t =6; t>0; t--) KDR_c_1h[t]=KDR_c_1h[t-1];    //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDR_c_1h[0]=KD_1h;

      //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
      RSI7_R_1h_Last = RSI7_R_1h; //zapamietanie aktualnej wart. RSI7_R_1h aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_S_1h_Last = RSI7_S_1h; //zapamietanie aktualnej wart. RSI7_S_1h aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_R_1h      = RSI7_max_1h(4);
      RSI14_R_1h     = RSI14_max_1h(4);

      HighRSI7_1h  = RSI7_R_1h - RSI7_S_1h;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_1h = RSI14_R_1h-RSI14_S_1h;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist
/* przerobic na odpowiednik 1h
      // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      R1_trendup=trendup2_rsi;
      R1_trenddn=trenddn2_rsi;
      R1_trendstp=trendstp2_rsi;
*/
      for( t =6; t>0; t--) R_c_1h[t]=R_c_1h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_c_1h[0]=Resist_C_1h;

      DoubleS_1h=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      if (R_c_1h[0]>R_c_1h[1] && R_c_1h[1]>KMR_c_1h[1] ) DoubleR_1h=DoubleR_1h+1;   //&& R_c_1h[1]>KMR_c_1h[1] licznik kolejnych R - wyzerowanie licznika w momencie nowej S

//--------"PRZETASOWANIE" w przypadku falszywej l.oporu--------------------------
      if (R_c_1h[0]==R_c_1h[2]) 
         {
            for(  t =1; t<=3; t++) KUR_c_1h[t]=KUR_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KUR_c_1h[0]=KU_1h;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KMR_c_1h[t]=KMR_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KMR_c_1h[0]=KM_1h;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KDR_c_1h[t]=KDR_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KDR_c_1h[0]=KD_1h;// czy to ma byc?

            for(  t =1; t<=3; t++) R_c_1h[t]=R_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_c_1h[0]=Resist_C_1h; // czy to ma byc?

          //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
            RSI7_R_1h  = RSI7_S_1h_Last;   //RSI7_max_1h(4);
            RSI14_R_1h = RSI14_R_1h_Last; //RSI14_max_1h(4);

            HighRSI7_1h  = RSI7_R_1h - RSI7_S_1h;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
            HighRSI14_1h = RSI14_R_1h- RSI14_S_1h;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist
/* przerobic na odpowiendik 1h
         // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
            R1_trendup=trendup2_rsi;
            R1_trenddn=trenddn2_rsi;
            R1_trendstp=trendstp2_rsi;
*/
            DoubleR_1h=0;   //licznik kolejnych R - wyzerowanie licznika w momencie nowej S
            if (S_c_1h[0]<S_c_1h[1]&& S_c_1h[1]<KMS_c_1h[1])DoubleS_1h=DoubleS_1h+1;  // && S_c_1h[1]<KMS_c_1h[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
  
         }
 }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


void save_keltner_support_close_1h()
{
      int t;
      for( t =6; t>0; t--) KUS_c_1h[t]=KUS_c_1h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUS_c_1h[0]=KU_1h;

      for( t =6; t>0; t--) KMS_c_1h[t]=KMS_c_1h[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMS_c_1h[0]=KM_1h;
      
      for( t =6; t>0; t--) KDS_c_1h[t]=KDS_c_1h[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDS_c_1h[0]=KD_1h;
/* przerobic na odpowiednik 1h
   // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      S1_trendup = trendup2_rsi;
      S1_trenddn = trenddn2_rsi;
      S1_trendstp= trendstp2_rsi;
*/
      RSI7_S_1h    = RSI7_Min_1h(4);
      RSI14_S_1h   = RSI14_Min_1h(4);
      HighRSI7_1h  = RSI7_R_1h - RSI7_S_1h;       // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_1h = RSI14_R_1h- RSI14_S_1h;      // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

      for( t =6; t>0; t--) S_c_1h[t]=S_c_1h[t-1]; // przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_c_1h[0]=Support_C_1h;

      if (S_c_1h[0]<S_c_1h[1]&& S_c_1h[1]<KMS_c_1h[1] ) DoubleS_1h=DoubleS_1h+1;  //&& S_c_1h[1]<KMS_c_1h[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      DoubleR_1h=0;                                 // licznik kolejnych R - wyzerowanie licznika w momencie nowej S

      if (S_c_1h[0]==S_c_1h[2])                    // "PRZETASOWANIE" w przypadku falszywej l.wsparcia
          {
               for(  t =1; t<=3; t++) KUS_c_1h[t]=KUS_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KUS_c_1h[0]=KU_1h;// czy to ma byc?

               for(  t =1; t<=3; t++) KMS_c_1h[t]=KMS_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KMS_c_1h[0]=KM_1h;// czy to ma byc?

               for(  t =1; t<=3; t++) KDS_c_1h[t]=KDS_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KDS_c_1h[0]=KD_1h;// czy to ma byc?
/* przerobic na odpowiednik 1h
            // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
               S1_trendup=trendup2_rsi;
               S1_trenddn=trenddn2_rsi;
               S1_trendstp=trendstp2_rsi;
*/
            // wybierz najmnizszy RSI sposrod RSI P1-3
               RSI7_S_1h = RSI7_S_1h_Last;  //RSI7_Min_1h(3);
               RSI14_S_1h= RSI14_S_1h_Last; //RSI14_Min_1h(3); 

               HighRSI7_1h  = RSI7_R_1h - RSI7_S_1h;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
               HighRSI14_1h = RSI14_R_1h-RSI14_S_1h;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

               for(  t =1; t<=3; t++) S_c_1h[t]=S_c_1h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               S_c_1h[0]=Support_C_1h;

               DoubleS_1h=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
               if (R_c_1h[0]>R_c_1h[1] && R_c_1h[1]>KMR_c_1h[1])DoubleR_1h=DoubleR_1h+1;   //&& R_c_1h[1]>KMR_c_1h[1]  licznik kolejnych R - wyzerowanie licznika w momencie nowej S

           } 
} 
//---koniec save_keltner_support_close_1h-----------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_resist_4h()
 {
      int t;
    //zapamietanie wartosci kanalu ketlera w momencie wystapienia linii Resist, w celu porownania ich wzajemnych wart. dla wskaznika Barry_v5 (ver.bez close)
      KUR_4h=KU_4h; 
      KMR_4h=KM_4h;
      KDR_4h=KD_4h;

      for(  t =6; t>0; t--) R_4h[t]=R_4h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_4h[0]=Resist_4h;

      Price_RSI7_R_4h=Close[0];                      //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_R_4h=Close[0];                     //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)

      if (R_4h[0]==R_4h[2])                     //przetasowanie w przypadku falszywej l.oporu
         {
            KUR_4h=KU_4h;
            KMR_4h=KM_4h;
            KDR_4h=KD_4h;

            for( t =1; t<=3; t++) R_4h[t]=R_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_4h[0]=Resist_4h;

            Price_RSI7_R_4h=Close[0];  //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
            Price_RSI14_R_4h=Close[0]; //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
        }
 }  

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_support_4h()
{

      int t;      
         KUS_4h=KU_4h;
         KMS_4h=KM_4h;
         KDS_4h=KD_4h;
   
      for(  t =6; t>0; t--) S_4h[t]=S_4h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_4h[0]=Support_4h;

      Price_RSI7_S_4h=Close[0];        // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_S_4h=Close[0];       // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
    
      if (S_4h[0]==S_4h[2])       // przetasowanie w przypadku falszywej l.wsparcia
        {
           for(  t =1; t<=3; t++) S_4h[t]=S_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
           S_4h[0]=Support_4h;
         
           Price_RSI7_S_4h=Close[0];   // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
           Price_RSI14_S_4h=Close[0];  // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_4h ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
     }
 }
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void save_keltner_resist_close_4h()
{
      int t;
      for( t =6; t>0; t--) KUR_c_4h[t]=KUR_c_4h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUR_c_4h[0]=KU_4h;
      
      for( t =6; t>0; t--) KMR_c_4h[t]=KMR_c_4h[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMR_c_4h[0]=KM_4h;

      for(  t =6; t>0; t--) KDR_c_4h[t]=KDR_c_4h[t-1];    //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDR_c_4h[0]=KD_4h;

      //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
      RSI7_R_4h_Last = RSI7_R_4h; //zapamietanie aktualnej wart. RSI7_R_4h aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_S_4h_Last = RSI7_S_4h; //zapamietanie aktualnej wart. RSI7_S_4h aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_R_4h      = RSI7_max_4h(4);
      RSI14_R_4h     = RSI14_max_4h(4);

      HighRSI7_4h  = RSI7_R_4h - RSI7_S_4h;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_4h = RSI14_R_4h-RSI14_S_4h;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist
/* przerobic na odpowiednik 4h
      // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      R1_trendup=trendup2_rsi;
      R1_trenddn=trenddn2_rsi;
      R1_trendstp=trendstp2_rsi;
*/
      for( t =6; t>0; t--) R_c_4h[t]=R_c_4h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_c_4h[0]=Resist_C_4h;

      DoubleS_4h=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      if (R_c_4h[0]>R_c_4h[1] && R_c_4h[1]>KMR_c_4h[1] ) DoubleR_4h=DoubleR_4h+1;   //&& R_c_4h[1]>KMR_c_4h[1] licznik kolejnych R - wyzerowanie licznika w momencie nowej S

//--------"PRZETASOWANIE" w przypadku falszywej l.oporu--------------------------
      if (R_c_4h[0]==R_c_4h[2]) 
         {
            for(  t =1; t<=3; t++) KUR_c_4h[t]=KUR_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KUR_c_4h[0]=KU_4h;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KMR_c_4h[t]=KMR_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KMR_c_4h[0]=KM_4h;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KDR_c_4h[t]=KDR_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KDR_c_4h[0]=KD_4h;// czy to ma byc?

            for(  t =1; t<=3; t++) R_c_4h[t]=R_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_c_4h[0]=Resist_C_4h; // czy to ma byc?

          //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
            RSI7_R_4h  = RSI7_S_4h_Last;   //RSI7_max_4h(4);
            RSI14_R_4h = RSI14_R_4h_Last; //RSI14_max_4h(4);

            HighRSI7_4h  = RSI7_R_4h - RSI7_S_4h;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
            HighRSI14_4h = RSI14_R_4h- RSI14_S_4h;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist
/* przerobic na odpowiednik 4h
         // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
            R1_trendup=trendup2_rsi;
            R1_trenddn=trenddn2_rsi;
            R1_trendstp=trendstp2_rsi;
*/
            DoubleR_4h=0;   //licznik kolejnych R - wyzerowanie licznika w momencie nowej S
            if (S_c_4h[0]<S_c_4h[1]&& S_c_4h[1]<KMS_c_4h[1])DoubleS_4h=DoubleS_4h+1;  // && S_c_4h[1]<KMS_c_4h[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
  
         }
 }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


void save_keltner_support_close_4h()
{
      int t;
      for( t =6; t>0; t--) KUS_c_4h[t]=KUS_c_4h[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUS_c_4h[0]=KU_4h;

      for( t =6; t>0; t--) KMS_c_4h[t]=KMS_c_4h[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMS_c_4h[0]=KM_4h;
      
      for( t =6; t>0; t--) KDS_c_4h[t]=KDS_c_4h[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDS_c_4h[0]=KD_4h;

/* przerobic na odpowiednik 4h
   // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      S1_trendup = trendup2_rsi;
      S1_trenddn = trenddn2_rsi;
      S1_trendstp= trendstp2_rsi;
*/
      RSI7_S_4h    = RSI7_Min_4h(4);
      RSI14_S_4h   = RSI14_Min_4h(4);
      HighRSI7_4h  = RSI7_R_4h - RSI7_S_4h;       // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_4h = RSI14_R_4h- RSI14_S_4h;      // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

      for( t =6; t>0; t--) S_c_4h[t]=S_c_4h[t-1]; // przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_c_4h[0]=Support_C_4h;

      if (S_c_4h[0]<S_c_4h[1]&& S_c_4h[1]<KMS_c_4h[1] ) DoubleS_4h=DoubleS_4h+1;  //&& S_c_4h[1]<KMS_c_4h[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      DoubleR_4h=0;                                 // licznik kolejnych R - wyzerowanie licznika w momencie nowej S

      if (S_c_4h[0]==S_c_4h[2])                    // "PRZETASOWANIE" w przypadku falszywej l.wsparcia
          {
               for(  t =1; t<=3; t++) KUS_c_4h[t]=KUS_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KUS_c_4h[0]=KU_4h;// czy to ma byc?

               for(  t =1; t<=3; t++) KMS_c_4h[t]=KMS_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KMS_c_4h[0]=KM_4h;// czy to ma byc?

               for(  t =1; t<=3; t++) KDS_c_4h[t]=KDS_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KDS_c_4h[0]=KD_4h;// czy to ma byc?
/* przerobic na odpowiednik 4h
            // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
               S1_trendup=trendup2_rsi;
               S1_trenddn=trenddn2_rsi;
               S1_trendstp=trendstp2_rsi;
*/ 
            // wybierz najmnizszy RSI sposrod RSI P1-3
               RSI7_S_4h = RSI7_S_4h_Last;  //RSI7_Min_4h(3);
               RSI14_S_4h= RSI14_S_4h_Last; //RSI14_Min_4h(3); 

               HighRSI7_4h  = RSI7_R_4h - RSI7_S_4h;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
               HighRSI14_4h = RSI14_R_4h-RSI14_S_4h;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

               for(  t =1; t<=3; t++) S_c_4h[t]=S_c_4h[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               S_c_4h[0]=Support_C_4h;

               DoubleS_4h=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
               if (R_c_4h[0]>R_c_4h[1] && R_c_4h[1]>KMR_c_4h[1])DoubleR_4h=DoubleR_4h+1;   //&& R_c_4h[1]>KMR_c_4h[1]  licznik kolejnych R - wyzerowanie licznika w momencie nowej S

           } 
} 
//---koniec save_keltner_support_close_4h-----------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_resist_1d()
 {
      int t;
    //zapamietanie wartosci kanalu ketlera w momencie wystapienia linii Resist, w celu porownania ich wzajemnych wart. dla wskaznika Barry_v5 (ver.bez close)
      KUR_1d=KU_1d; 
      KMR_1d=KM_1d;
      KDR_1d=KD_1d;

      for(  t =6; t>0; t--) R_1d[t]=R_1d[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_1d[0]=Resist_1d;

      Price_RSI7_R_1d=Close[0];                      //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_R_1d=Close[0];                     //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)

      if (R_1d[0]==R_1d[2])                     //przetasowanie w przypadku falszywej l.oporu
         {
            KUR_1d=KU_1d;
            KMR_1d=KM_1d;
            KDR_1d=KD_1d;

            for( t =1; t<=3; t++) R_1d[t]=R_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_1d[0]=Resist_1d;

            Price_RSI7_R_1d=Close[0];  //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
            Price_RSI14_R_1d=Close[0]; //zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
        }
 }  

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void save_keltner_support_1d()
{

      int t;      
         KUS_1d=KU_1d;
         KMS_1d=KM_1d;
         KDS_1d=KD_1d;
   
      for(  t =6; t>0; t--) S_1d[t]=S_1d[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_1d[0]=Support_1d;

      Price_RSI7_S_1d=Close[0];        // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
      Price_RSI14_S_1d=Close[0];       // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
    
      if (S_1d[0]==S_1d[2])       // przetasowanie w przypadku falszywej l.wsparcia
        {
           for(  t =1; t<=3; t++) S_1d[t]=S_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
           S_1d[0]=Support_1d;
         
           Price_RSI7_S_1d=Close[0];   // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
           Price_RSI14_S_1d=Close[0];  // zapamietanie ceny w momecie wystapienia S/R w wersji Close(aby okresliæ czy HighRSI7_1d ma pozwolic na Buy czy Sell, w zaleznosci do ktorej ceny bedzie mial blizej)
     }
 }
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void save_keltner_resist_close_1d()
{     
      int t;
      for( t =6; t>0; t--) KUR_c_1d[t]=KUR_c_1d[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUR_c_1d[0]=KU_1d;
      
      for( t =6; t>0; t--) KMR_c_1d[t]=KMR_c_1d[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMR_c_1d[0]=KM_1d;

      for(  t =6; t>0; t--) KDR_c_1d[t]=KDR_c_1d[t-1];    //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDR_c_1d[0]=KD_1d;

      //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
      RSI7_R_1d_Last = RSI7_R_1d; //zapamietanie aktualnej wart. RSI7_R_1d aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_S_1d_Last = RSI7_S_1d; //zapamietanie aktualnej wart. RSI7_S_1d aby mieæ moz³iwoœc przywrócenia jej w przypadku wystapienia fa³eszywej linii S/R
      RSI7_R_1d      = RSI7_max_1d(4);
      RSI14_R_1d     = RSI14_max_1d(4);

      HighRSI7_1d  = RSI7_R_1d - RSI7_S_1d;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_1d = RSI14_R_1d-RSI14_S_1d;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist
/* przerobic na odpowiednik 1d
      // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      R1_trendup=trendup2_rsi;
      R1_trenddn=trenddn2_rsi;
      R1_trendstp=trendstp2_rsi;
*/
      for( t =6; t>0; t--) R_c_1d[t]=R_c_1d[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      R_c_1d[0]=Resist_C_1d;

      DoubleS_1d=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      if (R_c_1d[0]>R_c_1d[1] && R_c_1d[1]>KMR_c_1d[1] ) DoubleR_1d=DoubleR_1d+1;   //&& R_c_1d[1]>KMR_c_1d[1] licznik kolejnych R - wyzerowanie licznika w momencie nowej S

//--------"PRZETASOWANIE" w przypadku falszywej l.oporu--------------------------
      if (R_c_1d[0]==R_c_1d[2]) 
         {
            for(  t =1; t<=3; t++) KUR_c_1d[t]=KUR_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KUR_c_1d[0]=KU_1d;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KMR_c_1d[t]=KMR_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KMR_c_1d[0]=KM_1d;// czy to ma byc?
 
            for(  t =1; t<=3; t++) KDR_c_1d[t]=KDR_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            KDR_c_1d[0]=KD_1d;// czy to ma byc?

            for(  t =1; t<=3; t++) R_c_1d[t]=R_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
            R_c_1d[0]=Resist_C_1d; // czy to ma byc?

          //zapamietanie poziomu RSI w momencie wystapienia S/R w wersji Close
            RSI7_R_1d  = RSI7_S_1d_Last;   //RSI7_max_1d(4);
            RSI14_R_1d = RSI14_R_1d_Last; //RSI14_max_1d(4);

            HighRSI7_1d  = RSI7_R_1d - RSI7_S_1d;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
            HighRSI14_1d = RSI14_R_1d- RSI14_S_1d;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist
/* przerobic na odpowiednik 1d
         // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
            R1_trendup=trendup2_rsi;
            R1_trenddn=trenddn2_rsi;
            R1_trendstp=trendstp2_rsi;
*/
            DoubleR_1d=0;   //licznik kolejnych R - wyzerowanie licznika w momencie nowej S
            if (S_c_1d[0]<S_c_1d[1]&& S_c_1d[1]<KMS_c_1d[1])DoubleS_1d=DoubleS_1d+1;  // && S_c_1d[1]<KMS_c_1d[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
  
         }
 }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


void save_keltner_support_close_1d()
{
      int t;
      for( t =6; t>0; t--) KUS_c_1d[t]=KUS_c_1d[t-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KUS_c_1d[0]=KU_1d;

      for( t =6; t>0; t--) KMS_c_1d[t]=KMS_c_1d[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KMS_c_1d[0]=KM_1d;
      
      for( t =6; t>0; t--) KDS_c_1d[t]=KDS_c_1d[t-1];     //przesuniecie wszystkich wartosci tablicy o 1 pozycje
      KDS_c_1d[0]=KD_1d;
/* przerobic na odpowiednik 1d
   // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
      S1_trendup = trendup2_rsi;
      S1_trenddn = trenddn2_rsi;
      S1_trendstp= trendstp2_rsi;
*/
      RSI7_S_1d    = RSI7_Min_1d(4);
      RSI14_S_1d   = RSI14_Min_1d(4);
      HighRSI7_1d  = RSI7_R_1d - RSI7_S_1d;       // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
      HighRSI14_1d = RSI14_R_1d- RSI14_S_1d;      // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

      for( t =6; t>0; t--) S_c_1d[t]=S_c_1d[t-1]; // przesuniecie wszystkich wartosci tablicy o 1 pozycje
      S_c_1d[0]=Support_C_1d;

      if (S_c_1d[0]<S_c_1d[1]&& S_c_1d[1]<KMS_c_1d[1] ) DoubleS_1d=DoubleS_1d+1;  //&& S_c_1d[1]<KMS_c_1d[1] licznik kolejnych S - zwiekszenie licznika w momencie nowej S
      DoubleR_1d=0;                                 // licznik kolejnych R - wyzerowanie licznika w momencie nowej S

      if (S_c_1d[0]==S_c_1d[2])                    // "PRZETASOWANIE" w przypadku falszywej l.wsparcia
          {
               for(  t =1; t<=3; t++) KUS_c_1d[t]=KUS_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KUS_c_1d[0]=KU_1d;// czy to ma byc?

               for(  t =1; t<=3; t++) KMS_c_1d[t]=KMS_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KMS_c_1d[0]=KM_1d;// czy to ma byc?

               for(  t =1; t<=3; t++) KDS_c_1d[t]=KDS_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               KDS_c_1d[0]=KD_1d;// czy to ma byc?
/* przerobic na odpowiednik 1d
            // zapamietanie wartosci ze wskaznika SW_hull w momencie tworzenia S/R (ustalenie sily trendu)
               S1_trendup=trendup2_rsi;
               S1_trenddn=trenddn2_rsi;
               S1_trendstp=trendstp2_rsi;
*/
            // wybierz najmnizszy RSI sposrod RSI P1-3
               RSI7_S_1d = RSI7_S_1d_Last;  //RSI7_Min_1d(3);
               RSI14_S_1d= RSI14_S_1d_Last; //RSI14_Min_1d(3); 

               HighRSI7_1d  = RSI7_R_1d - RSI7_S_1d;  // wyznaczenie roznicy RSI(7) pomiedzy ostatnia linia Support a Resist
               HighRSI14_1d = RSI14_R_1d-RSI14_S_1d;  // wyznaczenie roznicy RSI(14) pomiedzy ostatnia linia Support a Resist

               for(  t =1; t<=3; t++) S_c_1d[t]=S_c_1d[t+2]; //przesuniecie wszystkich wartosci tablicy o 2 pozycje (bo pojawil sie nowy S, a stary zostal przesuniety o 1, a pozniej znowu wrocil do starego S, wiec trzeba cofnac sie o dwie.
               S_c_1d[0]=Support_C_1d;

               DoubleS_1d=0;  //licznik kolejnych S - zwiekszenie licznika w momencie nowej S
               if (R_c_1d[0]>R_c_1d[1] && R_c_1d[1]>KMR_c_1d[1])DoubleR_1d=DoubleR_1d+1;   //&& R_c_1d[1]>KMR_c_1d[1]  licznik kolejnych R - wyzerowanie licznika w momencie nowej S

           } 
} 
//---koniec save_keltner_support_close_1d-----------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





// ====================================================================================
//                            FUNKCJE SPRAWDZAJ¥CE RODZAJ TRENDU 
// ------------------------------------------------------------------------------------
//       ##################### T R E N D   B O C Z N Y  M15 ##################
// ------------------------------------------------------------------------------------
//zweryfikowac czy mozna uzywac KM?(odp. tylko w odniesieniu do Biezacych wart np. Close0)


int spr_trend_boczny_15m()
{
    
if (( S_c_15m[0]<KMS_c_15m[0] && R_c_15m[0]>KMR_c_15m[0] && Close[0]>KM_15m )//#&& DoubleS_15m==0 && DoubleR_15m==0 //// jezeli Support1 jest mniejszy od Srodkowej a Resist1 powyzej
   ||(S_c_15m[0]<KMS_c_15m[0] && R_c_15m[0]>KMR_c_15m[0] && Close[0]<KM_15m )//#&& DoubleR_15m==0 && DoubleS_15m==0 //
     
   //||(S_c_15m[0]>KMS_c_15m[0] && R_c_15m[0]<KMR_c_15m[0] && DoubleR_15m==0)//&& DoubleR_15m==0 jezeli Support jest powyzej Srodkowej a Resist ponizej
   //# czy uwzglednic wystapienie formacji rosnacej w trendzie malejacym i odwrotnie? (wymusic boczny) 
   // zamiana w czterech ponizszych z KM na KU?
   ||(Close[0] <KM_15m && line_3r_up_15m==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] <KM_15m && line_3s_up_15m==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Support dla trendu malejacego
   ||(Close[0] >KM_15m && line_3r_dn_15m==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] >KM_15m && line_3s_dn_15m==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Support dla trendu malejacego

   //dodano close0
   ||(hak_r_dn_15m==1 && Close[0]<KM_15m && R_c_15m[2]<KMR_c_15m[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Resist_C_15m,  ale R3 ma byc juz ponizej KM z uwagi na charakterystyke trendu rosnacego/malejacego wzgledem keltera
   ||(hak_s_dn_15m==1 && Close[0]<KM_15m && S_c_15m[2]<KMS_c_15m[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Support_C_15m, ale S3 ma byc juz ponizej KM
   ||(hak_r_up_15m==1 && Close[0]>KM_15m && R_c_15m[2]>KMR_c_15m[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Resist_C_15m,  ale R3 ma byc juz powyzej KM
   ||(hak_s_up_15m==1 && Close[0]>KM_15m && S_c_15m[2]>KMS_c_15m[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Support_C_15m, ale S3 ma byc juz powyzej KM 

   ||(hak_r_dn_15m==1 && R_c_15m[0]<KDR_c_15m[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Resist_C_15m
   ||(hak_s_dn_15m==1 && S_c_15m[0]<KDS_c_15m[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Support_C_15m
   ||(hak_r_up_15m==1 && R_c_15m[0]>KUR_c_15m[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Resist_C_15m
   ||(hak_s_up_15m==1 && S_c_15m[0]>KUS_c_15m[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Support_C_15m
  
   ||(S_c_15m[0]>S_c_15m[1] && S_15m[0]>KMS_c_15m[0] && S_15m[1] < KMS_c_15m[1] && R_c_15m[0] < S_c_15m[0] && Close[0]<KU_15m && Close[0]<S_c_15m[0]) //odwrotnosc S/R w jednej polowce kanalu gornego tzn gdy to S1 jest wieksze od R1 (R1>S1 powyzej KM oznaczaloby ze jest tr. gorny). war. tylko w t.bocznym(screen przypadek1)
   ||(R_c_15m[0]<R_c_15m[1] && R_15m[0]<KMR_c_15m[0] && R_15m[1] > KMR_c_15m[1] && S_c_15m[0] > R_c_15m[0] && Close[0]>KD_15m && Close[0]>R_c_15m[0]) //odwrotnosc S/R w jednej polowce kanalu dolnego tzn gdy to R1 jest wieksze od S1 (R1>S1 ponizej KM oznaczaloby ze jest tr. dolny). war. tylko w t.bocznym(screen przypadek1)
   ||(S_c_15m[0]>KMS_c_15m[0] && R_c_15m[0]>KMR_c_15m[0] && Close[0]<KM_15m)  // jezeli S/R jest powyzej Srdokowej linii, a Close0 jest juz ponizej //z powodu tego war. jest dod. if
   ||(S_c_15m[0]<KMS_c_15m[0] && R_c_15m[0]<KMR_c_15m[0] && Close[0]>KM_15m)) // jezeli S/R jest poni¿ej Srodkowej linii, a Close0 jest ju¿ powy¿ej //z powodu tego war. jest dod. if
    {
      //ponizej warunek wykluczaj¹cy trend boczny z wieloma wyj¹tkami
      if (((Close[0]>KD_15m && Close[0]<KU_15m)                         // odfiltruj Boczny gdy Close0 jest ponizej dolnej linii i powyzej gornej(ZWERYFIKOWAC!)
        ||(hak_r_dn_15m==1 && Close[0]<KM_15m && Close[0]>KD_15m)         // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war. (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_15m)
        ||(hak_s_dn_15m==1 && Close[0]<KM_15m && Close[0]>KD_15m)         // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war  (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_15m
        ||(hak_r_up_15m==1 && Close[0]>KM_15m && Close[0]<KU_15m)         // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_15m
        ||(hak_s_up_15m==1 && Close[0]>KM_15m && Close[0]<KU_15m)         // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_15m
        ||(hak_r_dn_15m==1 && R_c_15m[0]<KDR_c_15m[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_15m
        ||(hak_s_dn_15m==1 && S_c_15m[0]<KDS_c_15m[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_15m
        ||(hak_r_up_15m==1 && R_c_15m[0]>KUR_c_15m[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_15m
        ||(hak_s_up_15m==1 && S_c_15m[0]>KUS_c_15m[0]))          // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_15m

        //ponizej warunki wykluczaj¹ce trend boczny
        && (!(DoubleS_15m>0 && R_c_15m[0]>KMR_c_15m[0] && S_c_15m[0]<KMS_c_15m[0] && Close[0]<KM_15m))
        && (!(DoubleR_15m>0 && S_c_15m[0]<KMS_c_15m[0] && R_c_15m[0]>KMR_c_15m[0] && Close[0]>KM_15m)))
         {
          rtrend_15m=0;
         }  
     }
 return(rtrend_15m);
}  


// ##----------------------------------------------------------------------
// #####################   T R E N D    R O S N ¥ C Y   M15 ##################
// ##----------------------------------------------------------------------
// ## SIGNAL BUY

 
int spr_trend_rosnacy_15m()
{
if ((S_c_15m[0]>KMS_c_15m[0] && R_c_15m[0]>KMR_c_15m[0] && Close[0]>KM_15m) //jezeli Support, Resist i Close0 s¹ powyzej srodkowej linii
  || (Close[0]>KU_15m) //jesli Close0 jest wiekszy od gornej linii
 // te dwa ponizsze sa sprzeczne z warunkami w trendzie bocznym (z podowu ktorych wstawiony jest tam dod. if)
 // || ( line_3s_dn_15m==1 && Close[0]>KU_15m) //  jesli formacja Support dla trendu dolnego ale przekracza gorna linie
 // || ( line_3r_dn_15m==1 && Close[0]>KU_15m) //  jesli formacja Resist  dla trendu dolnego ale przekracza gorna linie
 // ten ponizej war. chyba zostawic jesli wbocznym bedzie wl. war z badaniem podwojnych S i R
    || (DoubleR_15m>0 && S_c_15m[0]<KMS_c_15m[0] && R_c_15m[0]>KMR_c_15m[0] && Close[0]>KM_15m))  //jezeli SR sa pomiedzy Srodkowa, ale wystapila podwojna R i cena przekracza Srodkowa
  if (!rtrend_15m==0)  rtrend_15m=1;  
  /* 
   {
   if (Close[0]>KD_15m) // odfiltruj Rosnacy gdy Close0 jest mniejszy od dolnej linii 
    { 
    //  if (!rtrend_15m==0 | rtrend_15m ==2)  rtrend_15m=1;

       if (!(line_3s_dn_15m==1 && S_c_15m[0]>KMS_c_15m[0] && Close[0]<KU_15m))// nie uznawaj t. rosnacego gdy zawiera formacje Support dla trendu dolnego o ile nie przekracza gornej linii (bedzie to traktowane jako t. boczny) 
       if (!(line_3r_dn_15m==1 && R_c_15m[0]>KMR_c_15m[0] && Close[0]<KU_15m)) // nie uznawaj t. rosnacego gdy zawiera formacje Resist dla trendu dolnego o ile nie przekracza gornej linii (bedzie zaliczony jako boczny)
        //dodano close0
       if (!(hak_r_up_15m==1 && Close[0]>KM_15m && Close[0]<KU_15m && R_c_15m[2]>KMR_c_15m[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist w kanale(bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_15m==1 && Close[0]>KM_15m && Close[0]<KU_15m && S_c_15m[2]>KMS_c_15m[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support w kanale (bedzie zaliczone jako trend boczny)
       if (!(hak_r_up_15m==1 && R_c_15m[0]>KU_15m)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist poza kanalem (bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_15m==1 && S_c_15m[0]>KU_15m)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support poza kanalem  (bedzie zaliczone jako trend boczny)
       rtrend_15m=1;
     }
   }
*/
return (rtrend_15m);
}
// koniec spr trendu rosnacego

// =============================================================================================================================================

// ##-----------------------------------------------------------------------
// #####################   T R E N D    M A L E J ¥ C Y  M15 ##################
// ##-----------------------------------------------------------------------


int spr_trend_malejacy_15m()
{
  if ((S_c_15m[0]<KMS_c_15m[0] && R_c_15m[0]<KMR_c_15m[0] && Close[0]<KM_15m)               // jezeli Support, Resist i Close0 s¹ ponizej srodkowej linii
  || (Close[0]<KD_15m)                                                                      // jesli Close0 jest mniejszy od dolnej linii
//  || (line_3s_up_15m==1 && Close[0]<KD)                                                   // jesli formacja Support dla trendu rosnacego ale przekracza dolna linie //sprzeczne z  war. w tr. bocznym
//  || (line_3r_up_15m==1 && Close[0]<KD)                                                   // jesli formacja Resist  dla trendu rosnacego ale przekracza dolna linie
    || (DoubleS_15m>0 && R_c_15m[0]>KMR_c_15m[0] && S_c_15m[0]<KMS_c_15m[0] && Close[0]<KM_15m)) // jezeli linie SR sa pomiédzy Srodkowa,cena ponizej,  wystapila podwojna S, a Cena jest poni¿ej œrodkowej
 
  if (!(rtrend_15m==0)) rtrend_15m=2; 
/*
  { //Print ("WSZEDL DOLNY1---------------------------------");
   if (Close[0]<KU_15m )// odfiltruj Malejacy gdy Close0 jest wiekszy od gornej linii
    {
 //   if (!(rtrend_15m==0 || rtrend_15m==1)) rtrend_15m=2;

      if (!(line_3s_up_15m==1 && S_c_15m[0]<KMS_c_15m[0] && Close[0]>KD_15m))               //nie uznawaj t. malejacego gdy zawiera formacje Support dla trendu rosnacego (bedzie zaliczony jako boczny)
      if (!(line_3r_up_15m==1 && R_c_15m[0]<KMR_c_15m[0] && Close[0]>KD_15m))               //nie uznawaj t. malejacego gdy zawiera formacje Resist dla trendu rosnacego (bedzie zaliczony jako boczny)
      //dodano close0
      if (!(hak_s_dn_15m==1 && Close[0]<KM_15m && Close[0]>KD && S_c_15m[2]<KMS_c_15m[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support w kanale(bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_15m==1 && Close[0]<KM_15m && Close[0]>KD && R_c_15m[2]<KMR_c_15m[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist w kanale (bedzie zaliczone jako trend boczny)
      if (!(hak_s_dn_15m==1 && S_c_15m[0]<KDS_c_15m[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support poza kanalem (bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_15m==1 && R_c_15m[0]<KDR_c_15m[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist poza kanalem (bedzie zaliczone jako trend boczny)
      rtrend_15m=2; //Ustaawienie statusu trendu jako malejacy
   }
}
*/
 return (rtrend_15m);
} //koniec spr trendu malejacego


// ------------------------------------------------------------------------------------
//       ##################### T R E N D   B O C Z N Y  1H ##################
// ------------------------------------------------------------------------------------
//zweryfikowac czy mozna uzywac KM?(odp. tylko w odniesieniu do Biezacych wart np. Close0)


int spr_trend_boczny_1h()
{
    
if (( S_c_1h[0]<KMS_c_1h[0] && R_c_1h[0]>KMR_c_1h[0] && Close[0]>KM_1h )//#&& DoubleS_1h==0 && DoubleR_1h==0 //// jezeli Support1 jest mniejszy od Srodkowej a Resist1 powyzej
   ||(S_c_1h[0]<KMS_c_1h[0] && R_c_1h[0]>KMR_c_1h[0] && Close[0]<KM_1h )//#&& DoubleR_1h==0 && DoubleS_1h==0 //
     
   //||(S_c_1h[0]>KMS_c_1h[0] && R_c_1h[0]<KMR_c_1h[0] && DoubleR_1h==0)//&& DoubleR_1h==0 jezeli Support jest powyzej Srodkowej a Support ponizej
   //# czy uwzglednic wystapienie formacji rosnacej w trendzie malejacym i odwrotnie? (wymusic boczny) 
   // zamiana w czterech ponizszych z KM na KU?
   ||(Close[0] <KM_1h && line_3r_up_1h==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] <KM_1h && line_3s_up_1h==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Support dla trendu malejacego
   ||(Close[0] >KM_1h && line_3r_dn_1h==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] >KM_1h && line_3s_dn_1h==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Support dla trendu malejacego

   //dodano close0
   ||(hak_r_dn_1h==1 && Close[0]<KM_1h && R_c_1h[2]<KMR_c_1h[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Resist_C_1h,  ale R3 ma byc juz ponizej KM z uwagi na charakterystyke trendu rosnacego/malejacego wzgledem keltera
   ||(hak_s_dn_1h==1 && Close[0]<KM_1h && S_c_1h[2]<KMS_c_1h[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Support_C_1h, ale S3 ma byc juz ponizej KM
   ||(hak_r_up_1h==1 && Close[0]>KM_1h && R_c_1h[2]>KMR_c_1h[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Resist_C_1h,  ale R3 ma byc juz powyzej KM
   ||(hak_s_up_1h==1 && Close[0]>KM_1h && S_c_1h[2]>KMS_c_1h[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Support_C_1h, ale S3 ma byc juz powyzej KM 

   ||(hak_r_dn_1h==1 && R_c_1h[0]<KDR_c_1h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Resist_C_1h
   ||(hak_s_dn_1h==1 && S_c_1h[0]<KDS_c_1h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Support_C_1h
   ||(hak_r_up_1h==1 && R_c_1h[0]>KUR_c_1h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Resist_C_1h
   ||(hak_s_up_1h==1 && S_c_1h[0]>KUS_c_1h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Support_C_1h
  
   ||(S_c_1h[0]>S_c_1h[1] && S_1h[0]>KMS_c_1h[0] && S_1h[1] < KMS_c_1h[1] && R_c_1h[0] < S_c_1h[0] && Close[0]<KU_1h && Close[0]<S_c_1h[0]) //odwrotnosc S/R w jednej polowce kanalu gornego tzn gdy to S1 jest wieksze od R1 (R1>S1 powyzej KM oznaczaloby ze jest tr. gorny). war. tylko w t.bocznym(screen przypadek1)
   ||(R_c_1h[0]<R_c_1h[1] && R_1h[0]<KMR_c_1h[0] && R_1h[1] > KMR_c_1h[1] && S_c_1h[0] > R_c_1h[0] && Close[0]>KD_1h && Close[0]>R_c_1h[0]) //odwrotnosc S/R w jednej polowce kanalu dolnego tzn gdy to R1 jest wieksze od S1 (R1>S1 ponizej KM oznaczaloby ze jest tr. dolny). war. tylko w t.bocznym(screen przypadek1)
 
   ||(S_c_1h[0]>KMS_c_1h[0] && R_c_1h[0]>KMR_c_1h[0] && Close[0]<KM_1h)  // jezeli S/R jest powyzej Srdokowej linii, a Close0 jest juz ponizej //z powodu tego war. jest dod. if
   ||(S_c_1h[0]<KMS_c_1h[0] && R_c_1h[0]<KMR_c_1h[0] && Close[0]>KM_1h)) // jezeli S/R jest poni¿ej Srodkowej linii, a Close0 jest ju¿ powy¿ej //z powodu tego war. jest dod. if
    {
      //ponizej warunki wykluczaj¹ce trend boczny z wieloma wyj¹tkami
      if (((Close[0]>KD_1h && Close[0]<KU_1h)                         // odfiltruj Boczny gdy Close0 jest ponizej dolnej linii i powyzej gornej(ZWERYFIKOWAC!)
        ||(hak_r_dn_1h==1 && Close[0]<KM_1h && Close[0]>KD_1h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war. (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_1h)
        ||(hak_s_dn_1h==1 && Close[0]<KM_1h && Close[0]>KD_1h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war  (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_1h
        ||(hak_r_up_1h==1 && Close[0]>KM_1h && Close[0]<KU_1h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_1h
        ||(hak_s_up_1h==1 && Close[0]>KM_1h && Close[0]<KU_1h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_1h
        ||(hak_r_dn_1h==1 && R_c_1h[0]<KDR_c_1h[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_1h
        ||(hak_s_dn_1h==1 && S_c_1h[0]<KDS_c_1h[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_1h
        ||(hak_r_up_1h==1 && R_c_1h[0]>KUR_c_1h[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_1h
        ||(hak_s_up_1h==1 && S_c_1h[0]>KUS_c_1h[0]))           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_1h
        //ponizej warunki wykluczaj¹ce trend boczny
      && (!(DoubleS_1h>0 && R_c_1h[0]>KMR_c_1h[0] && S_c_1h[0]<KMS_c_1h[0] && Close[0]<KM_1h))
      && (!(DoubleR_1h>0 && S_c_1h[0]<KMS_c_1h[0] && R_c_1h[0]>KMR_c_1h[0] && Close[0]>KM_1h)))
         {
          rtrend_1h=0;
         }  
     }
 return(rtrend_1h);
}  


// ##----------------------------------------------------------------------
// #####################   T R E N D    R O S N ¥ C Y  1H  ##################
// ##----------------------------------------------------------------------
// ## SIGNAL BUY

 
int spr_trend_rosnacy_1h()
{
if ((S_c_1h[0]>KMS_c_1h[0] && R_c_1h[0]>KMR_c_1h[0] && Close[0]>KM_1h) //jezeli Support, Resist i Close0 s¹ powyzej srodkowej linii
  || (Close[0]>KU_1h) //jesli Close0 jest wiekszy od gornej linii
  // te dwa ponizsze sa sprzeczne z warunkami w trendzie bocznym (z podowu ktorych wstawiony jest tam dod. if)
 // || ( line_3s_dn_1h==1 && Close[0]>KU_1h) //  jesli formacja Support dla trendu dolnego ale przekracza gorna linie
 // || ( line_3r_dn_1h==1 && Close[0]>KU_1h) //  jesli formacja Resist  dla trendu dolnego ale przekracza gorna linie
// ten ponizej war. chyba zostawic jesli wbocznym bedzie wl. war z badaniem podwojnych S i R
    || (DoubleR_1h>0 && S_c_1h[0]<KMS_c_1h[0] && R_c_1h[0]>KMR_c_1h[0] && Close[0]>KM_1h))  //jezeli SR sa pomiedzy Srodkowa, ale wystapila podwojna R i cena przekracza Srodkowa
  if (!rtrend_1h==0)  rtrend_1h=1;  
  /* 
   {
   if (Close[0]>KD_1h) // odfiltruj Rosnacy gdy Close0 jest mniejszy od dolnej linii 
    { 
    //  if (!rtrend_1h==0 | rtrend_1h ==2)  rtrend_1h=1;

       if (!(line_3s_dn_1h==1 && S_c_1h[0]>KMS_c_1h[0] && Close[0]<KU_1h))// nie uznawaj t. rosnacego gdy zawiera formacje Support dla trendu dolnego o ile nie przekracza gornej linii (bedzie to traktowane jako t. boczny) 
       if (!(line_3r_dn_1h==1 && R_c_1h[0]>KMR_c_1h[0] && Close[0]<KU_1h)) // nie uznawaj t. rosnacego gdy zawiera formacje Resist dla trendu dolnego o ile nie przekracza gornej linii (bedzie zaliczony jako boczny)
        //dodano close0
       if (!(hak_r_up_1h==1 && Close[0]>KM_1h && Close[0]<KU_1h && R_c_1h[2]>KMR_c_1h[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist w kanale(bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_1h==1 && Close[0]>KM_1h && Close[0]<KU_1h && S_c_1h[2]>KMS_c_1h[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support w kanale (bedzie zaliczone jako trend boczny)
       if (!(hak_r_up_1h==1 && R_c_1h[0]>KU_1h)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist poza kanalem (bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_1h==1 && S_c_1h[0]>KU_1h)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support poza kanalem  (bedzie zaliczone jako trend boczny)
       rtrend_1h=1;
     }
   }
*/
return (rtrend_1h);
}
// koniec spr trendu rosnacego

// =============================================================================================================================================

// ##-----------------------------------------------------------------------
// #####################   T R E N D    M A L E J ¥ C Y  1H  ##################
// ##-----------------------------------------------------------------------


int spr_trend_malejacy_1h()
{
  if ((S_c_1h[0]<KMS_c_1h[0] && R_c_1h[0]<KMR_c_1h[0] && Close[0]<KM_1h)               // jezeli Support, Resist i Close0 s¹ ponizej srodkowej linii
  || (Close[0]<KD_1h)                                                                     // jesli Close0 jest mniejszy od dolnej linii
//  || (line_3s_up_1h==1 && Close[0]<KD)                                                   // jesli formacja Support dla trendu rosnacego ale przekracza dolna linie //sprzeczne z  war. w tr. bocznym
//  || (line_3r_up_1h==1 && Close[0]<KD)                                                   // jesli formacja Resist  dla trendu rosnacego ale przekracza dolna linie
    || (DoubleS_1h>0 && R_c_1h[0]>KMR_c_1h[0] && S_c_1h[0]<KMS_c_1h[0] && Close[0]<KM_1h)) // jezeli linie SR sa pomiédzy Srodkowa,cena ponizej i wystapila podwojna S
    
  if (!(rtrend_1h==0)) rtrend_1h=2; 
/*
  { //Print ("WSZEDL DOLNY1---------------------------------");
   if (Close[0]<KU_1h )// odfiltruj Malejacy gdy Close0 jest wiekszy od gornej linii
    {
 //   if (!(rtrend_1h==0 || rtrend_1h==1)) rtrend_1h=2;

      if (!(line_3s_up_1h==1 && S_c_1h[0]<KMS_c_1h[0] && Close[0]>KD_1h))               //nie uznawaj t. malejacego gdy zawiera formacje Support dla trendu rosnacego (bedzie zaliczony jako boczny)
      if (!(line_3r_up_1h==1 && R_c_1h[0]<KMR_c_1h[0] && Close[0]>KD_1h))               //nie uznawaj t. malejacego gdy zawiera formacje Resist dla trendu rosnacego (bedzie zaliczony jako boczny)
      //dodano close0
      if (!(hak_s_dn_1h==1 && Close[0]<KM_1h && Close[0]>KD && S_c_1h[2]<KMS_c_1h[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support w kanale(bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_1h==1 && Close[0]<KM_1h && Close[0]>KD && R_c_1h[2]<KMR_c_1h[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist w kanale (bedzie zaliczone jako trend boczny)
      if (!(hak_s_dn_1h==1 && S_c_1h[0]<KDS_c_1h[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support poza kanalem (bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_1h==1 && R_c_1h[0]<KDR_c_1h[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist poza kanalem (bedzie zaliczone jako trend boczny)
      rtrend_1h=2; //Ustaawienie statusu trendu jako malejacy
   }
}
*/
 return (rtrend_1h);
} //koniec spr trendu malejacego



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//       ##################### T R E N D   B O C Z N Y  4h ##################
// ------------------------------------------------------------------------------------
//zweryfikowac czy mozna uzywac KM?(odp. tylko w odniesieniu do Biezacych wart np. Close0)


int spr_trend_boczny_4h()
{
    
if (( S_c_4h[0]<KMS_c_4h[0] && R_c_4h[0]>KMR_c_4h[0] && Close[0]>KM_4h )//#&& DoubleS_4h==0 && DoubleR_4h==0 //// jezeli Support1 jest mniejszy od Srodkowej a Resist1 powyzej
   ||(S_c_4h[0]<KMS_c_4h[0] && R_c_4h[0]>KMR_c_4h[0] && Close[0]<KM_4h )//#&& DoubleR_4h==0 && DoubleS_4h==0 //
     
   //||(S_c_4h[0]>KMS_c_4h[0] && R_c_4h[0]<KMR_c_4h[0] && DoubleR_4h==0)//&& DoubleR_4h==0 jezeli Support jest powyzej Srodkowej a Support ponizej
   //# czy uwzglednic wystapienie formacji rosnacej w trendzie malejacym i odwrotnie? (wymusic boczny) 
   // zamiana w czterech ponizszych z KM na KU?
   ||(Close[0] <KM_4h && line_3r_up_4h==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] <KM_4h && line_3s_up_4h==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Support dla trendu malejacego
   ||(Close[0] >KM_4h && line_3r_dn_4h==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] >KM_4h && line_3s_dn_4h==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Support dla trendu malejacego

   //dodano close0
   ||(hak_r_dn_4h==1 && Close[0]<KM_4h && R_c_4h[2]<KMR_c_4h[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Resist_C_4h,  ale R3 ma byc juz ponizej KM z uwagi na charakterystyke trendu rosnacego/malejacego wzgledem keltera
   ||(hak_s_dn_4h==1 && Close[0]<KM_4h && S_c_4h[2]<KMS_c_4h[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Support_C_4h, ale S3 ma byc juz ponizej KM
   ||(hak_r_up_4h==1 && Close[0]>KM_4h && R_c_4h[2]>KMR_c_4h[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Resist_C_4h,  ale R3 ma byc juz powyzej KM
   ||(hak_s_up_4h==1 && Close[0]>KM_4h && S_c_4h[2]>KMS_c_4h[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Support_C_4h, ale S3 ma byc juz powyzej KM 

   ||(hak_r_dn_4h==1 && R_c_4h[0]<KDR_c_4h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Resist_C_4h
   ||(hak_s_dn_4h==1 && S_c_4h[0]<KDS_c_4h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Support_C_4h
   ||(hak_r_up_4h==1 && R_c_4h[0]>KUR_c_4h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Resist_C_4h
   ||(hak_s_up_4h==1 && S_c_4h[0]>KUS_c_4h[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Support_C_4h
  
   ||(S_c_4h[0]>S_c_4h[1] && S_4h[0]>KMS_c_4h[0] && S_4h[1] < KMS_c_4h[1] && R_c_4h[0] < S_c_4h[0] && Close[0]<KU_4h && Close[0]<S_c_4h[0]) //odwrotnosc S/R w jednej polowce kanalu gornego tzn gdy to S1 jest wieksze od R1 (R1>S1 powyzej KM oznaczaloby ze jest tr. gorny). war. tylko w t.bocznym(screen przypadek1)
   ||(R_c_4h[0]<R_c_4h[1] && R_4h[0]<KMR_c_4h[0] && R_4h[1] > KMR_c_4h[1] && S_c_4h[0] > R_c_4h[0] && Close[0]>KD_4h && Close[0]>R_c_4h[0]) //odwrotnosc S/R w jednej polowce kanalu dolnego tzn gdy to R1 jest wieksze od S1 (R1>S1 ponizej KM oznaczaloby ze jest tr. dolny). war. tylko w t.bocznym(screen przypadek1)
 
   ||(S_c_4h[0]>KMS_c_4h[0] && R_c_4h[0]>KMR_c_4h[0] && Close[0]<KM_4h)  // jezeli S/R jest powyzej Srdokowej linii, a Close0 jest juz ponizej //z powodu tego war. jest dod. if
   ||(S_c_4h[0]<KMS_c_4h[0] && R_c_4h[0]<KMR_c_4h[0] && Close[0]>KM_4h)) // jezeli S/R jest poni¿ej Srodkowej linii, a Close0 jest ju¿ powy¿ej //z powodu tego war. jest dod. if
    {
      //poni¿ej war. wykluczaj¹cy trend boczny z wieloma wyj¹tkami
      if (((Close[0]>KD_4h && Close[0]<KU_4h)                         // odfiltruj Boczny gdy Close0 jest ponizej dolnej linii i powyzej gornej(ZWERYFIKOWAC!)
        ||(hak_r_dn_4h==1 && Close[0]<KM_4h && Close[0]>KD_4h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war. (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_4h)
        ||(hak_s_dn_4h==1 && Close[0]<KM_4h && Close[0]>KD_4h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war  (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_4h
        ||(hak_r_up_4h==1 && Close[0]>KM_4h && Close[0]<KU_4h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_4h
        ||(hak_s_up_4h==1 && Close[0]>KM_4h && Close[0]<KU_4h)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_4h
        ||(hak_r_dn_4h==1 && R_c_4h[0]<KDR_c_4h[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_4h
        ||(hak_s_dn_4h==1 && S_c_4h[0]<KDS_c_4h[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_4h
        ||(hak_r_up_4h==1 && R_c_4h[0]>KUR_c_4h[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_4h
        ||(hak_s_up_4h==1 && S_c_4h[0]>KUS_c_4h[0]))           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_4h
        //ponizej warunki wykluczaj¹ce trend boczny
        && (!(DoubleS_4h>0 && R_c_4h[0]>KMR_c_4h[0] && S_c_4h[0]<KMS_c_4h[0] && Close[0]<KM_4h))
        && (!(DoubleR_4h>0 && S_c_4h[0]<KMS_c_4h[0] && R_c_4h[0]>KMR_c_4h[0] && Close[0]>KM_4h)))
         {
          rtrend_4h=0;
         }  
     }
 return(rtrend_4h);
}  


// ##----------------------------------------------------------------------
// #####################   T R E N D    R O S N ¥ C Y  4h  ##################
// ##----------------------------------------------------------------------
// ## SIGNAL BUY

 
int spr_trend_rosnacy_4h()
{
if ((S_c_4h[0]>KMS_c_4h[0] && R_c_4h[0]>KMR_c_4h[0] && Close[0]>KM_4h) //jezeli Support, Resist i Close0 s¹ powyzej srodkowej linii
  || (Close[0]>KU_4h) //jesli Close0 jest wiekszy od gornej linii
  // te dwa ponizsze sa sprzeczne z warunkami w trendzie bocznym (z podowu ktorych wstawiony jest tam dod. if)
 // || ( line_3s_dn_4h==1 && Close[0]>KU_4h) //  jesli formacja Support dla trendu dolnego ale przekracza gorna linie
 // || ( line_3r_dn_4h==1 && Close[0]>KU_4h) //  jesli formacja Resist  dla trendu dolnego ale przekracza gorna linie
// ten ponizej war. chyba zostawic jesli wbocznym bedzie wl. war z badaniem podwojnych S i R
    || (DoubleR_4h>0 && S_c_4h[0]<KMS_c_4h[0] && R_c_4h[0]>KMR_c_4h[0] && Close[0]>KM_4h))  //jezeli SR sa pomiedzy Srodkowa, ale wystapila podwojna R i cena przekracza Srodkowa
  if (!rtrend_4h==0)  rtrend_4h=1;  
  /* 
   {
   if (Close[0]>KD_4h) // odfiltruj Rosnacy gdy Close0 jest mniejszy od dolnej linii 
    { 
    //  if (!rtrend_4h==0 | rtrend_4h ==2)  rtrend_4h=1;

       if (!(line_3s_dn_4h==1 && S_c_4h[0]>KMS_c_4h[0] && Close[0]<KU_4h))// nie uznawaj t. rosnacego gdy zawiera formacje Support dla trendu dolnego o ile nie przekracza gornej linii (bedzie to traktowane jako t. boczny) 
       if (!(line_3r_dn_4h==1 && R_c_4h[0]>KMR_c_4h[0] && Close[0]<KU_4h)) // nie uznawaj t. rosnacego gdy zawiera formacje Resist dla trendu dolnego o ile nie przekracza gornej linii (bedzie zaliczony jako boczny)
        //dodano close0
       if (!(hak_r_up_4h==1 && Close[0]>KM_4h && Close[0]<KU_4h && R_c_4h[2]>KMR_c_4h[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist w kanale(bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_4h==1 && Close[0]>KM_4h && Close[0]<KU_4h && S_c_4h[2]>KMS_c_4h[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support w kanale (bedzie zaliczone jako trend boczny)
       if (!(hak_r_up_4h==1 && R_c_4h[0]>KU_4h)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist poza kanalem (bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_4h==1 && S_c_4h[0]>KU_4h)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support poza kanalem  (bedzie zaliczone jako trend boczny)
       rtrend_4h=1;
     }
   }
*/
return (rtrend_4h);
}
// koniec spr trendu rosnacego

// =============================================================================================================================================

// ##-----------------------------------------------------------------------
// #####################   T R E N D    M A L E J ¥ C Y  4h  ##################
// ##-----------------------------------------------------------------------


int spr_trend_malejacy_4h()
{
  if ((S_c_4h[0]<KMS_c_4h[0] && R_c_4h[0]<KMR_c_4h[0] && Close[0]<KM_4h)               // jezeli Support, Resist i Close0 s¹ ponizej srodkowej linii
  || (Close[0]<KD_4h)                                                                     // jesli Close0 jest mniejszy od dolnej linii
//  || (line_3s_up_4h==1 && Close[0]<KD)                                                   // jesli formacja Support dla trendu rosnacego ale przekracza dolna linie //sprzeczne z  war. w tr. bocznym
//  || (line_3r_up_4h==1 && Close[0]<KD)                                                   // jesli formacja Resist  dla trendu rosnacego ale przekracza dolna linie
    || (DoubleS_4h>0 && R_c_4h[0]>KMR_c_4h[0] && S_c_4h[0]<KMS_c_4h[0] && Close[0]<KM_4h)) // jezeli linie SR sa pomiédzy Srodkowa,cena ponizej i wystapila podwojna S
 
  if (!(rtrend_4h==0)) rtrend_4h=2; 
/*
  { //Print ("WSZEDL DOLNY1---------------------------------");
   if (Close[0]<KU_4h )// odfiltruj Malejacy gdy Close0 jest wiekszy od gornej linii
    {
 //   if (!(rtrend_4h==0 || rtrend_4h==1)) rtrend_4h=2;

      if (!(line_3s_up_4h==1 && S_c_4h[0]<KMS_c_4h[0] && Close[0]>KD_4h))               //nie uznawaj t. malejacego gdy zawiera formacje Support dla trendu rosnacego (bedzie zaliczony jako boczny)
      if (!(line_3r_up_4h==1 && R_c_4h[0]<KMR_c_4h[0] && Close[0]>KD_4h))               //nie uznawaj t. malejacego gdy zawiera formacje Resist dla trendu rosnacego (bedzie zaliczony jako boczny)
      //dodano close0
      if (!(hak_s_dn_4h==1 && Close[0]<KM_4h && Close[0]>KD && S_c_4h[2]<KMS_c_4h[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support w kanale(bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_4h==1 && Close[0]<KM_4h && Close[0]>KD && R_c_4h[2]<KMR_c_4h[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist w kanale (bedzie zaliczone jako trend boczny)
      if (!(hak_s_dn_4h==1 && S_c_4h[0]<KDS_c_4h[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support poza kanalem (bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_4h==1 && R_c_4h[0]<KDR_c_4h[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist poza kanalem (bedzie zaliczone jako trend boczny)
      rtrend_4h=2; //Ustaawienie statusu trendu jako malejacy
   }
}
*/
 return (rtrend_4h);
} //koniec spr trendu malejacego



//       ##################### T R E N D   B O C Z N Y  1d ##################
// ------------------------------------------------------------------------------------
//zweryfikowac czy mozna uzywac KM?(odp. tylko w odniesieniu do Biezacych wart np. Close0)


int spr_trend_boczny_1d()
{
    
if (( S_c_1d[0]<KMS_c_1d[0] && R_c_1d[0]>KMR_c_1d[0] && Close[0]>KM_1d )//#&& DoubleS_1d==0 && DoubleR_1d==0 //// jezeli Support1 jest mniejszy od Srodkowej a Resist1 powyzej
   ||(S_c_1d[0]<KMS_c_1d[0] && R_c_1d[0]>KMR_c_1d[0] && Close[0]<KM_1d )//#&& DoubleR_1d==0 && DoubleS_1d==0 //
     
   //||(S_c_1d[0]>KMS_c_1d[0] && R_c_1d[0]<KMR_c_1d[0] && DoubleR_1d==0)//&& DoubleR_1d==0 jezeli Support jest powyzej Srodkowej a Support ponizej
   //# czy uwzglednic wystapienie formacji rosnacej w trendzie malejacym i odwrotnie? (wymusic boczny) 
   // zamiana w czterech ponizszych z KM na KU?
   ||(Close[0] <KM_1d && line_3r_up_1d==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] <KM_1d && line_3s_up_1d==1)                         // jesli Close0 jest ponizej Srodkowej z formacja Support dla trendu malejacego
   ||(Close[0] >KM_1d && line_3r_dn_1d==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Resist  dla trendu malejacego
   ||(Close[0] >KM_1d && line_3s_dn_1d==1)                         // jesli Close0 jest powyzej Srodkowej z formacja Support dla trendu malejacego

   //dodano close0
   ||(hak_r_dn_1d==1 && Close[0]<KM_1d && R_c_1d[2]<KMR_c_1d[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Resist_C_1d,  ale R3 ma byc juz ponizej KM z uwagi na charakterystyke trendu rosnacego/malejacego wzgledem keltera
   ||(hak_s_dn_1d==1 && Close[0]<KM_1d && S_c_1d[2]<KMS_c_1d[2]) // jezeli w kanale t. malejacego wyst. zalamanie tj. koniec opadajacej formacji Support_C_1d, ale S3 ma byc juz ponizej KM
   ||(hak_r_up_1d==1 && Close[0]>KM_1d && R_c_1d[2]>KMR_c_1d[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Resist_C_1d,  ale R3 ma byc juz powyzej KM
   ||(hak_s_up_1d==1 && Close[0]>KM_1d && S_c_1d[2]>KMS_c_1d[2]) // jezeli w kanale t. rosnacego  wyst. zalamanie tj. koniec rosnacej   formacji Support_C_1d, ale S3 ma byc juz powyzej KM 

   ||(hak_r_dn_1d==1 && R_c_1d[0]<KDR_c_1d[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Resist_C_1d
   ||(hak_s_dn_1d==1 && S_c_1d[0]<KDS_c_1d[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. malejacego tj. koniec opadajacej formacji Support_C_1d
   ||(hak_r_up_1d==1 && R_c_1d[0]>KUR_c_1d[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Resist_C_1d
   ||(hak_s_up_1d==1 && S_c_1d[0]>KUS_c_1d[0])                // jezeli poza kanalem wyst. zalamanie poza kanalem t. rosnacego  tj. koniec rosnacej formacji Support_C_1d
  
   ||(S_c_1d[0]>S_c_1d[1] && S_1d[0]>KMS_c_1d[0] && S_1d[1] < KMS_c_1d[1] && R_c_1d[0] < S_c_1d[0] && Close[0]<KU_1d && Close[0]<S_c_1d[0]) //odwrotnosc S/R w jednej polowce kanalu gornego tzn gdy to S1 jest wieksze od R1 (R1>S1 powyzej KM oznaczaloby ze jest tr. gorny). war. tylko w t.bocznym(screen przypadek1)
   ||(R_c_1d[0]<R_c_1d[1] && R_1d[0]<KMR_c_1d[0] && R_1d[1] > KMR_c_1d[1] && S_c_1d[0] > R_c_1d[0] && Close[0]>KD_1d && Close[0]>R_c_1d[0]) //odwrotnosc S/R w jednej polowce kanalu dolnego tzn gdy to R1 jest wieksze od S1 (R1>S1 ponizej KM oznaczaloby ze jest tr. dolny). war. tylko w t.bocznym(screen przypadek1)
 
   ||(S_c_1d[0]>KMS_c_1d[0] && R_c_1d[0]>KMR_c_1d[0] && Close[0]<KM_1d)  // jezeli S/R jest powyzej Srdokowej linii, a Close0 jest juz ponizej //z powodu tego war. jest dod. if
   ||(S_c_1d[0]<KMS_c_1d[0] && R_c_1d[0]<KMR_c_1d[0] && Close[0]>KM_1d)) // jezeli S/R jest poni¿ej Srodkowej linii, a Close0 jest ju¿ powy¿ej //z powodu tego war. jest dod. if
    {
      //poni¿ej war. wykluczaj¹cy trend boczny z wieloma wyj¹tkami
      if (((Close[0]>KD_1d && Close[0]<KU_1d)                         // odfiltruj Boczny gdy Close0 jest w kanale (ZWERYFIKOWAC!)
        ||(hak_r_dn_1d==1 && Close[0]<KM_1d && Close[0]>KD_1d)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war. (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_1d)
        ||(hak_s_dn_1d==1 && Close[0]<KM_1d && Close[0]>KD_1d)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war  (jezeli wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_1d
        ||(hak_r_up_1d==1 && Close[0]>KM_1d && Close[0]<KU_1d)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_1d
        ||(hak_s_up_1d==1 && Close[0]>KM_1d && Close[0]<KU_1d)        // (war. powtorzony z pow. war. wej., a tu umieszczony jako wyjatek dla war.odfiltrowania, aby war. wyzej nie blokowal takiej sytuacji jak w tym war.(jezeli wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_1d
        ||(hak_r_dn_1d==1 && R_c_1d[0]<KDR_c_1d[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Resist_C_1d
        ||(hak_s_dn_1d==1 && S_c_1d[0]<KDS_c_1d[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. malejacego tj. koniec opadajacej formacji Support_C_1d
        ||(hak_r_up_1d==1 && R_c_1d[0]>KUR_c_1d[0])           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Resist_C_1d
        ||(hak_s_up_1d==1 && S_c_1d[0]>KUS_c_1d[0]))           // (war. powtorzony jw.)jezeli poza kanalem wyst. zalamanie t. rosnacego tj. koniec rosnacej formacji Support_C_1d
        //ponizej warunki wykluczaj¹ce trend boczny
        && (!(DoubleS_1d>0 && R_c_1d[0]>KMR_c_1d[0] && S_c_1d[0]<KMS_c_1d[0] && Close[0]<KM_1d))
        && (!(DoubleR_1d>0 && S_c_1d[0]<KMS_c_1d[0] && R_c_1d[0]>KMR_c_1d[0] && Close[0]>KM_1d)))
         {
          rtrend_1d=0;
         }  
     }
 return(rtrend_1d);
}  


// ##----------------------------------------------------------------------
// #####################   T R E N D    R O S N ¥ C Y  1d  ##################
// ##----------------------------------------------------------------------
// ## SIGNAL BUY

 
int spr_trend_rosnacy_1d()
{
if ((S_c_1d[0]>KMS_c_1d[0] && R_c_1d[0]>KMR_c_1d[0] && Close[0]>KM_1d) //jezeli Support, Resist i Close0 s¹ powyzej srodkowej linii
  || (Close[0]>KU_1d) //jesli Close0 jest wiekszy od gornej linii
  // te dwa ponizsze sa sprzeczne z warunkami w trendzie bocznym (z podowu ktorych wstawiony jest tam dod. if)
 // || ( line_3s_dn_1d==1 && Close[0]>KU_1d) //  jesli formacja Support dla trendu dolnego ale przekracza gorna linie
 // || ( line_3r_dn_1d==1 && Close[0]>KU_1d) //  jesli formacja Resist  dla trendu dolnego ale przekracza gorna linie
// ten ponizej war. chyba zostawic jesli wbocznym bedzie wl. war z badaniem podwojnych S i R
    || (DoubleR_1d>0 && S_c_1d[0]<KMS_c_1d[0] && R_c_1d[0]>KMR_c_1d[0] && Close[0]>KM_1d))  //jezeli SR sa pomiedzy Srodkowa, ale wystapila podwojna R i cena przekracza Srodkowa
  if (!rtrend_1d==0)  rtrend_1d=1;  
  /* 
   {
   if (Close[0]>KD_1d) // odfiltruj Rosnacy gdy Close0 jest mniejszy od dolnej linii 
    { 
    //  if (!rtrend_1d==0 | rtrend_1d ==2)  rtrend_1d=1;

       if (!(line_3s_dn_1d==1 && S_c_1d[0]>KMS_c_1d[0] && Close[0]<KU_1d))// nie uznawaj t. rosnacego gdy zawiera formacje Support dla trendu dolnego o ile nie przekracza gornej linii (bedzie to traktowane jako t. boczny) 
       if (!(line_3r_dn_1d==1 && R_c_1d[0]>KMR_c_1d[0] && Close[0]<KU_1d)) // nie uznawaj t. rosnacego gdy zawiera formacje Resist dla trendu dolnego o ile nie przekracza gornej linii (bedzie zaliczony jako boczny)
        //dodano close0
       if (!(hak_r_up_1d==1 && Close[0]>KM_1d && Close[0]<KU_1d && R_c_1d[2]>KMR_c_1d[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist w kanale(bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_1d==1 && Close[0]>KM_1d && Close[0]<KU_1d && S_c_1d[2]>KMS_c_1d[2])) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support w kanale (bedzie zaliczone jako trend boczny)
       if (!(hak_r_up_1d==1 && R_c_1d[0]>KU_1d)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Resist poza kanalem (bedzie zaliczone jako trend boczny)
       if (!(hak_s_up_1d==1 && S_c_1d[0]>KU_1d)) //nie uznawaj t. rosnacego gdy zawiera zakonczenie formacji rosnacej Support poza kanalem  (bedzie zaliczone jako trend boczny)
       rtrend_1d=1;
     }
   }
*/
return (rtrend_1d);
}
// koniec spr trendu rosnacego

// =============================================================================================================================================

// ##-----------------------------------------------------------------------
// #####################   T R E N D    M A L E J ¥ C Y  1d  ##################
// ##-----------------------------------------------------------------------


int spr_trend_malejacy_1d()
{
  if ((S_c_1d[0]<KMS_c_1d[0] && R_c_1d[0]<KMR_c_1d[0] && Close[0]<KM_1d)               // jezeli Support, Resist i Close0 s¹ ponizej srodkowej linii
  || (Close[0]<KD_1d)                                                                     // jesli Close0 jest mniejszy od dolnej linii
//  || (line_3s_up_1d==1 && Close[0]<KD)                                                   // jesli formacja Support dla trendu rosnacego ale przekracza dolna linie //sprzeczne z  war. w tr. bocznym
//  || (line_3r_up_1d==1 && Close[0]<KD)                                                   // jesli formacja Resist  dla trendu rosnacego ale przekracza dolna linie
    || (DoubleS_1d>0 && R_c_1d[0]>KMR_c_1d[0] && S_c_1d[0]<KMS_c_1d[0] && Close[0]<KM_1d)) // jezeli linie SR sa pomiédzy Srodkowa,cena ponizej i wystapila podwojna S
 
  if (!(rtrend_1d==0)) rtrend_1d=2; 
/*
  { //Print ("WSZEDL DOLNY1---------------------------------");
   if (Close[0]<KU_1d )// odfiltruj Malejacy gdy Close0 jest wiekszy od gornej linii
    {
 //   if (!(rtrend_1d==0 || rtrend_1d==1)) rtrend_1d=2;

      if (!(line_3s_up_1d==1 && S_c_1d[0]<KMS_c_1d[0] && Close[0]>KD_1d))               //nie uznawaj t. malejacego gdy zawiera formacje Support dla trendu rosnacego (bedzie zaliczony jako boczny)
      if (!(line_3r_up_1d==1 && R_c_1d[0]<KMR_c_1d[0] && Close[0]>KD_1d))               //nie uznawaj t. malejacego gdy zawiera formacje Resist dla trendu rosnacego (bedzie zaliczony jako boczny)
      //dodano close0
      if (!(hak_s_dn_1d==1 && Close[0]<KM_1d && Close[0]>KD && S_c_1d[2]<KMS_c_1d[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support w kanale(bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_1d==1 && Close[0]<KM_1d && Close[0]>KD && R_c_1d[2]<KMR_c_1d[2]))  //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist w kanale (bedzie zaliczone jako trend boczny)
      if (!(hak_s_dn_1d==1 && S_c_1d[0]<KDS_c_1d[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Support poza kanalem (bedzie zaliczone jako trend boczny)
      if (!(hak_r_dn_1d==1 && R_c_1d[0]<KDR_c_1d[0]))                                //nie uznawaj t. malejacego gdy zawiera zakonczenie formacji spadkowej Resist poza kanalem (bedzie zaliczone jako trend boczny)
      rtrend_1d=2; //Ustaawienie statusu trendu jako malejacy
   }
}
*/
 return (rtrend_1d);
} //koniec spr trendu malejacego



















//#############################################################################################################################







/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                    ## FUNKCJE NIEU¯YWANE
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/*


//###########################################################################################################################
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// USTAWIENIE NOWEGO POZIOMU STOP LOSS DLA BUY
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
double ustaw_Buy_SL2()
{
double tmp_SL;
int flag_War1, flag_War2; flag_War1=0; flag_War2=0; 
 if ((OrderOpenPrice()>S_15m[0])
     &&(Close[0]>S_15m[0]))
   {
    tmp_StopLoss=MathAbs((OrderOpenPrice()-S_15m[0])/pt);
    tmp_StopLoss=MathFloor(tmp_StopLoss);
          if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
          ||(tmp_StopLoss<min_OpenSL))
           {
              flag_War1=0;opisSL="Buy2nr1/1-31";}  
              else {flag_War1=1;opisSL="Buy2nr1/3-S1";} 
        
   if ((OrderOpenPrice()>S_15m[1] && S_15m[1]<S_15m[0])
        && (Close[0]>S_15m[1])) //a moze wywalic to? wtedy ucinalby transakcje powyzej nowej linii wsparica (tylko czy na gieldzie takie ustawianie jest dozwolone?)
           {
             tmp_SL=MathAbs((OrderOpenPrice()-S_15m[1])/pt);
             tmp_SL=MathFloor(tmp_SL);
               if ((tmp_SL>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
                 ||(tmp_SL<min_OpenSL))
                    {//Print("tmp_SL=",tmp_SL);
                     flag_War1=0;opisSL="Buy2nr2/1-31";}
                   else {flag_War2=1;opisSL="Buy2nr2/2-S_15m[1]";}  //ustaw flage ze bedzie nowy SL i ze zostal spelniony war2
             }
  
  if (flag_War1==1 && flag_War2==1) //jezeli spelnione zostaly oba warunki
     {
      if (tmp_StopLoss<tmp_SL) tmp_StopLoss=tmp_StopLoss; // to sprawdz ktory jest bardziej korzystny tzn ma niszy(bezpiecnziejszy) poziom SL. Pozostaw aktualny jesli jest nizszy
      else {tmp_StopLoss=tmp_SL;opisSL="Buy2nr3/1-S_15m[1]";}  // i ustaw ni¿szy poziom
     } 
  }

 return(tmp_StopLoss);        
 }          
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// USTAWIENIE PONOWNIE POZIOMU STOP LOSS DLA SELL
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
double ustaw_Sell_SL2()
{
double tmp_SL;
int flag_War1, flag_War2;
flag_War1=0; flag_War2=0; 
 if ((OrderOpenPrice()<R_15m[0])
    && (Close[0] < R_15m[0]))
  {
   tmp_StopLoss=MathAbs((OrderOpenPrice()-R_15m[0])/pt);
   tmp_StopLoss=MathFloor(tmp_StopLoss);
  
        if ((tmp_StopLoss>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
            ||(tmp_StopLoss<min_OpenSL))
              {
              flag_War1=0;opisSL="Sell2nr1/1-31"; //brak nowego SL 
              // Print ("Sell2nr1/1-31=",tmp_StopLoss);
              }  
            else {flag_War1=1;opisSL="Sell2nr1/2-R_15m[0]";
            //Print ("Sell2nr1/2=",tmp_StopLoss);
            } 
        
  if ((OrderOpenPrice()<R_15m[1]) 
      && (R_15m[1]>R_15m[0])
      && (Close[0]<R_15m[1]))
      {
        tmp_SL=MathAbs((OrderOpenPrice()-R_15m[1])/pt);
        tmp_SL=MathFloor(tmp_SL);
           if ((tmp_SL>35) //obl czy odl nie wieksza niz 31 pips i nie miejsza niz 15 pips
             ||(tmp_SL<min_OpenSL))
                 {flag_War1=0;opisSL="Sell2nr2/1-31";
                 //Print ("Sell2nr2/1=",tmp_StopLoss);
                 }
                   else {flag_War2=1;opisSL="Sell2nr2/2-S_15m[1]"; //ustaw flage ze bedzie nowy SL i ze zostal spelniony war2
                   //Print ("Sell2nr2/2=",tmp_StopLoss);
                   }  
      }
  
  
  if (flag_War1==1 && flag_War2==1) //jezeli spelnione zostaly oba warunki
     {
         if (tmp_StopLoss<tmp_SL) {tmp_StopLoss=tmp_StopLoss;// to sprawdz ktory jest bardziej korzystny tzn ma niszy(bezpiecnziejszy) poziom SL. Pozostaw aktualny jesli jest nizszy
         //Print ("Sell2nr2/3=",tmp_StopLoss);
           } 
             else {tmp_StopLoss=tmp_SL;opisSL="Sell2nr3/1-R2"; // i ustaw ni¿szy poziom
             //Print ("Sell2nr3/1=",tmp_StopLoss);
             }  
     } 
   
 }
//Print ("Sell2nrEnd=",tmp_StopLoss);
return(tmp_StopLoss);        
}


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//-------------------------------- BreakEven ----------------------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
void MoveBreakEven()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
      {
         if(OrderType()==OP_BUY)
         {
            if(BreakEven>0)
            {
            
               if(NormalizeDouble((Close[1]-OrderOpenPrice()),Digits)>BreakEven*pt) //pierwotnie bylo Bid zamiast Close[0]
               {
                  if(NormalizeDouble((OrderStopLoss()-OrderOpenPrice()),Digits)<0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()+0*Poin+(Ask-Bid),Digits),OrderTakeProfit(),0,Blue);
                     //return(0);
                  }
               }
            }
         }
         else
         {
            if(BreakEven>0)
            {
               
            
               if(NormalizeDouble((OrderOpenPrice()-Close[1]),Digits)>BreakEven*pt) // pierwotnie ponizej bylo Ask zamiast Close[0]
               {
                  if(NormalizeDouble((OrderOpenPrice()-OrderStopLoss()),Digits)<0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()-0*Poin-(Ask-Bid),Digits),OrderTakeProfit(),0,Red);
                      
              
                     //return(0);
                  
                  }
               }
            }
         }
      }
   }
}

//------------------------------------------------------------------
// -----------------------RUCHOMY STOP LOSS-------------------------
//------------------------------------------------------------------
int MoveTrailingStop()
{
int ticket = OrderTicket();
double dist, zysk;
double      bid = MarketInfo(OrderSymbol(),MODE_BID),
            ask = MarketInfo(OrderSymbol(),MODE_ASK),
            act_lev = TS_ActivatedLevel*pt,  // poziom od którego ma dzia³aæ TS
            distmin = TS_Distance * pt; // -- czyli ile pipsów za cen¹ ma siê przesuwaæ SL (zmienic nazwe zmienej na doist jesli ma byc o SL o stala wartosc)
     
     
      //if (dist<distmin) dist=StopLoss; ok //aby stop loss mial 35p ponizej dopuszczalnego minimum sl
     
//Print ("Wszedl TS1");
int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
 //Print ("buy1 Close1", Close[1], "dist ", dist, " Bid ",  Bid);
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
//Print ("Wszedl TS2");

// a tu bid - bid na close[1]
//  ----OBLICZANIE POZIOMU ZAMKNIECIA WZGLEDEM ZYSKU DLA BUY---
if (OrderType() == OP_BUY)
{
//Print ("Wszedl TS3");
           //double zysk=MathAbs(Close[1]-OrderOpenPrice());
            zysk=Close[0]-OrderOpenPrice();
            if (zysk >0)
      {      
            if (zysk<10*pt) SL_proc=0.9;//=OrderOpenPrice()-StopLoss; //0.9
            if (zysk>=10*pt && zysk<=20*pt)  SL_proc=0.9;  //0.9
            if (zysk>20*pt && zysk<=40*pt)  SL_proc=0.9;  //0.8
            if (zysk>40*pt && zysk<=60*pt)  SL_proc=0.8;  //0.7
            if (zysk>60*pt && zysk<=80*pt)  SL_proc=0.8;  //0.4
            if (zysk>80*pt && zysk<=100*pt) SL_proc=0.7 ; //0.3
            if (zysk>99*pt)  SL_proc=0.6; //spawdzic ten war. //0.3
      } 
      
         dist= NormalizeDouble(zysk*SL_proc,Digits); 
         
        
           
       // double dist= MathAbs(NormalizeDouble(zysk*SL_proc,Digits));
       //if (dist<act_lev) dist=MathAbs(zysk-StopLoss*Point); //aby stop loss mial 35p ponizej activation level     
       if (zysk<act_lev) dist=zysk-StopLoss*pt; //skrocenie wyjsciowego stop loss o zysk?
      
       if (ustaw_Buy_SL==1) //ustawienie popzimu SL dla nowotowieranych pozycji bez zalozonego SL
         {
          // Print ("Wszedl TS4");
           dist=ustaw_Buy_SL2();
           if (dist<min_OpenSL || dist>35) dist=min_OpenSL; else dist=dist+3;
           ustaw_Buy_SL=1; //przywroc flage bo funkcja oblicz_Buy_SL na pewno ja wyzerowala
           //Print (" funk dist=",dist);
             }
       // Print ("After dist=",dist, "    Close[1] - dist=",Close[0] - dist);
      //Print (" Ask:", Ask, " Close:", Close[0],"OrderOpenP: ",OrderOpenPrice()," Zysk:", zysk, " dist: ", dist, " SL_proc: ", SL_proc, " SL*Point:", StopLoss*Point, "10*Point: ", 10*Point);
}
// ---------------------------------------------------------------------
if (((OrderType() == OP_BUY) && (Close[0]> (OrderOpenPrice() + act_lev)) && (OrderStopLoss() < (Close[0] - dist)))
 || (ustaw_Buy_SL==1 && OrderType() == OP_BUY)) {
            //Print ("buy1 Close ", Close[0], " dist ", dist, " dist2 ", dist2," Bid ",  Bid);
 //Print ("Wszedl TS5");
   
   //   Print (" Ask:", Ask, " Close:", Close[1],"OrderOpenP: ",OrderOpenPrice()," Zysk:", zysk, " dist: ", dist, " SL_proc: ", SL_proc, " SL*Point:", StopLoss*Point, "10*Point: ", 10*Point);
            
            if (ustaw_Buy_SL==1)  //jezeli ustawienie dla nowego zlecenia innego poziomu SL to uzyj alternatywnego obliczenia zmiany ceny :)
            {
            // Print ("Wszedl TS5,a dist=",dist);
             if (!OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice() - dist * pt, OrderTakeProfit(), OrderExpiration(), Yellow))
              return(0);
             }
            else
            {
               if(!OrderModify(ticket, OrderOpenPrice(), Close[0] - dist, OrderTakeProfit(), OrderExpiration(), Yellow))
               {
               // Print ("buy1 Close1 ", Close[1], " dist ", dist, " Bid ",  Bid);
                  return(0);
               }
             }
         } //oryginalnie zamiast Close[0] bylo ask(malymi), dalej ask na close[1]
   ustaw_Buy_SL=0;     
 // ------OBLICZANIE POZIOMU ZAMKNIECIA WZGLEDEM ZYSKU DLA SELL --
 
 if (OrderType() == OP_SELL)
{
        //Print("Wszedl TSS1");
         //zysk=MathAbs(OrderOpenPrice()-Close[1]);
          zysk=Close[0]- OrderOpenPrice(); 
          if (zysk<0)
          {        
            if (zysk>-10*pt)SL_proc=0.9;
            if (zysk<=-10*pt && zysk>=-20*pt)  SL_proc=0.9;  //0.9
            if (zysk<-20*pt && zysk>=-40*pt)  SL_proc=0.9;
            if (zysk<-40*pt && zysk>=-60*pt)  SL_proc=0.8;
            if (zysk<-60*pt && zysk>=-80*pt)  SL_proc=0.8;
            if (zysk<-80*pt && zysk>=-100*pt) SL_proc=0.7;
            if (zysk<-99*pt)  SL_proc=0.6; //spawdzic ten war.
         }
      
       dist= MathAbs(NormalizeDouble(zysk*SL_proc,Digits));
        // ok dist= NormalizeDouble(zysk*SL_proc,Digits);
         //dist= NormalizeDouble(zysk*SL_proc,Digits); //+ czy minus zysk?
      // if (dist<act_lev) dist=MathAbs(zysk-StopLoss*Point); //aby stop loss mial 35p ponizej activation level   
                
        if (MathAbs(zysk)<act_lev) dist=zysk-StopLoss*pt; // a moze dodac? //skrocenie poczatkowego stop loss?
 //Print ("OrderType() ",OrderType(),"  Ask:", Ask, " Close:", Close[0]," OrderOpenP: ",OrderOpenPrice()," Zysk:", zysk, "act_lev=",act_lev," dist: ", dist, " distc ", zysk*SL_proc," SL_proc: ", SL_proc, " SL*Point:", StopLoss*Point, "10*Point: ", 10*Point);

   if (ustaw_Sell_SL==1) //ustawienie popzimu SL dla nowotowieranych pozycji bez zalozonego SL
         {
          //Print("Wszedl TSS2");
           dist=ustaw_Sell_SL2();
           if (dist<min_OpenSL || dist>35) dist=min_OpenSL; else dist=dist+3;
           ustaw_Sell_SL=1; //przywroc flage bo funkcja oblicz_Sell_SL na pewno ja wyzerowala, a wtedy nie wejdzie do war .mod. zlecenia
           //Print (" funk dist=",dist);
           }
  //Print("Wszedl TSS3"); 
  //Print ("After dist=",dist, "    zysk-StopLoss*Point",zysk-StopLoss*Point);
 }
 
 // ---------------------------------------------------------------
        
       if(((OrderType() == OP_SELL) && (Close[0] < (OrderOpenPrice() - act_lev)) && (OrderStopLoss() > (Close[0] + dist)))
       || (ustaw_Sell_SL==1 && OrderType() == OP_SELL))
        {
            //Print("Wszedl TSS4");
            if (ustaw_Sell_SL==1)  //jezeli ustawienie dla nowego zlecenia innego poziomu SL to uzyj alternatywnego obliczenia zmiany ceny :)
            {
              //Print("Wszedl TSS5");
              if (!OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice() + dist * pt, OrderTakeProfit(), OrderExpiration(), Yellow))
              return(0);
             }
            else
            {          
              if(!OrderModify(ticket, OrderOpenPrice(), Close[0] + dist, OrderTakeProfit(), OrderExpiration(), Blue)) 
                 {
                //  Print ("Sell1 Close ", Close[0], " dist ", dist," dist2 ",dist2, " Ask ",  Ask, "Bid ", Bid);
                    return(0);
                 }
             }
          ustaw_Sell_SL=0;
         } 
  }
return(0);
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//       funkcja pobierania z wykresu wspolrzednych cenowych dla linii trendu
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
double value_trendline(string name)
{
   for(int i=0;i<=ObjectsTotal();i++)
   {
      if (ObjectName(i) == name && ObjectType(name) == OBJ_TREND)
      {
         double value1 = iBarShift(Symbol(),Period(),ObjectGet(name,OBJPROP_TIME2))-iBarShift(Symbol(),Period(),ObjectGet(name,OBJPROP_TIME1));
         double value2 = iBarShift(Symbol(),Period(),ObjectGet(name,OBJPROP_TIME1));
         double value3 = ObjectGet(name,OBJPROP_PRICE2)-ObjectGet(name,OBJPROP_PRICE1);
         double level=-(value3*value2/value1)+ObjectGet(name,OBJPROP_PRICE1);
         return(level);
       }
    }
    return(0);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Zmienne do wyznaczania sily trendu poprzez wskaznik SW_hull_powertrend_15m

void powertrend_15m()
{
   int k;
   powertrend_15m0 = iCustom(NULL,PERIOD_M15,"SW_hull_powertrend",0,0);
   powertrend_15m1 = iCustom(NULL,PERIOD_M15,"SW_hull_powertrend",1,0); 
   powertrend_15m2 = iCustom(NULL,PERIOD_M15,"SW_hull_powertrend",2,0);
 
   powertrend_15m0_p[0]=powertrend_15m0; //zaktualizowanie ostatniej wartoœci RSI
   powertrend_15m1_p[0]=powertrend_15m1; //zaktualizowanie ostatniej wartoœci RSI
   powertrend_15m2_p[0]=powertrend_15m2; //zaktualizowanie ostatniej wartoœci RSI

   if (powertrend_15m0_p[0]!=powertrend_15m1_p[0] && powertrend_15m0_p[0]!=powertrend_15m2_p[0]) {powertrend_15m_up0=false;powertrend_15m_dn0=false;powertrend_15m_stp0=true;}
   if (powertrend_15m0_p[0]==powertrend_15m1_p[0])                                       {powertrend_15m_up0=true ;powertrend_15m_dn0=false;powertrend_15m_stp0=false;}
   if (powertrend_15m0_p[0]==powertrend_15m2_p[0])                                       {powertrend_15m_up0=false;powertrend_15m_dn0=true; powertrend_15m_stp0=false;}

  //---P2
  // Print ("Wejsciowe trend0_rsi=",trend0_rsi);
  // to ponizej chyba niepotrzebne, choc wystepuje w org. final3
  // if (powertrend_15m0_p[0]==0) powertrend_15m0_p[0]=powertrend_15m0;
  // if (powertrend_15m1_p[0]==0) powertrend_15m1_p[0]=powertrend_15m1;
  // if (powertrend_15m2_p[0]==0) powertrend_15m2_p[0]=powertrend_15m2;
   
   for(  k =6; k>0; k--) powertrend_15m0_p[k]=powertrend_15m0_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
   for(  k =6; k>0; k--) powertrend_15m1_p[k]=powertrend_15m1_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
   for(  k =6; k>0; k--) powertrend_15m2_p[k]=powertrend_15m2_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
   
   powertrend_15m0_p[0]=powertrend_15m0; //zaktualizowanie ostatniej wartoœci RSI
   powertrend_15m1_p[0]=powertrend_15m1; //zaktualizowanie ostatniej wartoœci RSI
   powertrend_15m2_p[0]=powertrend_15m2; //zaktualizowanie ostatniej wartoœci RSI

   if (powertrend_15m0_p[3]!=powertrend_15m1_p[3] && powertrend_15m0_p[3]!=powertrend_15m2_p[3]) {powertrend_15m_up2=false;powertrend_15m_dn2=false;powertrend_15m_stp2=true;}
   if (powertrend_15m0_p[3]==powertrend_15m1_p[3])                                       {powertrend_15m_up2=true; powertrend_15m_dn2=false;powertrend_15m_stp2=false;}
   if (powertrend_15m0_p[3]==powertrend_15m2_p[3])                                       {powertrend_15m_up2=false;powertrend_15m_dn2=true; powertrend_15m_stp2=false;}

   //Print ("powertrend_15m0_p[0]",powertrend_15m0_p[0], "  powertrend_15m0_p[1]=",powertrend_15m0_p[1],"  powertrend_15m0_p[2]=",powertrend_15m1_p[2],"  powertrend_15m0_p[3]=",powertrend_15m2_p[3]);
   //Print ("powertrend_15m1_p[0]",powertrend_15m1_p[0], "  powertrend_15m1_p[1]=",powertrend_15m1_p[1],"  powertrend_15m1_p[2]=",powertrend_15m1_p[2],"  powertrend_15m1_p[3]=",powertrend_15m2_p[3]);
   //Print ("powertrend_15m2_p[0]",powertrend_15m2_p[0], "  powertrend_15m2_p[1]=",powertrend_15m2_p[1],"  powertrend_15m2_p[2]=",powertrend_15m2_p[2],"  powertrend_15m2_p[3]=",powertrend_15m2_p[3]);
   //##Print (" Nowy bar2");
  }
  
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja przestawiajaca BE
void break_even()
{
   RefreshRates();
   if (activate_be >= 0)
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol()== OrderSymbol() && magic_number == OrderMagicNumber())
      {
         double act_be = activate_be;
         if (act_be + step_be < MarketInfo(Symbol(),MODE_STOPLEVEL)) act_be = MarketInfo(Symbol(),MODE_STOPLEVEL);
         
         if (OrderType() == OP_BUY  && NormalizeDouble(Bid - OrderOpenPrice(),Digits) >= act_be * Point && (OrderStopLoss() == 0 || OrderStopLoss() < OrderOpenPrice())) 
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice() + step_be * Point,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
         if (OrderType() == OP_SELL && NormalizeDouble(OrderOpenPrice() - Ask,Digits) >= act_be * Point && (OrderStopLoss() == 0 || OrderStopLoss() > OrderOpenPrice())) 
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice() - step_be * Point,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
      }
   }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// funkcja ruchomego stoploss

void trailing_stop()
{
   RefreshRates();
   if (activate_ts >= 0)
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol()== OrderSymbol() && OrderStopLoss() != 0 && magic_number == OrderMagicNumber())
      {
         double sl_ts = stop_loss_ts;
         if (sl_ts < MarketInfo(Symbol(),MODE_STOPLEVEL)) sl_ts = MarketInfo(Symbol(),MODE_STOPLEVEL);
         if (OrderType() == OP_BUY  && NormalizeDouble(Bid - OrderOpenPrice(),Digits) >= activate_ts  * Point && NormalizeDouble(Ask - OrderStopLoss(),Digits) >= (sl_ts + step_ts) * Point) 
            OrderModify(OrderTicket(),OrderOpenPrice(),Ask - sl_ts * Point,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
         if (OrderType() == OP_SELL && NormalizeDouble(OrderOpenPrice() - Ask,Digits) >= activate_ts  * Point && NormalizeDouble(OrderStopLoss() - Bid,Digits) >= (sl_ts + step_ts) * Point) 
            OrderModify(OrderTicket(),OrderOpenPrice(),Bid + sl_ts * Point,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
      }
   }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//funkcja ustawiajaca tp
void set_take_profit()
{
   RefreshRates();
   if (take_profit >= 0)
   for(int i = OrdersTotal() - 1; i >= 0;i--)
   {  
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if (Symbol()== OrderSymbol() && OrderTakeProfit() == 0 && magic_number == OrderMagicNumber())
      {
         tp = take_profit;
         if (tp < MarketInfo(Symbol(),MODE_STOPLEVEL)) tp = MarketInfo(Symbol(),MODE_STOPLEVEL);
         if (OrderType() == OP_BUY) 
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),Ask + tp * Point,OrderExpiration(),CLR_NONE);
         if (OrderType() == OP_SELL) 
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),Bid - tp * Point,OrderExpiration(),CLR_NONE);
      }
   }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void zapis_silny_szczyt()
{

  int k;

  // Print ("Wejsciowe trend0_rsi=",trend0_rsi);
   if (trend0_rsi_p[0]==0) trend0_rsi_p[0]=trend0_rsi;
   if (trend1_rsi_p[0]==0) trend1_rsi_p[0]=trend1_rsi;
   if (trend2_rsi_p[0]==0) trend2_rsi_p[0]=trend2_rsi;
   
   for(  k =6; k>0; k--) trend0_rsi_p[k]=trend0_rsi_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
   for(  k =6; k>0; k--) trend1_rsi_p[k]=trend1_rsi_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
   for(  k =6; k>0; k--) trend2_rsi_p[k]=trend2_rsi_p[k-1]; //przesuniecie wszystkich wartosci tablicy o 1 pozycje
   
   trend0_rsi_p[0]=trend0_rsi; //zaktualizowanie ostatniej wartoœci RSI
   trend1_rsi_p[0]=trend1_rsi; //zaktualizowanie ostatniej wartoœci RSI
   trend2_rsi_p[0]=trend2_rsi; //zaktualizowanie ostatniej wartoœci RSI

   if (trend0_rsi_p[3]!=trend1_rsi_p[3] && trend0_rsi_p[3]!=trend2_rsi_p[3]) {trendup2_rsi=false;trenddn2_rsi=false;trendstp2_rsi=true;}
   if (trend0_rsi_p[3]==trend1_rsi_p[3])                                     {trendup2_rsi=true; trenddn2_rsi=false;trendstp2_rsi=false;}
   if (trend0_rsi_p[3]==trend2_rsi_p[3])                                     {trendup2_rsi=false;trenddn2_rsi=true; trendstp2_rsi=false;}

}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SW_hull do S/L
//Wlaczyæ przy BE

void BE_custom()
{
   trend0 = iCustom(NULL,PERIOD_M15,"SW_hull THV",0,0);
   trend1 = iCustom(NULL,PERIOD_M15,"SW_hull THV",1,0); 
   trend2 = iCustom(NULL,PERIOD_M15,"SW_hull THV",2,0);

   if (trend0!=trend1 && trend0!=trend2) {trendup2=false;trenddn2=false;trendstp2=true;}
   if (trend0==trend1)                   {trendup2=true; trenddn2=false;trendstp2=false;}
   if (trend0==trend2)                   {trendup2=false;trenddn2=true ;trendstp2=false;}

   // ponizsze z Period1 na potrzeby uruchamiania BE
   //to tez  wlaczyc przy BE
   trend0_p1 = iCustom(NULL,PERIOD_M15,"SW_hull THV",0,1);
   trend1_p1 = iCustom(NULL,PERIOD_M15,"SW_hull THV",1,1); 
   trend2_p1 = iCustom(NULL,PERIOD_M15,"SW_hull THV",2,1);

   if (trend0_p1!=trend1_p1 && trend0_p1!=trend2_p1) {trendup1=false;trenddn1=false;trendstp1=true;}
   if (trend0_p1==trend1_p1)                         {trendup1=true; trenddn1=false;trendstp1=false;}
   if (trend0_p1==trend2_p1)                         {trendup1=false;trenddn1=true; trendstp1=false;}
 }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                         WEJSCIA PO PRZEKROCZENIU GORNEJ/DOLENJ LINII KELTNERA
//sprawdzic z close[1] aby umozliwic wejcie po lekkim przekroczeni linii k.
//sprawdzic czy nie lepszy bedzie TSI_Short_C zamiast vshort

int wejscia_ketler()
{
   if (R_15m[0]>KMR_c_15m[0] && S_15m[0]<KDS_c_15m[0] && Close[1]<KD_15m)// Buy gdy jest mocny spadek poza dolna l. keltera  
   // || (R_c_15m[0]<KDR_c_15m[0] && S_c_15m[0]<KDS_c_15m[0] && Close[1]<KD)) 
         {
            if (dl_wejscia==1)
               {
                 if (Ask-Open[0]<15*pt && TSI_0b>TSI_1b && TSI_2b<0 && TSI_0b>0 && time!=Time[0]) {CRCO="CRC19";return(OP_BUY);} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                 //&& TSI_1b<0 
               }
                else
                  {
                   if (Ask-Open[0]<15*pt &&TSI_0b>TSI_1b && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && time!=Time[0]) {CRCO="CRC20";return(OP_BUY);} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                   if (RSI7_S_15m < RSI_Buy && TSI_1b>TSI_2b && TSI_3b<0 && TSI_2b<0 && TSI_1b<0 && TSI_0b>0 && TSI_0b<=15 && time!=Time[0]) {CRCO="CRC21";return(OP_BUY);} //Print ("Warunek SELL , Order=",Order);Print ("RSI FILTR ",FI_1f," ",RSI_filtr);    
                     //&& TSI_0b<=15
                  }
          }

   if (S_15m[0]<KMS_c_15m[0] && R_15m[0]>KUR_c_15m[0] && Close[1]>KU_15m)  //S1 bez "_C" aby zwiekszyc szanse wejscia
     //|| (S_c_15m[0]>KUS_c_15m[0] && R_c_15m[0]>KUR_c_15m[0] && Close[1]>KU)) //a tu specjalnie S1 "_C" aby zwiekszyc szanse wejscia
       {
         if (dl_wejscia==1)
            {
              if (Open[0]-Bid<15*pt && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && time!=Time[0]) {CRCO="CRC22";return(OP_SELL);}
            //&& TSI_1b>=-15
                 //Print ("Vshort shell");
            }
              else
               {
                 if (Open[0]-Bid<15*pt &&RSI7_R_15m > RSI_Sell && TSI_0b<TSI_1b && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-15 && time!=Time[0]) {CRCO="CRC23";return(OP_SELL);}
                 if (RSI7_R_15m > RSI_Sell && TSI_1b<TSI_2b && TSI_3b>0 && TSI_2b>0 && TSI_1b>0 && TSI_0b<0 && TSI_0b>=-15 && time!=Time[0]) {CRCO="CRC24";return(OP_SELL);}
                  //&& TSI_3b>0
               }
  
            }
 return (-1);
} //koniec funkcji wejscia_ketler


*/