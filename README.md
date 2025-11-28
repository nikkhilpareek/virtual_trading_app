# STONKS - Virtual Stock Trading App
A easy to use app for learning stock trading. Use the In-App Currency to buy/sell stocks and learn how the stock market works.

> TEAM: Nikhil Pareek, Dhruv Sharma, Deepak Vishwakarma

## 🚀 Quick Start

### Backend Setup (Required for Market Data)

1. **Open a terminal and navigate to backend folder:**
   ```bash
   cd backend
   ```

2. **Start the backend server:**
   ```bash
   ./start.sh
   ```
   Or manually:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

3. **Verify it's running:**
   - Open browser: http://localhost:8000
   - You should see API information

### Flutter App Setup

1. **Get dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

**Note:** For Android Emulator, update the backend URL in `lib/core/services/yfinance_service.dart` to use `http://10.0.2.2:8000` instead of `localhost`.

For detailed backend setup instructions, see [backend/README.md](backend/README.md)

---

## 🎯 NEW: Stop-Loss & Bracket Orders

**Automated risk management is now available!**

### 📚 Documentation

- **[QUICK_START_ORDERS.md](QUICK_START_ORDERS.md)** - 5-minute setup guide with code examples
- **[ORDER_IMPLEMENTATION.md](ORDER_IMPLEMENTATION.md)** - Complete technical documentation
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Feature overview & architecture

### ⚡ Quick Setup

```bash
# 1. Run database migration (Supabase SQL Editor)
# Copy-paste: database/orders_table.sql

# 2. Install backend dependencies
cd backend
pip install -r requirements.txt

# 3. Start backend (order monitor auto-starts)
./start.sh

# 4. Update Flutter dependencies
flutter pub get

# 5. Run app
flutter run
```

### 💡 Usage Example

```dart
// Create stop-loss order
context.read<OrderBloc>().add(
  CreateStopLossOrder(
    assetSymbol: 'RELIANCE',
    assetName: 'Reliance Industries',
    assetType: AssetType.stock,
    orderSide: OrderSide.sell,
    quantity: 10,
    triggerPrice: 2450.0,  // Auto-sell at ₹2450
  ),
);

// Create bracket order (entry + stop-loss + target)
context.read<OrderBloc>().add(
  CreateBracketOrder(
    assetSymbol: 'BTC',
    assetName: 'Bitcoin',
    assetType: AssetType.crypto,
    orderSide: OrderSide.buy,
    quantity: 0.01,
    entryPrice: 7500000.0,      // ₹75L entry
    stopLossPrice: 7000000.0,   // ₹70L stop (limit loss)
    targetPrice: 8500000.0,     // ₹85L target (lock profit)
  ),
);
```

**See [QUICK_START_ORDERS.md](QUICK_START_ORDERS.md) for complete usage guide.**

---

## Features (Planned to be Added in the App)
- ✅ Real-Time Stock Prices using YFinance API
    1. ✅ Indian Stock Markets (NSE/BSE) - RELIANCE, TCS, INFY, etc.
    2. ✅ Cryptocurrency prices (BTC, ETH, BNB)
    3. 🔄 Global Exchanges (Future Feature)
- ✅ Buy/Sell Orders - Basic Buy/Sell feature
- ✅ **Advanced Order Types** ⭐ NEW!
    - ✅ **Stop-Loss Orders** - Automatic sell when price drops to limit losses
    - ✅ **Bracket Orders** - Entry + Stop-Loss + Take-Profit in one order
    - ✅ **Background Monitoring** - Orders execute automatically 24/7
    - ✅ **Balance Reservation** - Funds locked for pending buy orders
    - ✅ **Auto-Cancellation** - Bracket order sibling cancels when one fills
- ✅ Watchlist - For Tracking Stocks the user is interested in
- 🔄 Achievements - Different simple in app tasks for user to earn extra in app currency

## Screens in the App
- ✅ Home Screen: Dashboard with quick actions
- ✅ Profile Screen: User info and portfolio summary
- ✅ Assets Screen: Current holdings, watchlist, P&L
- ✅ Market Screen: Browse and search stocks with real-time prices
- ✅ Learn Screen: Educational content about stocks and finance
- 🔄 Analysis Screen: Technical Analysis with Indicators (Future Feature)

## Features (To be Worked on After basic things are implemented)
- Advanced Order Types: Implement more complex orders like bracket orders or trailing stop-loss orders.
- Options and Futures Trading Simulation
- Add a Crypto Tab for Similar things but CRYPTO!!!


### Tech Stack 
- Flutter - Mobile app framework
- FastAPI + YFinance - Backend for real-time market data
- Supabase - Authentication, DB & Storage
- Figma - Design

## Backend API

The app now uses a local FastAPI backend that fetches real-time data from Yahoo Finance (via YFinance library).

**Endpoints:**
- `GET /quote/{symbol}` - Get stock quote (e.g., RELIANCE, TCS)
- `GET /crypto/{symbol}` - Get crypto quote (e.g., BTC, ETH)
- `GET /top` - Get top 10 Indian stocks
- `GET /batch?symbols=SYM1,SYM2` - Get multiple quotes
- `GET /search/{query}` - Search for stocks

**See [backend/README.md](backend/README.md) for complete API documentation.**


