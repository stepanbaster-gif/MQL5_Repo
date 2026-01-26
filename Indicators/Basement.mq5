//+------------------------------------------------------------------+
//|                                                     Basement.mq5 |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Stepan Baster"
#property indicator_separate_window
#property indicator_height 180
#property indicator_plots   1
#property indicator_type1   DRAW_NONE 

#include "Include/CandlePatterns.mqh" 

input int InpMagic    = 777; 
// Лимиты размеров (должны совпадать с советником)
input int InpSizeMicroLimit   = 5;   
input int InpSizeSmallLimit   = 20;  
input int InpSizeNormLimit    = 40;  
input int InpSizeLargeLimit   = 60;  

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
   ObjectsDeleteAll(0, "TM_B_"); // Удаляем все объекты подвала
}

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
   int win = ChartWindowFind();
   if(win < 0) return(rates_total);

   // Очищаем и рисуем заново
   ObjectsDeleteAll(win, "TM_B_Draw_"); 

   // Рисуем заголовок
   DrawText(win, "TM_B_Title", 10, 5, "MULTI-TIMEFRAME PATTERN MONITOR", clrWhite, 10);

   // --- ZONE 1: M1 ---
   ProcessTimeframe(win, _Symbol, PERIOD_M1, 10, 30, "M1");

   // --- ZONE 2: M5 ---
   ProcessTimeframe(win, _Symbol, PERIOD_M5, 250, 30, "M5");

   // --- ZONE 3: M15 ---
   ProcessTimeframe(win, _Symbol, PERIOD_M15, 490, 30, "M15");

   return(rates_total);
}

// Функция обработки одного ТФ
void ProcessTimeframe(int win, string sym, ENUM_TIMEFRAMES tf, int x_offset, int y_offset, string tf_name)
{
   PatternInfo p = ExtAnalyst.AnalyzePattern(sym, tf, 1);
   
   // Заголовок ТФ
   DrawText(win, "TM_B_H_"+tf_name, x_offset + 80, y_offset, tf_name, clrYellow, 12);
   
   // Описание паттерна
   DrawText(win, "TM_B_D_"+tf_name, x_offset + 10, y_offset + 100, p.description, clrWhite, 8);
   
   // Рисуем свечу 2 (Prev)
   DrawCandleParams(win, "TM_B_Draw_"+tf_name+"_C2", x_offset + 50, y_offset + 50, p.c2);
   
   // Рисуем свечу 1 (Signal)
   DrawCandleParams(win, "TM_B_Draw_"+tf_name+"_C1", x_offset + 120, y_offset + 50, p.c1);
   
   // Подписи размеров
   DrawText(win, "TM_B_S_"+tf_name+"_C2", x_offset + 50, y_offset + 85, ExtAnalyst.GetSizeString(p.c2.size_cat), clrGray, 7);
   DrawText(win, "TM_B_S_"+tf_name+"_C1", x_offset + 120, y_offset + 85, ExtAnalyst.GetSizeString(p.c1.size_cat), clrGray, 7);
}

void DrawCandleParams(int win, string name, int x, int y, CandleInfo &ci)
{
   color cColor = ci.is_bull ? clrLime : clrRed;
   if(ci.type == TYPE_DOJI) cColor = clrYellow;
   
   // Высота зависит от размера
   int h_total = 20;
   if(ci.size_cat == SIZE_SMALL) h_total = 35;
   if(ci.size_cat == SIZE_NORMAL) h_total = 50;
   if(ci.size_cat == SIZE_LARGE) h_total = 65;
   if(ci.size_cat == SIZE_EXTRA) h_total = 80;
   
   int w_body = 16;
   
   // Пропорции тела (визуально)
   int h_body = (int)(h_total * (ci.body_pct / 100.0));
   if(h_body < 2) h_body = 2; // Минимум
   
   // 1. Фитиль (Линия)
   string obj_wick = name + "_W";
   ObjectCreate(0, obj_wick, OBJ_RECTANGLE_LABEL, win, 0, 0);
   ObjectSetInteger(0, obj_wick, OBJPROP_XDISTANCE, x + (w_body/2) - 1);
   ObjectSetInteger(0, obj_wick, OBJPROP_YDISTANCE, y - (h_total/2));
   ObjectSetInteger(0, obj_wick, OBJPROP_XSIZE, 2);
   ObjectSetInteger(0, obj_wick, OBJPROP_YSIZE, h_total);
   ObjectSetInteger(0, obj_wick, OBJPROP_BGCOLOR, cColor);
   ObjectSetInteger(0, obj_wick, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   
   // 2. Тело
   string obj_body = name + "_B";
   ObjectCreate(0, obj_body, OBJ_RECTANGLE_LABEL, win, 0, 0);
   ObjectSetInteger(0, obj_body, OBJPROP_XDISTANCE, x);
   // Центрируем тело по вертикали относительно фитиля (схематично)
   ObjectSetInteger(0, obj_body, OBJPROP_YDISTANCE, y - (h_body/2)); 
   ObjectSetInteger(0, obj_body, OBJPROP_XSIZE, w_body);
   ObjectSetInteger(0, obj_body, OBJPROP_YSIZE, h_body);
   ObjectSetInteger(0, obj_body, OBJPROP_BGCOLOR, cColor);
   ObjectSetInteger(0, obj_body, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, obj_body, OBJPROP_BORDER_TYPE, BORDER_FLAT);
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
}