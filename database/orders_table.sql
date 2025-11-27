-- =====================================================
-- Orders Table Schema for Stop-Loss & Bracket Orders
-- =====================================================
-- Run this SQL in your Supabase SQL Editor
-- This table stores pending, triggered, and historical orders
CREATE TABLE IF NOT EXISTS orders (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    -- Asset information
    asset_symbol TEXT NOT NULL,
    asset_name TEXT NOT NULL,
    asset_type TEXT NOT NULL CHECK (asset_type IN ('stock', 'crypto', 'mutualFund')),
    -- Order configuration
    order_type TEXT NOT NULL CHECK (
        order_type IN ('market', 'limit', 'stop_loss', 'bracket')
    ),
    order_side TEXT NOT NULL CHECK (order_side IN ('buy', 'sell')),
    quantity DECIMAL(20, 8) NOT NULL CHECK (quantity > 0),
    -- Price triggers and limits
    trigger_price DECIMAL(20, 8),
    -- For stop-loss: price that activates the order
    limit_price DECIMAL(20, 8),
    -- For limit orders: max buy/min sell price
    stop_loss_price DECIMAL(20, 8),
    -- For bracket orders: stop-loss exit price
    target_price DECIMAL(20, 8),
    -- For bracket orders: take-profit exit price
    -- Order status and execution
    status TEXT NOT NULL DEFAULT 'pending' CHECK (
        status IN (
            'pending',
            'triggered',
            'partially_filled',
            'filled',
            'cancelled',
            'expired',
            'failed'
        )
    ),
    filled_quantity DECIMAL(20, 8) DEFAULT 0,
    avg_fill_price DECIMAL(20, 8),
    -- Financial tracking
    reserved_balance DECIMAL(20, 8),
    -- Amount reserved from user balance for buy orders
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    triggered_at TIMESTAMP WITH TIME ZONE,
    filled_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    -- Bracket order relationships
    parent_order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    -- Links child orders to parent entry order
    bracket_stop_loss_id UUID,
    -- Entry order points to its stop-loss leg
    bracket_target_id UUID,
    -- Entry order points to its take-profit leg
    -- Execution details
    transaction_id UUID REFERENCES transactions(id),
    -- Link to executed transaction
    cancellation_reason TEXT,
    failure_reason TEXT,
    -- Additional metadata
    notes TEXT,
    client_order_id TEXT -- Optional client-side reference
);
-- =====================================================
-- Indexes for Performance
-- =====================================================
-- Most common query: fetch pending orders for a user
CREATE INDEX idx_orders_user_status ON orders(user_id, status)
WHERE status IN ('pending', 'triggered');
-- Monitor orders by symbol and status for price checking
CREATE INDEX idx_orders_symbol_status ON orders(asset_symbol, status)
WHERE status IN ('pending', 'triggered');
-- Order history queries
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);
-- Bracket order relationships
CREATE INDEX idx_orders_parent ON orders(parent_order_id)
WHERE parent_order_id IS NOT NULL;
-- Find orders by transaction
CREATE INDEX idx_orders_transaction ON orders(transaction_id)
WHERE transaction_id IS NOT NULL;
-- =====================================================
-- Triggers for Automatic Updates
-- =====================================================
-- Automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_orders_updated_at() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_orders_updated_at BEFORE
UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_orders_updated_at();
-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================
-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
-- Users can view their own orders
CREATE POLICY "Users can view their own orders" ON orders FOR
SELECT USING (auth.uid() = user_id);
-- Users can create their own orders
CREATE POLICY "Users can create their own orders" ON orders FOR
INSERT WITH CHECK (auth.uid() = user_id);
-- Users can update their own pending orders (for cancellation)
CREATE POLICY "Users can update their own pending orders" ON orders FOR
UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
-- Users can delete their own cancelled orders (soft delete via status update is preferred)
CREATE POLICY "Users can delete their own orders" ON orders FOR DELETE USING (auth.uid() = user_id);
-- =====================================================
-- Helper Views (Optional)
-- =====================================================
-- View for active orders (pending + triggered)
CREATE OR REPLACE VIEW active_orders AS
SELECT o.*,
    CASE
        WHEN o.order_type = 'bracket' THEN (
            SELECT json_build_object(
                    'stop_loss',
                    json_build_object(
                        'id',
                        sl.id,
                        'price',
                        sl.stop_loss_price,
                        'status',
                        sl.status
                    ),
                    'target',
                    json_build_object(
                        'id',
                        tg.id,
                        'price',
                        tg.target_price,
                        'status',
                        tg.status
                    )
                )
            FROM orders sl
                LEFT JOIN orders tg ON tg.id = o.bracket_target_id
            WHERE sl.id = o.bracket_stop_loss_id
        )
    END as bracket_legs
FROM orders o
WHERE o.status IN ('pending', 'triggered', 'partially_filled');
-- View for order history with transaction details
CREATE OR REPLACE VIEW order_history AS
SELECT o.*,
    t.total_amount as executed_amount,
    t.balance_after,
    t.created_at as execution_time
FROM orders o
    LEFT JOIN transactions t ON o.transaction_id = t.id
WHERE o.status IN ('filled', 'cancelled', 'expired', 'failed')
ORDER BY o.created_at DESC;
-- =====================================================
-- Validation Functions
-- =====================================================
-- Function to validate stop-loss order prices
CREATE OR REPLACE FUNCTION validate_stop_loss_order() RETURNS TRIGGER AS $$ BEGIN IF NEW.order_type = 'stop_loss' THEN IF NEW.trigger_price IS NULL THEN RAISE EXCEPTION 'Stop-loss orders must have a trigger_price';
END IF;
IF NEW.order_side = 'sell'
AND NEW.trigger_price <= 0 THEN RAISE EXCEPTION 'Stop-loss sell trigger price must be positive';
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_validate_stop_loss BEFORE
INSERT
    OR
UPDATE ON orders FOR EACH ROW
    WHEN (NEW.order_type = 'stop_loss') EXECUTE FUNCTION validate_stop_loss_order();
-- Function to validate bracket order structure
CREATE OR REPLACE FUNCTION validate_bracket_order() RETURNS TRIGGER AS $$ BEGIN IF NEW.order_type = 'bracket' THEN IF NEW.stop_loss_price IS NULL
    OR NEW.target_price IS NULL THEN RAISE EXCEPTION 'Bracket orders must have both stop_loss_price and target_price';
END IF;
-- For buy bracket orders: stop_loss < entry < target
IF NEW.order_side = 'buy' THEN IF NEW.stop_loss_price >= NEW.avg_fill_price
OR NEW.target_price <= NEW.avg_fill_price THEN RAISE EXCEPTION 'Buy bracket order: stop_loss_price < entry_price < target_price';
END IF;
END IF;
-- For sell bracket orders: target < entry < stop_loss
IF NEW.order_side = 'sell' THEN IF NEW.target_price >= NEW.avg_fill_price
OR NEW.stop_loss_price <= NEW.avg_fill_price THEN RAISE EXCEPTION 'Sell bracket order: target_price < entry_price < stop_loss_price';
END IF;
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_validate_bracket BEFORE
INSERT
    OR
UPDATE ON orders FOR EACH ROW
    WHEN (NEW.order_type = 'bracket') EXECUTE FUNCTION validate_bracket_order();
-- =====================================================
-- Sample Queries for Testing
-- =====================================================
-- Get all pending orders for a user
-- SELECT * FROM orders WHERE user_id = 'your-user-id' AND status = 'pending' ORDER BY created_at DESC;
-- Get bracket order with its legs
-- SELECT 
--     e.*,
--     sl.id as stop_loss_id, sl.stop_loss_price, sl.status as sl_status,
--     tg.id as target_id, tg.target_price, tg.status as tg_status
-- FROM orders e
-- LEFT JOIN orders sl ON sl.id = e.bracket_stop_loss_id
-- LEFT JOIN orders tg ON tg.id = e.bracket_target_id
-- WHERE e.id = 'parent-order-id';
-- Cancel a pending order
-- UPDATE orders SET status = 'cancelled', cancelled_at = NOW(), cancellation_reason = 'User requested' WHERE id = 'order-id' AND status = 'pending';
-- =====================================================
-- Maintenance Functions
-- =====================================================
-- Function to archive old filled/cancelled orders (optional)
CREATE OR REPLACE FUNCTION archive_old_orders(days_old INTEGER DEFAULT 90) RETURNS INTEGER AS $$
DECLARE archived_count INTEGER;
BEGIN WITH archived AS (
    DELETE FROM orders
    WHERE status IN ('filled', 'cancelled', 'expired')
        AND created_at < NOW() - INTERVAL '1 day' * days_old
    RETURNING *
)
SELECT COUNT(*) INTO archived_count
FROM archived;
RETURN archived_count;
END;
$$ LANGUAGE plpgsql;
-- Usage: SELECT archive_old_orders(90); -- Archive orders older than 90 days
COMMENT ON TABLE orders IS 'Stores all order types including market, limit, stop-loss, and bracket orders for the virtual trading platform';
COMMENT ON COLUMN orders.order_type IS 'Type of order: market (immediate), limit (at specific price), stop_loss (triggered at price), bracket (entry + stop-loss + target)';
COMMENT ON COLUMN orders.trigger_price IS 'Price level that activates a stop-loss order';
COMMENT ON COLUMN orders.stop_loss_price IS 'Exit price for bracket order stop-loss leg';
COMMENT ON COLUMN orders.target_price IS 'Exit price for bracket order take-profit leg';
COMMENT ON COLUMN orders.parent_order_id IS 'Links bracket order legs to their parent entry order';
COMMENT ON COLUMN orders.reserved_balance IS 'Amount held from user balance for pending buy orders to prevent insufficient funds';