//+------------------------------------------------------------------+
//|                                                     Basement.mq5 |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Stepan Baster"
#property indicator_separate_window
#property indicator_height 150

// Исправление Warning
#property indicator_buffers 1  
#property indicator_plots   1
#property indicator_type1   DRAW_NONE 

#include "Include/CandlePatterns.mqh" 

input int InpMagic    = 777; 
// Настройки свечей (должны совпадать с Engine)
input int InpSizeMicroLimit   = 5;   
input int InpSizeSmallLimit   = 20;  
input int InpSizeNormLimit    = 40;  
input int InpSizeLargeLimit   = 60;  

// --- НАСТРОЙКИ ДИЗАЙНА ---
input int InpStartX   = 200; // Начало рисования (M1) - сдвинули вправо
input int InpStepX    = 150; // Шаг между таймфреймами (расстояние)

double EmptyBuffer[];
CCandleAnalyst ExtAnalyst;

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   SetIndexBuffer(0, EmptyBuffer, INDICATOR_DATA);
   
   ExtAnalyst.Init(InpSizeMicroLimit, InpSizeSmallLimit, InpSizeNormLimit, InpSizeLargeLimit);
   
   Print("Basement: Init OK. Compact Mode.");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "TM_B_"); 
   ChartRedraw(0);
}

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
   int win = ChartWindowFind();
   if(win < 0) win = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) - 1;

   ObjectsDeleteAll(0, "TM_B_Draw_"); 

   // 1. Левая часть - Заголовки (статичный текст)
   DrawText(win, "TM_B_MainTitle", 10, 10, "TRADE MONSTER", clrWhite, 12);
   DrawText(win, "TM_B_SubTitle",  10, 30, "Multi-Timeframe Logic", clrGray, 8);
   
   // Тут можно будет вывести общую информацию, место свободно (0-200 пикселей)

   // 2. Графическая часть (Сдвинута вправо)
   // M1 (на позиции InpStartX) -> например 200
   ProcessTimeframe(win, _Symbol, PERIOD_M1, InpStartX, 30, "M1");

   // M5 (на позиции InpStartX + шаг) -> например 350
   ProcessTimeframe(win, _Symbol, PERIOD_M5, InpStartX + InpStepX, 30, "M5");

   // M15 (на позиции InpStartX + 2*шаг) -> например 500
   ProcessTimeframe(win, _Symbol, PERIOD_M15, InpStartX + (InpStepX * 2), 30, "M15");

   ChartRedraw(0);
   return(rates_total);
}

void ProcessTimeframe(int win, string sym, ENUM_TIMEFRAMES tf, int x_offset, int y_offset, string tf_name)
{
   PatternInfo p = ExtAnalyst.AnalyzePattern(sym, tf, 1);
   
   if(p.c1.total_size_pts == 0 && p.c2.total_size_pts == 0)
   {
      DrawText(win, "TM_B_H_"+tf_name, x_offset + 30, y_offset, tf_name + "...", clrGray, 10);
      return;
   }

   // 1. Заголовок ТФ (чуть выше свечей)
   DrawText(win, "TM_B_H_"+tf_name, x_offset + 40, y_offset - 20, tf_name, clrYellow, 10);
   
   // 2. Рисуем свечи (теперь они меньше)
   // Свеча 2 (Prev)
   DrawCandleCompact(win, "TM_B_Draw_"+tf_name+"_C2", x_offset + 20, y_offset + 30, p.c2);
   
   // Свеча 1 (Signal)
   DrawCandleCompact(win, "TM_B_Draw_"+tf_name+"_C1", x_offset + 70, y_offset + 30, p.c1);
   
   // 3. Текстовое описание под свечами
   string desc = p.description; // Например: FULL BU + DOJI
   // Если описание длинное, разбиваем или уменьшаем шрифт
   DrawText(win, "TM_B_D_"+tf_name, x_offset, y_offset + 80, desc, clrWhite, 7);
   
   // Размеры (XS, XL...)
   DrawText(win, "TM_B_S_"+tf_name+"_C2", x_offset + 20, y_offset + 65, ExtAnalyst.GetSizeString(p.c2.size_cat), clrGray, 7);
   DrawText(win, "TM_B_S_"+tf_name+"_C1", x_offset + 70, y_offset + 65, ExtAnalyst.GetSizeString(p.c1.size_cat), clrGray, 7);
}

// Новая функция для рисования КОМПАКТНЫХ свечей
void DrawCandleCompact(int win, string name, int x, int y, CandleInfo &ci)
{
   color cColor = ci.is_bull ? clrLime : clrRed;
   if(ci.type == TYPE_DOJI) cColor = clrYellow;
   
   // --- НОВЫЕ РАЗМЕРЫ (Уменьшены) ---
   int h_total = 15; // Micro
   if(ci.size_cat == SIZE_SMALL) h_total = 25;
   if(ci.size_cat == SIZE_NORMAL) h_total = 35;
   if(ci.size_cat == SIZE_LARGE) h_total = 45;
   if(ci.size_cat == SIZE_EXTRA) h_total = 55; // Максимум 55 пикселей (было 80)
   
   int w_body = 10; // Ширина тела (было 16)
   
   int h_body = (int)(h_total * (ci.body_pct / 100.0));
   if(h_body < 2) h_body = 2; 
   
   // 1. Фитиль
   string obj_wick = name + "_W";
   if(ObjectFind(0, obj_wick) < 0) ObjectCreate(0, obj_wick, OBJ_RECTANGLE_LABEL, win, 0, 0);
   
   ObjectSetInteger(0, obj_wick, OBJPROP_XDISTANCE, x + (w_body/2) - 1);
   ObjectSetInteger(0, obj_wick, OBJPROP_YDISTANCE, y - (h_total/2));
   ObjectSetInteger(0, obj_wick, OBJPROP_XSIZE, 2); // Тонкий фитиль
   ObjectSetInteger(0, obj_wick, OBJPROP_YSIZE, h_total);
   ObjectSetInteger(0, obj_wick, OBJPROP_BGCOLOR, cColor);
   ObjectSetInteger(0, obj_wick, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, obj_wick, OBJPROP_BACK, false); 
   
   // 2. Тело
   string obj_body = name + "_B";
   if(ObjectFind(0, obj_body) < 0) ObjectCreate(0, obj_body, OBJ_RECTANGLE_LABEL, win, 0, 0);
   
   ObjectSetInteger(0, obj_body, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, obj_body, OBJPROP_YDISTANCE, y - (h_body/2)); 
   ObjectSetInteger(0, obj_body, OBJPROP_XSIZE, w_body);
   ObjectSetInteger(0, obj_body, OBJPROP_YSIZE, h_body);
   ObjectSetInteger(0, obj_body, OBJPROP_BGCOLOR, cColor);
   ObjectSetInteger(0, obj_body, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, obj_body, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, obj_body, OBJPROP_BACK, false); 
}

void DrawText(int win, string name, int x, int y, string text, color clr, int size)
{
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, win, 0, 0);
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false); 
}