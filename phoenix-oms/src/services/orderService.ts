import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
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
        currency VARCHAR(3) DEFAULT 'VND',
        order_type order_type NOT NULL DEFAULT 'ONLINE',
        status order_status NOT NULL DEFAULT 'PENDING',
        item_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
    try {
      const itemsPath = path.join(__dirname, '..', 'data', 'items_data.json');
      const raw = fs.readFileSync(itemsPath, 'utf-8');
      const parsed = JSON.parse(raw) as { name: string; detail: string }[];
      itemNames = (parsed || []).slice(0, 100);
    } catch (e) {
      console.warn('items_data.json not found or invalid. Falling back to generated items.');
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
        o.updated_at,
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
        o.updated_at,
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

  async generateMockOrders(count: number = 2): Promise<Order[]> {
    const mockOrders: Order[] = [];

    const orderTypes: OrderType[] = ['ONLINE','OFFLINE','INSTORE','MARKETPLACE','CALLCENTER'];
    let customerNames: string[] = [];
    try {
      const namesPath = path.join(__dirname, '..', 'data', 'customer_names_en.json');
      const raw = fs.readFileSync(namesPath, 'utf-8');
      const parsed = JSON.parse(raw) as string[];
      customerNames = Array.isArray(parsed) && parsed.length > 0 ? parsed : [];
    } catch (e) {
      // ignore
    }
    if (customerNames.length === 0) {
      customerNames = [
        'Nguyen Van A', 'Tran Thi B', 'Le Van C', 'Pham Thi D', 'Hoang Van E',
        'Vu Thi F', 'Do Van G', 'Bui Thi H', 'Dang Van I', 'Ngo Thi K',
        'Nguyen Thi L', 'Tran Van M', 'Le Van N', 'Pham Van O', 'Hoang Van P',
        'Vu Van Q', 'Do Van R', 'Bui Van S', 'Dang Van T', 'Ngo Van U',
        'Nguyen Thi V', 'Tran Van W', 'Le Van X', 'Pham Van Y', 'Hoang Van Z'
      ];
    }

    for (let i = 0; i < count; i++) {
      const orderId = `ORD-${Date.now()}-${i + 1}`;
      const customerIndex = i % customerNames.length;
      const order_type = orderTypes[Math.floor(Math.random() * orderTypes.length)];
      const randomItemId = Math.floor(Math.random() * 100) + 1; // 1..100
      
      const order: Order = {
        order_id: orderId,
        customer_id: `CUST-${customerIndex + 1}`,
        customer_name: customerNames[customerIndex],
        customer_email: `customer${customerIndex + 1}@example.com`,
        customer_phone: `090${Math.floor(Math.random() * 9000000) + 1000000}`,
        total_amount: Math.floor(Math.random() * 40000000) + 1000000,
        currency: 'VND',
        order_type,
        status: 'PENDING',
        item_id: randomItemId,
        payment_method: 'CREDIT_CARD',
        shipping_address: `${Math.floor(Math.random() * 100) + 1} Street, District ${Math.floor(Math.random() * 20) + 1}, Ho Chi Minh City`,
        notes: `Mock order ${i + 1} - PENDING`
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
        INSERT INTO orders (order_id, customer_id, customer_name, customer_email, customer_phone, 
                           total_amount, currency, order_type, status, payment_method, shipping_address, notes, item_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8::order_type, $9, $10, $11, $12, $13)
        RETURNING *
      `;
      
      const orderValues = [
        orderId,
        orderData.customer_id,
        orderData.customer_name,
        orderData.customer_email,
        orderData.customer_phone,
        orderData.total_amount,
        orderData.currency || 'VND',
        (orderData.order_type || 'ONLINE'),
        'PENDING',
        orderData.payment_method,
        orderData.shipping_address,
        orderData.notes || null,
        orderData.item_id || null
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

  async seedMockData(count: number = 2): Promise<void> {
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
          item_id: order.item_id
        } as CreateOrderRequest;
        
        await this.createOrder(orderData);
      } catch (error) {
        console.error(`Error creating mock order: ${error}`);
      }
    }
    
    console.log(`Mock data seeded successfully: ${mockOrders.length} orders (PENDING)`);
  }
}
