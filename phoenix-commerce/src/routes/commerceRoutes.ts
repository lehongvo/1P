import { Router } from 'express';
import { CommerceController } from '../controllers/commerceController';

const router = Router();
const commerceController = new CommerceController();

// Health check
router.get('/health', commerceController.getHealth.bind(commerceController));

// Commerce processing routes
router.post('/process/:orderId', commerceController.processOrder.bind(commerceController));

// Simulation routes
router.post('/simulate-processing', commerceController.simulateOrderProcessing.bind(commerceController));

export default router;
