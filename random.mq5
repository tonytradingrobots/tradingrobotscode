#include <Trade\Trade.mqh>
CTrade trade;
ulong _ticket=0;

input double _tp=500; // Takeprofit in points
input double _sl=500; // Stoploss in points
input double percentrisk=0.25; // Risk % 

int OnInit()
{
   MathSrand(GetTickCount());
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
      if(MathRand()<16384)
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         lotsize=CalcLotsize(_sl*_Point);
         if(lotsize==0) return;
         if(trade.Buy(lotsize,_Symbol,entry,entry-(_sl*_Point),entry+(_tp*_Point),"Random Buy"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
      else
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         lotsize=CalcLotsize(_sl*_Point);
         if(lotsize==0) return;
         if(trade.Sell(lotsize,_Symbol,entry,entry+(_sl*_Point),entry-(_tp*_Point),"Random Sell"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
   }
   else
   {
      if(!PositionSelectByTicket(_ticket)) _ticket=0; // closed
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