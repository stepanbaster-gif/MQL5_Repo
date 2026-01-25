#property indicator_separate_window
#property indicator_height 150
#property indicator_plots 0

input color InpTextColor = clrCyan;
input int   InpFontSize  = 10;
input int   InpMagic     = 777;

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   
   // Сетка интерфейса
   CreateLabel("TM_Label_Title", 10, 10, "=== MONITOR: " + Symbol() + " ===", clrYellow);
   
   CreateLabel("TM_Label_Step",  10, 35, "STEP: 0", clrWhite);
   CreateLabel("TM_Label_Loss",  10, 55, "SERIES LOSS: 0.00", clrOrangeRed);
   CreateLabel("TM_Label_Net",   10, 75, "NET RESULT: 0.00", clrSpringGreen);
   
   CreateLabel("TM_Label_NewsT", 250, 10, "=== NEXT ECONOMIC EVENT ===", clrCyan);
   CreateLabel("TM_Label_News",  250, 35, "WAITING FOR DATA...", clrLightBlue);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "TM_Label_"); }

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
   string prefix = "TM_" + IntegerToString(InpMagic) + "_";
   
   // Чтение числовых данных (RAM)
   double net  = GlobalVariableGet(prefix + "Net");
   double loss = GlobalVariableGet(prefix + "Loss");
   int    step = (int)GlobalVariableGet(prefix + "Step");
   
   // Обновление цифр
   ObjectSetString(0, "TM_Label_Step", OBJPROP_TEXT, "STEP: " + IntegerToString(step));
   ObjectSetString(0, "TM_Label_Loss", OBJPROP_TEXT, "SERIES LOSS: " + DoubleToString(loss, 2));
   ObjectSetString(0, "TM_Label_Net",  OBJPROP_TEXT, "NET RESULT: " + DoubleToString(net, 2));
   
// Чтение текста новости через скрытый объект
   string news_obj_name = prefix + "NewsObj";
   if(ObjectFind(0, news_obj_name) >= 0)
     {
      string current_news = ObjectGetString(0, news_obj_name, OBJPROP_TEXT);
      ObjectSetString(0, "TM_Label_News", OBJPROP_TEXT, current_news);
      
      // Логика цвета: если в строке есть "00:" (меньше часа до новости), красим в красный
      if(StringFind(current_news, "in 00:") >= 0)
         ObjectSetInteger(0, "TM_Label_News", OBJPROP_COLOR, clrOrangeRed);
      else
         ObjectSetInteger(0, "TM_Label_News", OBJPROP_COLOR, clrLightBlue);
     }

   return(rates_total);
}

void CreateLabel(string name, int x, int y, string text, color clr)
{
   ObjectCreate(0, name, OBJ_LABEL, 1, 0, 0); 
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}