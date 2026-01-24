//+------------------------------------------------------------------+
//|                 Script_CloseAllMagic.mq5                         |
//|  Closes all positions for current symbol with specified Magic    |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include <Trade/Trade.mqh>

input long InpMagic = 9001;

CTrade trade;

//+------------------------------------------------------------------+
void OnStart()
{
   string sym = _Symbol;

   int total = PositionsTotal();
   int closed = 0, skipped = 0;

   for(int i=total-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) { skipped++; continue; }

      string ps = PositionGetString(POSITION_SYMBOL);
      long   pm = (long)PositionGetInteger(POSITION_MAGIC);

      if(ps != sym || pm != InpMagic)
      {
         skipped++;
         continue;
      }

      trade.SetExpertMagicNumber(InpMagic);

      bool ok = trade.PositionClose(ticket);
      if(!ok)
      {
         Print("Close FAILED. ticket=", (string)ticket,
               " retcode=", trade.ResultRetcode(),
               " desc=", trade.ResultRetcodeDescription());
         continue;
      }

      closed++;
      Print("Close OK. ticket=", (string)ticket,
            " deal=", trade.ResultDeal(),
            " magic=", InpMagic);
   }

   Print("CloseAllMagic DONE. closed=", closed, " skipped=", skipped, " sym=", sym, " magic=", InpMagic);
}
