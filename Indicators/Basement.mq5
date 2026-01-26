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

// Подключаем аналитика, чтобы знать имена свечей
#include "Include/CandlePatterns.mqh" 

input int InpMagic    = 777; 
input int InpFontSize = 10;
input color InpColor  = clrWhite;

// Настройки размеров для аналитика (должны совпадать с Engine)
input int InpSizeMicroLimit   = 5;   
input int InpSizeSmallLimit   = 20;  
input int InpSizeNormLimit    = 40;  
input int InpSizeLargeLimit   = 60; 

double EmptyBuffer[];
CCandleAnalyst ExtAnalyst;

//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   SetIndexBuffer(0, EmptyBuffer, INDICATOR_DATA);
   
   // Инициализируем аналитика
   ExtAnalyst.Init(InpSizeMicroLimit, InpSizeSmallLimit, InpSizeNormLimit, InpSizeLargeLimit);
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "TM_Label_");
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   int win = ChartWindowFind();
   if(win < 0) win = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) - 1;

   // 1. ПОЛУЧАЕМ ДАННЫЕ ОТ ENGINE (Global Variables)
   string prefix = "TM_" + IntegerToString(InpMagic) + "_";
   double val_net   = GlobalVariableGet(prefix + "Net");
   double val_step  = GlobalVariableGet(prefix + "Step");
   
   // 2. АНАЛИЗИРУЕМ СВЕЧИ (Сами, чтобы знать имена обеих)
   PatternInfo p = ExtAnalyst.AnalyzePattern(_Symbol, PERIOD_CURRENT, 1);
   
   // Формируем цвета и названия для C2 (Пред) и C1 (Сигнал)
   string t2 = ExtAnalyst.GetTypeString(p.c2.type);
   string t1 = ExtAnalyst.GetTypeString(p.c1.type);
   string s2 = ExtAnalyst.GetSizeString(p.c2.size_cat);
   string s1 = ExtAnalyst.GetSizeString(p.c1.size_cat);
   
   color c2_color = p.c2.is_bull ? clrLime : clrRed;
   if(p.c2.type == TYPE_DOJI) c2_color = clrYellow;
   
   color c1_color = p.c1.is_bull ? clrLime : clrRed;
   if(p.c1.type == TYPE_DOJI) c1_color = clrYellow;

   // 3. ПОЛУЧАЕМ НОВОСТИ (Из объекта)
   string news_obj = prefix + "NewsObj";
   string news_text = "NO NEWS DATA";
   if(ObjectFind(0, news_obj) >= 0) {
      news_text = ObjectGetString(0, news_obj, OBJPROP_TEXT);
   }

   // --- ОТРИСОВКА (ТРИ КОЛОНКИ) ---

   // КОЛОНКА 1: СТАТУС (Слева)
   UpdateLabel("TM_Label_Title", 10, 5,  "TRADE MONSTER STATUS", clrWhite, win, 12);
   UpdateLabel("TM_Label_Net",   10, 30, "NET P/L: " + DoubleToString(val_net, 2), (val_net >= 0 ? clrLime : clrRed), win, 10);
   UpdateLabel("TM_Label_Step",  10, 50, "CURRENT STEP: " + IntegerToString((int)val_step), clrWhite, win, 10);

   // КОЛОНКА 2: СВЕЧИ (Посередине - ТЕПЕРЬ ДВЕ СТРОКИ)
   UpdateLabel("TM_Label_C_Head", 220, 5, "CANDLE ANALYSIS (2 BARS)", clrGray, win, 8);
   
   // Свеча 2 (Вчера)
   UpdateLabel("TM_Label_C2",     220, 25, "PREV (2): " + t2 + " [" + s2 + "]", c2_color, win, 10);
   // Свеча 1 (Сигнал)
   UpdateLabel("TM_Label_C1",     220, 45, "SIGNAL(1): " + t1 + " [" + s1 + "]", c1_color, win, 10);
   
   // Общее описание паттерна (мелко снизу)
   UpdateLabel("TM_Label_Patt",   220, 70, "Combo: " + p.description, clrGray, win, 8);

   // КОЛОНКА 3: НОВОСТИ (Справа - 3 строчки)
   UpdateLabel("TM_Label_N_Head", 480, 5, "UPCOMING EVENTS", clrCyan, win, 8);
   
   // Разбиваем текст новостей на 3 строки по символу переноса "\n"
   string line1 = "-", line2 = "-", line3 = "-";
   int idx1 = StringFind(news_text, "\n");
   
   if(idx1 < 0) {
      line1 = news_text; // Всего одна новость
   } else {
      line1 = StringSubstr(news_text, 0, idx1);
      string rest = StringSubstr(news_text, idx1 + 1);
      int idx2 = StringFind(rest, "\n");
      if(idx2 < 0) {
         line2 = rest; // Две новости
      } else {
         line2 = StringSubstr(rest, 0, idx2);
         line3 = StringSubstr(rest, idx2 + 1); // Три новости
      }
   }
   
   UpdateLabel("TM_Label_N1", 480, 25, line1, clrLightBlue, win, 8);
   UpdateLabel("TM_Label_N2", 480, 40, line2, clrLightBlue, win, 8);
   UpdateLabel("TM_Label_N3", 480, 55, line3, clrLightBlue, win, 8);

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