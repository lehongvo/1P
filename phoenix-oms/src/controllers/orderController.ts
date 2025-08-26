import { Request, Response } from 'express';
import { OrderService } from '../services/orderService';
import { CreateOrderRequest, UpdateOrderStatusRequest, ApiResponse } from '../types';

export class OrderController {
  private orderService: OrderService;

  constructor() {
    this.orderService = new OrderService();
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
      await this.orderService.seedMockData(isNaN(count) ? 2 : count);
      
      const response: ApiResponse<any> = {
        success: true,
        message: `Mock data seeded successfully (${isNaN(count) ? 2 : count} orders, PENDING)`
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
