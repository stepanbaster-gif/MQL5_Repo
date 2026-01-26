//+------------------------------------------------------------------+
//|                                                   NewsModule.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//+------------------------------------------------------------------+
#property strict

// Структура для хранения и сортировки кандидатов
struct SNewsCandidate
{
   datetime time;    // Время
   string   title;   // Название
};

class CNewsModule
  {
private:
   string         m_symbol;
   string         m_curr_base;
   string         m_curr_profit;
   bool           m_only_high;
   
   datetime       m_last_update;

public:
   CNewsModule();
   ~CNewsModule();
   
   // Инициализация
   void Init(string symbol, bool only_high_importance);
   
   // Получение текста для Дашборда (ТОП-3)
   string GetNextNewsInfo();
   
private:
   // Вспомогательная функция: собирает новости в общий массив
   void CollectNewsForCurrency(string currency, datetime start, datetime end, 
                               SNewsCandidate &candidates[]);
  };

CNewsModule::CNewsModule()
  {
   m_symbol = "";
   m_only_high = true;
   m_last_update = 0;
  }

CNewsModule::~CNewsModule()
  {
  }

void CNewsModule::Init(string symbol, bool only_high_importance)
  {
   m_symbol = symbol;
   m_only_high = only_high_importance;
   
   // Определяем валюты
   m_curr_base   = SymbolInfoString(m_symbol, SYMBOL_CURRENCY_BASE);
   m_curr_profit = SymbolInfoString(m_symbol, SYMBOL_CURRENCY_PROFIT);
   
   if(m_curr_base == "" && StringLen(m_symbol) == 6)
     {
      m_curr_base = StringSubstr(m_symbol, 0, 3);
      m_curr_profit = StringSubstr(m_symbol, 3, 3);
     }
     
   Print("NewsModule: Init for ", m_symbol, " [", m_curr_base, " - ", m_curr_profit, "]");
  }

string CNewsModule::GetNextNewsInfo()
  {
   // Кэширование (чтобы не грузить терминал каждую секунду)
   if(TimeCurrent() - m_last_update < 60 && m_last_update > 0)
     {
      // (Упрощенно: позволяем коду ниже отработать, это быстро)
     }
   m_last_update = TimeCurrent();
   
   datetime start = TimeCurrent();
   datetime end   = start + 24 * 3600; // 24 часа вперед
   
   // Динамический массив для сбора всех подходящих новостей
   SNewsCandidate candidates[];
   
   // 1. Собираем новости по Базовой валюте
   if(m_curr_base != "")
      CollectNewsForCurrency(m_curr_base, start, end, candidates);
      
   // 2. Собираем новости по Валюте Прибыли
   if(m_curr_profit != "" && m_curr_profit != m_curr_base)
      CollectNewsForCurrency(m_curr_profit, start, end, candidates);
      
   // 3. Если ничего не нашли
   int total = ArraySize(candidates);
   if(total == 0) return "No events (24h)";
   
   // 4. Сортируем по времени (ближайшие - сверху)
   // ArraySort не работает со строками внутри структур, делаем простую сортировку пузырьком
   for(int i = 0; i < total - 1; i++)
     {
      for(int j = 0; j < total - i - 1; j++)
        {
         if(candidates[j].time > candidates[j + 1].time)
           {
            // Меняем местами
            SNewsCandidate temp = candidates[j];
            candidates[j] = candidates[j + 1];
            candidates[j + 1] = temp;
           }
        }
     }
   
   // 5. Формируем строку (ТОП 3)
   string result = "";
   int count = MathMin(total, 3); // Берем максимум 3 или сколько есть
   
   for(int i=0; i<count; i++)
     {
      long left_seconds = candidates[i].time - TimeCurrent();
      int h = (int)(left_seconds / 3600);
      int m = (int)((left_seconds % 3600) / 60);
      
      string s_time = IntegerToString(h) + "h " + IntegerToString(m) + "m";
      if(left_seconds < 0) s_time = "NOW!";
      
      // Формат: "2h 30m: NFP"
      // Добавляем перенос строки \n, если это не первая новость
      if(i > 0) result += "\n       "; 
      
      result += s_time + ": " + candidates[i].title;
     }
     
   return result;
  }

// Внутренний метод сбора новостей
void CNewsModule::CollectNewsForCurrency(string currency, datetime start, datetime end, 
                                         SNewsCandidate &candidates[])
{
   MqlCalendarValue values[];
   
   // Запрашиваем календарь для конкретной валюты (NULL вместо страны, currency - валюта)
   if(CalendarValueHistory(values, start, end, NULL, currency))
   {
      int total_vals = ArraySize(values);
      MqlCalendarEvent news_item; 
      
      for(int i=0; i<total_vals; i++)
      {
         // Получаем детали
         if(!CalendarEventById(values[i].event_id, news_item)) continue;
         
         // Фильтр Важности (High >= 2)
         if(m_only_high && news_item.importance < 2) continue;
         
         // Если новость подходит - добавляем в массив кандидатов
         int size = ArraySize(candidates);
         ArrayResize(candidates, size + 1);
         
         candidates[size].time  = values[i].time;
         candidates[size].title = news_item.name;
      }
   }
}