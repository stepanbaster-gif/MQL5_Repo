#property indicator_separate_window
#property indicator_height 150
#property indicator_plots 0 // Нам не нужны линии, только графика

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "TM_Basement");
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   // Здесь позже будет отрисовка данных из Engine
   return(rates_total);
}