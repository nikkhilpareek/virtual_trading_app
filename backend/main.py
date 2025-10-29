from fastapi import FastAPI, HTTPException
import yfinance as yf
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from datetime import datetime

app = FastAPI(title="Stonks Trading API", version="1.0.0")

# Allow Flutter (on localhost) to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all origins for testing
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_stock_data(symbol: str, suffix: str = ".NS"):
    """Helper function to fetch stock data with error handling"""
    try:
        ticker = f"{symbol}{suffix}"
        stock = yf.Ticker(ticker)
        
        # Get latest data
        hist = stock.history(period="5d")
        if hist.empty:
            return None
            
        info = stock.info
        latest = hist.iloc[-1]
        previous = hist.iloc[-2] if len(hist) > 1 else latest
        
        current_price = float(latest['Close'])
        previous_close = float(previous['Close'])
        change = current_price - previous_close
        change_percent = (change / previous_close * 100) if previous_close > 0 else 0.0
        
        return {
            "symbol": symbol.upper(),
            "price": round(current_price, 2),
            "change": round(change, 2),
            "changePercent": round(change_percent, 2),
            "volume": int(latest.get('Volume', 0)),
            "previousClose": round(previous_close, 2),
            "open": round(float(latest['Open']), 2),
            "high": round(float(latest['High']), 2),
            "low": round(float(latest['Low']), 2),
            "latestTradingDay": latest.name.strftime('%Y-%m-%d'),
            "name": info.get('longName', symbol.upper()),
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
def search_stocks(query: str):
    """
    Search for stocks (simplified version)
    Returns common Indian stocks matching the query
    """
    # Common Indian stocks database (simplified)
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
        "POWERGRID": "Power Grid Corporation",
        "NTPC": "NTPC Ltd",
    }
    
    query_upper = query.upper()
    matches = []
    
    for symbol, name in stocks_db.items():
        if query_upper in symbol or query_upper in name.upper():
            matches.append({
                "symbol": symbol,
                "name": name,
                "type": "stock"
            })
    
    return {"results": matches, "count": len(matches)}
