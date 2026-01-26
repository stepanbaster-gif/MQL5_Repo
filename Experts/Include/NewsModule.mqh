//+------------------------------------------------------------------+
//|                                                   NewsModule.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property strict

struct SNewsCandidate
{
   datetime time;    // Время события
   string   title;   // Название
   string   currency;// Валюта
};

class CNewsModule
{
private:
   string         m_symbol;
   bool           m_only_high;
   
   SNewsCandidate m_cache[]; // Кэш новостей
   datetime       m_last_update_time; // Время последнего обновления кэша

public:
   CNewsModule();
   ~CNewsModule();
   
   // Инициализация
   void Init(string symbol, bool only_high_importance);
   
   // Получение текста (ТОП-3), с авто-обновлением
   string GetNextNewsInfo();
   
private:
   // Принудительное обновление списка
   void RefreshNews();
   
   // Сбор новостей по одной валюте
   void CollectNewsForCurrency(string currency, datetime start, datetime end, SNewsCandidate &candidates[]);
};

CNewsModule::CNewsModule()
{
   m_symbol = "";
   m_only_high = true;
   m_last_update_time = 0;
}

CNewsModule::~CNewsModule()
{
}

void CNewsModule::Init(string symbol, bool only_high_importance)
{
   m_symbol = symbol;
   m_only_high = only_high_importance;
   m_last_update_time = 0; // Сброс таймера, чтобы обновиться сразу
   
   Print("NewsModule: Init for ", m_symbol, " [Auto-Refresh enabled]");
   RefreshNews(); // Первичная загрузка
}

string CNewsModule::GetNextNewsInfo()
{
   // 1. ПРОВЕРКА НА ОБНОВЛЕНИЕ (Раз в 15 минут = 900 секунд)
   if(TimeCurrent() - m_last_update_time > 900)
   {
      RefreshNews();
   }

   if(ArraySize(m_cache) == 0) return "No upcoming news";

   // 2. Формируем строку из ТОП-3 ближайших
   string result = "";
   int count = 0;
   datetime now = TimeCurrent();
   
   for(int i=0; i<ArraySize(m_cache); i++)
   {
      // Пропускаем уже прошедшие новости (старые удалятся при следующем Refresh)
      if(m_cache[i].time < now) continue;
      
      long left_seconds = m_cache[i].time - now;
      int h = (int)(left_seconds / 3600);
      int m = (int)((left_seconds % 3600) / 60);
      
      string s_time = IntegerToString(h) + "h " + IntegerToString(m) + "m";
      if(left_seconds < 60) s_time = "NOW!";
      
      // Добавляем разделитель, если это не первая строка
      if(count > 0) result += "\n"; 
      
      result += s_time + ": " + m_cache[i].currency + " - " + m_cache[i].title;
      
      count++;
      if(count >= 3) break; // Показываем только 3 ближайших
   }
   
   if(result == "") return "No upcoming news";
   return result;
}

void CNewsModule::RefreshNews()
{
   // Очищаем кэш
   ArrayFree(m_cache);
   
   // Определяем валюты пары (например EUR и USD)
   string base = StringSubstr(m_symbol, 0, 3);
   string profit = StringSubstr(m_symbol, 3, 3);
   
   // Берем новости от СЕЙЧАС до +3 ДНЯ
   datetime start = TimeCurrent();
   datetime end   = start + (3 * 24 * 3600); 
   
   // Собираем во временный массив
   SNewsCandidate temp_candidates[];
   CollectNewsForCurrency(base, start, end, temp_candidates);
   CollectNewsForCurrency(profit, start, end, temp_candidates);
   
   // Сортировка пузырьком (событий мало, так что быстро)
   int total = ArraySize(temp_candidates);
   for(int i=0; i<total-1; i++) {
      for(int j=0; j<total-i-1; j++) {
         if(temp_candidates[j].time > temp_candidates[j+1].time) {
            SNewsCandidate tmp = temp_candidates[j];
            temp_candidates[j] = temp_candidates[j+1];
            temp_candidates[j+1] = tmp;
         }
      }
   }
   
   // --- ИСПРАВЛЕНИЕ: Копируем вручную, так как есть string ---
   ArrayResize(m_cache, total);
   for(int i=0; i<total; i++)
   {
      m_cache[i].time     = temp_candidates[i].time;
      m_cache[i].title    = temp_candidates[i].title;
      m_cache[i].currency = temp_candidates[i].currency;
   }
   // ----------------------------------------------------------
   
   m_last_update_time = TimeCurrent();
   // Print("NewsModule: Updated. Found ", total, " events.");
}

void CNewsModule::CollectNewsForCurrency(string currency, datetime start, datetime end, 
                                         SNewsCandidate &candidates[])
{
   MqlCalendarValue values[];
   
   // Запрашиваем календарь
   if(CalendarValueHistory(values, start, end, NULL, currency))
   {
      int total_vals = ArraySize(values);
      MqlCalendarEvent news_item; 
      
      for(int i=0; i<total_vals; i++)
      {
         // Получаем описание события по ID
         if(!CalendarEventById(values[i].event_id, news_item)) continue;
         
         // Фильтр Важности
         // 0=None, 1=Low, 2=Medium, 3=High
         if(m_only_high && news_item.importance < 3) continue;
         
         // Добавляем в массив
         int size = ArraySize(candidates);
         ArrayResize(candidates, size + 1);
         candidates[size].time  = values[i].time;
         candidates[size].title = news_item.name; // Или news_item.event_code если имя пустое
         candidates[size].currency = currency;
      }
   }
}