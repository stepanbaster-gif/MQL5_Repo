#property indicator_separate_window
#property indicator_height 150
#property indicator_plots 0

input color InpTextColor = clrCyan;
input int   InpFontSize  = 10;
input int   InpMagic     = 777;

int OnInit() {
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   ObjectCreate(0, "TM_Label_Step", OBJ_LABEL, 1, 0, 0);
   ObjectSetInteger(0, "TM_Label_Step", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "TM_Label_Step", OBJPROP_YDISTANCE, 35);
   ObjectSetString(0, "TM_Label_Step", OBJPROP_TEXT, "STEP: 0");
   
   ObjectCreate(0, "TM_Label_News", OBJ_LABEL, 1, 0, 0);
   ObjectSetInteger(0, "TM_Label_News", OBJPROP_XDISTANCE, 250);
   ObjectSetInteger(0, "TM_Label_News", OBJPROP_YDISTANCE, 35);
   ObjectSetString(0, "TM_Label_News", OBJPROP_TEXT, "WAITING FOR DATA...");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "TM_Label_"); }

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   string prefix = "TM_" + IntegerToString(InpMagic) + "_";
   
   // Читаем цифру шага
   double step = GlobalVariableGet(prefix + "Step");
   ObjectSetString(0, "TM_Label_Step", OBJPROP_TEXT, "STEP: " + IntegerToString((int)step));
   
   // Читаем текст новости из объекта
   string news_obj = prefix + "NewsObj";
   if(ObjectFind(0, news_obj) >= 0) {
      string txt = ObjectGetString(0, news_obj, OBJPROP_TEXT);
      ObjectSetString(0, "TM_Label_News", OBJPROP_TEXT, txt);
   }
   return(rates_total);
}