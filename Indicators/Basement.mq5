#property indicator_separate_window
#property indicator_height 150
#property indicator_plots 0

input color InpTextColor = clrCyan;
input int   InpFontSize  = 10;
input int   InpMagic     = 777;

int OnInit() {
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   // Левая колонка - Финансы
   CreateLabel("TM_Label_Title", 10, 10, "=== MONITOR: EURUSD ===", clrYellow);
   CreateLabel("TM_Label_Step",  10, 35, "STEP: 0", clrWhite);
   CreateLabel("TM_Label_Loss",  10, 55, "SERIES LOSS: 0.00", clrOrangeRed);
   CreateLabel("TM_Label_Net",   10, 75, "NET RESULT: 0.00", clrSpringGreen);
   
   // Правая колонка - События
   CreateLabel("TM_Label_NewsT", 250, 10, "=== NEXT ECONOMIC EVENT ===", clrCyan);
   CreateLabel("TM_Label_News",  250, 35, "WAITING FOR DATA...", clrLightBlue);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "TM_Label_"); }

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   string prefix = "TM_" + IntegerToString(InpMagic) + "_";
   
   // 1. Читаем числа из RAM
   double net  = GlobalVariableGet(prefix + "Net");
   double loss = GlobalVariableGet(prefix + "Loss");
   int    step = (int)GlobalVariableGet(prefix + "Step");
   
   // 2. Обновляем визуализацию
   ObjectSetString(0, "TM_Label_Step", OBJPROP_TEXT, "STEP: " + IntegerToString(step));
   ObjectSetString(0, "TM_Label_Loss", OBJPROP_TEXT, "SERIES LOSS: " + DoubleToString(loss, 2));
   ObjectSetString(0, "TM_Label_Net",  OBJPROP_TEXT, "NET RESULT: " + DoubleToString(net, 2));
   
   // 3. Читаем текст новости из скрытого объекта
   string news_obj = prefix + "NewsObj";
   if(ObjectFind(0, news_obj) >= 0) {
      string current_news = ObjectGetString(0, news_obj, OBJPROP_TEXT);
      ObjectSetString(0, "TM_Label_News", OBJPROP_TEXT, current_news);
   }
   return(rates_total);
}

void CreateLabel(string name, int x, int y, string text, color clr) {
   ObjectCreate(0, name, OBJ_LABEL, 1, 0, 0); 
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}