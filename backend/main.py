from fastapi import FastAPI, HTTPException
import yfinance as yf
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from datetime import datetime
import logging
import requests

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create a custom session with headers to avoid blocking
session = requests.Session()
session.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
})

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
        logger.info(f"Fetching data for: {ticker}")
        
        # Create ticker with custom session to avoid rate limiting
        stock = yf.Ticker(ticker, session=session)
        
        # Get latest data with timeout
        hist = stock.history(period="5d", timeout=10)
        
        if hist.empty:
            logger.warning(f"No data returned for {ticker}")
            return None
        
        logger.info(f"Successfully fetched {len(hist)} days of data for {ticker}")
        
        latest = hist.iloc[-1]
        previous = hist.iloc[-2] if len(hist) > 1 else latest
        
        current_price = float(latest['Close'])
        previous_close = float(previous['Close'])
        change = current_price - previous_close
        change_percent = (change / previous_close * 100) if previous_close > 0 else 0.0
        
        # Try to get info, but don't fail if it's not available
        try:
            info = stock.info
            stock_name = info.get('longName', symbol.upper())
        except Exception as info_error:
            logger.warning(f"Could not fetch info for {ticker}: {info_error}")
            stock_name = symbol.upper()
        
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
            "name": stock_name,
        }
    except Exception as e:
        logger.error(f"Error fetching {symbol}{suffix}: {str(e)}")
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
    errors = []
    
    logger.info(f"Fetching top stocks: {tickers}")
    
    for symbol in tickers:
        try:
            data = get_stock_data(symbol, ".NS")
            if data:
                result.append(data)
            else:
                errors.append(symbol)
        except Exception as e:
            logger.error(f"Failed to fetch {symbol}: {e}")
            errors.append(symbol)
    
    logger.info(f"Successfully fetched {len(result)} stocks, failed: {len(errors)}")
    
    return {
        "stocks": result,
        "count": len(result),
        "failed": errors if errors else None
    }

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
