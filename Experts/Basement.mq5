//+------------------------------------------------------------------+
//|                                                     Basement.mq5 |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Stepan Baster"
#property indicator_separate_window
#property indicator_height 130
#property indicator_buffers 1 
#property indicator_plots   1
#property indicator_type1   DRAW_NONE 

#include "Include/CandlePatterns.mqh" 

input int InpMagic    = 777; 
input int InpFontSize = 10;
input color InpColor  = clrWhite;

input int InpSizeMicroLimit   = 5;   
input int InpSizeSmallLimit   = 20;  
input int InpSizeNormLimit    = 40;  
input int InpSizeLargeLimit   = 60; 

// Настройка только для отображения в заголовке, расчет берем из Engine
input int InpChannelDepth     = 20; 

double EmptyBuffer[];
CCandleAnalyst ExtAnalyst;

int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   SetIndexBuffer(0, EmptyBuffer, INDICATOR_DATA);
   ExtAnalyst.Init(InpSizeMicroLimit, InpSizeSmallLimit, InpSizeNormLimit, InpSizeLargeLimit);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "TM_Label_");
   ChartRedraw(0);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   int win = ChartWindowFind();
   if(win < 0) win = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) - 1;

   string prefix = "TM_" + IntegerToString(InpMagic) + "_";
   double val_net   = GlobalVariableGet(prefix + "Net");
   double val_step  = GlobalVariableGet(prefix + "Step");
   double val_float = GlobalVariableGet(prefix + "Float");
   double val_series = GlobalVariableGet(prefix + "SeriesSum");
   
   // --- ПОЛУЧАЕМ ГОТОВЫЙ КАНАЛ ИЗ ENGINE ---
   double val_high = GlobalVariableGet(prefix + "ChHigh");
   double val_low  = GlobalVariableGet(prefix + "ChLow");
   // ----------------------------------------
   
   PatternInfo p = ExtAnalyst.AnalyzePattern(_Symbol, PERIOD_CURRENT, 1);
   
   string t2 = ExtAnalyst.GetTypeString(p.c2.type);
   string t1 = ExtAnalyst.GetTypeString(p.c1.type);
   string s2 = ExtAnalyst.GetSizeString(p.c2.size_cat);
   string s1 = ExtAnalyst.GetSizeString(p.c1.size_cat);
   
   color c2_color = p.c2.is_bull ? clrLime : clrWhite;
   if(p.c2.type == TYPE_DOJI) c2_color = clrYellow;
   
   color c1_color = p.c1.is_bull ? clrLime : clrWhite;
   if(p.c1.type == TYPE_DOJI) c1_color = clrYellow;

   string news_obj = prefix + "NewsObj";
   string news_text = "NO NEWS DATA";
   if(ObjectFind(0, news_obj) >= 0) {
      news_text = ObjectGetString(0, news_obj, OBJPROP_TEXT);
   }

   // --- ОТРИСОВКА ---

   // 1. СТАТУС
   UpdateLabel("TM_Label_Title", 10, 5,  "TRADE MONSTER STATUS", clrWhite, win, 12);
   
   UpdateLabel("TM_Label_Net",   10, 30, "NET P/L: " + DoubleToString(val_net, 2), (val_net >= 0 ? clrLime : clrWhite), win, 10);
   UpdateLabel("TM_Label_Step",  10, 50, "CURRENT STEP: " + IntegerToString((int)val_step), clrWhite, win, 10);
   UpdateLabel("TM_Label_Float", 10, 70, "CURRENT FLOAT: " + DoubleToString(val_float, 2), (val_float >= 0 ? clrLime : clrWhite), win, 10);
   UpdateLabel("TM_Label_CSV",   10, 90, "SERIES (CSV): " + DoubleToString(val_series, 2), (val_series >= 0 ? clrLime : clrWhite), win, 10);

   // 2. СВЕЧИ
   UpdateLabel("TM_Label_C_Head", 250, 30, "CANDLE ANALYSIS (2 BARS)", clrWhite, win, 10);
   
   UpdateLabel("TM_Label_C2",     250, 50, "PREV (2): " + t2 + " [" + s2 + "]", c2_color, win, 10);
   UpdateLabel("TM_Label_C1",     250, 70, "SIGNAL(1): " + t1 + " [" + s1 + "]", c1_color, win, 10);
   UpdateLabel("TM_Label_Patt",   250, 90, "Combo: " + p.description, clrWhite, win, 8);
   
   // 3. КОРИДОР (Берем из Engine)
   int channel_size = 0;
   if(val_high > 0 && val_low > 0)
      channel_size = (int)((val_high - val_low) / SymbolInfoDouble(_Symbol, SYMBOL_POINT));

   UpdateLabel("TM_Label_D_Head", 500, 30, "CHANNEL (" + IntegerToString(InpChannelDepth) + " BARS)", clrWhite, win, 10);
   
   UpdateLabel("TM_Label_H", 500, 50, "HIGH: " + DoubleToString(val_high, _Digits), clrLime, win, 10);
   UpdateLabel("TM_Label_L", 500, 70, "LOW:  " + DoubleToString(val_low, _Digits), clrRed, win, 10);
   UpdateLabel("TM_Label_R", 500, 90, "RANGE: " + IntegerToString(channel_size) + " pts", clrGray, win, 8);
   
   // 4. НОВОСТИ
   UpdateLabel("TM_Label_N_Head", 750, 30, "UPCOMING EVENTS", clrWhite, win, 10);
   
   string line1 = "-", line2 = "-", line3 = "-";
   int idx1 = StringFind(news_text, "\n");
   
   if(idx1 < 0) {
      line1 = news_text;
   } else {
      line1 = StringSubstr(news_text, 0, idx1);
      string rest = StringSubstr(news_text, idx1 + 1);
      int idx2 = StringFind(rest, "\n");
      if(idx2 < 0) {
         line2 = rest;
      } else {
         line2 = StringSubstr(rest, 0, idx2);
         line3 = StringSubstr(rest, idx2 + 1);
      }
   }
   
   UpdateLabel("TM_Label_N1", 750, 50, line1, clrLightBlue, win, 8);
   UpdateLabel("TM_Label_N2", 750, 65, line2, clrLightBlue, win, 8);
   UpdateLabel("TM_Label_N3", 750, 80, line3, clrLightBlue, win, 8);

   ChartRedraw(0);
   return(rates_total);
  }

void UpdateLabel(string name, int x, int y, string text, color clr, int window, int size)
{
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, window, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK, false); 
   }
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
}