import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import cron from 'node-cron';
import orderRoutes from './routes/orderRoutes';
import { OrderService } from './services/orderService';
import { OrderStatus } from './types';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;
const DATA_API_KEY = '0x9f299A715cb6aF84e93ba90371538Ddf130E1ec0021hf902';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API key middleware for all /api/v1 except /api/v1/health
app.use('/api/v1', (req, res, next) => {
  if (req.path === '/health') return next();
  const headerKey = req.header('x-api-key') || req.header('authorization') || '';
  const token = headerKey.replace(/^Bearer\s+/i, '').trim();
  if (token !== DATA_API_KEY) {
    return res.status(401).json({ success: false, code: 'UNAUTHORIZED', error: 'Invalid API key' });
  }
  return next();
});

// Routes
app.use('/api/v1', orderRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Phoenix OMS',
    version: '1.0.0',
    description: 'Order Management System for LOTUS O2O',
    endpoints: {
      health: '/api/v1/health',
      orders: '/api/v1/orders',
      seedMockData: '/api/v1/seed-mock-data'
    }
  });
});

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Something went wrong!'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

// Auto-advance cron (every 2 minutes)
const terminalStatuses: OrderStatus[] = ['COMPLETE','CLOSED','CANCELED','FRAUD'];
const progression: OrderStatus[] = [
  'PENDING',
  'PENDING_PAYMENT',
  'PAYMENT_REVIEW',
  'PROCESSING',
  'SHIPPING',
  'COMPLETE',
  'CLOSED'
];

const service = new OrderService();

// Robust seeding on startup: retry until DB is ready (max 30 attempts)
(async () => {
  const maxAttempts = 30;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await service.ensureItemsSeeded();
      console.log('✅ Items master ensured (100 rows).');
      break;
    } catch (err: any) {
      const delayMs = 2000;
      console.error(`❌ Seed items attempt ${attempt}/${maxAttempts} failed: ${err?.message || err}. Retrying in ${delayMs/1000}s...`);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }
})();

cron.schedule('0 */2 * * * *', async () => {
  try {
    console.log('🌱Start: Auto-advance cron (every 2 minutes)');
    const inProgress = await (async () => {
      const result = await service.getOrders(500, 0);
      return result.filter((o: any) => !terminalStatuses.includes(o.status));
    })();

    for (const order of inProgress) {
      // 3% branch to exception (CANCELED/FRAUD), 97% follow standard progression
      const r = Math.random();
      if (r < 0.03) {
        const exception: OrderStatus = Math.random() < 0.5 ? 'CANCELED' : 'FRAUD';
        await service.updateOrderStatus(order.order_id, exception, 'Auto-exception by OMS cron (3%)');
        continue;
      }

      const currentIndex = progression.indexOf(order.status);
      if (currentIndex === -1) {
        continue;
      }
      const next = progression[Math.min(currentIndex + 1, progression.length - 1)];
      if (next !== order.status) {
        await service.updateOrderStatus(order.order_id, next, 'Auto-advanced by OMS cron (97%)');
      }
    }
    console.log('🌱End: Auto-advance cron (every 2 minutes)');
  } catch (e) {
    console.error('Auto-advance cron error:', e);
  }
});

// Seed mock data every 5 minutes
cron.schedule('0 */5 * * * *', async () => {
  try {
    console.log('🌱Start: Seeding mock data via cron (every 5 minutes)');
    await fetch(`http://localhost:${PORT}/api/v1/seed-mock-data`, {
      method: 'POST',
      headers: {
        'x-api-key': DATA_API_KEY
      }
    });
    console.log('🌱End: Seeded mock data via cron (every 5 minutes)');
  } catch (e) {
    console.error('Seed cron error:', e);
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Phoenix OMS server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/v1/health`);
  console.log(`📦 Orders API: http://localhost:${PORT}/api/v1/orders`);
  console.log(`🌱 Seed mock data: http://localhost:${PORT}/api/v1/seed-mock-data`);
  console.log('⏰ OMS auto-advance cron: every 2 minutes (97% main path, 3% exception)');
  console.log('⏰ OMS seed cron: every 5 minutes');
});
