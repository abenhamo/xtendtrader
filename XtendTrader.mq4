//+------------------------------------------------------------------+
//|                                                  XtendTrader.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "abenhamo @ XtendPlex"
#property link      "http://www.xtendplex.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//extern int EA_Magic;
extern double Lot=0.01;
//extern int StratNumber = 7;
extern double Take_Profit=0;
extern double TP_Shift=0.8;
extern double Max_lot=0.20;
extern bool Use_Average_Profit_As_TP=true;
extern double Stop_Loss=0;
extern bool Use_Mult_TP_As_SL=false;
extern double Mult=3;
extern bool Use_Razor_Scalper= true;
extern bool Use_Trend_Lazer=false;
extern bool Use_Fort_ind=true;
extern bool Reverse_mode= true;
extern int Max_Trades=4;
extern double Minimum_Success_Rate=90;


extern string Trend_Lazer_Parameters="Trend Lazer Parameters";
extern int Trend_Lazer_PPeriod=3;
extern int Trend_Lazer_Maximum_History_Bars=1000;
extern string Razor_Scalper_Parameters=" Razor Scalper Parameters";
extern int Razor_Scalper_PPeriod=7;
extern int Razor_Scalper_Maximum_History_Bars=1000;
extern string Fort_ind_Parameters ="Fort ind Parameters";
extern int Fort_ind_Period=34;


string Trades_Comment = Reverse_mode ? "XtendTrader Rev Mode": "XtendTrader Agressive Mode";

double  Success_Rate=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,18,1),5);

double Average_Profit=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,16,1),5);
double Min_Move=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,17,1),5);

double Used_TP =0;
double Used_SL = 0;

int Last_Razor=0;
int Actual_Trades=0;

double Used_Lot=0;

datetime LastOpenTime=0;

bool Buy_Exist=false;
bool Sell_Exist=false;

int Buy_Ticket=0;
int Sell_Ticket=0;
int Actual_Trades_Sell= 0;
int Actual_Trades_Buy = 0;
int LastTraded=0;

int Last_Proc=0;
double BuySellCounter =0;
bool closeBuy = false;
bool closeSell = false;
int EA_Instance_UID;
int EA_Number = 111;
string AutoMagic;
int EA_Magic;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int AutoMagic()
{
   string 
      Cur1 = StringSubstr(Symbol(),0,3),
      Cur2 = StringSubstr(Symbol(),3,3),
      magic1 = "0",
      magic2 = "0";
 
   int 
      Period_ID = 0;
 
   if (Cur1 == "EUR") magic1 = "1";
   if (Cur1 == "GBP") magic1 = "2";
   if (Cur1 == "USD") magic1 = "3";
   if (Cur1 == "AUD") magic1 = "4";
   if (Cur1 == "CHF") magic1 = "5";
   if (Cur1 == "CAD") magic1 = "6";
   if (Cur1 == "JPY") magic1 = "7";
   if (Cur1 == "NZD") magic1 = "8";
 
   if (Cur2 == "EUR") magic2 = "1";
   if (Cur2 == "GBP") magic2 = "2";
   if (Cur2 == "USD") magic2 = "3";
   if (Cur2 == "AUD") magic2 = "4";
   if (Cur2 == "CHF") magic2 = "5";
   if (Cur2 == "CAD") magic2 = "6";
   if (Cur2 == "JPY") magic2 = "7";
   if (Cur2 == "NZD") magic2 = "8";
 
 
   switch (Period()){
        case PERIOD_MN1: Period_ID = 9; break;
        case PERIOD_W1:  Period_ID = 8; break;
        case PERIOD_D1:  Period_ID = 7; break;
        case PERIOD_H4:  Period_ID = 6; break;
        case PERIOD_H1:  Period_ID = 5; break;
        case PERIOD_M30: Period_ID = 4; break;
        case PERIOD_M15: Period_ID = 3; break;
        case PERIOD_M5:  Period_ID = 2; break;
        case PERIOD_M1:  Period_ID = 1; break;
   }
 
   AutoMagic = StringConcatenate(EA_Number, EA_Instance_UID, magic1, magic2, Period_ID,0);
   while (GlobalVariableCheck(AutoMagic)){                                                                        // if MagicNumber already exists then increment Instance_UID
        EA_Instance_UID ++;               
        AutoMagic = StringConcatenate(EA_Number, EA_Instance_UID, magic1, magic2, Period_ID,0);
   }
   if (!GlobalVariableCheck(AutoMagic)) GlobalVariableSet(AutoMagic,StrToDouble(AutoMagic));                      // MagicNumber does not exist, so write it as a Gvar
   if (EA_Instance_UID > 1 ){
         Print("Note that this is instance number " + IntegerToString(EA_Instance_UID) + " of this EA on this currency pair!");    // alert the user to the conflict
         Alert("Multiple instance of same EA & same currency pair. Check your risk settings. EA_Instance_UID reassigned!");
   }
   return(StrToInteger(AutoMagic));
}



void Close_X()
  {

   if(LastTraded==0 && Last_Proc!=Buy_Ticket)
     {

      if(OrderSelect(Buy_Ticket,SELECT_BY_TICKET,MODE_HISTORY))
        {
         if(OrderCloseTime()!=0)
            { 
               if(OrderProfit()>0) 
                 {
                  for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
                    {
                     if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
                       {
                        if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==0)
                          {
      
                           while(IsTradeContextBusy()==True) {Sleep(100);}
                           closeBuy= OrderClose(OrderTicket(),OrderLots(),Bid,3,clrRed);
      
                          }
      
                       }
      
                    }
                  Last_Proc=Buy_Ticket;
                  BuySellCounter =0;
                  return;
      
                 }
           }
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(LastTraded==1 && Last_Proc!=Sell_Ticket)
     {

      if(OrderSelect(Sell_Ticket,SELECT_BY_TICKET,MODE_HISTORY))
        {
         if(OrderCloseTime()!=0)
            {
               if(OrderProfit()>0) 
                 {
      
                  for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
                    {
                     if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
                       {
                        if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==1)
                          {
      
                           while(IsTradeContextBusy()==True) {Sleep(100);}
                           closeSell= OrderClose(OrderTicket(),OrderLots(),Ask,3,clrRed);
      
                          }
      
                       }
      
                    }
      
                  Last_Proc=Sell_Ticket;
                  BuySellCounter =0;
                  return;
      
      
                 }
            }
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_Actual_Profit(int type)
  {

   double profit=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(type==0)
     {

      for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
        {
         if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==0) profit=profit+OrderProfit();

           }

        }

     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(type==1)
     {

      for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
        {
         if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==1) profit=profit+OrderProfit();

           }

        }

     }

   return NormalizeDouble(profit,2);


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_Actual_Lots(int type)
  {

   double lots=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(type==0)
     {

      for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
        {
         if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==0) lots=lots+OrderLots();

           }

        }

     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(type==1)
     {

      for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
        {
         if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==1) lots=lots+OrderLots();

           }

        }

     }

   return NormalizeDouble(lots,2);



  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_Avg_Price(int type)
  {

   double price=0;
   int trades=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(type==0)
     {

      for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
        {
         if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==0) {price=price+OrderOpenPrice(); trades=trades+1; }

           }

        }

     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(type==1)
     {

      for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
        {
         if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==1) {price=price+OrderOpenPrice(); trades=trades+1; }

           }

        }

     }

   return NormalizeDouble(price/trades,5);



  }
//+------------------------------------------------------------------+
// X * current_price + Total_lots_same_way x Avg_open_price =current_price + avg_profit × TP_Shift 

// X  = (current_price + avg_profit × TP_Shift -  Total_lots_same_way x Avg_open_price) / current_price

int Get_Nb_Trades(int type)
  {

   int num=0;

   for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==type) num=num+1;

        }
     }

   return num;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool lazorFunct(bool isLong) {
if(Use_Trend_Lazer) {
double UpLazer=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,0,1),5);
double DownLazer=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,1,1),5);

if(isLong) {
if(UpLazer != 0 && DownLazer == 0) return true;
else return false;
} else {
if(DownLazer != 0 && UpLazer == 0) return true;
else return false;
}
} else return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool scalperFunct(bool isLong) {
if(Use_Razor_Scalper) {
double Buy_Razor=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Razor Scalper","___ S E T T I N G S ___",Razor_Scalper_PPeriod,Razor_Scalper_Maximum_History_Bars,"___ D I S P L A Y ___",false,"___ C O L O R S ___",1,"___ A L E R T S ___",false,false,false,false,2,1),5);
double Sell_Razor = NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Razor Scalper","___ S E T T I N G S ___",Razor_Scalper_PPeriod,Razor_Scalper_Maximum_History_Bars,"___ D I S P L A Y ___",false,"___ C O L O R S ___",1,"___ A L E R T S ___",false,false,false,false,3,1),5);
double Back_Razor = NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Razor Scalper","___ S E T T I N G S ___",Razor_Scalper_PPeriod,Razor_Scalper_Maximum_History_Bars,"___ D I S P L A Y ___",false,"___ C O L O R S ___",1,"___ A L E R T S ___",false,false,false,false,10,1),5);

if(isLong) {
if(Buy_Razor == 1 && Back_Razor == 1) return true;
else return false;
} else {
if(Sell_Razor == -1 && Back_Razor == -1) return true;
else return false;
}
} else return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool trendFunct(bool isLong) {
if(Use_Fort_ind) {
double TrendSmth = NormalizeDouble(iCustom(Symbol(),PERIOD_CURRENT,"Fort_ind",Fort_ind_Period,0,0),5);
if(isLong) {
if(Bid > TrendSmth) return true;
else return false;
} else {
if(Bid < TrendSmth) return true;
else return false;
}
} else return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   EA_Magic = AutoMagic();
   printf(IntegerToString(EA_Magic));
   return(INIT_SUCCEEDED);
  }
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  //AutoMagic= "";
  GlobalVariablesDeleteAll();
  printf(" AutoMagic : " + AutoMagic);

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void Reverse()
{

      Average_Profit=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,16,1),5);
     
      Update_SL_TP();
     

          if(scalperFunct(true) && lazorFunct(true) && trendFunct(true))
             {
                   if((Get_Nb_Trades(0)+ Get_Nb_Trades(1))==0) 
                   {  
                      Buy_Ticket=OrderSend(NULL,0,Lot,Ask,3,SL(Used_SL,0),TP(Used_TP,0),Trades_Comment,EA_Magic,0,clrRed);
                      LastTraded=0;
                      Last_Proc=Buy_Ticket; 
                      return;
                   }
                   
                   else 
                   {
                      if(LastTraded==1 && Last_Proc!=Buy_Ticket) 
                        {
                        
                        if(OrderSelect(Last_Proc,SELECT_BY_TICKET))
                           {
             
                              if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==1)
                                {
                                 closeSell= OrderClose(OrderTicket(),OrderLots(),Ask,3,clrRed);
                                }
                        
                           }
                        
                           Buy_Ticket=OrderSend(NULL,0,Lot,Ask,3,SL(Used_SL,0),TP(Used_TP,0),Trades_Comment,EA_Magic,0,clrRed);
                           LastTraded=0;
                           Last_Proc=Buy_Ticket;
                           return;
                               
                        }
                     }
             }
          
           if(lazorFunct(false) && scalperFunct(false) && trendFunct(false))
            {
                    if((Get_Nb_Trades(0)+ Get_Nb_Trades(1))==0)  
                   {  
                      Sell_Ticket=OrderSend(NULL,1,Lot,Bid,3,SL(Used_SL,1),TP(Used_TP,1),Trades_Comment,EA_Magic,0,clrRed);
                      LastTraded=1;
                      Last_Proc=Sell_Ticket; 
                      return;
                   }
                   
                 else 
                  {
                      if(LastTraded==0) //&& Last_Proc!=Sell_Ticket) 
                        {
                        
                           if(OrderSelect(Last_Proc,SELECT_BY_TICKET))
                              {
                
                                 if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==0)
                                   {
                                    closeBuy= OrderClose(OrderTicket(),OrderLots(),Bid,3,clrRed);
                                   }
                           
                              }
                        
                           Sell_Ticket=OrderSend(NULL,1,Lot,Bid,3,SL(Used_SL,1),TP(Used_TP,1),Trades_Comment,EA_Magic,0,clrRed);
                           LastTraded=1;
                           Last_Proc=Sell_Ticket;
                           return;
                               
                        }
                   }
            }
            

}

void OnTick()
  {
//---
if (Reverse_mode) {
 if(LastOpenTime!=Time[0])
   {
      Reverse();
     LastOpenTime=Time[0];
   }
}



else {

   if(LastOpenTime!=Time[0])
     {


      Success_Rate=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,18,1),5);

      Average_Profit=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,16,1),5);
      Min_Move=NormalizeDouble(iCustom(Symbol(),0,"Market\\PipFinite Trend Laser","___ S E T T I N G S ___",Trend_Lazer_PPeriod,Trend_Lazer_Maximum_History_Bars,"___ D I S P L A Y ___",false,false,2,15,8,true,"___ C O L O R S ___",1,true,"___ A L E R T S ___",false,false,false,17,1),5);

      Update_SL_TP();

      Update_Max();

      Update_SL_TP();

      Close_X();
      Open_Buy();
      Open_Sell();

      LastOpenTime=Time[0];
     }

   Close_X();
   Update_SL_TP();
   Update_Max();
   
   }

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Buy_Open_Conditions()
  {

      if(lazorFunct(true) && scalperFunct(true) && trendFunct(true) && Success_Rate >= Minimum_Success_Rate && Actual_Trades_Buy < Max_Trades ) return true;


   return false;


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Sell_Open_Conditions()
  {

      if(lazorFunct(false) && scalperFunct(false) && trendFunct(false) && Success_Rate >= Minimum_Success_Rate && Actual_Trades_Sell < Max_Trades ) return true;


   return false;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Open_Buy()
  {

   if(Buy_Open_Conditions())
     {
     
      BuySellCounter = BuySellCounter +1; 
      if(Get_Nb_Trades(0)==0) Used_Lot=NormalizeDouble(Lot,2);
      if(Get_Actual_Profit(0)>=0 && Get_Nb_Trades(0) >= 1) return;

      
      if(Get_Actual_Profit(0)<0 && Get_Nb_Trades(0)>=1) {
         //if (BuySellCounter <= -StratNumber) 
         Used_Lot=NormalizeDouble((Get_Actual_Lots(0)*(Get_Avg_Price(0)-Ask-NormalizeDouble(Average_Profit/10000,5)*TP_Shift))/(NormalizeDouble(Average_Profit/10000,5)*TP_Shift),2);
       //  else  return;//Used_Lot=NormalizeDouble(Lot,2);
       }
      
      
      if(Used_Lot <= 0 ) return;
      if(Used_Lot>Max_lot) return;//Used_Lot=NormalizeDouble(Max_lot,2);
      while(IsTradeContextBusy()==True) {Sleep(100);}

      Buy_Ticket=OrderSend(NULL,0,Used_Lot,Ask,3,SL(Used_SL,0),TP(Used_TP,0),Trades_Comment,EA_Magic,0,clrRed);
      LastTraded= 0;

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Open_Sell()
  {

   if(Sell_Open_Conditions())
     {
     
      BuySellCounter =BuySellCounter -1;
      if(Get_Nb_Trades(1)==0) Used_Lot=NormalizeDouble(Lot,2);
      if(Get_Actual_Profit(1)>=0 && Get_Nb_Trades(1) >= 1) return;

      if(Get_Actual_Profit(1)<0 && Get_Nb_Trades(1)>=1) {
      // if (BuySellCounter >= StratNumber) 
       Used_Lot=NormalizeDouble((Get_Actual_Lots(1)*(Get_Avg_Price(1)-Bid+NormalizeDouble(Average_Profit/10000,5)*TP_Shift))/(-NormalizeDouble(Average_Profit/10000,5)*TP_Shift),2);
      // else return; // Used_Lot=NormalizeDouble(Lot,2);
      }

      if(Used_Lot <= 0 ) return;
      if(Used_Lot>Max_lot) return;//Used_Lot=NormalizeDouble(Max_lot,2);
      while(IsTradeContextBusy()==True) {Sleep(100);}
      Sell_Ticket=OrderSend(NULL,1,Used_Lot,Bid,3,SL(Used_SL,1),TP(Used_TP,1),Trades_Comment,EA_Magic,0,clrRed);
      LastTraded=1;

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Update_SL_TP()
  {

   if(Use_Average_Profit_As_TP) Used_TP=NormalizeDouble(Average_Profit,2);
   if(!Use_Average_Profit_As_TP) Used_TP=Take_Profit;

   if(Use_Mult_TP_As_SL)  Used_SL = NormalizeDouble(Used_TP * Mult,2);
   if(!Use_Mult_TP_As_SL) Used_SL = Stop_Loss;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Update_Max()
  {

   int MaxBuy=0;
   int MaxSell=0;

   for(int iCnt=OrdersTotal()-1; iCnt>=0; iCnt --)
     {
      if(OrderSelect(iCnt,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==0) MaxBuy=MaxBuy+1;
         if(OrderMagicNumber()==EA_Magic && OrderSymbol()==Symbol() && OrderType()==1) MaxSell=MaxSell+1;

        }

     }

   Actual_Trades_Sell=MaxSell;
   Actual_Trades_Buy =MaxBuy;


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SL(double SL,int type)
  {

   if(SL == 0) return 0;

   if(type == 0) return ( Bid - SL * fPoint(Symbol()) );
   if(type == 1) return ( Ask + SL * fPoint(Symbol()) );

   return 0;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TP(double TP,int type)
  {

   if(TP == 0) return 0;

   if(type == 0) return ( Ask + TP * fPoint(Symbol()) );
   if(type == 1) return ( Bid - TP * fPoint(Symbol()) );


   return 0;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fPoint(string sPaire)
  {

   if((MarketInfo(sPaire, MODE_DIGITS)) == 2 || (MarketInfo(sPaire, MODE_DIGITS)) == 3) return 0.01;
   else return 0.0001;

  }
//+------------------------------------------------------------------+
