import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import cron from 'node-cron';
import commerceRoutes from './routes/commerceRoutes';
import { CommerceService } from './services/commerceService';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;
const commerceService = new CommerceService();

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/v1', commerceRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Phoenix Commerce Engine',
    version: '1.0.0',
    description: 'Commerce Engine for LOTUS O2O',
    endpoints: {
      health: '/api/v1/health',
      processOrder: '/api/v1/process/:orderId',
      processingHistory: '/api/v1/processing-history',
      monitoringEvents: '/api/v1/monitoring-events',
      processingStats: '/api/v1/processing-stats',
      simulateProcessing: '/api/v1/simulate-processing'
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

// Schedule order processing simulation every 30 seconds
cron.schedule('*/30 * * * * *', async () => {
  try {
    console.log('🔄 Running scheduled order processing simulation...');
    await commerceService.simulateOrderProcessing();
    console.log('✅ Order processing simulation completed');
  } catch (error) {
    console.error('❌ Error in scheduled order processing:', error);
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Phoenix Commerce Engine server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/v1/health`);
  console.log(`⚙️ Process order: http://localhost:${PORT}/api/v1/process/:orderId`);
  console.log(`📈 Processing stats: http://localhost:${PORT}/api/v1/processing-stats`);
  console.log(`🔄 Simulate processing: http://localhost:${PORT}/api/v1/simulate-processing`);
  console.log(`⏰ Scheduled order processing: Every 30 seconds`);
});
