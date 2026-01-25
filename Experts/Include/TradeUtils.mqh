//+------------------------------------------------------------------+
//|                                                   TradeUtils.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//|                    VERSION 7.5 (COMMON FOLDER SCREENSHOTS)       |
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
   bool              OpenBuy(double lot, double sl, double tp, string comment);
   bool              OpenSell(double lot, double sl, double tp, string comment);
   void              CloseAllPositions();
   bool              ClosePartial(ulong ticket, double lot_to_close);
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

// --- OPEN BUY (С СОХРАНЕНИЕМ В COMMON ПАПКУ) ---
bool CTradeUtils::OpenBuy(double lot, double sl, double tp, string comment)
  {
   if(m_trade == NULL || m_symbol == NULL) return false;
   double price = m_symbol.Ask();
   
   if(m_trade.Buy(lot, m_symbol.Name(), price, sl, tp, comment))
     {
      ulong ticket = m_trade.ResultDeal();
      if(ticket == 0) ticket = m_trade.ResultOrder(); 

      if(m_logger != NULL) 
         m_logger.Log("OPEN BUY | TICKET: " + IntegerToString(ticket) + " | " + comment);

      // Имя файла для общей папки (начинается с '\')
      string name = "\\Shot_BUY_" + IntegerToString((long)TimeCurrent()) + ".png";
      ChartRedraw(0);

      // Используем флаг CHART_SCREENSHOT_COMMON (или сохранение через терминал)
      // В MT5 для сохранения в CommonFiles имя должно начинаться с '\'
      if(ChartScreenShot(0, name, 1920, 1080, ALIGN_RIGHT))
        {
         Print(">> SCREENSHOT SAVED TO COMMON: " + name);
        }
      else
        {
         Print(">> SCREENSHOT FAILED! Error: ", GetLastError());
        }
      
      return true;
     }
   if(m_logger != NULL) m_logger.Log("Order Buy Error: " + IntegerToString(GetLastError()), true);
   return false;
  }

// --- OPEN SELL (С СОХРАНЕНИЕМ В COMMON ПАПКУ) ---
bool CTradeUtils::OpenSell(double lot, double sl, double tp, string comment)
  {
   if(m_trade == NULL || m_symbol == NULL) return false;
   double price = m_symbol.Bid(); 
   
   if(m_trade.Sell(lot, m_symbol.Name(), price, sl, tp, comment))
     {
      ulong ticket = m_trade.ResultDeal();
      if(ticket == 0) ticket = m_trade.ResultOrder();

      if(m_logger != NULL) 
         m_logger.Log("OPEN SELL | TICKET: " + IntegerToString(ticket) + " | " + comment);

      string name = "\\Shot_SELL_" + IntegerToString((long)TimeCurrent()) + ".png";
      ChartRedraw(0);

      if(ChartScreenShot(0, name, 1920, 1080, ALIGN_RIGHT))
        {
         Print(">> SCREENSHOT SAVED TO COMMON: " + name);
        }
      else
        {
         Print(">> SCREENSHOT FAILED! Error: ", GetLastError());
        }

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

bool CTradeUtils::ClosePartial(ulong ticket, double lot_to_close)
  {
   if(m_trade == NULL) return false;
   
   if(PositionSelectByTicket(ticket))
     {
      double current_lot = PositionGetDouble(POSITION_VOLUME);
      
      if(lot_to_close >= current_lot)
        {
         if(m_trade.PositionClose(ticket))
           {
            if(m_logger != NULL) m_logger.Log("PARTIAL CLOSE (FULL) -> Ticket: " + IntegerToString(ticket));
            return true;
           }
        }
      else
        {
         if(m_trade.PositionClosePartial(ticket, lot_to_close))
           {
            if(m_logger != NULL) 
               m_logger.Log("PARTIAL CLOSE -> Ticket: " + IntegerToString(ticket) + " | Closed: " + DoubleToString(lot_to_close, 2));
            return true;
           }
        }
     }
   return false;
  }