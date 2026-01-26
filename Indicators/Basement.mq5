//+------------------------------------------------------------------+
//|                                                     Basement.mq5 |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Stepan Baster"
#property indicator_separate_window
#property indicator_buffers 1  // <-- ВОТ ЭТОЙ СТРОЧКИ НЕ ХВАТАЛО
#property indicator_plots   1
#property indicator_type1   DRAW_NONE 
#property indicator_height  150

input int InpMagic    = 777; 
input int InpFontSize = 10;
input int InpColumnX  = 500; // Отступ для новостей

// Буфер-пустышка
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
   if(win < 0) return(rates_total);

   string prefix = "TM_" + IntegerToString(InpMagic) + "_";

   // Читаем данные из Глобальных Переменных (GV)
   double g_net   = GlobalVariableGet(prefix + "Net");
   double g_loss  = GlobalVariableGet(prefix + "Loss");
   double g_step  = GlobalVariableGet(prefix + "Step");
   double g_profit= GlobalVariableGet(prefix + "Profit");
   double g_ctype = GlobalVariableGet(prefix + "CandleType"); // 1..7

   // 1. ЛЕВАЯ КОЛОНКА (Статистика)
   string txt_main = "STEP: " + IntegerToString((int)g_step) + 
                     " | SERIES LOSS: " + DoubleToString(g_loss, 2) + 
                     " | CURRENT: " + DoubleToString(g_profit, 2);
   
   color clr_net = (g_net >= 0) ? clrLime : clrRed;
   string txt_net = "NET RESULT: " + DoubleToString(g_net, 2);

   UpdateLabel("TM_Label_Main", 10, 10, txt_main, clrWhite, win);
   UpdateLabel("TM_Label_Net",  10, 35, txt_net,  clr_net, win, 14);

   // 2. ПРАВАЯ КОЛОНКА (Новости) - используем InpColumnX
   int col_x = InpColumnX;

   UpdateLabel("TM_Label_NewsHead", col_x, 5, "=== TOP 3 NEWS EVENTS ===", clrCyan, win);

   string news_obj = prefix + "NewsObj";
   string msg = (ObjectFind(0, news_obj) >= 0) ? ObjectGetString(0, news_obj, OBJPROP_TEXT) : "WAITING...";
   
   string lines[];
   StringSplit(msg, '\n', lines);
   int count = ArraySize(lines);
   
   if(count > 0) UpdateLabel("TM_Label_News1", col_x, 25, lines[0], clrLightBlue, win);
   else          UpdateLabel("TM_Label_News1", col_x, 25, "No events", clrGray, win);
   
   if(count > 1) UpdateLabel("TM_Label_News2", col_x, 40, lines[1], clrLightBlue, win);
   else          ObjectDelete(0, "TM_Label_News2");
   
   if(count > 2) UpdateLabel("TM_Label_News3", col_x, 55, lines[2], clrLightBlue, win);
   else          ObjectDelete(0, "TM_Label_News3");

   // Паттерн (под новостями)
   string p_text = "NO PATTERN";
   color p_color = clrGray;
   int c_type = (int)g_ctype;

   if(c_type == 1)      { p_text = "FULL BULL"; p_color = clrLime; }
   else if(c_type == 2) { p_text = "FULL BEAR"; p_color = clrRed; }
   else if(c_type == 3) { p_text = "NORMAL BULL"; p_color = clrSpringGreen; }
   else if(c_type == 4) { p_text = "NORMAL BEAR"; p_color = clrTomato; }
   else if(c_type == 5) { p_text = "PIN BULL"; p_color = clrAqua; }
   else if(c_type == 6) { p_text = "PIN BEAR"; p_color = clrMagenta; }
   else if(c_type == 7) { p_text = "DOJI"; p_color = clrYellow; }

   UpdateLabel("TM_Label_Pattern", col_x, 80, "LAST CANDLE: " + p_text, p_color, win);

   return(rates_total);
  }

void UpdateLabel(string name, int x, int y, string text, color clr, int window, int size=0)
{
   if(size == 0) size = InpFontSize;
   
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, window, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
}