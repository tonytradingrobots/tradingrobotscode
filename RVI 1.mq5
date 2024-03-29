#include <Trade\Trade.mqh>
CTrade trade;
ulong _ticket=0;
int hRVI,hEMA;
double bRVImain[],bRVIsignal[],bEMA[];

input double _sl=200; // Stoploss in points 
input int rvi_period=10; // RVI period
input int ema_period=50; // EMA period
input bool use_ema=true; // Use EMA filter
input double percentrisk=0.25; // Risk % 

int OnInit()
{
   hRVI=iRVI(_Symbol,_Period,rvi_period);
   ArraySetAsSeries(bRVImain,true); // [0] newest
   ArraySetAsSeries(bRVIsignal,true);
   hEMA=iMA(_Symbol,_Period,ema_period,0,MODE_EMA,PRICE_TYPICAL);
   ArraySetAsSeries(bEMA,true);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{ 
}
void OnTick()
{
   double entry,lotsize;
   
   if(_ticket==0)
   {
      CopyBuffer(hRVI,0,1,2,bRVImain);
      CopyBuffer(hRVI,1,1,2,bRVIsignal);
      CopyBuffer(hEMA,0,1,2,bEMA);   
      entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      
      if(iLow(_Symbol,_Period,1)>bEMA[0] || !use_ema) // price above EMA[1] up trend
      {
         if(bRVImain[0]>bRVIsignal[0] && bRVImain[1]<bRVIsignal[1] ) // main cross above signal is entry signal in up trend
         {
            entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            lotsize=CalcLotsize(_sl*_Point);
            if(lotsize==0) return;
            if(trade.Buy(lotsize,_Symbol,entry,entry-(_sl*_Point),0,"RVI/EMA Buy"))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE){ _ticket=trade.ResultOrder(); Print("Buy Entry signal opened"); }
            }
         }
      }
      
      if(iHigh(_Symbol,_Period,1)<bEMA[0] || !use_ema) // price below EMA[1] down trend
      {
         if(bRVImain[0]<bRVIsignal[0] && bRVImain[1]>bRVIsignal[1] ) // main cross below signal is entry signal in down trend
         {
            entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
            lotsize=CalcLotsize(_sl*_Point);
            if(lotsize==0) return;
            if(trade.Sell(lotsize,_Symbol,entry,entry+(_sl*_Point),0,"RVI/EMA Sell"))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE){ _ticket=trade.ResultOrder(); Print("Sell Entry signal opened"); }
            }
         }
      }
   }
   else
   {
      if(PositionSelectByTicket(_ticket))
      {
         CopyBuffer(hRVI,0,1,2,bRVImain);
         CopyBuffer(hRVI,1,1,2,bRVIsignal);
         CopyBuffer(hEMA,0,1,2,bEMA);   
      
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) // buy in up trend look for exit signal
         {
            if(bRVImain[0]<bRVIsignal[0] && bRVImain[1]>bRVIsignal[1] ) // main cross below signal is exit signal 
            {
               if(trade.PositionClose(_ticket,ULONG_MAX)){ _ticket=0; Print("Buy exit signal closed"); } else Print("Error closing a BUY on exit signal"); 
            }         
         }
         else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) // sell in down trend look for exit signal
         {
            if(bRVImain[0]>bRVIsignal[0] && bRVImain[1]<bRVIsignal[1] ) // main cross above signal is exit signal 
            {
               if(trade.PositionClose(_ticket,ULONG_MAX)){ _ticket=0; Print("Sell exit signal closed"); } else Print("Error closing a SELL on exit signal"); 
            }         
         }
      }
      else _ticket=0; // closed
   }
}

double CalcLotsize(double pricerisk) // i.e. 0.00100 is risk 100 points = 10 pips EURUSD
{
   double tmplotsize=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN); // minimum lotsize i.e. 0.01 CFD EURUSD
   double calc=tmplotsize; 
   double cashrisk=AccountInfoDouble(ACCOUNT_BALANCE)*percentrisk*0.01; // £10000 * 1% = £100
   double tickrisk=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE)*(pricerisk/SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)); // risk per 1.00 lot
   // tickvalue is 1 tick and 1.00 lot, 1 point/tick of EURUSD=$1/tick or point per 1.0 lot, this value is in account currency 
   
   if((tmplotsize*tickrisk)>cashrisk) return(0); // can't do minimum trade 0.01 > 1%
   
   while(true) // find nearest correct lotsize < 1%
   {
      if((tmplotsize*tickrisk)>cashrisk) break;
      calc=tmplotsize;
      tmplotsize+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
      if(tmplotsize>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; // maximum trade size      
   }   
   return(calc);
}