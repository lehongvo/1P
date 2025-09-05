import { Router } from 'express';
import { OrderController } from '../controllers/orderController';

const router = Router();
const orderController = new OrderController();

// Health check
router.get('/health', orderController.getHealth.bind(orderController));

// Monitoring endpoint (last 1h orders + items)
router.get('/monitor/recent', orderController.getRecentForMonitoring.bind(orderController));

// Order routes
router.post('/orders', orderController.createOrder.bind(orderController));
router.get('/orders', orderController.getOrders.bind(orderController));
router.get('/orders/:orderId', orderController.getOrderById.bind(orderController));
router.put('/orders/:orderId/status', orderController.updateOrderStatus.bind(orderController));

// Mock data seeding
router.post('/seed-mock-data', orderController.seedMockData.bind(orderController));

export default router;
