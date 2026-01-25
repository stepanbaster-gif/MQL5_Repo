#property indicator_separate_window
#property indicator_height 150
#property indicator_plots 0

// Настройки отображения
input color InpTextColor = clrCyan;
input int   InpFontSize  = 10;
input int   InpMagic     = 777; // Должен совпадать с Magic советника

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   
   // Создаем метки для данных
   CreateLabel("TM_Label_Title", 10, 10, "=== SERIES MONITOR ===", InpTextColor);
   CreateLabel("TM_Label_Step",  10, 30, "STEP: 0", clrWhite);
   CreateLabel("TM_Label_Loss",  10, 50, "SERIES LOSS: 0.00", clrRed);
   CreateLabel("TM_Label_Net",   10, 70, "NET RESULT: 0.00", clrLime);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "TM_Label_");
}

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
   // Формируем префикс для поиска переменных (как в Engine v7.6)
   string prefix = "TM_" + IntegerToString(InpMagic) + "_";
   
   // Читаем данные из Глобальных Переменных терминала
   double net   = GlobalVariableGet(prefix + "Net");
   double loss  = GlobalVariableGet(prefix + "Loss");
   int    step  = (int)GlobalVariableGet(prefix + "Step");
   
   // Обновляем текст на экране
   ObjectSetString(0, "TM_Label_Step", OBJPROP_TEXT, "STEP: " + IntegerToString(step));
   ObjectSetString(0, "TM_Label_Loss", OBJPROP_TEXT, "SERIES LOSS: " + DoubleToString(loss, 2));
   ObjectSetString(0, "TM_Label_Net",  OBJPROP_TEXT, "NET RESULT: " + DoubleToString(net, 2));
   
   return(rates_total);
}

// Вспомогательная функция для создания текста
void CreateLabel(string name, int x, int y, string text, color clr)
{
   ObjectCreate(0, name, OBJ_LABEL, 1, 0, 0); // Индекс окна 1 (подвал)
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}