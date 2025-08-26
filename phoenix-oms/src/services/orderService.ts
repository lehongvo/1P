import { v4 as uuidv4 } from 'uuid';
import pool from '../database/connection';
import { Order, OrderStatus, CreateOrderRequest, OrderType } from '../types';

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

    const itemNames: { name: string; detail: string }[] = [
      { name: 'Wireless Mouse', detail: 'Ergonomic 2.4G wireless optical mouse' },
      { name: 'Mechanical Keyboard', detail: 'RGB backlit, blue switches, full size' },
      { name: 'USB-C Charger', detail: '65W fast charger with PD support' },
      { name: 'Noise Cancelling Headphones', detail: 'Over-ear ANC with 30h battery' },
      { name: '4K Monitor', detail: '27-inch IPS, HDR10, 60Hz' },
      { name: 'Portable SSD', detail: '1TB NVMe USB 3.2 Gen2 drive' },
      { name: 'Webcam 1080p', detail: 'Full HD with dual mics and privacy cover' },
      { name: 'Bluetooth Speaker', detail: 'Waterproof portable speaker, deep bass' },
      { name: 'Smartwatch', detail: 'Heart-rate, GPS, sleep tracking' },
      { name: 'Fitness Tracker', detail: '24/7 activity and SPO2 monitoring' },
      { name: 'Gaming Controller', detail: 'Wireless joystick for PC/Console' },
      { name: 'HDMI Cable', detail: '2.1 certified, 8K/60, 48Gbps' },
      { name: 'USB-C Hub', detail: '7-in-1 with HDMI, SD, USB 3.0' },
      { name: 'Laptop Stand', detail: 'Adjustable aluminum cooling stand' },
      { name: 'Wireless Earbuds', detail: 'True wireless with ANC and transparency' },
      { name: 'Action Camera', detail: '4K/60 stabilization, waterproof' },
      { name: 'Drone', detail: '4K camera, 3-axis gimbal, GPS return' },
      { name: 'Tripod', detail: 'Lightweight aluminum tripod with head' },
      { name: 'Ring Light', detail: '12-inch LED with phone holder' },
      { name: 'Power Bank', detail: '20,000mAh PD 30W fast charge' },
      { name: 'Wireless Router', detail: 'Wi‑Fi 6 dual-band gigabit' },
      { name: 'Network Switch', detail: '8‑port gigabit unmanaged switch' },
      { name: 'NAS Enclosure', detail: '2‑bay RAID, 2.5GbE support' },
      { name: 'Smart Plug', detail: 'Wi‑Fi plug with energy monitoring' },
      { name: 'Smart Bulb', detail: 'RGB smart bulb, voice control' },
      { name: 'Doorbell Camera', detail: '1080p video doorbell with chime' },
      { name: 'IP Security Camera', detail: 'Pan/tilt, night vision, alerts' },
      { name: 'Electric Kettle', detail: '1.7L stainless steel, auto shutoff' },
      { name: 'Air Fryer', detail: '4L rapid air technology cooker' },
      { name: 'Coffee Maker', detail: 'Drip coffee machine with timer' },
      { name: 'Blender', detail: 'High-speed blender for smoothies' },
      { name: 'Rice Cooker', detail: 'Multi-function digital rice cooker' },
      { name: 'Vacuum Cleaner', detail: 'Cordless stick with HEPA filter' },
      { name: 'Robot Vacuum', detail: 'LiDAR mapping and mop combo' },
      { name: 'Electric Toothbrush', detail: 'Sonic with pressure sensor' },
      { name: 'Hair Dryer', detail: 'Ionic fast-dry with diffuser' },
      { name: 'Steam Iron', detail: 'Ceramic soleplate, anti-drip' },
      { name: 'Clothes Steamer', detail: 'Handheld garment steamer' },
      { name: 'Air Purifier', detail: 'HEPA 13, PM2.5 sensor, silent' },
      { name: 'Humidifier', detail: 'Ultrasonic cool mist 4L' },
      { name: 'Dehumidifier', detail: '20L/day with auto defrost' },
      { name: 'Water Filter Pitcher', detail: '5‑stage filter for clean water' },
      { name: 'Yoga Mat', detail: 'Non-slip TPE 6mm mat' },
      { name: 'Adjustable Dumbbells', detail: 'Pair 2.5–25kg quick select' },
      { name: 'Resistance Bands', detail: 'Set of 5 with door anchor' },
      { name: 'Foam Roller', detail: 'Deep-tissue muscle massage' },
      { name: 'Jump Rope', detail: 'Weighted speed rope, bearing' },
      { name: 'Camping Tent', detail: '2‑person waterproof quick setup' },
      { name: 'Sleeping Bag', detail: '3‑season lightweight mummy bag' },
      { name: 'Hiking Backpack', detail: '30L ventilated daypack' },
      { name: 'Portable Stove', detail: 'Butane gas camp cooker' },
      { name: 'LED Lantern', detail: 'Rechargeable 1000lm lantern' },
      { name: 'E‑Reader', detail: '6‑inch front-lit e‑ink display' },
      { name: 'Tablet', detail: '10‑inch tablet, 128GB storage' },
      { name: 'Smartphone Gimbal', detail: '3‑axis stabilization, tracking' },
      { name: 'Photo Printer', detail: 'Wireless A4 inkjet printer' },
      { name: 'Laser Printer', detail: 'Monochrome duplex laser printer' },
      { name: 'Shredder', detail: 'Cross-cut 12‑sheet shredder' },
      { name: 'Office Chair', detail: 'Ergonomic mesh lumbar support' },
      { name: 'Standing Desk', detail: 'Electric height adjustable desk' },
      { name: 'Desk Lamp', detail: 'Eye-care LED with USB charging' },
      { name: 'Whiteboard', detail: 'Magnetic dry-erase 90×60cm' },
      { name: 'Tool Kit', detail: '108‑piece household tool set' },
      { name: 'Cordless Drill', detail: 'Brushless 20V with 2 batteries' },
      { name: 'Screwdriver Set', detail: 'Precision 60‑in‑1 repair kit' },
      { name: 'Multimeter', detail: 'Auto‑range digital multimeter' },
      { name: 'Soldering Station', detail: 'Temperature‑controlled 60W' },
      { name: 'Air Compressor', detail: 'Portable tire inflator 12V' },
      { name: 'Car Dash Cam', detail: '1440p with GPS and Wi‑Fi' },
      { name: 'Car Jump Starter', detail: '1000A peak with power bank' },
      { name: 'Bike Helmet', detail: 'Lightweight with MIPS safety' },
      { name: 'Bike Lock', detail: 'Heavy-duty U‑lock with cable' },
      { name: 'Bike Light Set', detail: 'USB front and rear lights' },
      { name: 'Electric Scooter', detail: '350W motor, 30km range' },
      { name: 'Luggage 24"', detail: 'Hardshell spinner suitcase' },
      { name: 'Travel Adapter', detail: 'Universal plug with PD' },
      { name: 'Passport Holder', detail: 'RFID blocking leather wallet' },
      { name: 'Sunglasses', detail: 'Polarized UV400 protection' },
      { name: 'Winter Jacket', detail: 'Waterproof insulated parka' },
      { name: 'Running Shoes', detail: 'Breathable cushioning trainers' },
      { name: 'Hoodie', detail: 'Fleece-lined zip hoodie' },
      { name: 'Backpack', detail: 'Anti-theft laptop backpack 15.6"' },
      { name: 'Leather Belt', detail: 'Full-grain reversible belt' },
      { name: 'Wallet', detail: 'Slim RFID blocking card holder' },
      { name: 'Wrist Watch', detail: 'Quartz analog stainless steel' },
      { name: 'Desk Organizer', detail: 'Metal mesh file organizer' },
      { name: 'Cable Management Box', detail: 'Hide power strip and cords' },
      { name: 'Surge Protector', detail: '8 outlets with USB ports' },
      { name: 'Smart Thermostat', detail: 'Learning temperature control' },
      { name: 'Video Projector', detail: '1080p native, 300" display' },
      { name: 'Projection Screen', detail: '120" foldable anti-crease' },
      { name: 'HD Capture Card', detail: '1080p60 USB streaming device' },
      { name: 'Microphone', detail: 'USB condenser with pop filter' },
      { name: 'Audio Interface', detail: '2‑in/2‑out 24‑bit 192kHz' },
      { name: 'Studio Headphones', detail: 'Over‑ear monitoring headphones' },
      { name: 'Graphics Tablet', detail: '8192 levels pen tablet' },
      { name: 'RGB Light Strip', detail: 'Smart LED strip, music sync' },
      { name: 'Smart Scale', detail: 'Body composition Bluetooth scale' },
      { name: 'Massage Gun', detail: 'Percussion deep tissue massager' },
      { name: 'First Aid Kit', detail: 'Comprehensive home emergency kit' },
      { name: 'Fire Extinguisher', detail: 'ABC dry chemical 1kg' },
      { name: 'Safe Box', detail: 'Digital keypad home safe' }
    ];

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

    const customerNames = [
      'Nguyen Van A', 'Tran Thi B', 'Le Van C', 'Pham Thi D', 'Hoang Van E',
      'Vu Thi F', 'Do Van G', 'Bui Thi H', 'Dang Van I', 'Ngo Thi K',
      'Nguyen Thi L', 'Tran Van M', 'Le Van N', 'Pham Van O', 'Hoang Van P',
      'Vu Van Q', 'Do Van R', 'Bui Van S', 'Dang Van T', 'Ngo Van U',
      'Nguyen Thi V', 'Tran Van W', 'Le Van X', 'Pham Van Y', 'Hoang Van Z',
      'Vu Van AA', 'Do Van BB', 'Bui Van CC', 'Dang Van DD', 'Ngo Van EE',
      'Nguyen Thi FF', 'Tran Van GG', 'Le Van HH', 'Pham Van II', 'Hoang Van JJ',
      'Vu Van KK', 'Do Van LL', 'Bui Van MM', 'Dang Van NN', 'Ngo Van OO',
      'Nguyen Thi PP', 'Tran Van QQ', 'Le Van RR', 'Pham Van SS', 'Hoang Van TT',
      'Vu Van UU', 'Do Van VV', 'Bui Van WW', 'Dang Van XX', 'Ngo Van YY',
      'Nguyen Thi ZZ', 'Tran Van AA', 'Le Van BB', 'Pham Van CC', 'Hoang Van DD',
      'Vu Van EE', 'Do Van FF', 'Bui Van GG', 'Dang Van HH', 'Ngo Van II',
      'Nguyen Thi JJ', 'Tran Van KK', 'Le Van LL', 'Pham Van MM', 'Hoang Van NN',
      'Vu Van OO', 'Do Van PP', 'Bui Van QQ', 'Dang Van RR', 'Ngo Van SS',
      'Nguyen Thi TT', 'Tran Van UU', 'Le Van VV', 'Pham Van WW', 'Hoang Van XX',
      'Vu Van YY', 'Do Van ZZ', 'Bui Van AAA', 'Dang Van BBB', 'Ngo Van CCC',
      'Nguyen Thi DDD', 'Tran Van EEE', 'Le Van FFF', 'Pham Van GGG', 'Hoang Van HHH'
    ];

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
