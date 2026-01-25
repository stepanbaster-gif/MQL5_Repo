#property strict
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include "Logger.mqh"

class CRiskControl
  {
private:
   CSymbolInfo      *m_symbol;
   CLogger          *m_logger;
   CAccountInfo      m_account;
   int               m_start_hour;
   int               m_end_hour;
   double            m_max_spread;

public:
                     CRiskControl(void);
                    ~CRiskControl(void);

   void              Init(CSymbolInfo *symbol_ptr, CLogger *logger_ptr);
   void              SetParams(int start_h, int end_h, double max_spread); // Убран bool
   bool              CheckTime(bool &is_close_time, int close_h, int close_m);
   bool              CheckSpread();
   bool              IsRealAccount();
  };

CRiskControl::CRiskControl(void) { }
CRiskControl::~CRiskControl(void) { }

void CRiskControl::Init(CSymbolInfo *symbol_ptr, CLogger *logger_ptr)
  {
   m_symbol = symbol_ptr;
   m_logger = logger_ptr;
  }

void CRiskControl::SetParams(int start_h, int end_h, double max_spread)
  {
   m_start_hour = start_h;
   m_end_hour = end_h;
   m_max_spread = max_spread;
  }

bool CRiskControl::IsRealAccount()
  {
   if(m_account.TradeMode() == ACCOUNT_TRADE_MODE_REAL)
     {
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.Log("CRITICAL: REAL ACCOUNT BLOCK", true);
      return true;
     }
   return false;
  }

bool CRiskControl::CheckSpread()
  {
   if(CheckPointer(m_symbol) == POINTER_INVALID) return false;
   m_symbol.RefreshRates();
   double spread_points = m_symbol.Spread(); 
   if(spread_points > m_max_spread)
     {
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.LogSpread(spread_points, m_max_spread);
      return false;
     }
   return true;
  }

bool CRiskControl::CheckTime(bool &is_close_time, int close_h, int close_m)
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour > close_h || (dt.hour == close_h && dt.min >= close_m))
     {
      is_close_time = true;
      return false;
     }
   is_close_time = false;
   if(dt.hour < m_start_hour || dt.hour >= m_end_hour)
      return false;
   return true;
  }#property strict
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include "Logger.mqh"

class CRiskControl
  {
private:
   CSymbolInfo      *m_symbol;
   CLogger          *m_logger;
   CAccountInfo      m_account;
   int               m_start_hour;
   int               m_end_hour;
   double            m_max_spread;

public:
                     CRiskControl(void);
                    ~CRiskControl(void);

   void              Init(CSymbolInfo *symbol_ptr, CLogger *logger_ptr);
   void              SetParams(int start_h, int end_h, double max_spread); // Убран bool
   bool              CheckTime(bool &is_close_time, int close_h, int close_m);
   bool              CheckSpread();
   bool              IsRealAccount();
  };

CRiskControl::CRiskControl(void) { }
CRiskControl::~CRiskControl(void) { }

void CRiskControl::Init(CSymbolInfo *symbol_ptr, CLogger *logger_ptr)
  {
   m_symbol = symbol_ptr;
   m_logger = logger_ptr;
  }

void CRiskControl::SetParams(int start_h, int end_h, double max_spread)
  {
   m_start_hour = start_h;
   m_end_hour = end_h;
   m_max_spread = max_spread;
  }

bool CRiskControl::IsRealAccount()
  {
   if(m_account.TradeMode() == ACCOUNT_TRADE_MODE_REAL)
     {
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.Log("CRITICAL: REAL ACCOUNT BLOCK", true);
      return true;
     }
   return false;
  }

bool CRiskControl::CheckSpread()
  {
   if(CheckPointer(m_symbol) == POINTER_INVALID) return false;
   m_symbol.RefreshRates();
   double spread_points = m_symbol.Spread(); 
   if(spread_points > m_max_spread)
     {
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.LogSpread(spread_points, m_max_spread);
      return false;
     }
   return true;
  }

bool CRiskControl::CheckTime(bool &is_close_time, int close_h, int close_m)
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour > close_h || (dt.hour == close_h && dt.min >= close_m))
     {
      is_close_time = true;
      return false;
     }
   is_close_time = false;
   if(dt.hour < m_start_hour || dt.hour >= m_end_hour)
      return false;
   return true;
  }