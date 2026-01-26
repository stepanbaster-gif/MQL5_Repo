//+------------------------------------------------------------------+
//|                                                     Basement.mq5 |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Stepan Baster"
#property indicator_separate_window
#property indicator_height 150
#property indicator_plots   1
#property indicator_type1   DRAW_NONE 

#include "Include/CandlePatterns.mqh" // Подключаем логику анализа

input int InpMagic    = 777; 
input int InpFontSize = 10;
// Настройки диапазонов для визуала (должны совпадать с советником)
input int     InpSizeMicroLimit   = 5;   
input int     InpSizeSmallLimit   = 20;  
input int     InpSizeNormLimit    = 40;  
input int     InpSizeLargeLimit   = 60;  

double EmptyBuffer[];

// Объект-аналитик внутри индикатора
CCandleAnalyst ExtAnalyst;

//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   SetIndexBuffer(0, EmptyBuffer, INDICATOR_DATA);
   
   ExtAnalyst.Init(InpSizeMicroLimit, InpSizeSmallLimit, InpSizeNormLimit, InpSizeLargeLimit);
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "TM_Label_");
   ObjectsDeleteAll(0, "TM_Draw_"); // Удаляем рисунки свечей
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   int win = ChartWindowFind();
   if(win < 0) return(rates_total);

   // 1. Анализируем две свечи
   PatternInfo p = ExtAnalyst.AnalyzePattern(1);

   // 2. Рисуем текст
   UpdateLabel("TM_Label_Title", 10, 10, "MARKET CONTEXT (2 BARS)", clrWhite, win, 10);
   UpdateLabel("TM_Label_Patt",  10, 30, "Combo: " + p.description, clrYellow, win, 12);

   // 3. ХУДОЖЕСТВЕННАЯ ЧАСТЬ: Рисуем свечи
   // Координаты центра рисования (справа, чтобы не мешать тексту)
   int start_x = 300;
   int start_y = 70; 
   int width = 20;
   
   // Рисуем Свечу 2 (Левая)
   DrawCandle(win, "TM_Draw_C2", start_x, start_y, width, p.c2);
   
   // Рисуем Свечу 1 (Правая)
   DrawCandle(win, "TM_Draw_C1", start_x + 40, start_y, width, p.c1);
   
   // Подписи под свечами
   UpdateLabel("TM_Label_C2_Name", start_x, start_y + 50, "PREV", clrGray, win, 8);
   UpdateLabel("TM_Label_C1_Name", start_x + 40, start_y + 50, "SIGNAL", clrGray, win, 8);

   return(rates_total);
  }

// Функция для рисования схематичной свечи
void DrawCandle(int win, string name, int x, int y, int w, CandleInfo &ci)
{
   // Базовый цвет
   color cColor = ci.is_bull ? clrLime : clrRed;
   if(ci.type == TYPE_DOJI) cColor = clrYellow;
   
   // Высота схематичная, зависит от размера (XS, S, M, L, XL)
   int h_pixels = 20;
   if(ci.size_cat == SIZE_SMALL) h_pixels = 30;
   if(ci.size_cat == SIZE_NORMAL) h_pixels = 50;
   if(ci.size_cat == SIZE_LARGE) h_pixels = 70;
   if(ci.size_cat == SIZE_EXTRA) h_pixels = 90;
   
   // 1. Тело (Rectangle Label)
   string obj_body = name + "_Body";
   if(ObjectFind(0, obj_body) < 0) ObjectCreate(0, obj_body, OBJ_RECTANGLE_LABEL, win, 0, 0);
   ObjectSetInteger(0, obj_body, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, obj_body, OBJPROP_YDISTANCE, y - (h_pixels/2)); // Центрируем
   ObjectSetInteger(0, obj_body, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, obj_body, OBJPROP_YSIZE, h_pixels);
   ObjectSetInteger(0, obj_body, OBJPROP_BGCOLOR, cColor);
   ObjectSetInteger(0, obj_body, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, obj_body, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   
   // 2. Хвосты (вертикальная линия через Rectangle Label шириной 1-2 пикселя)
   string obj_wick = name + "_Wick";
   if(ObjectFind(0, obj_wick) < 0) ObjectCreate(0, obj_wick, OBJ_RECTANGLE_LABEL, win, 0, 0);
   ObjectSetInteger(0, obj_wick, OBJPROP_XDISTANCE, x + (w/2) - 1);
   ObjectSetInteger(0, obj_wick, OBJPROP_YDISTANCE, y - (h_pixels/2) - 10); // Чуть выше тела
   ObjectSetInteger(0, obj_wick, OBJPROP_XSIZE, 2);
   ObjectSetInteger(0, obj_wick, OBJPROP_YSIZE, h_pixels + 20); // Длиннее тела
   ObjectSetInteger(0, obj_wick, OBJPROP_BGCOLOR, cColor);
   ObjectSetInteger(0, obj_wick, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void UpdateLabel(string name, int x, int y, string text, color clr, int window, int size=10)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, window, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
}