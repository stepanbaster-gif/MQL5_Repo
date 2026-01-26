//+------------------------------------------------------------------+
//|                                                     Basement.mq5 |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Stepan Baster"
#property indicator_separate_window
#property indicator_height 120
#property indicator_buffers 1 
#property indicator_plots   1
#property indicator_type1   DRAW_NONE 

input int InpMagic    = 777; 
input int InpFontSize = 10;
input color InpColor  = clrWhite;

double EmptyBuffer[];

//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   SetIndexBuffer(0, EmptyBuffer, INDICATOR_DATA);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "TM_Label_");
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   int win = ChartWindowFind();
   if(win < 0) win = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) - 1;

   string prefix = "TM_" + IntegerToString(InpMagic) + "_";

   // 1. Читаем данные из Глобальных Переменных (связь с Engine)
   double val_net   = GlobalVariableGet(prefix + "Net");
   double val_step  = GlobalVariableGet(prefix + "Step");
   double val_type  = GlobalVariableGet(prefix + "CandleType");
   
   // 2. Читаем Новости (из скрытого объекта, который создает Engine)
   string news_obj = prefix + "NewsObj";
   string news_text = "WAITING FOR NEWS DATA...";
   if(ObjectFind(0, news_obj) >= 0) {
      news_text = ObjectGetString(0, news_obj, OBJPROP_TEXT);
   }

   // 3. Расшифровка типа свечи
   string p_text = "ANALYZING...";
   color p_color = clrGray;
   int c_type = (int)val_type;

   if(c_type == 1)      { p_text = "FULL BULL (Strong)"; p_color = clrLime; }
   else if(c_type == 2) { p_text = "FULL BEAR (Strong)"; p_color = clrRed; }
   else if(c_type == 3) { p_text = "NORMAL BULL"; p_color = clrSpringGreen; }
   else if(c_type == 4) { p_text = "NORMAL BEAR"; p_color = clrTomato; }
   else if(c_type == 5) { p_text = "PIN BAR (Bullish)"; p_color = clrAqua; }
   else if(c_type == 6) { p_text = "PIN BAR (Bearish)"; p_color = clrMagenta; }
   else if(c_type == 7) { p_text = "DOJI (Indecision)"; p_color = clrYellow; }
   
   // 4. Отрисовка Текста (Левая колонка - Статус)
   UpdateLabel("TM_Label_Title", 10, 5,  "TRADE MONSTER STATUS", clrWhite, win, 12);
   UpdateLabel("TM_Label_Net",   10, 30, "NET P/L: " + DoubleToString(val_net, 2), (val_net >= 0 ? clrLime : clrRed), win, 10);
   UpdateLabel("TM_Label_Step",  10, 50, "CURRENT STEP: " + IntegerToString((int)val_step), clrWhite, win, 10);
   
   // 5. Центральная колонка - Паттерн
   UpdateLabel("TM_Label_P_Title", 250, 5,  "LAST CANDLE PATTERN", clrGray, win, 8);
   UpdateLabel("TM_Label_Pattern", 250, 25, p_text, p_color, win, 12);
   
   // 6. Правая колонка - Новости (Мультистрочный текст)
   UpdateLabel("TM_Label_N_Title", 500, 5, "UPCOMING NEWS", clrCyan, win, 8);
   
   // Разбиваем новости на строки, если они склеены
   string line1 = news_text;
   string line2 = "";
   string line3 = "";
   
   int n1 = StringFind(news_text, "\n");
   if(n1 > 0) {
      line1 = StringSubstr(news_text, 0, n1);
      string rest = StringSubstr(news_text, n1 + 1);
      int n2 = StringFind(rest, "\n");
      if(n2 > 0) {
         line2 = StringSubstr(rest, 0, n2);
         line3 = StringSubstr(rest, n2 + 1);
      } else {
         line2 = rest;
      }
   }
   
   UpdateLabel("TM_Label_News1", 500, 25, line1, clrLightBlue, win, 8);
   UpdateLabel("TM_Label_News2", 500, 40, line2, clrLightBlue, win, 8);
   UpdateLabel("TM_Label_News3", 500, 55, line3, clrLightBlue, win, 8);

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