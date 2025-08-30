// AddToCloud MongoDB Initialization Script
// This script sets up collections and indexes for logging and analytics

// Switch to addtocloud_logs database
db = db.getSiblingDB('addtocloud_logs');

// Create collections with validation schemas

// Application logs collection
db.createCollection("application_logs", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["timestamp", "level", "service", "message"],
         properties: {
            timestamp: {
               bsonType: "date",
               description: "Log timestamp - required"
            },
            level: {
               bsonType: "string",
               enum: ["ERROR", "WARN", "INFO", "DEBUG", "TRACE"],
               description: "Log level - required"
            },
            service: {
               bsonType: "string",
               description: "Service name - required"
            },
            message: {
               bsonType: "string",
               description: "Log message - required"
            },
            metadata: {
               bsonType: "object",
               description: "Additional metadata"
            },
            user_id: {
               bsonType: "string",
               description: "User identifier"
            },
            request_id: {
               bsonType: "string",
               description: "Request trace ID"
            },
            ip_address: {
               bsonType: "string",
               description: "Client IP address"
            }
         }
      }
   }
});

// Security events collection
db.createCollection("security_events", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["timestamp", "event_type", "severity", "source"],
         properties: {
            timestamp: {
               bsonType: "date",
               description: "Event timestamp - required"
            },
            event_type: {
               bsonType: "string",
               enum: ["login", "logout", "failed_login", "credential_request", "credential_approved", "credential_denied", "api_access", "unauthorized_access"],
               description: "Type of security event - required"
            },
            severity: {
               bsonType: "string",
               enum: ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
               description: "Event severity - required"
            },
            source: {
               bsonType: "string",
               description: "Event source - required"
            },
            user_id: {
               bsonType: "string",
               description: "User identifier"
            },
            ip_address: {
               bsonType: "string",
               description: "Source IP address"
            },
            user_agent: {
               bsonType: "string",
               description: "User agent string"
            },
            details: {
               bsonType: "object",
               description: "Additional event details"
            }
         }
      }
   }
});

// Performance metrics collection
db.createCollection("performance_metrics", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["timestamp", "service", "metric_name", "value"],
         properties: {
            timestamp: {
               bsonType: "date",
               description: "Metric timestamp - required"
            },
            service: {
               bsonType: "string",
               description: "Service name - required"
            },
            metric_name: {
               bsonType: "string",
               description: "Metric name - required"
            },
            value: {
               bsonType: "number",
               description: "Metric value - required"
            },
            unit: {
               bsonType: "string",
               description: "Metric unit"
            },
            tags: {
               bsonType: "object",
               description: "Metric tags for filtering"
            }
         }
      }
   }
});

// Cloud resource usage collection
db.createCollection("cloud_usage", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["timestamp", "provider", "service", "resource_type"],
         properties: {
            timestamp: {
               bsonType: "date",
               description: "Usage timestamp - required"
            },
            provider: {
               bsonType: "string",
               enum: ["aws", "azure", "gcp"],
               description: "Cloud provider - required"
            },
            service: {
               bsonType: "string",
               description: "Cloud service name - required"
            },
            resource_type: {
               bsonType: "string",
               description: "Resource type - required"
            },
            resource_id: {
               bsonType: "string",
               description: "Resource identifier"
            },
            region: {
               bsonType: "string",
               description: "Cloud region"
            },
            cost: {
               bsonType: "number",
               description: "Resource cost"
            },
            usage_metrics: {
               bsonType: "object",
               description: "Usage metrics"
            }
         }
      }
   }
});

// Create indexes for better performance

// Application logs indexes
db.application_logs.createIndex({ "timestamp": -1 });
db.application_logs.createIndex({ "level": 1 });
db.application_logs.createIndex({ "service": 1 });
db.application_logs.createIndex({ "user_id": 1 });
db.application_logs.createIndex({ "request_id": 1 });
db.application_logs.createIndex({ "timestamp": -1, "level": 1 });

// Security events indexes
db.security_events.createIndex({ "timestamp": -1 });
db.security_events.createIndex({ "event_type": 1 });
db.security_events.createIndex({ "severity": 1 });
db.security_events.createIndex({ "user_id": 1 });
db.security_events.createIndex({ "ip_address": 1 });
db.security_events.createIndex({ "timestamp": -1, "severity": 1 });

// Performance metrics indexes
db.performance_metrics.createIndex({ "timestamp": -1 });
db.performance_metrics.createIndex({ "service": 1 });
db.performance_metrics.createIndex({ "metric_name": 1 });
db.performance_metrics.createIndex({ "timestamp": -1, "service": 1 });

// Cloud usage indexes
db.cloud_usage.createIndex({ "timestamp": -1 });
db.cloud_usage.createIndex({ "provider": 1 });
db.cloud_usage.createIndex({ "service": 1 });
db.cloud_usage.createIndex({ "resource_type": 1 });
db.cloud_usage.createIndex({ "region": 1 });
db.cloud_usage.createIndex({ "timestamp": -1, "provider": 1 });

// Insert sample data for development and testing

// Sample application logs
db.application_logs.insertMany([
    {
        timestamp: new Date(),
        level: "INFO",
        service: "credential-service",
        message: "Service started successfully",
        metadata: {
            port: 8080,
            environment: "production"
        }
    },
    {
        timestamp: new Date(),
        level: "INFO",
        service: "frontend",
        message: "Frontend application loaded",
        metadata: {
            version: "1.0.0",
            build: "prod"
        }
    }
]);

// Sample security events
db.security_events.insertMany([
    {
        timestamp: new Date(),
        event_type: "login",
        severity: "LOW",
        source: "credential-service",
        user_id: "admin",
        ip_address: "127.0.0.1",
        details: {
            success: true,
            login_method: "form"
        }
    }
]);

// Sample performance metrics
db.performance_metrics.insertMany([
    {
        timestamp: new Date(),
        service: "credential-service",
        metric_name: "response_time",
        value: 125.5,
        unit: "ms",
        tags: {
            endpoint: "/api/credentials",
            method: "POST"
        }
    },
    {
        timestamp: new Date(),
        service: "credential-service",
        metric_name: "memory_usage",
        value: 512,
        unit: "MB",
        tags: {
            process: "main"
        }
    }
]);

// Sample cloud usage data
db.cloud_usage.insertMany([
    {
        timestamp: new Date(),
        provider: "aws",
        service: "EC2",
        resource_type: "t3.medium",
        resource_id: "i-1234567890abcdef0",
        region: "us-east-1",
        cost: 0.0416,
        usage_metrics: {
            cpu_utilization: 45.2,
            memory_utilization: 67.8,
            network_in: 1024,
            network_out: 2048
        }
    },
    {
        timestamp: new Date(),
        provider: "azure",
        service: "AKS",
        resource_type: "Standard_D2s_v3",
        resource_id: "aks-cluster-1",
        region: "eastus",
        cost: 0.096,
        usage_metrics: {
            node_count: 3,
            pod_count: 15,
            cpu_requests: 1.5,
            memory_requests: "3Gi"
        }
    }
]);

// Create TTL indexes for automatic cleanup (logs older than 90 days)
db.application_logs.createIndex({ "timestamp": 1 }, { expireAfterSeconds: 7776000 }); // 90 days
db.security_events.createIndex({ "timestamp": 1 }, { expireAfterSeconds: 15552000 }); // 180 days for security events
db.performance_metrics.createIndex({ "timestamp": 1 }, { expireAfterSeconds: 2592000 }); // 30 days
db.cloud_usage.createIndex({ "timestamp": 1 }, { expireAfterSeconds: 31536000 }); // 365 days

print("MongoDB initialization completed successfully!");
print("Collections created: application_logs, security_events, performance_metrics, cloud_usage");
print("Indexes created for optimal performance");
print("Sample data inserted for development testing");
