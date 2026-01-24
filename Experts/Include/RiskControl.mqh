//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//|                                            VERSION 2.0 (SHARED)  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Stepan Baster"
#property link      ""
#property version   "2.00"
#property strict

class CLogger
  {
private:
   string            m_symbol;
   long              m_account;
   string            m_filename_main;
   string            m_filename_spread;

public:
                     CLogger(void);
                    ~CLogger(void);

   // Инициализация (привязка к счету)
   void              Init(string symbol, long account_id);

   // Основной лог (торговля и ошибки)
   void              Log(string message, bool is_error = false);

   // Лог спреда (только аномалии)
   void              LogSpread(double spread, double threshold);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogger::CLogger(void)
  {
   m_symbol = "";
   m_account = 0;
   m_filename_main = "";
   m_filename_spread = "";
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogger::~CLogger(void)
  {
  }

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
void CLogger::Init(string symbol, long account_id)
  {
   m_symbol = symbol;
   m_account = account_id;
   
   // Формируем имена файлов с ID счета, чтобы не путать демо и реал
   m_filename_main = "TradeMonster_Log_" + IntegerToString(account_id) + ".csv";
   m_filename_spread = "Spread_Monitor_" + IntegerToString(account_id) + ".csv";
  }

//+------------------------------------------------------------------+
//| Main Log Function                                                |
//+------------------------------------------------------------------+
void CLogger::Log(string message, bool is_error = false)
  {
   // Флаги: Чтение | Запись | CSV | ANSI | !! РАЗРЕШИТЬ ОБЩИЙ ДОСТУП !!
   int handle = FileOpen(m_filename_main, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE, ";");
   
   if(handle != INVALID_HANDLE)
     {
      // Переходим в конец файла
      FileSeek(handle, 0, SEEK_END);
      
      // Если файл пустой (начало), пишем заголовок
      if(FileSize(handle) == 0)
        {
         FileWrite(handle, "Time", "Symbol", "Type", "Message");
        }
      
      string type = is_error ? "ERROR" : "INFO";
      FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), m_symbol, type, message);
      FileClose(handle);
     }
   else
     {
      Print("CRITICAL ERROR: Cannot open log file! Error code: ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//| Spread Log Function                                              |
//+------------------------------------------------------------------+
void CLogger::LogSpread(double spread, double threshold)
  {
   // Тот же набор флагов с FILE_SHARE_READ
   int handle = FileOpen(m_filename_spread, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE, ";");
   
   if(handle != INVALID_HANDLE)
     {
      FileSeek(handle, 0, SEEK_END);
      
      if(FileSize(handle) == 0)
        {
         FileWrite(handle, "Time", "Symbol", "Spread", "Threshold", "Comment");
        }
      
      string comment = "High Spread Detected";
      FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), m_symbol, DoubleToString(spread, 1), DoubleToString(threshold, 1), comment);
      FileClose(handle);
     }
  }
//+------------------------------------------------------------------+