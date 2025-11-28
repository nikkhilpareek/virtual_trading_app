# Order Monitoring and Execution Service
# This service runs in the background and monitors pending orders

import asyncio
import yfinance as yf
from datetime import datetime
from typing import Dict, List, Optional
from supabase import create_client, Client
import os

class OrderMonitorService:
    """
    Background service that monitors pending orders and executes them
    when trigger conditions are met
    """
    
    def __init__(self, supabase_url: str, supabase_key: str):
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.price_cache: Dict[str, Dict] = {}
        self.cache_duration = 5  # seconds
        
    async def monitor_orders(self):
        """Main monitoring loop - checks orders every 5 seconds"""
        print("🔍 Order Monitor Service started")
        
        while True:
            try:
                await self._check_pending_orders()
                await asyncio.sleep(5)  # Check every 5 seconds
            except Exception as e:
                print(f"❌ Error in monitor loop: {e}")
                await asyncio.sleep(5)
    
    async def _check_pending_orders(self):
        """Fetch and process all pending orders"""
        try:
            # Get all pending and triggered orders
            response = self.supabase.table('orders').select('*').in_(
                'status', ['pending', 'triggered']
            ).execute()
            
            orders = response.data
            
            if not orders:
                return
            
            print(f"📊 Checking {len(orders)} pending orders...")
            
            # Group orders by symbol to minimize API calls
            orders_by_symbol = {}
            for order in orders:
                symbol = order['asset_symbol']
                if symbol not in orders_by_symbol:
                    orders_by_symbol[symbol] = []
                orders_by_symbol[symbol].append(order)
            
            # Check each symbol's orders
            for symbol, symbol_orders in orders_by_symbol.items():
                await self._process_symbol_orders(symbol, symbol_orders)
                
        except Exception as e:
            print(f"❌ Error checking pending orders: {e}")
    
    async def _process_symbol_orders(self, symbol: str, orders: List[dict]):
        """Process all orders for a specific symbol"""
        try:
            # Get current price
            asset_type = orders[0]['asset_type']
            current_price = await self._get_current_price(symbol, asset_type)
            
            if current_price is None:
                print(f"⚠️  Could not fetch price for {symbol}")
                return
            
            print(f"💰 {symbol}: ₹{current_price:.2f}")
            
            # Check each order
            for order in orders:
                should_trigger = self._check_trigger_condition(order, current_price)
                
                if should_trigger:
                    print(f"🎯 TRIGGER: Order {order['id'][:8]}... for {symbol}")
                    await self._execute_order(order, current_price)
                    
        except Exception as e:
            print(f"❌ Error processing {symbol} orders: {e}")
    
    def _check_trigger_condition(self, order: dict, current_price: float) -> bool:
        """Check if order should be triggered based on current price"""
        order_type = order['order_type']
        order_side = order['order_side']
        trigger_price = order.get('trigger_price')
        
        if not trigger_price:
            return False
        
        # Stop-loss logic
        if order_type == 'stop_loss':
            if order_side == 'sell':
                # Sell stop-loss: trigger when price falls to or below trigger
                return current_price <= trigger_price
            else:
                # Buy stop-loss: trigger when price rises to or above trigger
                return current_price >= trigger_price
        
        return False
    
    async def _execute_order(self, order: dict, current_price: float):
        """Execute a triggered order"""
        try:
            order_id = order['id']
            user_id = order['user_id']
            asset_symbol = order['asset_symbol']
            asset_name = order['asset_name']
            asset_type = order['asset_type']
            order_side = order['order_side']
            quantity = float(order['quantity'])
            
            print(f"⚡ Executing {order_side} order: {quantity} x {asset_symbol} @ ₹{current_price}")
            
            if order_side == 'buy':
                success = await self._execute_buy(
                    user_id, asset_symbol, asset_name, asset_type,
                    quantity, current_price, order_id
                )
            else:
                success = await self._execute_sell(
                    user_id, asset_symbol, asset_name, asset_type,
                    quantity, current_price, order_id
                )
            
            if success:
                # Handle bracket order logic
                await self._handle_bracket_order(order)
                
        except Exception as e:
            print(f"❌ Failed to execute order {order_id}: {e}")
            # Mark order as failed
            self.supabase.table('orders').update({
                'status': 'failed',
                'failure_reason': str(e),
                'updated_at': datetime.utcnow().isoformat()
            }).eq('id', order_id).execute()
    
    async def _execute_buy(self, user_id: str, symbol: str, name: str, 
                          asset_type: str, quantity: float, price: float, order_id: str) -> bool:
        """Execute a buy order"""
        total_cost = quantity * price
        
        # Check balance
        profile = self.supabase.table('profiles').select('stonk_balance').eq(
            'id', user_id
        ).single().execute()
        
        current_balance = float(profile.data['stonk_balance'])
        
        # Add reserved balance back if it exists
        order = self.supabase.table('orders').select('reserved_balance').eq(
            'id', order_id
        ).single().execute()
        
        reserved = float(order.data.get('reserved_balance') or 0)
        if reserved > 0:
            current_balance += reserved
        
        if current_balance < total_cost:
            raise Exception(f"Insufficient balance: need ₹{total_cost:.2f}, have ₹{current_balance:.2f}")
        
        new_balance = current_balance - total_cost
        
        # Update balance
        self.supabase.table('profiles').update({
            'stonk_balance': new_balance
        }).eq('id', user_id).execute()
        
        # Update or create holding
        holding = self.supabase.table('holdings').select('*').eq(
            'user_id', user_id
        ).eq('asset_symbol', symbol).execute()
        
        if holding.data:
            # Update existing holding
            old_qty = float(holding.data[0]['quantity'])
            old_avg = float(holding.data[0]['average_price'])
            new_qty = old_qty + quantity
            new_avg = ((old_qty * old_avg) + (quantity * price)) / new_qty
            
            self.supabase.table('holdings').update({
                'quantity': new_qty,
                'average_price': new_avg,
                'updated_at': datetime.utcnow().isoformat()
            }).eq('id', holding.data[0]['id']).execute()
        else:
            # Create new holding
            self.supabase.table('holdings').insert({
                'user_id': user_id,
                'asset_symbol': symbol,
                'asset_name': name,
                'asset_type': asset_type,
                'quantity': quantity,
                'average_price': price,
                'current_price': price
            }).execute()
        
        # Create transaction
        transaction_data = {
            'user_id': user_id,
            'asset_symbol': symbol,
            'asset_name': name,
            'asset_type': asset_type,
            'transaction_type': 'buy',
            'quantity': quantity,
            'price_per_unit': price,
            'total_amount': total_cost,
            'balance_after': new_balance
        }
        
        tx_response = self.supabase.table('transactions').insert(
            transaction_data
        ).execute()
        
        transaction_id = tx_response.data[0]['id']
        
        # Update order status
        self.supabase.table('orders').update({
            'status': 'filled',
            'filled_quantity': quantity,
            'avg_fill_price': price,
            'filled_at': datetime.utcnow().isoformat(),
            'transaction_id': transaction_id,
            'updated_at': datetime.utcnow().isoformat()
        }).eq('id', order_id).execute()
        
        print(f"✅ Buy order executed: {quantity} x {symbol} @ ₹{price}")
        return True
    
    async def _execute_sell(self, user_id: str, symbol: str, name: str,
                           asset_type: str, quantity: float, price: float, order_id: str) -> bool:
        """Execute a sell order"""
        # Check holding
        holding = self.supabase.table('holdings').select('*').eq(
            'user_id', user_id
        ).eq('asset_symbol', symbol).single().execute()
        
        if not holding.data:
            raise Exception(f"No holdings found for {symbol}")
        
        available_qty = float(holding.data['quantity'])
        if available_qty < quantity:
            raise Exception(f"Insufficient holdings: need {quantity}, have {available_qty}")
        
        total_proceeds = quantity * price
        
        # Update balance
        profile = self.supabase.table('profiles').select('stonk_balance').eq(
            'id', user_id
        ).single().execute()
        
        current_balance = float(profile.data['stonk_balance'])
        new_balance = current_balance + total_proceeds
        
        self.supabase.table('profiles').update({
            'stonk_balance': new_balance
        }).eq('id', user_id).execute()
        
        # Update or delete holding
        new_qty = available_qty - quantity
        if new_qty > 0.0001:
            self.supabase.table('holdings').update({
                'quantity': new_qty,
                'updated_at': datetime.utcnow().isoformat()
            }).eq('id', holding.data['id']).execute()
        else:
            self.supabase.table('holdings').delete().eq(
                'id', holding.data['id']
            ).execute()
        
        # Create transaction
        transaction_data = {
            'user_id': user_id,
            'asset_symbol': symbol,
            'asset_name': name,
            'asset_type': asset_type,
            'transaction_type': 'sell',
            'quantity': quantity,
            'price_per_unit': price,
            'total_amount': total_proceeds,
            'balance_after': new_balance
        }
        
        tx_response = self.supabase.table('transactions').insert(
            transaction_data
        ).execute()
        
        transaction_id = tx_response.data[0]['id']
        
        # Update order status
        self.supabase.table('orders').update({
            'status': 'filled',
            'filled_quantity': quantity,
            'avg_fill_price': price,
            'filled_at': datetime.utcnow().isoformat(),
            'transaction_id': transaction_id,
            'updated_at': datetime.utcnow().isoformat()
        }).eq('id', order_id).execute()
        
        print(f"✅ Sell order executed: {quantity} x {symbol} @ ₹{price}")
        return True
    
    async def _handle_bracket_order(self, order: dict):
        """Handle bracket order logic - cancel sibling when one leg fills"""
        parent_id = order.get('parent_order_id')
        
        if not parent_id:
            return
        
        # This is a bracket order leg - cancel the sibling
        parent = self.supabase.table('orders').select('*').eq(
            'id', parent_id
        ).single().execute()
        
        if not parent.data:
            return
        
        # Find sibling order ID
        stop_loss_id = parent.data.get('bracket_stop_loss_id')
        target_id = parent.data.get('bracket_target_id')
        
        sibling_id = target_id if order['id'] == stop_loss_id else stop_loss_id
        
        if sibling_id:
            # Cancel the sibling order
            self.supabase.table('orders').update({
                'status': 'cancelled',
                'cancelled_at': datetime.utcnow().isoformat(),
                'cancellation_reason': 'Bracket order sibling filled',
                'updated_at': datetime.utcnow().isoformat()
            }).eq('id', sibling_id).execute()
            
            print(f"🔗 Cancelled sibling bracket order: {sibling_id[:8]}...")
    
    async def _get_current_price(self, symbol: str, asset_type: str) -> Optional[float]:
        """Get current price with caching"""
        cache_key = f"{symbol}_{asset_type}"
        
        # Check cache
        if cache_key in self.price_cache:
            cached = self.price_cache[cache_key]
            age = (datetime.now() - cached['timestamp']).total_seconds()
            if age < self.cache_duration:
                return cached['price']
        
        # Fetch new price
        try:
            if asset_type == 'crypto':
                ticker = yf.Ticker(f"{symbol}-INR")
            else:
                ticker = yf.Ticker(f"{symbol}.NS")
            
            hist = ticker.history(period="1d")
            if hist.empty:
                return None
            
            price = float(hist['Close'].iloc[-1])
            
            # Update cache
            self.price_cache[cache_key] = {
                'price': price,
                'timestamp': datetime.now()
            }
            
            return price
            
        except Exception as e:
            print(f"⚠️  Error fetching price for {symbol}: {e}")
            return None


# Standalone function to run the service
async def run_order_monitor():
    """Run the order monitoring service"""
    import os
    from dotenv import load_dotenv
    
    load_dotenv()
    
    supabase_url = os.getenv('SUPABASE_URL', 'https://edmeobztjodvmichfmej.supabase.co')
    supabase_key = os.getenv('SUPABASE_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbWVvYnp0am9kdm1pY2hmbWVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4ODAwOTQsImV4cCI6MjA3NjQ1NjA5NH0.ZQi5iPj6JE7Ft_jVq7fBAib4C6BrQ7Lztmd5AMB3zzo')
    
    service = OrderMonitorService(supabase_url, supabase_key)
    await service.monitor_orders()


if __name__ == "__main__":
    asyncio.run(run_order_monitor())
