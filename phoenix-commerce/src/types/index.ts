export type OrderType = 'ONLINE' | 'OFFLINE' | 'INSTORE' | 'MARKETPLACE' | 'CALLCENTER';

export interface Order {
  id?: number;
  order_id: string;
  customer_id: string;
  customer_name: string;
  customer_email: string;
  customer_phone?: string;
  total_amount: number;
  currency?: string;
  order_type: OrderType;
  status: OrderStatus;
  created_at?: Date;
  updated_at?: Date;
  payment_method?: string;
  shipping_address?: string;
  tracking_number?: string;
  notes?: string;
}

export type OrderStatus = 
  | 'PENDING'
  | 'PENDING_PAYMENT'
  | 'PROCESSING'
  | 'COMPLETE'
  | 'CLOSED'
  | 'CANCELED'
  | 'HOLDED'
  | 'PAYMENT_REVIEW'
  | 'FRAUD'
  | 'SHIPPING';

export interface ProcessingResult {
  success: boolean;
  canFulfill: boolean;
  inventoryAvailable: boolean;
  pricingValid: boolean;
  customerEligible: boolean;
  errorMessage?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}
