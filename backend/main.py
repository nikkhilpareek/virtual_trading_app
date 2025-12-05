from fastapi import FastAPI, HTTPException
import yfinance as yf
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from datetime import datetime
import asyncio
from contextlib import asynccontextmanager
import os
from dotenv import load_dotenv
from order_monitor import OrderMonitorService

# Load environment variables
load_dotenv()

# Global monitor service instance
monitor_service = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan"""
    global monitor_service
    
    # Startup
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    
    if supabase_url and supabase_key:
        try:
            monitor_service = OrderMonitorService(supabase_url, supabase_key)
            await monitor_service.start()
        except Exception as e:
            print(f"❌ Failed to start order monitor: {e}")
            monitor_service = None
    else:
        print("⚠️  SUPABASE_URL or SUPABASE_KEY not set - Order monitoring disabled")
    
    yield
    
    # Shutdown
    if monitor_service:
        await monitor_service.stop()

app = FastAPI(
    title="Virtual Trading API",
    description="Backend API for Virtual Trading Application with Stop-Loss and Bracket Orders",
    version="2.0.0",
    lifespan=lifespan
)

# Allow Flutter (on localhost) to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all origins for testing
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_stock_data(symbol: str, suffix: str = ".NS"):
    """Helper function to fetch stock data with robust fallbacks for NSE/BSE."""
    try:
        base_symbol = symbol.upper().strip()
        attempted = []

        def try_history(tkr: str):
            s = yf.Ticker(tkr)
            # Primary attempt
            h = s.history(period="5d")
            if h is None or h.empty:
                # Fallback: direct download with repair and explicit interval
                h = yf.download(tkr, period="5d", interval="1d", progress=False, auto_adjust=False, repair=True)
            return s, h

        # 1) Try NSE first
        ticker = f"{base_symbol}{suffix}"
        attempted.append(ticker)
        stock, hist = try_history(ticker)

        # 2) If empty, try BSE
        if hist is None or hist.empty:
            ticker_bse = f"{base_symbol}.BO"
            attempted.append(ticker_bse)
            stock, hist = try_history(ticker_bse)

        # 3) If still empty, try without any suffix (Yahoo sometimes maps automatically)
        if hist is None or hist.empty:
            ticker_raw = base_symbol
            attempted.append(ticker_raw)
            stock, hist = try_history(ticker_raw)

        if hist is None or hist.empty:
            print(f"No data for {base_symbol}. Tried: {attempted}")
            return None

        latest = hist.iloc[-1]
        previous = hist.iloc[-2] if len(hist) > 1 else latest

        current_price = float(latest['Close'])
        previous_close = float(previous['Close'])
        change = current_price - previous_close
        change_percent = (change / previous_close * 100) if previous_close > 0 else 0.0

        # Try to fetch company name, but don't fail if unavailable
        name = base_symbol
        try:
            # Prefer get_info() when available; fall back to .info
            if hasattr(stock, "get_info"):
                info = stock.get_info()
            else:
                info = getattr(stock, "info", {}) or {}
            name = info.get('longName', info.get('shortName', base_symbol))
        except Exception:
            pass

        return {
            "symbol": base_symbol,
            "price": round(current_price, 2),
            "change": round(change, 2),
            "changePercent": round(change_percent, 2),
            "volume": int(latest.get('Volume', 0)) if isinstance(latest.get('Volume', 0), (int, float)) else 0,
            "previousClose": round(previous_close, 2),
            "open": round(float(latest['Open']), 2),
            "high": round(float(latest['High']), 2),
            "low": round(float(latest['Low']), 2),
            "latestTradingDay": latest.name.strftime('%Y-%m-%d') if hasattr(latest, 'name') else datetime.now().strftime('%Y-%m-%d'),
            "name": name,
        }
    except Exception as e:
        print(f"Error fetching {symbol}: {str(e)}")
        return None

@app.get("/")
def read_root():
    """API root endpoint"""
    return {
        "message": "Stonks Trading API",
        "version": "1.0.0",
        "endpoints": [
            "/quote/{symbol}",
            "/crypto/{symbol}",
            "/top",
            "/batch?symbols=SYMBOL1,SYMBOL2",
            "/search/{query}"
        ]
    }

@app.get("/quote/{symbol}")
def get_stock_quote(symbol: str):
    """
    Get detailed stock quote for Indian stocks
    Examples: RELIANCE, TCS, INFY, HDFCBANK
    """
    data = get_stock_data(symbol, ".NS")
    if data:
        return data
    else:
        raise HTTPException(status_code=404, detail=f"Stock data not found for {symbol}")

@app.get("/crypto/{symbol}")
def get_crypto_quote(symbol: str, market: str = "INR"):
    """
    Get cryptocurrency quote
    Examples: BTC, ETH, BNB, DOGE
    Market: USD, INR (default: INR)
    """
    try:
        # For crypto, use different suffixes
        if market.upper() == "INR":
            ticker = f"{symbol}-INR"
        else:
            ticker = f"{symbol}-{market.upper()}"
            
        crypto = yf.Ticker(ticker)
        hist = crypto.history(period="2d")
        
        if hist.empty:
            raise HTTPException(status_code=404, detail=f"Crypto data not found for {symbol}")
        
        latest = hist.iloc[-1]
        previous = hist.iloc[-2] if len(hist) > 1 else latest
        
        current_price = float(latest['Close'])
        previous_close = float(previous['Close'])
        change = current_price - previous_close
        change_percent = (change / previous_close * 100) if previous_close > 0 else 0.0
        
        return {
            "symbol": symbol.upper(),
            "market": market.upper(),
            "price": round(current_price, 2),
            "change": round(change, 2),
            "changePercent": round(change_percent, 2),
            "bidPrice": round(current_price * 0.999, 2),  # Approximate
            "askPrice": round(current_price * 1.001, 2),  # Approximate
            "lastRefreshed": latest.name.strftime('%Y-%m-%d %H:%M:%S'),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching crypto data: {str(e)}")

@app.get("/top")
def get_top_stocks():
    """Get top Indian stocks"""
    tickers = ["RELIANCE", "TCS", "INFY", "HDFCBANK", "ICICIBANK", 
               "HINDUNILVR", "BHARTIARTL", "ITC", "SBIN", "LT"]
    result = []
    
    for symbol in tickers:
        data = get_stock_data(symbol, ".NS")
        if data:
            result.append(data)
    
    return {"stocks": result}

@app.get("/batch")
def get_batch_quotes(symbols: str):
    """
    Get multiple stock quotes in batch
    Example: /batch?symbols=RELIANCE,TCS,INFY
    """
    symbol_list = [s.strip().upper() for s in symbols.split(',')]
    result = []
    
    for symbol in symbol_list:
        data = get_stock_data(symbol, ".NS")
        if data:
            result.append(data)
    
    return {"stocks": result, "count": len(result)}

@app.get("/search/{query}")
def search_stocks(query: str, limit: int = 20):
    """
    Search for Indian stocks by symbol or name
    Returns matching stocks from NSE/BSE
    """
    # Expanded Indian stocks database with NSE listings
    stocks_db = {
        "RELIANCE": "Reliance Industries Ltd",
        "TCS": "Tata Consultancy Services",
        "INFY": "Infosys Ltd",
        "HDFCBANK": "HDFC Bank Ltd",
        "ICICIBANK": "ICICI Bank Ltd",
        "HINDUNILVR": "Hindustan Unilever Ltd",
        "BHARTIARTL": "Bharti Airtel Ltd",
        "ITC": "ITC Ltd",
        "SBIN": "State Bank of India",
        "LT": "Larsen & Toubro Ltd",
        "KOTAKBANK": "Kotak Mahindra Bank",
        "AXISBANK": "Axis Bank Ltd",
        "WIPRO": "Wipro Ltd",
        "ASIANPAINT": "Asian Paints Ltd",
        "MARUTI": "Maruti Suzuki India Ltd",
        "TITAN": "Titan Company Ltd",
        "NESTLEIND": "Nestle India Ltd",
        "ADANIENT": "Adani Enterprises Ltd",
        "ADANIPORTS": "Adani Ports & SEZ Ltd",
        "ADANIGREEN": "Adani Green Energy Ltd",
        "POWERGRID": "Power Grid Corporation",
        "NTPC": "NTPC Ltd",
        "BAJFINANCE": "Bajaj Finance Ltd",
        "BAJAJFINSV": "Bajaj Finserv Ltd",
        "HCLTECH": "HCL Technologies Ltd",
        "TECHM": "Tech Mahindra Ltd",
        "ULTRACEMCO": "UltraTech Cement Ltd",
        "SUNPHARMA": "Sun Pharmaceutical",
        "DRREDDY": "Dr. Reddy's Laboratories",
        "CIPLA": "Cipla Ltd",
        "DIVISLAB": "Divi's Laboratories",
        "TATASTEEL": "Tata Steel Ltd",
        "JSWSTEEL": "JSW Steel Ltd",
        "HINDALCO": "Hindalco Industries",
        "VEDL": "Vedanta Ltd",
        "COALINDIA": "Coal India Ltd",
        "ONGC": "Oil & Natural Gas Corp",
        "BPCL": "Bharat Petroleum",
        "IOC": "Indian Oil Corporation",
        "GRASIM": "Grasim Industries",
        "TATAMOTORS": "Tata Motors Ltd",
        "M&M": "Mahindra & Mahindra",
        "EICHERMOT": "Eicher Motors Ltd",
        "HEROMOTOCO": "Hero MotoCorp Ltd",
        "BAJAJ-AUTO": "Bajaj Auto Ltd",
        "INDUSINDBK": "IndusInd Bank Ltd",
        "BANDHANBNK": "Bandhan Bank Ltd",
        "SHRIRAMFIN": "Shriram Finance Ltd",
        "ANGELONE": "Angel One Ltd",
        "ICICIGI": "ICICI Lombard General Insurance",
        "SBILIFE": "SBI Life Insurance",
        "HDFCLIFE": "HDFC Life Insurance",
        "BRITANNIA": "Britannia Industries",
        "DABUR": "Dabur India Ltd",
        "GODREJCP": "Godrej Consumer Products",
        "TATACONSUM": "Tata Consumer Products",
        "TATAPOWER": "Tata Power Company",
        "DLF": "DLF Ltd",
        "GODREJPROP": "Godrej Properties",
        "ZOMATO": "Zomato Ltd",
        "NYKAA": "FSN E-Commerce (Nykaa)",
        "PAYTM": "One97 Communications (Paytm)",
        "POLICYBZR": "PB Fintech (PolicyBazaar)",
    }
    
    query_upper = query.upper()
    matches = []
    
    # Search in stocks database
    for symbol, name in stocks_db.items():
        if query_upper in symbol or query_upper in name.upper():
            matches.append({
                "symbol": symbol,
                "name": name,
                "type": "stock",
                "exchange": "NSE"
            })
            
            if len(matches) >= limit:
                break
    
    return {"results": matches, "count": len(matches)}
