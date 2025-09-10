import { Request, Response } from 'express';
import { OrderService } from '../services/orderService';
import { ApiResponse, CreateOrderRequest, UpdateOrderStatusRequest } from '../types';

const DATA_API_KEY = '0x9f299A715cb6aF84e93ba90371538Ddf130E1ec0021hf902';

export class OrderController {
  private orderService: OrderService;

  constructor() {
    this.orderService = new OrderService();
  }

  private isAuthorized(req: Request): boolean {
    const headerKey = req.header('x-api-key') || req.header('authorization') || '';
    const token = headerKey.replace(/^Bearer\s+/i, '').trim();
    return token === DATA_API_KEY;
  }

  async getRecentForMonitoring(req: Request, res: Response): Promise<void> {
    try {
      if (!this.isAuthorized(req)) {
        res.status(401).json({ success: false, code: 'UNAUTHORIZED', error: 'Unauthorized' });
        return;
      }
      const minutes = req.query.minutes ? Math.max(1, Math.min(1440, parseInt(String(req.query.minutes), 10))) : 60;
      const limit = req.query.limit ? Math.max(1, Math.min(5000, parseInt(String(req.query.limit), 10))) : 1000;

      const { rows, total, statusCounts } = await this.orderService.getRecentOrdersSummary(minutes, limit);
      const response = {
        success: true,
        code: 'OK',
        windowMinutes: minutes,
        limit,
        total,
        statusCounts,
        data: rows
      };
      res.status(200).json(response);
    } catch (error) {
      res.status(500).json({ success: false, code: 'INTERNAL_ERROR', error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }

  async createOrder(req: Request, res: Response): Promise<void> {
    try {
      const orderData: CreateOrderRequest = req.body;
      const order = await this.orderService.createOrder(orderData);
      
      const response: ApiResponse<any> = {
        success: true,
        data: order,
        message: 'Order created successfully'
      };
      
      res.status(201).json(response);
    } catch (error) {
      const response: ApiResponse<any> = {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
      
      res.status(400).json(response);
    }
  }

  async getOrders(req: Request, res: Response): Promise<void> {
    try {
      const limit = parseInt(req.query.limit as string) || 100;
      const offset = parseInt(req.query.offset as string) || 0;
      
      const orders = await this.orderService.getOrders(limit, offset);
      
      const response: ApiResponse<any> = {
        success: true,
        data: orders,
        message: 'Orders retrieved successfully'
      };
      
      res.status(200).json(response);
    } catch (error) {
      const response: ApiResponse<any> = {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
      
      res.status(500).json(response);
    }
  }

  async getOrderById(req: Request, res: Response): Promise<void> {
    try {
      const { orderId } = req.params;
      const order = await this.orderService.getOrderById(orderId);
      
      if (!order) {
        const response: ApiResponse<any> = {
          success: false,
          error: 'Order not found'
        };
        
        res.status(404).json(response);
        return;
      }
      
      const response: ApiResponse<any> = {
        success: true,
        data: order,
        message: 'Order retrieved successfully'
      };
      
      res.status(200).json(response);
    } catch (error) {
      const response: ApiResponse<any> = {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
      
      res.status(500).json(response);
    }
  }

  async updateOrderStatus(req: Request, res: Response): Promise<void> {
    try {
      const { orderId } = req.params;
      const statusData: UpdateOrderStatusRequest = req.body;
      
      const order = await this.orderService.updateOrderStatus(
        orderId, 
        statusData.status, 
        statusData.notes
      );
      
      const response: ApiResponse<any> = {
        success: true,
        data: order,
        message: 'Order status updated successfully'
      };
      
      res.status(200).json(response);
    } catch (error) {
      const response: ApiResponse<any> = {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
      
      res.status(400).json(response);
    }
  }

  async seedMockData(req: Request, res: Response): Promise<void> {
    try {
      const count = req.query.count ? parseInt(req.query.count as string, 10) : 2;
      await this.orderService.seedMockData(isNaN(count) ? 1 : count);
      
      const response: ApiResponse<any> = {
        success: true,
        message: `Mock data seeded successfully (${isNaN(count) ? 1 : count} orders, PENDING)`
      };
      
      res.status(200).json(response);
    } catch (error) {
      const response: ApiResponse<any> = {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
      
      res.status(500).json(response);
    }
  }

  async getHealth(req: Request, res: Response): Promise<void> {
    const response: ApiResponse<any> = {
      success: true,
      data: {
        service: 'Phoenix OMS',
        status: 'healthy',
        timestamp: new Date().toISOString()
      },
      message: 'Service is healthy'
    };
    
    res.status(200).json(response);
  }
}
