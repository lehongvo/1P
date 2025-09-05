import { Request, Response } from 'express';
import { CommerceService } from '../services/commerceService';
import { ApiResponse } from '../types';

export class CommerceController {
  private commerceService: CommerceService;

  constructor() {
    this.commerceService = new CommerceService();
  }

  async processOrder(req: Request, res: Response): Promise<void> {
    try {
      const { orderId } = req.params;
      const result = await this.commerceService.processOrder(orderId);
      
      const response: ApiResponse<any> = {
        success: true,
        data: result,
        message: 'Order processed successfully'
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

  async simulateOrderProcessing(req: Request, res: Response): Promise<void> {
    try {
      await this.commerceService.simulateOrderProcessing();
      
      const response: ApiResponse<any> = {
        success: true,
        message: 'Order processing simulation completed'
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
        service: 'Phoenix Commerce Engine',
        status: 'healthy',
        timestamp: new Date().toISOString()
      },
      message: 'Service is healthy'
    };
    
    res.status(200).json(response);
  }
}
