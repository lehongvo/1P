export type OrderType = 'ONLINE' | 'OFFLINE' | 'INSTORE' | 'MARKETPLACE' | 'CALLCENTER';

export interface Item {
  id?: number;
  item_id: number;
  name: string;
  detail?: string;
  created_at?: Date;
}

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
  item_id?: number;
  created_at?: Date;
  updated_at?: Date;
  end_time_processing?: Date | null;
  end_time_payment_review?: Date | null;
  end_time_shipping?: Date | null;
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

export interface CreateOrderRequest {
  customer_id: string;
  customer_name: string;
  customer_email: string;
  customer_phone?: string;
  total_amount: number;
  currency?: string;
  order_type?: OrderType;
  payment_method?: string;
  shipping_address?: string;
  item_id?: number;
  notes?: string;
}

export interface UpdateOrderStatusRequest {
  status: OrderStatus;
  notes?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}
