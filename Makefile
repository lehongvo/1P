.PHONY: start stop restart status logs

start:
	@echo "🚀 Starting 1P Service Project..."
	docker-compose up -d
	@echo "⏳ Waiting for containers to be ready..."
	sleep 10
	@echo "🎯 Starting mock data generator..."
	cd mock && bash ./generate_mock_data.sh --watch &

stop:
	@echo "🛑 Stopping 1P Service Project..."
	pkill -f generate_mock_data || true
	docker-compose down

restart: stop start

status:
	@echo "📊 Container Status:"
	docker-compose ps
	@echo "📊 Mock Data Generator Status:"
	ps aux | grep generate_mock_data | grep -v grep || echo "Not running"

logs:
	docker-compose logs -f

clean:
	@echo "🧹 Cleaning up..."
	docker-compose down -v
	docker system prune -f
