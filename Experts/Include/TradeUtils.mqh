//+------------------------------------------------------------------+
//|                                                   TradeUtils.mqh |
//|                                  Copyright 2026, Stepan Baster   |
//|                             VERSION 6.5 (SCREENSHOT DEBUG)       |
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

// --- OPEN BUY (С ПРОВЕРКОЙ СКРИНШОТА) ---
bool CTradeUtils::OpenBuy(double lot, double sl, double tp, string comment)
  {
   if(m_trade == NULL || m_symbol == NULL) return false;
   double price = m_symbol.Ask();
   
   if(m_trade.Buy(lot, m_symbol.Name(), price, sl, tp, comment))
     {
      ulong ticket = m_trade.ResultDeal(); 
      if(ticket == 0) ticket = m_trade.ResultOrder(); 

      // 1. Лог в файл
      if(m_logger != NULL) 
         m_logger.Log("OPEN BUY | TICKET: " + IntegerToString(ticket) + " | " + comment);
         
      // 2. Скриншот с отчетом в журнал
      string name = "Shot_BUY_" + IntegerToString((long)TimeCurrent()) + ".png";
      
      // Принудительно обновляем график перед снимком
      ChartRedraw(0);
      
      if(ChartScreenShot(0, name, 1920, 1080))
        {
         Print(">> SCREENSHOT SAVED: " + name); // <--- ИЩИТЕ ЭТО В ЖУРНАЛЕ
        }
      else
        {
         // Если ошибка - выводим код
         Print(">> SCREENSHOT FAILED! Error Code: ", GetLastError()); 
        }
      
      return true;
     }
   if(m_logger != NULL) m_logger.Log("Order Buy Error: " + IntegerToString(GetLastError()), true);
   return false;
  }

// --- OPEN SELL (С ПРОВЕРКОЙ СКРИНШОТА) ---
bool CTradeUtils::OpenSell(double lot, double sl, double tp, string comment)
  {
   if(m_trade == NULL || m_symbol == NULL) return false;
   double price = m_symbol.Bid(); 
   
   if(m_trade.Sell(lot, m_symbol.Name(), price, sl, tp, comment))
     {
      ulong ticket = m_trade.ResultDeal();
      if(ticket == 0) ticket = m_trade.ResultOrder();

      // 1. Лог в файл
      if(m_logger != NULL) 
         m_logger.Log("OPEN SELL | TICKET: " + IntegerToString(ticket) + " | " + comment);
         
      // 2. Скриншот с отчетом в журнал
      string name = "Shot_SELL_" + IntegerToString((long)TimeCurrent()) + ".png";
      
      ChartRedraw(0);

      if(ChartScreenShot(0, name, 1920, 1080))
        {
         Print(">> SCREENSHOT SAVED: " + name); // <--- ИЩИТЕ ЭТО В ЖУРНАЛЕ
        }
      else
        {
         Print(">> SCREENSHOT FAILED! Error Code: ", GetLastError());
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