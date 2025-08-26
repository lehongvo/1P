import { v4 as uuidv4 } from 'uuid';
import pool from '../database/connection';
import { Order, OrderStatus, CreateOrderRequest, OrderType } from '../types';

export class OrderService {
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
      const order_type = orderTypes[i % orderTypes.length];
      
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
                           total_amount, currency, order_type, status, payment_method, shipping_address, notes)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
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
        orderData.notes || null
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

  async getOrders(limit: number = 100, offset: number = 0): Promise<Order[]> {
    const query = `
      SELECT * FROM orders 
      ORDER BY created_at DESC 
      LIMIT $1 OFFSET $2
    `;
    
    const result = await pool.query(query, [limit, offset]);
    return result.rows;
  }

  async getOrderById(orderId: string): Promise<Order | null> {
    const query = 'SELECT * FROM orders WHERE order_id = $1';
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

  // Mock data generation for testing
  async seedMockData(count: number = 2): Promise<void> {
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
          payment_method: order.payment_method,
          shipping_address: order.shipping_address,
          notes: order.notes
        } as CreateOrderRequest;
        
        await this.createOrder(orderData);
      } catch (error) {
        console.error(`Error creating mock order: ${error}`);
      }
    }
    
    console.log(`Mock data seeded successfully: ${mockOrders.length} orders (PENDING)`);
  }
}
