//+------------------------------------------------------------------+
//|                                                   TradeUtils.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//|                                     VERSION 5.3 (ADD SELL)       |
//+------------------------------------------------------------------+
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include "Logger.mqh"

class CTradeUtils
  {
private:
   CTrade           *m_trade;
   CSymbolInfo      *m_symbol;
   CLogger          *m_logger;
   int               m_magic;

public:
                     CTradeUtils();
                    ~CTradeUtils();

   void              Init(CTrade *trade_ptr, CSymbolInfo *symbol_ptr, CLogger *logger_ptr, int magic);

   // Открытие позиций
   bool              OpenBuy(double lot, double sl, double tp, string comment);
   bool              OpenSell(double lot, double sl, double tp, string comment); // <--- ДОБАВЛЕНО
   
   // Закрытие
   void              CloseAllPositions();
  };

CTradeUtils::CTradeUtils() : m_trade(NULL), m_symbol(NULL), m_logger(NULL), m_magic(0) {}
CTradeUtils::~CTradeUtils() {}

void CTradeUtils::Init(CTrade *trade_ptr, CSymbolInfo *symbol_ptr, CLogger *logger_ptr, int magic)
  {
   m_trade = trade_ptr;
   m_symbol = symbol_ptr;
   m_logger = logger_ptr;
   m_magic = magic;
  }

// --- BUY ---
bool CTradeUtils::OpenBuy(double lot, double sl, double tp, string comment)
  {
   if(m_trade == NULL || m_symbol == NULL) return false;
   double price = m_symbol.Ask();
   
   if(m_trade.Buy(lot, m_symbol.Name(), price, sl, tp, comment))
     {
      if(m_logger != NULL) m_logger.Log("BUY OPEN. Lot: " + DoubleToString(lot, 2) + " | " + comment);
      ChartScreenShot(0, "Shot_BUY_"+IntegerToString((long)TimeCurrent())+".png", 1920, 1080);
      return true;
     }
   if(m_logger != NULL) m_logger.Log("Order Buy Error: " + IntegerToString(GetLastError()), true);
   return false;
  }

// --- SELL ---
bool CTradeUtils::OpenSell(double lot, double sl, double tp, string comment)
  {
   if(m_trade == NULL || m_symbol == NULL) return false;
   double price = m_symbol.Bid(); // Продаем по Bid
   
   if(m_trade.Sell(lot, m_symbol.Name(), price, sl, tp, comment))
     {
      if(m_logger != NULL) m_logger.Log("SELL OPEN. Lot: " + DoubleToString(lot, 2) + " | " + comment);
      ChartScreenShot(0, "Shot_SELL_"+IntegerToString((long)TimeCurrent())+".png", 1920, 1080);
      return true;
     }
   if(m_logger != NULL) m_logger.Log("Order Sell Error: " + IntegerToString(GetLastError()), true);
   return false;
  }

void CTradeUtils::CloseAllPositions()
  {
   if(m_trade == NULL) return;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == m_magic)
        {
         m_trade.PositionClose(ticket);
         if(m_logger != NULL) m_logger.Log("FORCE CLOSE -> Ticket: " + IntegerToString(ticket));
        }
     }
  }