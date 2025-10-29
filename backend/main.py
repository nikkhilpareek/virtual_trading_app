from fastapi import FastAPI
import yfinance as yf
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Allow Flutter (on localhost) to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all origins for testing
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/price/{symbol}")
def get_stock_price(symbol: str):
    try:
        stock = yf.Ticker(f"{symbol}.NS")
        data = stock.history(period="1d", interval="1m")
        current_price = float(data["Close"].iloc[-1])
        return {"symbol": symbol.upper(), "price": current_price}
    except Exception as e:
        return {"error": str(e)}

@app.get("/top")
def get_top_stocks():
    tickers = ["RELIANCE.NS", "TCS.NS", "INFY.NS", "HDFCBANK.NS", "ICICIBANK.NS"] 
    result = []
    for t in tickers:
        try:
            stock = yf.Ticker(t)
            data = stock.history(period="1d", interval="1m")
            price = float(data["Close"].iloc[-1])
            result.append({"symbol": t.replace(".NS", ""), "price": price})
        except:
            pass
    return {"stocks": result}
