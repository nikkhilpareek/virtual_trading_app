# Stonks Trading API Backend

FastAPI backend server that provides real-time stock and cryptocurrency data using YFinance.

## Features

- ✅ Real-time Indian stock quotes (NSE)
- ✅ Cryptocurrency prices (BTC, ETH, BNB, etc.)
- ✅ Top stocks endpoint
- ✅ Batch quote fetching
- ✅ Stock search functionality
- ✅ CORS enabled for Flutter app

## Prerequisites

Make sure you have Python 3.7+ installed on your system.

## Installation

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install required packages:**
   ```bash
   pip3 install fastapi uvicorn yfinance
   ```

   Or if you have a requirements.txt:
   ```bash
   pip3 install -r requirements.txt
   ```

## Running the Backend

### Option 1: Simple Run (Development)

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Option 2: With Custom Host/Port

```bash
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### What the flags mean:
- `--reload`: Auto-restart when code changes (dev only)
- `--host 0.0.0.0`: Makes server accessible from other devices on network
- `--port 8000`: Server runs on port 8000
- `main:app`: Refers to the `app` object in `main.py`

### Option 3: Production Mode (No auto-reload)

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Testing the Backend

Once the server is running, you should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [xxxxx] using WatchFiles
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Test in Browser

Open your browser and visit:
- http://localhost:8000/ - API info
- http://localhost:8000/quote/RELIANCE - Get Reliance stock quote
- http://localhost:8000/top - Get top stocks
- http://localhost:8000/crypto/BTC - Get Bitcoin price

## API Endpoints

### 1. Root Endpoint
```
GET /
```
Returns API information and available endpoints.

### 2. Get Stock Quote
```
GET /quote/{symbol}
```
Get real-time quote for an Indian stock.

**Example:**
```
GET /quote/RELIANCE
```

**Response:**
```json
{
  "symbol": "RELIANCE",
  "name": "Reliance Industries Ltd",
  "price": 2450.50,
  "change": 12.30,
  "changePercent": 0.51,
  "volume": 5234567,
  "previousClose": 2438.20,
  "open": 2440.00,
  "high": 2455.75,
  "low": 2435.00,
  "latestTradingDay": "2025-10-29"
}
```

### 3. Get Cryptocurrency Quote
```
GET /crypto/{symbol}?market=INR
```
Get cryptocurrency price in INR or USD.

**Example:**
```
GET /crypto/BTC?market=INR
```

**Response:**
```json
{
  "symbol": "BTC",
  "market": "INR",
  "price": 5234567.89,
  "change": 12345.67,
  "changePercent": 0.24,
  "bidPrice": 5233000.00,
  "askPrice": 5236000.00,
  "lastRefreshed": "2025-10-29 14:30:00"
}
```

### 4. Get Top Stocks
```
GET /top
```
Get list of top 10 Indian stocks with real-time prices.

**Response:**
```json
{
  "stocks": [
    {
      "symbol": "RELIANCE",
      "name": "Reliance Industries Ltd",
      "price": 2450.50,
      "change": 12.30,
      "changePercent": 0.51,
      ...
    },
    ...
  ]
}
```

### 5. Batch Quotes
```
GET /batch?symbols=SYMBOL1,SYMBOL2,SYMBOL3
```
Get multiple stock quotes in one request.

**Example:**
```
GET /batch?symbols=RELIANCE,TCS,INFY
```

**Response:**
```json
{
  "stocks": [...],
  "count": 3
}
```

### 6. Search Stocks
```
GET /search/{query}
```
Search for stocks by name or symbol.

**Example:**
```
GET /search/reliance
```

**Response:**
```json
{
  "results": [
    {
      "symbol": "RELIANCE",
      "name": "Reliance Industries Ltd",
      "type": "stock"
    }
  ],
  "count": 1
}
```

## Connecting to Flutter App

### For iOS Simulator or Android Emulator on Same Machine

The Flutter app is already configured to use `http://localhost:8000` which works for:
- **iOS Simulator**: Uses `localhost` or `127.0.0.1`
- **Android Emulator**: You need to change the URL

### For Android Emulator

Android Emulator uses a special IP to access host machine's localhost.

**Edit** `lib/core/services/yfinance_service.dart`:

```dart
// Change from:
static const String _baseUrl = 'http://localhost:8000';

// To:
static const String _baseUrl = 'http://10.0.2.2:8000';
```

### For Real Physical Device (iPhone/Android)

1. **Find your computer's IP address:**

   **On macOS:**
   ```bash
   ipconfig getifaddr en0
   ```
   This will show something like: `192.168.1.100`

   **On Linux:**
   ```bash
   hostname -I
   ```

   **On Windows:**
   ```bash
   ipconfig
   ```
   Look for "IPv4 Address" under your active network adapter.

2. **Make sure backend is running with `--host 0.0.0.0`:**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

3. **Update Flutter app** in `lib/core/services/yfinance_service.dart`:
   ```dart
   static const String _baseUrl = 'http://192.168.1.100:8000';  // Use your IP
   ```

4. **Make sure your phone and computer are on the same Wi-Fi network!**

### Testing the Connection

After updating the URL and running the backend, you can test in Flutter:

1. The app will automatically try to fetch market data when you open the Market screen
2. Check the Flutter debug console for any connection errors
3. If you see data loading, it's working! 🎉

## Troubleshooting

### Port Already in Use
If port 8000 is already in use, try a different port:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8080
```
Remember to update the `_baseUrl` in Flutter app accordingly.

### Connection Refused / Timeout

1. **Check if backend is running:**
   - You should see "Uvicorn running on..." in terminal
   
2. **Check firewall settings:**
   - macOS: System Settings → Network → Firewall
   - Allow Python/uvicorn through firewall
   
3. **For physical device:**
   - Ensure phone and computer are on same Wi-Fi
   - Try pinging your computer's IP from another device
   - Some corporate/school networks block device-to-device communication

### No Data / Empty Responses

1. **Check internet connection** - YFinance needs internet to fetch data
2. **Market hours** - Stock data may be stale outside market hours
3. **Symbol format** - Use correct symbols (e.g., "RELIANCE" not "RELIANCE.NS")

### Rate Limiting

YFinance is free but has soft limits. If you get too many requests errors:
- The app has built-in caching (2 minutes)
- Avoid refreshing too frequently
- The backend fetches data efficiently

## Development Tips

### View API Documentation

FastAPI provides interactive API documentation automatically:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Monitor Logs

The backend prints helpful logs. Watch the terminal where uvicorn is running to see:
- Incoming requests
- Errors fetching data
- Stock symbols being queried

### Hot Reload

With `--reload` flag, the backend auto-restarts when you edit `main.py`. No need to restart manually!

## Next Steps

1. ✅ Start the backend: `uvicorn main:app --reload --host 0.0.0.0 --port 8000`
2. ✅ Update Flutter app's `_baseUrl` if needed (based on your device)
3. ✅ Run your Flutter app
4. ✅ Navigate to Market screen
5. ✅ Watch real-time data load! 🚀

## Need Help?

- FastAPI Docs: https://fastapi.tiangolo.com/
- YFinance Docs: https://github.com/ranaroussi/yfinance
- Check terminal output for error messages
- Verify network connectivity between devices
