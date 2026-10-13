# AWS Event Platform — architecture diagram

## 1. Mermaid

```mermaid
flowchart TB
  client(["Client / Producer"])

  subgraph AWS["AWS Cloud - eu-west-1"]
    direction TB

    subgraph ING["Ingestion layer (Serverless)"]
      apigw["API Gateway<br/>HTTP API - POST /events"]
      lambda["Lambda - Producer<br/>Python 3.12"]
    end

    subgraph TRN["Transport layer"]
      ddb[("DynamoDB<br/>awsevt-events-staging")]
      eb{{"EventBridge bus<br/>awsevt-bus-staging"}}
      sns["SNS topic<br/>awsevt-notifications-staging"]
      sqs["SQS queue<br/>awsevt-events-queue-staging"]
      dlq["SQS DLQ"]
    end

    subgraph VPC["VPC 10.1.0.0/16"]
      subgraph EKS["EKS cluster - Kubernetes 1.30"]
        argo["ArgoCD"]
        proc["processing-service<br/>Python pod - /metrics"]
        prom["Prometheus"]
        graf["Grafana"]
      end
      subgraph NET["Network"]
        sna["Public subnet eu-west-1a"]
        snb["Public subnet eu-west-1b"]
        igw["Internet Gateway"]
        rt["Route table"]
        sg["Security group"]
      end
    end

    subgraph SUP["Support layer"]
      ecr["ECR"]
      cw["CloudWatch"]
      iam["IAM - roles, policies, IRSA"]
    end

    subgraph BKE["Terraform backend"]
      s3s[("S3 - remote state")]
      s3a[("S3 - build artifacts")]
      lock[("DynamoDB awsevt-tf-lock")]
    end
  end

  subgraph CI["CI/CD"]
    git["Git repo<br/>GitOps manifests"]
    gha["GitHub Actions"]
    trivy["Trivy scan"]
  end

  client -->|"HTTPS POST"| apigw
  apigw -->|"invokes"| lambda
  lambda -->|"stores raw event"| ddb
  lambda -->|"publishes event"| eb
  eb -->|"Rule 1: priority=high"| sns
  eb -->|"Rule 2: type=processing_required"| sqs
  sqs -.->|"failed after max retries"| dlq
  proc -->|"polls"| sqs
  proc -->|"writes results"| ddb
  prom -->|"scrapes /metrics"| proc
  graf -->|"queries PromQL"| prom
  argo -->|"deploys"| proc
  argo -->|"pulls manifests"| git
  git -->|"push triggers workflow"| gha
  gha -->|"built image"| trivy
  trivy -->|"scan OK, push image"| ecr
  ecr -->|"image pull"| EKS
  iam -->|"IRSA roles"| EKS
  EKS -->|"logs and metrics"| cw
  lock -.->|"state locking"| s3s

  classDef sls fill:#FFF3E6,stroke:#ED7100,color:#232F3E,stroke-width:2px
  classDef k8s fill:#E8F0FE,stroke:#326CE5,color:#232F3E,stroke-width:2px
  classDef data fill:#EAF5E4,stroke:#3F8624,color:#232F3E,stroke-width:2px
  classDef sec fill:#FDECEE,stroke:#DD344C,color:#232F3E,stroke-width:2px
  classDef cicd fill:#F3ECFF,stroke:#8C4FFF,color:#232F3E,stroke-width:2px
  classDef gray fill:#F2F3F3,stroke:#545B64,color:#232F3E,stroke-width:2px
  class apigw,lambda,eb,sns,sqs,dlq sls
  class argo,proc,prom,graf k8s
  class ddb,s3s,s3a,lock data
  class iam sec
  class ecr,git,gha,trivy cicd
  class cw,sna,snb,igw,rt,sg gray
  style AWS fill:#FFFFFF,stroke:#232F3E,stroke-width:3px
  style VPC fill:#FAFAFA,stroke:#545B64,stroke-dasharray:5 5
  style EKS fill:#F5F8FF,stroke:#326CE5,stroke-dasharray:5 5
```

## 2. Excalidraw

Open `aws-event-platform.excalidraw` in excalidraw.com (File → Open) or drag it onto the canvas.

Colors: Serverless orange · Kubernetes blue · Data green · Security red · CI/CD purple · Network/CloudWatch gray.

### Boxes

| Label | Layer | Position (x, y) | Type |
|---|---|---|---|
| Client / Producer — HTTPS POST | Client | (860, 20) | client |
| API Gateway — (HTTP API) — POST /events | Ingestion | (860, 190) | sls |
| Lambda — Producer — Python 3.12 | Ingestion | (1330, 190) | sls |
| SNS topic — awsevt-notifications- — staging | Transport | (430, 385) | sls |
| EventBridge bus — awsevt-bus-staging | Transport | (730, 385) | sls |
| SQS queue — awsevt-events-queue- — staging | Transport | (1030, 385) | sls |
| SQS Dead-Letter — Queue | Transport | (1030, 505) | sls |
| DynamoDB — awsevt-events-staging | Transport | (1330, 385) | data |
| ArgoCD — (GitOps sync) | EKS | (470, 780) | k8s |
| processing-service — (Python pod) — /metrics | EKS | (790, 780) | k8s |
| Prometheus | EKS | (1110, 780) | k8s |
| Grafana — (dashboards) | EKS | (1430, 780) | k8s |
| Managed node group — EC2 workers in public subnets 1a / 1b | EKS | (470, 930) | gray |
| Public subnet — eu-west-1a | Network (VPC) | (1760, 740) | gray |
| Public subnet — eu-west-1b | Network (VPC) | (1760, 798) | gray |
| Internet Gateway | Network (VPC) | (1760, 856) | gray |
| Route table | Network (VPC) | (1760, 914) | gray |
| Security group | Network (VPC) | (1760, 972) | gray |
| ECR — container registry | Support | (430, 1145) | cicd |
| CloudWatch — logs & metrics | Support | (730, 1145) | gray |
| IAM — roles, policies, IRSA | Support | (1030, 1145) | sec |
| S3 bucket — Terraform remote state | Backend | (430, 1325) | data |
| S3 bucket — build artifacts | Backend | (730, 1325) | data |
| DynamoDB — awsevt-tf-lock | Backend | (1030, 1325) | data |
| Git repo — (GitOps manifests) | CI/CD | (70, 780) | cicd |
| GitHub Actions — build | CI/CD | (70, 960) | cicd |
| Trivy — image scan | CI/CD | (70, 1145) | cicd |

### Arrows

| From | To | Label |
|---|---|---|
| Client / Producer HTTPS POST | API Gateway (HTTP API) POST /events | HTTPS POST |
| API Gateway (HTTP API) POST /events | Lambda — Producer Python 3.12 | invokes |
| Lambda — Producer Python 3.12 | DynamoDB awsevt-events-staging | stores raw event |
| Lambda — Producer Python 3.12 | EventBridge bus awsevt-bus-staging | publishes event |
| EventBridge bus awsevt-bus-staging | SNS topic awsevt-notifications- staging | Rule 1: priority=high |
| EventBridge bus awsevt-bus-staging | SQS queue awsevt-events-queue- staging | Rule 2: type= processing_required |
| SQS queue awsevt-events-queue- staging | SQS Dead-Letter Queue | failed after max retries |
| processing-service (Python pod) /metrics | SQS queue awsevt-events-queue- staging | polls |
| processing-service (Python pod) /metrics | DynamoDB awsevt-events-staging | writes results |
| Prometheus | processing-service (Python pod) /metrics | scrapes /metrics |
| Grafana (dashboards) | Prometheus | queries (PromQL) |
| ArgoCD (GitOps sync) | processing-service (Python pod) /metrics | deploys |
| ArgoCD (GitOps sync) | Git repo (GitOps manifests) | pulls manifests (GitOps) |
| Git repo (GitOps manifests) | GitHub Actions build | push triggers workflow |
| GitHub Actions build | Trivy image scan | built image |
| Trivy image scan | ECR container registry | scan OK → push image |
| ECR container registry | EKS cluster | image pull |
| IAM roles, policies, IRSA | EKS cluster | IRSA roles |
| EKS cluster | CloudWatch logs & metrics | logs & metrics |
| DynamoDB awsevt-tf-lock | S3 bucket Terraform remote state | state locking |

## 3. Caption

**Figure 1.** AWS Event Platform (eu-west-1) — a hybrid serverless and Kubernetes architecture. Clients send events over HTTPS to an API Gateway HTTP API, which invokes a Python 3.12 Lambda producer that validates each event, stores it in DynamoDB and publishes it to a custom EventBridge bus. Content-based rules fan high-priority events out to SNS for email/Slack notifications and route events that need processing to an SQS queue backed by a dead-letter queue. A processing-service pod on Amazon EKS (Kubernetes 1.30) polls the queue and writes results back to DynamoDB, while Prometheus and Grafana provide observability and ArgoCD keeps the cluster in sync with Git. GitHub Actions builds, scans (Trivy) and pushes images to ECR, IAM roles for service accounts secure pod access to AWS, CloudWatch collects logs and metrics, and Terraform state lives in S3 with DynamoDB locking, all inside a VPC (10.1.0.0/16) spanning two public subnets.
