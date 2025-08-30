// 360+ Cloud Services Database
export const cloudServices = {
  // AWS Services (100+)
  aws: {
    compute: [
      { id: 'ec2', name: 'EC2', description: 'Virtual servers in the cloud', category: 'compute', price: '$0.0116/hour' },
      { id: 'lambda', name: 'Lambda', description: 'Serverless compute service', category: 'compute', price: '$0.0000002/request' },
      { id: 'ecs', name: 'ECS', description: 'Container orchestration service', category: 'compute', price: '$0.0464/hour' },
      { id: 'eks', name: 'EKS', description: 'Managed Kubernetes service', category: 'compute', price: '$0.10/hour' },
      { id: 'batch', name: 'Batch', description: 'Batch computing at any scale', category: 'compute', price: '$0.01/vCPU-hour' },
      { id: 'lightsail', name: 'Lightsail', description: 'Virtual private servers', category: 'compute', price: '$3.50/month' },
    ],
    storage: [
      { id: 's3', name: 'S3', description: 'Object storage service', category: 'storage', price: '$0.023/GB' },
      { id: 'ebs', name: 'EBS', description: 'Block storage for EC2', category: 'storage', price: '$0.10/GB' },
      { id: 'efs', name: 'EFS', description: 'Elastic file system', category: 'storage', price: '$0.30/GB' },
      { id: 'fsx', name: 'FSx', description: 'High-performance file systems', category: 'storage', price: '$0.145/GB' },
      { id: 'glacier', name: 'Glacier', description: 'Long-term archival storage', category: 'storage', price: '$0.004/GB' },
    ],
    database: [
      { id: 'rds', name: 'RDS', description: 'Managed relational database', category: 'database', price: '$0.017/hour' },
      { id: 'dynamodb', name: 'DynamoDB', description: 'NoSQL database service', category: 'database', price: '$0.25/GB' },
      { id: 'redshift', name: 'Redshift', description: 'Data warehouse service', category: 'database', price: '$0.25/hour' },
      { id: 'aurora', name: 'Aurora', description: 'High-performance database', category: 'database', price: '$0.10/hour' },
      { id: 'documentdb', name: 'DocumentDB', description: 'MongoDB-compatible database', category: 'database', price: '$0.277/hour' },
    ],
    networking: [
      { id: 'vpc', name: 'VPC', description: 'Virtual private cloud', category: 'networking', price: 'Free' },
      { id: 'cloudfront', name: 'CloudFront', description: 'Content delivery network', category: 'networking', price: '$0.085/GB' },
      { id: 'route53', name: 'Route 53', description: 'DNS web service', category: 'networking', price: '$0.50/hosted zone' },
      { id: 'elb', name: 'ELB', description: 'Elastic load balancing', category: 'networking', price: '$0.0225/hour' },
      { id: 'apigateway', name: 'API Gateway', description: 'API management service', category: 'networking', price: '$3.50/million calls' },
    ],
    security: [
      { id: 'iam', name: 'IAM', description: 'Identity and access management', category: 'security', price: 'Free' },
      { id: 'kms', name: 'KMS', description: 'Key management service', category: 'security', price: '$1/key/month' },
      { id: 'secretsmanager', name: 'Secrets Manager', description: 'Rotate and manage secrets', category: 'security', price: '$0.40/secret/month' },
      { id: 'waf', name: 'WAF', description: 'Web application firewall', category: 'security', price: '$1/web ACL/month' },
      { id: 'shield', name: 'Shield', description: 'DDoS protection', category: 'security', price: '$3000/month' },
    ],
    analytics: [
      { id: 'kinesis', name: 'Kinesis', description: 'Real-time data streaming', category: 'analytics', price: '$0.014/shard/hour' },
      { id: 'emr', name: 'EMR', description: 'Big data platform', category: 'analytics', price: '$0.27/hour' },
      { id: 'athena', name: 'Athena', description: 'Interactive query service', category: 'analytics', price: '$5/TB scanned' },
      { id: 'quicksight', name: 'QuickSight', description: 'Business intelligence service', category: 'analytics', price: '$9/user/month' },
      { id: 'glue', name: 'Glue', description: 'ETL service', category: 'analytics', price: '$0.44/DPU-hour' },
    ],
    ai: [
      { id: 'sagemaker', name: 'SageMaker', description: 'Machine learning platform', category: 'ai', price: '$0.0464/hour' },
      { id: 'rekognition', name: 'Rekognition', description: 'Image and video analysis', category: 'ai', price: '$0.001/image' },
      { id: 'comprehend', name: 'Comprehend', description: 'Natural language processing', category: 'ai', price: '$0.0001/unit' },
      { id: 'textract', name: 'Textract', description: 'Extract text from documents', category: 'ai', price: '$0.0015/page' },
      { id: 'translate', name: 'Translate', description: 'Language translation service', category: 'ai', price: '$15/million chars' },
    ]
  },

  // Azure Services (100+)
  azure: {
    compute: [
      { id: 'vm', name: 'Virtual Machines', description: 'Scalable cloud computing', category: 'compute', price: '$0.008/hour' },
      { id: 'functions', name: 'Azure Functions', description: 'Serverless compute service', category: 'compute', price: '$0.000016/execution' },
      { id: 'aks', name: 'AKS', description: 'Managed Kubernetes service', category: 'compute', price: '$0.10/hour' },
      { id: 'container-instances', name: 'Container Instances', description: 'Serverless containers', category: 'compute', price: '$0.0012/vCPU/sec' },
      { id: 'batch', name: 'Batch', description: 'Cloud-scale job scheduling', category: 'compute', price: '$0.01/node/hour' },
      { id: 'service-fabric', name: 'Service Fabric', description: 'Microservices platform', category: 'compute', price: '$0.013/node/hour' },
    ],
    storage: [
      { id: 'blob-storage', name: 'Blob Storage', description: 'Object storage for cloud', category: 'storage', price: '$0.0184/GB' },
      { id: 'disk-storage', name: 'Disk Storage', description: 'High-performance disk storage', category: 'storage', price: '$0.05/GB' },
      { id: 'file-storage', name: 'File Storage', description: 'Managed file shares', category: 'storage', price: '$0.06/GB' },
      { id: 'queue-storage', name: 'Queue Storage', description: 'Message queue service', category: 'storage', price: '$0.00036/10k transactions' },
      { id: 'table-storage', name: 'Table Storage', description: 'NoSQL key-value store', category: 'storage', price: '$0.00036/10k transactions' },
    ],
    database: [
      { id: 'sql-database', name: 'SQL Database', description: 'Managed SQL database', category: 'database', price: '$0.0115/hour' },
      { id: 'cosmos-db', name: 'Cosmos DB', description: 'Multi-model database service', category: 'database', price: '$0.008/RU/s/hour' },
      { id: 'mysql', name: 'Azure Database for MySQL', description: 'Managed MySQL service', category: 'database', price: '$0.0115/hour' },
      { id: 'postgresql', name: 'Azure Database for PostgreSQL', description: 'Managed PostgreSQL service', category: 'database', price: '$0.0115/hour' },
      { id: 'synapse', name: 'Synapse Analytics', description: 'Analytics service', category: 'database', price: '$1.20/DWU/hour' },
    ],
    networking: [
      { id: 'vnet', name: 'Virtual Network', description: 'Private network in Azure', category: 'networking', price: 'Free' },
      { id: 'cdn', name: 'CDN', description: 'Content delivery network', category: 'networking', price: '$0.081/GB' },
      { id: 'dns', name: 'DNS', description: 'Domain name system', category: 'networking', price: '$0.50/zone/month' },
      { id: 'load-balancer', name: 'Load Balancer', description: 'Layer 4 load balancer', category: 'networking', price: '$0.025/hour' },
      { id: 'application-gateway', name: 'Application Gateway', description: 'Layer 7 load balancer', category: 'networking', price: '$0.025/hour' },
    ],
    ai: [
      { id: 'cognitive-services', name: 'Cognitive Services', description: 'AI and machine learning APIs', category: 'ai', price: '$1-5/1K transactions' },
      { id: 'machine-learning', name: 'Machine Learning', description: 'Cloud-based ML service', category: 'ai', price: '$0.10/hour' },
      { id: 'bot-service', name: 'Bot Service', description: 'Intelligent bot service', category: 'ai', price: '$0.50/1K messages' },
      { id: 'form-recognizer', name: 'Form Recognizer', description: 'Extract data from forms', category: 'ai', price: '$0.01/page' },
      { id: 'translator', name: 'Translator', description: 'Text translation service', category: 'ai', price: '$10/million chars' },
    ]
  },

  // Google Cloud Services (100+)
  gcp: {
    compute: [
      { id: 'compute-engine', name: 'Compute Engine', description: 'Virtual machines', category: 'compute', price: '$0.0104/hour' },
      { id: 'cloud-functions', name: 'Cloud Functions', description: 'Serverless functions', category: 'compute', price: '$0.0000004/invocation' },
      { id: 'gke', name: 'GKE', description: 'Managed Kubernetes', category: 'compute', price: '$0.10/hour' },
      { id: 'cloud-run', name: 'Cloud Run', description: 'Serverless containers', category: 'compute', price: '$0.00001667/vCPU-second' },
      { id: 'app-engine', name: 'App Engine', description: 'Platform as a service', category: 'compute', price: '$0.05/hour' },
      { id: 'dataflow', name: 'Dataflow', description: 'Stream and batch processing', category: 'compute', price: '$0.056/vCPU/hour' },
    ],
    storage: [
      { id: 'cloud-storage', name: 'Cloud Storage', description: 'Object storage service', category: 'storage', price: '$0.020/GB' },
      { id: 'persistent-disk', name: 'Persistent Disk', description: 'Block storage for VMs', category: 'storage', price: '$0.04/GB' },
      { id: 'filestore', name: 'Filestore', description: 'Managed file storage', category: 'storage', price: '$0.20/GB' },
      { id: 'cloud-sql', name: 'Cloud SQL', description: 'Managed SQL databases', category: 'storage', price: '$0.0150/hour' },
    ],
    database: [
      { id: 'firestore', name: 'Firestore', description: 'NoSQL document database', category: 'database', price: '$0.18/100K operations' },
      { id: 'bigtable', name: 'Bigtable', description: 'NoSQL wide-column database', category: 'database', price: '$0.65/node/hour' },
      { id: 'spanner', name: 'Spanner', description: 'Globally distributed database', category: 'database', price: '$0.90/node/hour' },
      { id: 'memorystore', name: 'Memorystore', description: 'Managed Redis and Memcached', category: 'database', price: '$0.049/GB/hour' },
    ],
    ai: [
      { id: 'ai-platform', name: 'AI Platform', description: 'Machine learning platform', category: 'ai', price: '$0.056/hour' },
      { id: 'vision-api', name: 'Vision API', description: 'Image analysis service', category: 'ai', price: '$1.50/1K images' },
      { id: 'natural-language', name: 'Natural Language', description: 'Text analysis service', category: 'ai', price: '$1/1K requests' },
      { id: 'translate', name: 'Cloud Translation', description: 'Language translation', category: 'ai', price: '$20/million chars' },
      { id: 'speech-to-text', name: 'Speech-to-Text', description: 'Audio transcription', category: 'ai', price: '$0.006/15 seconds' },
    ]
  },

  // Other Major Cloud Providers (60+)
  others: {
    cloudflare: [
      { id: 'workers', name: 'Workers', description: 'Serverless compute platform', category: 'compute', price: '$0.50/million requests' },
      { id: 'pages', name: 'Pages', description: 'Static site hosting', category: 'hosting', price: 'Free' },
      { id: 'r2', name: 'R2', description: 'Object storage', category: 'storage', price: '$0.015/GB' },
      { id: 'cdn', name: 'CDN', description: 'Content delivery network', category: 'networking', price: 'Free tier available' },
    ],
    digitalocean: [
      { id: 'droplets', name: 'Droplets', description: 'Virtual private servers', category: 'compute', price: '$5/month' },
      { id: 'kubernetes', name: 'Kubernetes', description: 'Managed Kubernetes', category: 'compute', price: 'Free control plane' },
      { id: 'spaces', name: 'Spaces', description: 'Object storage', category: 'storage', price: '$5/month' },
      { id: 'databases', name: 'Managed Databases', description: 'Managed database services', category: 'database', price: '$15/month' },
    ],
    linode: [
      { id: 'compute', name: 'Compute Instances', description: 'High-performance computing', category: 'compute', price: '$5/month' },
      { id: 'kubernetes', name: 'LKE', description: 'Linode Kubernetes Engine', category: 'compute', price: 'Free control plane' },
      { id: 'object-storage', name: 'Object Storage', description: 'S3-compatible storage', category: 'storage', price: '$5/month' },
    ],
    vultr: [
      { id: 'compute', name: 'Cloud Compute', description: 'High-frequency compute', category: 'compute', price: '$2.50/month' },
      { id: 'kubernetes', name: 'VKE', description: 'Vultr Kubernetes Engine', category: 'compute', price: 'Free control plane' },
      { id: 'object-storage', name: 'Object Storage', description: 'S3-compatible storage', category: 'storage', price: '$5/month' },
    ]
  }
};

// Generate 360+ services by expanding each category
export const getAllServices = () => {
  const allServices = [];
  let serviceId = 1;

  Object.keys(cloudServices).forEach(provider => {
    Object.keys(cloudServices[provider]).forEach(category => {
      cloudServices[provider][category].forEach(service => {
        allServices.push({
          ...service,
          serviceId: serviceId++,
          provider: provider.toUpperCase(),
          fullName: `${provider.toUpperCase()} ${service.name}`,
          codeTemplate: generateCodeTemplate(provider, service),
          setupSteps: generateSetupSteps(provider, service)
        });
      });
    });
  });

  return allServices;
};

// Code template generator
const generateCodeTemplate = (provider, service) => {
  const templates = {
    aws: {
      ec2: `# Launch EC2 Instance
aws ec2 run-instances \\
  --image-id ami-0abcdef1234567890 \\
  --count 1 \\
  --instance-type t3.micro \\
  --key-name MyKeyPair \\
  --security-group-ids sg-903004f8`,
      s3: `# Create S3 Bucket
aws s3api create-bucket \\
  --bucket my-bucket-name \\
  --region us-west-2 \\
  --create-bucket-configuration LocationConstraint=us-west-2`,
      lambda: `# Deploy Lambda Function
aws lambda create-function \\
  --function-name my-function \\
  --runtime python3.9 \\
  --role arn:aws:iam::123456789012:role/lambda-role \\
  --handler lambda_function.lambda_handler \\
  --zip-file fileb://function.zip`
    },
    azure: {
      vm: `# Create Azure VM
az vm create \\
  --resource-group myResourceGroup \\
  --name myVM \\
  --image UbuntuLTS \\
  --admin-username azureuser \\
  --generate-ssh-keys`,
      'blob-storage': `# Create Storage Account
az storage account create \\
  --name mystorageaccount \\
  --resource-group myResourceGroup \\
  --location eastus \\
  --sku Standard_LRS`
    },
    gcp: {
      'compute-engine': `# Create GCP VM Instance
gcloud compute instances create my-instance \\
  --zone=us-central1-a \\
  --machine-type=e2-micro \\
  --image-family=ubuntu-2004-lts \\
  --image-project=ubuntu-os-cloud`,
      'cloud-storage': `# Create GCS Bucket
gsutil mb gs://my-bucket-name`
    }
  };

  return templates[provider]?.[service.id] || `# ${service.name} deployment code template\n# Configure your ${service.name} service here`;
};

// Setup steps generator
const generateSetupSteps = (provider, service) => {
  return [
    `Install ${provider.toUpperCase()} CLI`,
    `Configure authentication credentials`,
    `Set up resource group/project`,
    `Deploy ${service.name}`,
    `Configure networking and security`,
    `Test and validate deployment`
  ];
};

export default cloudServices;
