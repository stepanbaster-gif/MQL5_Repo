//+------------------------------------------------------------------+
//|                                                  RiskControl.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//|                                            VERSION 1.0 (MODULAR) |
//+------------------------------------------------------------------+
#property strict
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include "Logger.mqh"

class CRiskControl
  {
private:
   CSymbolInfo      *m_symbol;       // Указатель на символ
   CLogger          *m_logger;       // Указатель на логгер
   CAccountInfo      m_account;

   // Настройки
   int               m_start_hour;
   int               m_end_hour;
   double            m_max_spread;
   bool              m_check_day_open;

public:
                     CRiskControl(void);
                    ~CRiskControl(void);

   void              Init(CSymbolInfo *symbol_ptr, CLogger *logger_ptr);
   void              SetParams(int start_h, int end_h, double max_spread, bool use_day_open);

   // Основные проверки
   bool              CheckTime(bool &is_close_time, int close_h, int close_m);
   bool              CheckSpread();
   bool              CheckDayOpen(ENUM_TIMEFRAMES timeframe);
   bool              IsRealAccount();
  };

CRiskControl::CRiskControl(void) { }
CRiskControl::~CRiskControl(void) { }

void CRiskControl::Init(CSymbolInfo *symbol_ptr, CLogger *logger_ptr)
  {
   m_symbol = symbol_ptr;
   m_logger = logger_ptr;
  }

void CRiskControl::SetParams(int start_h, int end_h, double max_spread, bool use_day_open)
  {
   m_start_hour = start_h;
   m_end_hour = end_h;
   m_max_spread = max_spread;
   m_check_day_open = use_day_open;
  }

bool CRiskControl::IsRealAccount()
  {
   if(m_account.TradeMode() == ACCOUNT_TRADE_MODE_REAL)
     {
      Print("CRITICAL: REAL ACCOUNT DETECTED. STOPPING.");
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.Log("CRITICAL: REAL ACCOUNT BLOCK ACTIVATED", true);
      return true; 
     }
   return false;
  }

bool CRiskControl::CheckSpread()
  {
   if(CheckPointer(m_symbol) == POINTER_INVALID) return false;
   
   m_symbol.RefreshRates();
   double spread_points = m_symbol.Spread(); // В пунктах терминала
   // Если 5-знак, иногда нужно корректировать, но обычно Spread() возвращает int/double корректно для сравнения
   
   // Логика мониторинга (как была раньше)
   if(spread_points > m_max_spread)
     {
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.LogSpread(spread_points, m_max_spread);
      return false; // Спред велик, торговать нельзя
     }
   return true; // Всё ок
  }

bool CRiskControl::CheckTime(bool &is_close_time, int close_h, int close_m)
  {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   // 1. Проверка на жесткое закрытие (Hard Stop)
   if(dt.hour == close_h && dt.min >= close_m)
     {
      is_close_time = true;
      return false; // Торговать нельзя, пора спать
     }
   
   if(dt.hour > close_h) // Если время перевалило (например 23 часа)
     {
      is_close_time = true;
      return false;
     }

   is_close_time = false;

   // 2. Проверка на вход (Soft Stop)
   if(dt.hour < m_start_hour || dt.hour >= m_end_hour)
      return false; // Время вне рабочего окна

   return true;
  }

bool CRiskControl::CheckDayOpen(ENUM_TIMEFRAMES timeframe)
  {
   if(!m_check_day_open) return true; // Если фильтр выключен
   
   double open_price = iOpen(NULL, PERIOD_D1, 0);
   double current_price = m_symbol.Bid();
   
   // Разрешаем BUY только если цена выше открытия дня
   if(current_price < open_price) return false;
   
   return true;
  }