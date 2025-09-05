import axios from 'axios';
import pool from '../database/connection';
import { 
  Order, 
  ProcessingResult 
} from '../types';

export class CommerceService {
  private omsApiUrl: string;

  constructor() {
    this.omsApiUrl = process.env.OMS_API_URL || 'http://localhost:3001';
  }

  async processOrder(orderId: string): Promise<ProcessingResult> {
    // Fetch order from OMS
    const order = await this.getOrderFromOMS(orderId);
    if (!order) {
      throw new Error('Order not found in OMS');
    }

    // Perform business validations
    const result = await this.performBusinessValidations(order);

    // Optionally, update OMS status hint via notes (actual status flow controlled by OMS)
    try {
      await axios.put(`${this.omsApiUrl}/api/v1/orders/${order.order_id}/status`, {
        status: result.success ? 'PROCESSING' : 'HOLDED',
        notes: result.success ? 'Validated by Commerce Engine' : (result.errorMessage || 'Validation failed')
      });
    } catch (e) {
      // Best-effort; do not block
    }

    return result;
  }

  private async performBusinessValidations(order: Order): Promise<ProcessingResult> {
    const result: ProcessingResult = {
      success: true,
      canFulfill: true,
      inventoryAvailable: true,
      pricingValid: true,
      customerEligible: true
    };

    const inventoryAvailable = await this.checkInventory(order);
    result.inventoryAvailable = inventoryAvailable;
    if (!inventoryAvailable) {
      result.success = false;
      result.canFulfill = false;
      result.errorMessage = 'Insufficient inventory';
      return result;
    }

    const pricingValid = await this.validatePricing(order);
    result.pricingValid = pricingValid;
    if (!pricingValid) {
      result.success = false;
      result.canFulfill = false;
      result.errorMessage = 'Pricing validation failed';
      return result;
    }

    const customerEligible = await this.checkCustomerEligibility(order);
    result.customerEligible = customerEligible;
    if (!customerEligible) {
      result.success = false;
      result.canFulfill = false;
      result.errorMessage = 'Customer not eligible';
      return result;
    }

    return result;
  }

  private async checkInventory(order: Order): Promise<boolean> {
    const random = Math.random();
    return random > 0.1;
  }

  private async validatePricing(order: Order): Promise<boolean> {
    const random = Math.random();
    return random > 0.05;
  }

  private async checkCustomerEligibility(order: Order): Promise<boolean> {
    const random = Math.random();
    return random > 0.02;
  }

  async getOrderFromOMS(orderId: string): Promise<Order | null> {
    try {
      const response = await axios.get(`${this.omsApiUrl}/api/v1/orders/${orderId}`);
      return response.data.data;
    } catch (error) {
      return null;
    }
  }

  async simulateOrderProcessing(): Promise<void> {
    try {
      const response = await axios.get(`${this.omsApiUrl}/api/v1/orders?limit=10`);
      const orders = response.data.data as Order[];
      
      for (const order of orders) {
        if (order.status === 'PENDING') {
          try {
            await new Promise(resolve => setTimeout(resolve, Math.random() * 2000 + 500));
            await this.processOrder(order.order_id);
          } catch (_) {}
        }
      }
    } catch (error) {}
  }
}
