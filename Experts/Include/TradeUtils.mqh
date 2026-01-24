//+------------------------------------------------------------------+
//|                                                   TradeUtils.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//|                                            VERSION 1.0 (MODULAR) |
//+------------------------------------------------------------------+
#property strict
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include "Logger.mqh"

class CTradeUtils
  {
private:
   CTrade           *m_trade;        // Указатель на CTrade (из Engine)
   CSymbolInfo      *m_symbol;       // Указатель на символ
   CLogger          *m_logger;       // Указатель на логгер
   int               m_magic;

public:
                     CTradeUtils(void);
                    ~CTradeUtils(void);

   void              Init(CTrade *trade_ptr, CSymbolInfo *symbol_ptr, CLogger *logger_ptr, int magic);

   // Операции
   bool              OpenBuy(double volume, string comment);
   void              CloseAllPositions();
   
   // Расчеты
   double            CalculateSeriesProfit();
   int               CountTrades();
  };

CTradeUtils::CTradeUtils(void) { }
CTradeUtils::~CTradeUtils(void) { }

void CTradeUtils::Init(CTrade *trade_ptr, CSymbolInfo *symbol_ptr, CLogger *logger_ptr, int magic)
  {
   m_trade = trade_ptr;
   m_symbol = symbol_ptr;
   m_logger = logger_ptr;
   m_magic = magic;
  }

bool CTradeUtils::OpenBuy(double volume, string comment)
  {
   if(CheckPointer(m_symbol) == POINTER_INVALID) return false;
   m_symbol.RefreshRates();
   
   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid(); // Для SL
   
   // Простой расчет стопов (можно усложнить позже)
   // Для стратегии сетки пока берем просто вход, стопы контролирует Engine или виртуально
   double sl = 0; 
   double tp = 0;

   bool res = m_trade.Buy(volume, m_symbol.Name(), ask, sl, tp, comment);
   
   if(res)
     {
      // Формируем красивую строку для лога (ИСПРАВЛЕНИЕ ОШИБКИ 387)
      string log_msg = StringFormat("ORDER OPEN: BUY Vol: %.2f Price: %.5f", volume, ask);
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.Log(log_msg);
      
      // Скриншот
      ChartScreenShot(0, "TradeMonster_Shot_" + IntegerToString((long)TimeCurrent()) + ".png", 1920, 1080);
     }
   else
     {
      string err = "Order Failed: " + IntegerToString(GetLastError());
      if(CheckPointer(m_logger) != POINTER_INVALID)
         m_logger.Log(err, true);
     }
   return res;
  }

void CTradeUtils::CloseAllPositions()
  {
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         if(PositionGetString(POSITION_SYMBOL) == m_symbol.Name() && PositionGetInteger(POSITION_MAGIC) == m_magic)
           {
            m_trade.PositionClose(ticket);
            if(CheckPointer(m_logger) != POINTER_INVALID)
               m_logger.Log("Hard Close: Ticket " + IntegerToString(ticket));
           }
        }
     }
  }

double CTradeUtils::CalculateSeriesProfit()
  {
   double profit = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      if(PositionGetTicket(i) > 0)
        {
         if(PositionGetString(POSITION_SYMBOL) == m_symbol.Name() && PositionGetInteger(POSITION_MAGIC) == m_magic)
           {
            profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
           }
        }
     }
   return profit;
  }