//+------------------------------------------------------------------+
//|                                                   NewsModule.mqh |
//|                            Copyright 25.01.2026, Stepan Baster   |
//|                    VERSION 2.0 (MT5 NATIVE CALENDAR)             |
//+------------------------------------------------------------------+
#property strict

class CNewsModule
  {
private:
   string   m_next_event_name;
   datetime m_next_event_time;
   string   m_next_event_curr;

public:
   CNewsModule() : m_next_event_name(""), m_next_event_time(0) {}

   // Метод автоматического сканирования календаря MT5
   void RefreshEvents()
     {
      MqlCalendarValue values[];
      datetime date_from = TimeCurrent();
      datetime date_to = date_from + PeriodSeconds(PERIOD_D1) * 7; // Смотрим на неделю вперед

      // Запрашиваем данные из встроенного календаря MetaTrader 5
      if(CalendarValueGet(values, date_from, date_to))
        {
         for(int i=0; i<ArraySize(values); i++)
           {
            MqlCalendarEvent event;
            if(CalendarEventById(values[i].event_id, event))
              {
               // ФИЛЬТР: Только EUR или USD И Только высокая важность (3)
               if((event.currency == "EUR" || event.currency == "USD") && 
                  event.importance == CALENDAR_IMPORTANCE_HIGH)
                 {
                  m_next_event_name = event.name;
                  m_next_event_time = values[i].time;
                  m_next_event_curr = event.currency;
                  return; // Нашли ближайшую и выходим
                 }
              }
           }
        }
     }

   string GetNextNewsInfo()
     {
      RefreshEvents(); // Обновляем данные

      if(m_next_event_time == 0) return "No High Impact News (EUR/USD)";

      datetime now = TimeCurrent();
      if(m_next_event_time > now)
        {
         long diff = (long)m_next_event_time - (long)now;
         return StringFormat("%s [%s] in %02d:%02d", 
                m_next_event_name, m_next_event_curr, 
                diff/3600, (diff%3600)/60);
        }
      return "Checking next events...";
     }
  };