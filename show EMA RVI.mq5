int hRVI,hEMA;
double bRVImain[],bRVIsignal[],bEMA[];

input int rvi_period=10; // RVI period
input int ema_period=50; // EMA period

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
   CopyBuffer(hRVI,0,1,2,bRVImain);
   CopyBuffer(hRVI,1,1,2,bRVIsignal);
   CopyBuffer(hEMA,0,1,2,bEMA);   
   
   Comment("\n\nEMA(",ema_period,")[1][2]=",DoubleToString(bEMA[0],_Digits+1)," ",DoubleToString(bEMA[1],_Digits+1),
      "\nRVI(",rvi_period,")main[1][2]=",DoubleToString(bRVImain[0],3)," ",DoubleToString(bRVImain[1],3),
      "\nRVI(",rvi_period,")signal[1][2]=",DoubleToString(bRVIsignal[0],3)," ",DoubleToString(bRVIsignal[1],3) );
}