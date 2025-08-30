#!/bin/bash

# AddToCloud Database Deployment Script (Linux/macOS)
# This script deploys PostgreSQL, MongoDB, and Redis using Docker Compose

set -e

# Default parameters
MODE="docker"
ACTION="start"
SERVICE="all"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

function print_usage() {
    echo -e "${CYAN}AddToCloud Database Deployment Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m, --mode      Deployment mode: docker, kubernetes, k8s (default: docker)"
    echo "  -a, --action    Action: start, stop, restart, status, logs, clean (default: start)"
    echo "  -s, --service   Service: all, postgres, mongodb, redis (default: all)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start all databases with Docker"
    echo "  $0 -m docker -a start                # Start all databases with Docker"
    echo "  $0 -m kubernetes -a start             # Deploy to Kubernetes"
    echo "  $0 -a stop                            # Stop all databases"
    echo "  $0 -s postgres -a logs                # Show PostgreSQL logs"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

echo -e "${CYAN}🚀 AddToCloud Database Deployment Script${NC}"
echo -e "${YELLOW}Mode: $MODE | Action: $ACTION | Service: $SERVICE${NC}"

function start_docker_databases() {
    echo -e "${GREEN}🐳 Starting databases with Docker Compose...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
    
    # Start databases
    if [[ "$SERVICE" == "all" ]]; then
        docker-compose -f docker-compose.databases.yml up -d
    else
        docker-compose -f docker-compose.databases.yml up -d "$SERVICE"
    fi
    
    echo -e "${GREEN}✅ Databases started successfully!${NC}"
    echo ""
    echo -e "${CYAN}📋 Database Connection Information:${NC}"
    echo -e "${WHITE}PostgreSQL: localhost:5432${NC}"
    echo -e "${GRAY}  Database: addtocloud_prod${NC}"
    echo -e "${GRAY}  Username: addtocloud${NC}"
    echo -e "${GRAY}  Password: addtocloud_secure_2024${NC}"
    echo ""
    echo -e "${WHITE}MongoDB: localhost:27017${NC}"
    echo -e "${GRAY}  Database: addtocloud_logs${NC}"
    echo -e "${GRAY}  Username: addtocloud${NC}"
    echo -e "${GRAY}  Password: addtocloud_mongo_2024${NC}"
    echo ""
    echo -e "${WHITE}Redis: localhost:6379${NC}"
    echo -e "${GRAY}  Password: addtocloud_redis_2024${NC}"
    echo ""
    echo -e "${CYAN}🔧 Admin Interfaces:${NC}"
    echo -e "${WHITE}pgAdmin: http://localhost:5050${NC}"
    echo -e "${GRAY}  Email: admin@addtocloud.tech${NC}"
    echo -e "${GRAY}  Password: addtocloud_admin_2024${NC}"
    echo ""
    echo -e "${WHITE}Mongo Express: http://localhost:8081${NC}"
    echo -e "${GRAY}  Username: admin${NC}"
    echo -e "${GRAY}  Password: addtocloud_admin_2024${NC}"
    echo ""
    echo -e "${WHITE}RedisInsight: http://localhost:8001${NC}"
}

function stop_docker_databases() {
    echo -e "${YELLOW}🛑 Stopping databases...${NC}"
    
    cd "$PROJECT_ROOT"
    
    if [[ "$SERVICE" == "all" ]]; then
        docker-compose -f docker-compose.databases.yml down
    else
        docker-compose -f docker-compose.databases.yml stop "$SERVICE"
    fi
    
    echo -e "${GREEN}✅ Databases stopped successfully!${NC}"
}

function get_docker_status() {
    echo -e "${CYAN}📊 Database Status:${NC}"
    
    cd "$PROJECT_ROOT"
    docker-compose -f docker-compose.databases.yml ps
}

function get_docker_logs() {
    echo -e "${CYAN}📋 Database Logs:${NC}"
    
    cd "$PROJECT_ROOT"
    
    if [[ "$SERVICE" == "all" ]]; then
        docker-compose -f docker-compose.databases.yml logs -f --tail=50
    else
        docker-compose -f docker-compose.databases.yml logs -f --tail=50 "$SERVICE"
    fi
}

function clean_docker_databases() {
    echo -e "${RED}🧹 Cleaning up databases and volumes...${NC}"
    
    echo -e "${YELLOW}This will delete all database data.${NC}"
    read -p "Type 'YES' to confirm: " confirmation
    
    if [[ "$confirmation" != "YES" ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        return
    fi
    
    cd "$PROJECT_ROOT"
    docker-compose -f docker-compose.databases.yml down -v --remove-orphans
    
    echo -e "${GREEN}✅ Databases and volumes removed successfully!${NC}"
}

function deploy_kubernetes_databases() {
    echo -e "${GREEN}☸️ Deploying databases to Kubernetes...${NC}"
    
    # Check if kubectl is available
    if ! command -v kubectl >/dev/null 2>&1; then
        echo -e "${RED}❌ kubectl is not available. Please install kubectl and configure your cluster connection.${NC}"
        exit 1
    fi
    
    # Apply Kubernetes manifests
    kubectl apply -f "$PROJECT_ROOT/infrastructure/kubernetes/databases/"
    
    echo -e "${GREEN}✅ Kubernetes deployment initiated!${NC}"
    echo -e "${YELLOW}🔄 Waiting for pods to be ready...${NC}"
    
    # Wait for deployments to be ready
    kubectl wait --for=condition=ready pod -l app=postgres -n addtocloud-databases --timeout=300s
    kubectl wait --for=condition=ready pod -l app=mongodb -n addtocloud-databases --timeout=300s
    kubectl wait --for=condition=ready pod -l app=redis -n addtocloud-databases --timeout=300s
    
    echo -e "${GREEN}✅ All database pods are ready!${NC}"
    
    # Show connection information
    echo ""
    echo -e "${CYAN}📋 Kubernetes Service Information:${NC}"
    kubectl get services -n addtocloud-databases
}

function clean_kubernetes_databases() {
    echo -e "${RED}🧹 Removing Kubernetes databases...${NC}"
    
    echo -e "${YELLOW}This will delete all Kubernetes database resources.${NC}"
    read -p "Type 'YES' to confirm: " confirmation
    
    if [[ "$confirmation" != "YES" ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        return
    fi
    
    kubectl delete namespace addtocloud-databases --ignore-not-found=true
    echo -e "${GREEN}✅ Kubernetes databases removed successfully!${NC}"
}

# Main execution
case "$MODE" in
    "docker")
        case "$ACTION" in
            "start")
                start_docker_databases
                ;;
            "stop")
                stop_docker_databases
                ;;
            "restart")
                stop_docker_databases
                sleep 5
                start_docker_databases
                ;;
            "status")
                get_docker_status
                ;;
            "logs")
                get_docker_logs
                ;;
            "clean")
                clean_docker_databases
                ;;
            *)
                echo -e "${RED}❌ Unknown action: $ACTION${NC}"
                print_usage
                exit 1
                ;;
        esac
        ;;
    "kubernetes"|"k8s")
        case "$ACTION" in
            "start")
                deploy_kubernetes_databases
                ;;
            "stop"|"clean")
                clean_kubernetes_databases
                ;;
            "status")
                if kubectl get namespace addtocloud-databases >/dev/null 2>&1; then
                    kubectl get all -n addtocloud-databases
                else
                    echo -e "${YELLOW}No Kubernetes databases found or kubectl not configured.${NC}"
                fi
                ;;
            "logs")
                if [[ "$SERVICE" == "all" ]]; then
                    kubectl logs -n addtocloud-databases -l component=database --tail=50
                else
                    kubectl logs -n addtocloud-databases -l app="$SERVICE" --tail=50
                fi
                ;;
            *)
                echo -e "${RED}❌ Unknown action: $ACTION${NC}"
                print_usage
                exit 1
                ;;
        esac
        ;;
    *)
        echo -e "${RED}❌ Unknown mode: $MODE${NC}"
        print_usage
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Database deployment script completed!${NC}"
