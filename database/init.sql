-- Create database schema for LOTUS O2O System

-- Safe enum creation (works in entrypoint)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_type') THEN
    CREATE TYPE order_type AS ENUM ('ONLINE','OFFLINE','INSTORE','MARKETPLACE','CALLCENTER');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    CREATE TYPE order_status AS ENUM (
      'PENDING','PENDING_PAYMENT','PROCESSING','COMPLETE','CLOSED','CANCELED','HOLDED','PAYMENT_REVIEW','FRAUD','SHIPPING'
    );
  END IF;
END
$$;

-- Items master table
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    item_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    detail TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(50) UNIQUE NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'VND',
    order_type order_type NOT NULL DEFAULT 'ONLINE',
    status order_status NOT NULL DEFAULT 'PENDING',
    item_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time_processing TIMESTAMP NULL,
    end_time_payment_review TIMESTAMP NULL,
    end_time_shipping TIMESTAMP NULL,
    payment_method VARCHAR(50),
    shipping_address TEXT,
    tracking_number VARCHAR(100),
    notes TEXT,
    CONSTRAINT fk_orders_item_id FOREIGN KEY (item_id) REFERENCES items(item_id)
);

-- Backfill-safe migration for existing databases
ALTER TABLE orders ADD COLUMN IF NOT EXISTS end_time_processing TIMESTAMP NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS end_time_payment_review TIMESTAMP NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS end_time_shipping TIMESTAMP NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_order_type ON orders(order_type);
CREATE INDEX IF NOT EXISTS idx_orders_item_id ON orders(item_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_orders_updated_at'
  ) THEN
    CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END
$$;

-- Promotion table for tracking promotion files
CREATE TABLE IF NOT EXISTS promotion (
    id SERIAL PRIMARY KEY,
    path_file TEXT NOT NULL,
    status INTEGER DEFAULT 4,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    promotion_id VARCHAR(50),
    item_code VARCHAR(50),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    config_data JSONB
);

-- Create indexes for promotion table
CREATE INDEX IF NOT EXISTS idx_promotion_status ON promotion(status);
CREATE INDEX IF NOT EXISTS idx_promotion_created_at ON promotion(created_at);
CREATE INDEX IF NOT EXISTS idx_promotion_promotion_id ON promotion(promotion_id);

-- Create trigger to update updated_at timestamp for promotion table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_promotion_updated_at'
  ) THEN
    CREATE TRIGGER update_promotion_updated_at BEFORE UPDATE ON promotion
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END
$$;

-- Price table for tracking price files
CREATE TABLE IF NOT EXISTS price (
    id SERIAL PRIMARY KEY,
    path_file TEXT NOT NULL,
    status INTEGER DEFAULT 4,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    item_code VARCHAR(50),
    action VARCHAR(50) DEFAULT ''
);

-- Create indexes for price table
CREATE INDEX IF NOT EXISTS idx_price_status ON price(status);
CREATE INDEX IF NOT EXISTS idx_price_created_at ON price(created_at);
CREATE INDEX IF NOT EXISTS idx_price_item_code ON price(item_code);

-- Create trigger to update updated_at timestamp for price table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_price_updated_at'
  ) THEN
    CREATE TRIGGER update_price_updated_at BEFORE UPDATE ON price
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END
$$;
