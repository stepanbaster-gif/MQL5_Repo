//+------------------------------------------------------------------+
//|                                                   NewsModule.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property strict

struct SNewsEvent
  {
   datetime time;
   string   currency;
   string   event_name;
   int      importance; // 1-Low, 2-Mid, 3-High
  };

class CNewsModule
  {
private:
   SNewsEvent m_events[];
   int        m_total;

public:
   CNewsModule() : m_total(0) {}
   
   // Добавление новости в список
   void AddEvent(datetime t, string curr, string name, int imp)
     {
      ArrayResize(m_events, m_total + 1);
      m_events[m_total].time = t;
      m_events[m_total].currency = curr;
      m_events[m_total].event_name = name;
      m_events[m_total].importance = imp;
      m_total++;
     }

   // Поиск ближайшей новости
   string GetNextNewsInfo()
     {
      if(m_total == 0) return "No events";
      datetime now = TimeCurrent();
      for(int i=0; i<m_total; i++)
        {
         if(m_events[i].time > now)
           {
            long diff = (long)m_events[i].time - (long)now;
            return StringFormat("%s [%s] in %02d:%02d", 
                   m_events[i].event_name, m_events[i].currency, 
                   diff/3600, (diff%3600)/60);
           }
        }
      return "All news passed";
     }
  };