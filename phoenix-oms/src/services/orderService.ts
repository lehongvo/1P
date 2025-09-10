import { v4 as uuidv4 } from 'uuid';
import customerNamesData from '../data/customer_names_en.json';
import itemsData from '../data/items_data.json';
import pool from '../database/connection';
import { CreateOrderRequest, Order, OrderStatus, OrderType } from '../types';

export class OrderService {
  async ensureSchema(): Promise<void> {
    // Create types and tables if they do not exist
    await pool.query(`
      DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_type') THEN
          CREATE TYPE order_type AS ENUM ('ONLINE','OFFLINE','INSTORE','MARKETPLACE','CALLCENTER');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
          CREATE TYPE order_status AS ENUM ('PENDING','PENDING_PAYMENT','PROCESSING','COMPLETE','CLOSED','CANCELED','HOLDED','PAYMENT_REVIEW','FRAUD','SHIPPING');
        END IF;
      END $$;

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
        currency VARCHAR(3) DEFAULT 'USD',
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

      CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
      CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
      CREATE INDEX IF NOT EXISTS idx_orders_order_type ON orders(order_type);
      CREATE INDEX IF NOT EXISTS idx_orders_item_id ON orders(item_id);

      CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS TRIGGER AS $$
      BEGIN NEW.updated_at = CURRENT_TIMESTAMP; RETURN NEW; END; $$ LANGUAGE plpgsql;

      DO $$ BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_trigger WHERE tgname = 'update_orders_updated_at'
        ) THEN
          CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        END IF;
      END $$;
    `);
  }

  async ensureItemsSeeded(): Promise<void> {
    await this.ensureSchema();
    const countRes = await pool.query('SELECT COUNT(*)::int as count FROM items');
    const count = countRes.rows[0]?.count || 0;
    if (count >= 100) return;

    await pool.query('TRUNCATE TABLE items RESTART IDENTITY CASCADE');
    let itemNames: { name: string; detail: string }[] = [];
    const parsedItems = (itemsData as unknown as { name: string; detail: string }[]) || [];
    if (Array.isArray(parsedItems) && parsedItems.length > 0) {
      itemNames = parsedItems.slice(0, 100);
    } else {
      console.warn('items_data.json empty or invalid. Falling back to generated items.');
      for (let i = 1; i <= 100; i++) {
        itemNames.push({ name: `General Item ${i}`, detail: `Generic description for item ${i}` });
      }
    }

    // Ensure exactly 100 entries (pad if fewer)
    while (itemNames.length < 100) {
      const idx = itemNames.length + 1;
      itemNames.push({ name: `General Item ${idx}`, detail: `Generic description for item ${idx}` });
    }

    const values: string[] = [];
    const params: any[] = [];
    for (let i = 0; i < 100; i++) {
      const itemId = i + 1;
      values.push(`($${params.length + 1}, $${params.length + 2}, $${params.length + 3})`);
      params.push(itemId, itemNames[i].name, itemNames[i].detail);
    }
    const sql = `INSERT INTO items (item_id, name, detail) VALUES ${values.join(',')}`;
    await pool.query(sql, params);
  }

  async getRecentOrdersWithItems(lastMinutes: number): Promise<any[]> {
    const query = `
      SELECT 
        o.order_id,
        o.customer_id,
        o.customer_name,
        o.status,
        o.order_type,
        o.total_amount,
        o.currency,
        o.updated_at,
        o.end_time_processing,
        o.end_time_payment_review,
        o.end_time_shipping,
        i.name as item_name,
        i.detail as item_detail
      FROM orders o
      LEFT JOIN items i ON o.item_id = i.item_id
      WHERE o.updated_at >= NOW() - INTERVAL '${lastMinutes} minutes'
      ORDER BY o.updated_at DESC
      LIMIT 1000
    `;
    const result = await pool.query(query);
    return result.rows;
  }

  async getRecentOrdersSummary(lastMinutes: number = 60, limit: number = 1000): Promise<{ rows: any[]; total: number; statusCounts: Record<string, number>; }> {
    const rowsQuery = `
      SELECT 
        o.order_id,
        o.customer_id,
        o.customer_name,
        o.status,
        o.order_type,
        o.total_amount,
        o.currency,
        o.updated_at,
        o.end_time_processing,
        o.end_time_payment_review,
        o.end_time_shipping,
        i.name as item_name,
        i.detail as item_detail
      FROM orders o
      LEFT JOIN items i ON o.item_id = i.item_id
      WHERE o.updated_at >= NOW() - INTERVAL '${lastMinutes} minutes'
      ORDER BY o.updated_at DESC
      LIMIT ${limit}
    `;

    const countQuery = `
      SELECT COUNT(*)::int as total
      FROM orders o
      WHERE o.updated_at >= NOW() - INTERVAL '${lastMinutes} minutes'
    `;

    const statusAggQuery = `
      SELECT o.status, COUNT(*)::int as count
      FROM orders o
      WHERE o.updated_at >= NOW() - INTERVAL '${lastMinutes} minutes'
      GROUP BY o.status
    `;

    const [rowsRes, totalRes, statusRes] = await Promise.all([
      pool.query(rowsQuery),
      pool.query(countQuery),
      pool.query(statusAggQuery)
    ]);

    const statusCounts: Record<string, number> = {};
    for (const r of statusRes.rows) {
      statusCounts[r.status] = r.count;
    }

    return { rows: rowsRes.rows, total: totalRes.rows[0]?.total || 0, statusCounts };
  }

  async generateMockOrders(count: number = 1): Promise<Order[]> {
    const mockOrders: Order[] = [];

    const orderTypes: OrderType[] = ['ONLINE','OFFLINE','INSTORE','MARKETPLACE','CALLCENTER'];
    let customerNames: string[] = [];
    const parsedNames = (customerNamesData as unknown as string[]) || [];
    if (Array.isArray(parsedNames) && parsedNames.length > 0) {
      customerNames = parsedNames;
    }
    
    for (let i = 0; i < count; i++) {
      const orderId = `ORD-${Date.now()}-${i + 1}`;
      
      const customerIndex = customerNames.length > 0
        ? Math.floor(Math.random() * customerNames.length)
        : 0;
      const order_type = orderTypes[Math.floor(Math.random() * orderTypes.length)];
      const randomItemId = Math.floor(Math.random() * 100) + 1; // 1..100
      const now = new Date();
      const addDays = (date: Date, days: number) => new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
      const addHours = (date: Date, hours: number) => new Date(date.getTime() + hours * 60 * 60 * 1000);
      const randInt = (min: number, max: number) => Math.floor(Math.random() * (max - min + 1)) + min;

      // Generate timeline per order_type
      let end_time_processing: Date;
      let end_time_shipping: Date;
      let end_time_payment_review: Date;

      if (order_type === 'ONLINE' || order_type === 'CALLCENTER') {
        end_time_processing = addDays(now, randInt(1, 2));
        end_time_shipping = addDays(end_time_processing, randInt(1, 2));
        end_time_payment_review = addHours(end_time_shipping, 2);
      } else {
        end_time_processing = addDays(now, randInt(1, 2));
        end_time_payment_review = addHours(end_time_processing, 2);
        end_time_shipping = addDays(end_time_payment_review, randInt(1, 2));
      }
      
      const order: Order = {
        order_id: orderId,
        customer_id: `CUST-${customerIndex + 1}`,
        customer_name: customerNames[customerIndex],
        customer_email: (() => {
          const raw = customerNames[customerIndex] || `customer${customerIndex + 1}`;
          const local = raw
            .toLowerCase()
            .normalize('NFKD')
            .replace(/[^a-z0-9\s.-]/g, '')
            .trim()
            .replace(/\s+/g, '.');
          return `${local || 'customer'}.${customerIndex + 1}@gmail.com`;
        })(),
        customer_phone: (() => {
          // Generate NANP-compliant number: +1-AAA-XXX-XXXX (A and X 2-9 for area/exchange start)
          const randDigit = (min: number, max: number) => Math.floor(Math.random() * (max - min + 1)) + min;
          const area = `${randDigit(2,9)}${randDigit(0,9)}${randDigit(0,9)}`;
          const exchange = `${randDigit(2,9)}${randDigit(0,9)}${randDigit(0,9)}`;
          const line = `${randDigit(0,9)}${randDigit(0,9)}${randDigit(0,9)}${randDigit(0,9)}`;
          return `+1-${area}-${exchange}-${line}`;
        })(),
        total_amount: (() => {
          const min = 10;   // $10.00
          const max = 1000; // $1000.00
          const value = Math.random() * (max - min) + min;
          return Math.round(value * 100) / 100; // two decimals
        })(),
        currency: 'USD',
        order_type,
        status: 'PENDING',
        item_id: randomItemId,
        payment_method: 'CREDIT_CARD',
        shipping_address: `${Math.floor(Math.random() * 100) + 1} Street, District ${Math.floor(Math.random() * 20) + 1}, Ho Chi Minh City`,
        notes: `Mock order ${i + 1} - PENDING`,
        end_time_processing,
        end_time_payment_review,
        end_time_shipping
      };

      mockOrders.push(order);
    }

    return mockOrders;
  }

  async createOrder(orderData: CreateOrderRequest): Promise<Order> {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      const orderId = `ORD-${Date.now()}-${uuidv4().substring(0, 8)}`;
      
      const orderQuery = `
        INSERT INTO orders (
          order_id, customer_id, customer_name, customer_email, customer_phone,
          total_amount, currency, order_type, status,
          payment_method, shipping_address, notes, item_id,
          end_time_processing, end_time_payment_review, end_time_shipping
        )
        VALUES (
          $1, $2, $3, $4, $5,
          $6, $7, $8::order_type, $9,
          $10, $11, $12, $13,
          $14, $15, $16
        )
        RETURNING *
      `;
      
      const orderValues = [
        orderId,
        orderData.customer_id,
        orderData.customer_name,
        orderData.customer_email,
        orderData.customer_phone,
        orderData.total_amount,
        orderData.currency || 'USD',
        (orderData.order_type || 'ONLINE'),
        'PENDING',
        orderData.payment_method,
        orderData.shipping_address,
        orderData.notes || null,
        orderData.item_id || null,
        (orderData as any).end_time_processing || null,
        (orderData as any).end_time_payment_review || null,
        (orderData as any).end_time_shipping || null
      ];
      
      const orderResult = await client.query(orderQuery, orderValues);
      const order = orderResult.rows[0];
      
      await client.query('COMMIT');
      
      return order;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getOrders(limit: number = 100, offset: number = 0): Promise<any[]> {
    const query = `
      SELECT 
        o.order_id,
        o.customer_id,
        o.customer_name,
        o.customer_email,
        o.customer_phone,
        o.total_amount,
        o.currency,
        o.order_type,
        o.status,
        o.created_at,
        o.updated_at,
        o.payment_method,
        o.shipping_address,
        o.tracking_number,
        o.notes,
        i.name as item_name,
        i.detail as item_detail
      FROM orders o
      LEFT JOIN items i ON o.item_id = i.item_id
      ORDER BY o.created_at DESC 
      LIMIT $1 OFFSET $2
    `;
    const result = await pool.query(query, [limit, offset]);
    return result.rows;
  }

  async getOrderById(orderId: string): Promise<any | null> {
    const query = `
      SELECT 
        o.order_id,
        o.customer_id,
        o.customer_name,
        o.customer_email,
        o.customer_phone,
        o.total_amount,
        o.currency,
        o.order_type,
        o.status,
        o.created_at,
        o.updated_at,
        o.end_time_processing,
        o.end_time_payment_review,
        o.end_time_shipping,
        o.payment_method,
        o.shipping_address,
        o.tracking_number,
        o.notes,
        i.name as item_name,
        i.detail as item_detail
      FROM orders o
      LEFT JOIN items i ON o.item_id = i.item_id
      WHERE o.order_id = $1
    `;
    const result = await pool.query(query, [orderId]);
    return result.rows[0] || null;
  }

  async updateOrderStatus(orderId: string, status: OrderStatus, notes?: string): Promise<Order> {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      const currentOrder = await this.getOrderById(orderId);
      if (!currentOrder) {
        throw new Error('Order not found');
      }
      
      const updateQuery = `
        UPDATE orders 
        SET status = $1, notes = COALESCE($3, notes), updated_at = CURRENT_TIMESTAMP
        WHERE order_id = $2
        RETURNING *
      `;
      
      const result = await client.query(updateQuery, [status, orderId, notes || null]);
      
      await client.query('COMMIT');
      
      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async seedMockData(count: number = 1): Promise<void> {
    await this.ensureItemsSeeded();

    const mockOrders = await this.generateMockOrders(count);
    
    for (const order of mockOrders) {
      try {
        const orderData = {
          customer_id: order.customer_id,
          customer_name: order.customer_name,
          customer_email: order.customer_email,
          customer_phone: order.customer_phone,
          total_amount: order.total_amount,
          currency: order.currency,
          order_type: order.order_type,
          payment_method: order.payment_method,
          shipping_address: order.shipping_address,
          notes: order.notes,
          item_id: order.item_id,
          end_time_processing: order.end_time_processing,
          end_time_payment_review: order.end_time_payment_review,
          end_time_shipping: order.end_time_shipping
        } as CreateOrderRequest;
        
        await this.createOrder(orderData);
      } catch (error) {
        console.error(`Error creating mock order: ${error}`);
      }
    }
    
    console.log(`Mock data seeded successfully: ${mockOrders.length} orders (PENDING)`);
  }
}
