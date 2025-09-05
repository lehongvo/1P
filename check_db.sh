#!/bin/bash
PGPASSWORD="lotus_password" psql -h 34.142.150.197 -p 5432 -U lotus_user -d lotus_o2o -c "SELECT COUNT(*) as total_records, COUNT(CASE WHEN status = 4 THEN 1 END) as failed_records, COUNT(CASE WHEN status = 1 THEN 1 END) as success_records FROM promotion WHERE DATE(created_at) = '2025-09-05';"
