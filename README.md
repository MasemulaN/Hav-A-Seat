# 🎟️ Hav-A-Seat

Hav-A-Seat is a Flask-based event reservation system developed as part of the CAPACITI Mid-Level Cloud Engineering Project.

The application allows users to view upcoming events, select available sessions, and make reservations. It also includes an administrative interface for managing events and sessions.

The project was developed progressively from a locally running Flask application into a containerised application deployed on AWS, with infrastructure managed using Terraform and automated deployment through GitHub Actions.

---

## 📌 Project Overview

Hav-A-Seat demonstrates the development and deployment of a cloud-ready web application using:

- 🐍 Python and Flask
- 🐘 PostgreSQL
- 🐳 Docker
- ☁️ Amazon Web Services (AWS)
- 🏗️ Terraform
- 🔄 GitHub Actions
- 🔐 GitHub Actions OIDC authentication
- 📡 AWS Systems Manager (SSM)
- ⚖️ Application Load Balancer (ALB)
- 📈 EC2 Auto Scaling
- 🔒 AWS networking and security controls

The project covers application development, database integration, containerisation, cloud infrastructure, security, scalability, and CI/CD automation.

---

## ✨ Application Features

### 👤 User Features

- View upcoming events
- View event descriptions, categories, locations, and dates
- View available sessions for each event
- View session times and available seats
- Select a session for a reservation
- Submit a reservation with:
  - Full name
  - Email address
  - Number of tickets
- Receive appropriate validation and reservation responses
  <img width="1600" height="900" alt="02-app-events-page" src="https://github.com/user-attachments/assets/f498494f-27a7-42a9-8412-a8f952a1497b" />
  <img width="1600" height="895" alt="03-reservation-page" src="https://github.com/user-attachments/assets/12bfb693-f310-43ce-840e-2b186b964ccd" />
  <img width="1600" height="900" alt="04-reservation-confirmation" src="https://github.com/user-attachments/assets/866d6d8a-00ec-438f-9832-3d3c10affeb7" />

### 🛠️ Admin Features

The application includes an administrative interface that allows authorised administrators to manage event information.

Admin functionality includes:

- 🔐 Admin login
- 📊 Admin dashboard
- ➕ Create events
- ✏️ Edit events
- 🗑️ Delete events
- 📅 Manage event sessions
- 👥 View reservation-related information
- 🚫 Handle cancelled events
- 🎫 Validate session capacity

The admin interface uses separate templates and authentication controls from the public-facing application.

<img width="1600" height="900" alt="09-admin-loggin-page" src="https://github.com/user-attachments/assets/098340a9-4a79-42a5-8827-4c3e6042c43d" />
<img width="1600" height="873" alt="10-admin-dashboard" src="https://github.com/user-attachments/assets/b61b0f0e-d832-4baa-8f7a-e6a724a4684c" />
<img width="1600" height="900" alt="11-admin-event-edit" src="https://github.com/user-attachments/assets/419d195e-06ea-4331-b3e8-ee0172b8dc92" />
<img width="1598" height="900" alt="13-delete-event" src="https://github.com/user-attachments/assets/c3087194-eb25-4cd9-a014-8710b7adc67f" />

---

## 🗄️ Database

Hav-A-Seat uses PostgreSQL as its relational database.

The database contains three primary tables:

### 🎭 Events

Stores information about events, including:

- Event ID
- Title
- Description
- Category
- Location
- Start date
- End date
- Cancellation status

### 🕐 Sessions

Stores individual sessions belonging to events.

Each session contains:

- Session ID
- Event ID
- Session date
- Start time
- End time
- Capacity

Sessions are linked to events using a foreign key with cascading deletion.

### 🎟️ Reservations

Stores user reservations.

Each reservation contains:

- Reservation ID
- Session ID
- Full name
- Email address
- Number of tickets
- Reservation status
- Creation timestamp

Database constraints are used to prevent invalid values such as zero or negative ticket quantities and session capacities.

---

## 🐳 Docker

The Flask application is containerised using Docker.

The Docker image installs the required Python dependencies and runs the application using Gunicorn.

The application container exposes port '5000' internally.

In the AWS environment, the container is published on port '80' on the EC2 instances and forwards traffic to the Flask/Gunicorn application running on port '5000'.

The Docker image is published to Docker Hub as:

'masemulan/hav-a-seat'

The CI/CD pipeline publishes both:

- 'latest'
- Git commit SHA tagged images

This allows the latest application version to be deployed while also retaining commit-specific image versions.

---

## ☁️ AWS Infrastructure

The application is deployed to AWS in the 'af-south-1' region.

The infrastructure was designed using multiple Availability Zones to improve availability.

### 🌐 Network Architecture
<img width="1917" height="1078" alt="01-vpc-network-overview" src="https://github.com/user-attachments/assets/e38029b0-32a2-4c66-96e4-cd9d462ef500" />

The VPC contains:

- 2 public subnets
- 2 private subnets
- Resources distributed across 2 Availability Zones
- Internet connectivity for public resources
- Private networking for application/database resources
- Security groups controlling communication between components

The infrastructure was provisioned and managed using Terraform.

### ⚖️ Application Load Balancer
<img width="1917" height="1076" alt="08-alb-overview" src="https://github.com/user-attachments/assets/e5051746-5234-4749-854d-9c1a611f8be4" />

An Application Load Balancer provides the public entry point for the application.

The ALB distributes incoming HTTP traffic between the running EC2 application instances.

The target group listens on port '80'.

The EC2 instances are registered as targets and are monitored using ALB health checks.

Both application instances have been verified as healthy.

### 🖥️ EC2 and Auto Scaling
<img width="1919" height="1079" alt="11-auto-scaling-group" src="https://github.com/user-attachments/assets/676d1d52-75a3-4b31-a95f-31daec9a4f01" />
<img width="1919" height="1079" alt="12-ec2" src="https://github.com/user-attachments/assets/59392bca-4b39-4cd7-b226-b46b6fa669ca" />

The application runs on EC2 instances distributed across two Availability Zones.

The instances are managed using an Auto Scaling Group.

The application container runs on each instance using:

- Container name: 'hav-a-seat'
- Docker image: 'masemulan/hav-a-seat:latest'
- Host port: 80'
- Container port: '5000'

The Auto Scaling configuration supports multiple application instances and provides redundancy across Availability Zones.

### 🗃️ Amazon RDS
<img width="1919" height="1079" alt="06-rds-config" src="https://github.com/user-attachments/assets/92c0f392-8785-413a-9839-bc649a380baf" />

PostgreSQL is hosted using Amazon RDS for the cloud deployment.

The RDS database is separated from the application instances and is accessed using the appropriate network and security configuration.

### 📡 AWS Systems Manager

AWS Systems Manager (SSM) is used to remotely execute deployment commands on the EC2 instances.

This allows the CI/CD pipeline to deploy the application without requiring SSH access to the EC2 instances.

### 🔄 Why SSM Was Used Instead of SSH During Week 3

The Week 3 requirements in the project PDF specify that the CI/CD pipeline should:

1. Trigger when code is pushed to the 'main' branch
2. Build the Docker image
3. Push the image to Docker Hub
4. SSH into the EC2 instances
5. Pull the latest image
6. Restart the container

The project therefore explicitly mentions SSH as the intended method for remotely reaching the EC2 instances during deployment.

However, Hav-A-Seat's actual AWS architecture created an important networking and security consideration.

### 🔐 The EC2 Instances Are in Private Subnets

The application EC2 instances are deployed into private subnets as part of the 3-tier AWS architecture.

The public Application Load Balancer receives internet traffic and forwards it to the private EC2 application instances. The EC2 instances are therefore not designed to be directly reachable from the public internet.

GitHub Actions hosted runners run outside the Hav-A-Seat VPC. A normal SSH connection from a GitHub-hosted runner to a private EC2 IP address would therefore not work directly.

To make literal SSH deployment work, an additional access mechanism such as a bastion host, VPN, or another network path into the VPC would be required. That would add infrastructure, configuration, maintenance, and additional security considerations that are not necessary for this project.

### 📡 Why AWS Systems Manager Was Chosen

AWS Systems Manager (SSM) provides a way for GitHub Actions to send commands to the EC2 instances through AWS without requiring the instances to be publicly accessible through SSH.

This fits the existing Hav-A-Seat architecture because the EC2 instances already use an IAM role with the 'AmazonSSMManagedInstanceCore' policy.

The deployment flow therefore becomes:

GitHub Actions
    ↓
Authenticate to AWS using GitHub OIDC
    ↓
AWS Systems Manager
    ↓
Send deployment commands to the EC2 instances
    ↓
Pull the Docker image
    ↓
Stop/remove the old container
    ↓
Start the new container
    ↓
Verify deployment

### 🛡️ Security Advantages of SSM

Using SSM instead of SSH provides several security and operational advantages:

- 🔐 No SSH private keys need to be stored or managed by GitHub Actions.
- 🌐 The EC2 instances do not need publicly accessible SSH port 22 for the CI/CD deployment.
- 🪪 Access is controlled through AWS IAM roles and policies.
- 🔑 GitHub Actions authenticates to AWS using OIDC rather than long-lived AWS access keys.
- 📡 Deployment commands are sent through AWS Systems Manager rather than by opening an SSH session from the GitHub runner.
- 🛡️ The approach reduces the attack surface associated with exposing SSH access and simplifies credential management.

### 📈 Why SSM Also Fits the Auto Scaling Group

Hav-A-Seat uses an Auto Scaling Group rather than relying on one permanent EC2 instance.

Because instances in an Auto Scaling Group can be replaced or scaled out, using fixed EC2 IP addresses for SSH deployment would be fragile. The CI/CD deployment can instead discover the current running application instances and use SSM to send the deployment commands to them.

This means the deployment process is better aligned with the scalable architecture:

GitHub Actions
    ↓
AWS SSM
    ↓
Current Hav-A-Seat EC2 instances
    ↓
Docker image deployment

A future EC2 instance created by the Auto Scaling Group must also be configured to obtain and run the appropriate application image when it launches. This is important because a deployment should not depend only on the particular EC2 instances that happened to exist when the pipeline ran.

### ⚠️ Relationship to the Project Requirement

SSM does not change the purpose of the Week 3 requirement. The requirement is to automate the remote deployment of the new Docker image to the EC2 application servers.

The difference is the remote-access mechanism:

- Project specification: SSH into EC2
- Hav-A-Seat implementation: AWS Systems Manager (SSM)

This is a deliberate architecture decision based on the project's private-subnet and Auto Scaling design.

The implementation still fulfils the deployment sequence required for Week 3:

1. Push code to 'main'
2. GitHub Actions builds the Docker image
3. GitHub Actions pushes the image to Docker Hub
4. GitHub Actions authenticates to AWS using OIDC
5. SSM sends deployment commands to the EC2 instances
6. EC2 instances pull the new Docker image
7. The old container is stopped and replaced
8. The deployment is verified

For this project, SSM was therefore selected instead of SSH because it provides a more secure and AWS-native deployment mechanism that fits the existing private-subnet and Auto Scaling architecture, without requiring an additional bastion host or publicly exposed SSH access.

---

## 🏗️ Infrastructure as Code

Terraform is used to define and manage the AWS infrastructure.

The Terraform configuration includes resources such as:

- VPC networking
- Public and private subnets
- Route tables
- Internet Gateway
- NAT Gateway
- Security groups
- EC2 launch configuration
- Auto Scaling Group
- Application Load Balancer
- Target group
- RDS PostgreSQL
- IAM roles and policies
- GitHub Actions OIDC configuration

Terraform state is used to track the infrastructure managed by the project.

Infrastructure changes are reviewed using:


'terraform plan'
and applied using:

'terraform apply'

---

## 🔐 Security

Security was considered at both the application and infrastructure levels.

### AWS Security

The infrastructure uses security groups to control traffic between:

* Internet-facing components
* Load balancer
* EC2 instances
* Database resources

The database is not exposed directly to the public internet.

### 🔑 GitHub Actions OIDC

GitHub Actions authenticates with AWS using OpenID Connect (OIDC).

This avoids storing long-lived AWS access keys inside GitHub Actions secrets.

The GitHub Actions IAM role uses a trust policy that restricts access to the project's GitHub repository and the 'main' branch.

The workflow uses:

permissions:
  contents: read
  id-token: write

AWS credentials are configured using:

aws-actions/configure-aws-credentials

The workflow then verifies the AWS identity before continuing with deployment.

---

## 🔄 CI/CD Pipeline
<img width="1600" height="900" alt="successful-pipeline" src="https://github.com/user-attachments/assets/b59c0687-74f4-4f39-8a3e-b0211672b1ba" />
<img width="1600" height="900" alt="pipeline-post-app-update" src="https://github.com/user-attachments/assets/6111fdb8-2d25-4a51-a677-311f491a1858" />

The project includes an automated GitHub Actions CI/CD pipeline.

The workflow is located at:

'.github/workflows/deploy.yml'

The pipeline is triggered when changes are pushed to the 'main' branch or when manually started using GitHub Actions.

### 1️⃣ Test Application

The first stage:

* Checks out the repository
* Sets up Python
* Installs project dependencies
* Runs Python syntax checks using 'compileall'

### 2️⃣ Build and Push Docker Image

After the tests pass, the Docker stage:

* Logs into Docker Hub
* Sets up Docker Buildx
* Builds the application image
* Pushes the image to Docker Hub
* Creates both 'latest and Git SHA image tags

### 3️⃣ Deploy to EC2

The deployment stage:

* Authenticates with AWS using GitHub OIDC
* Verifies the AWS identity
* Finds running Hav-A-Seat EC2 instances
* Uses AWS Systems Manager to execute deployment commands
* Pulls the latest Docker image
* Preserves the existing container environment
* Stops and removes the old container
* Starts the new container
* Verifies that the new container is running

### 4️⃣ Deployment Verification
<img width="1598" height="900" alt="app-after-changes" src="https://github.com/user-attachments/assets/7c3f7ca1-30c9-46df-8eaa-ccce159885db" />

The workflow performs a final verification using SSM to confirm:

* The 'hav-a-seat' container is running
* The expected Docker image is being used
* The deployment completed successfully

---

## 🧪 Deployment Testing

The deployed application has been tested through the public Application Load Balancer.

The following endpoints have been verified:

### 🏠 Home Page
<img width="1600" height="900" alt="01-app-home-page" src="https://github.com/user-attachments/assets/da730a26-61f5-456b-86e2-e3def8f3e6d3" />

Returns:

'HTTP 200 OK'

### 🎭 Events Page
<img width="1600" height="900" alt="02-app-events-page" src="https://github.com/user-attachments/assets/5169c969-3475-4bb9-bf0d-cf522f51fe8c" />

Returns:

'HTTP 200 OK'

### ⚖️ Load Balancer Health

Both EC2 instances registered with the target group have been verified as:

'healthy'

### 🐳 Container Verification

Both EC2 instances have been verified to run:

'masemulan/hav-a-seat:latest'

with the application container mapped as:

'80 -> 5000'

---


## 📊 Monitoring, Scaling & Security

### 🎯 Objectives

The focus was on configuring application scaling, monitoring AWS infrastructure, and applying security best practices to the Hav-A-Seat deployment.

### 📈 Auto Scaling
<img width="1600" height="900" alt="01-auto-scaling-activity" src="https://github.com/user-attachments/assets/83fc4e74-b7cf-4111-8461-cccf326dec07" />

The Hav-A-Seat application uses an EC2 Auto Scaling Group to maintain application availability and respond to changes in demand.

The scaling configuration was designed to:

* Scale up when average CPU utilisation reaches approximately 70%
* Scale down when average CPU utilisation falls to approximately 30%
* Maintain application capacity across multiple Availability Zones
* Use CloudWatch metrics and alarms to trigger scaling actions

This allows the application to respond automatically to increased or decreased workload without requiring manual changes to the EC2 instance count.

### 📊 CloudWatch Monitoring

-CloudWatch Alarms

<img width="1600" height="900" alt="02-cloudwatch-alarms" src="https://github.com/user-attachments/assets/f9747cc8-d5fd-4237-bce9-873926a911b1" />
<img width="1600" height="899" alt="03-scale-out-alarm-details" src="https://github.com/user-attachments/assets/9d36106f-2cec-4401-b577-b8e8128a66ee" />
<img width="1600" height="900" alt="04-scale-in-alarm-details" src="https://github.com/user-attachments/assets/3a9b10dc-ed04-42f3-93a6-cff78799c01b" />

-MONITORING DASHBOARD

<img width="1600" height="900" alt="10-cloudwatch-monitoring-dashboard" src="https://github.com/user-attachments/assets/86545cd5-ffb1-47a3-aad3-eabf04039cf6" />


AWS CloudWatch was used to monitor the application infrastructure.

Monitoring activities included:

* CloudWatch application logs
* CPU utilisation monitoring
* CloudWatch alarms
* Auto Scaling monitoring
* Verification of scaling-related alarm states and activity

The CloudWatch configuration provides visibility into application-server performance and supports the Auto Scaling strategy.

### 🔐 Security Design
<img width="1600" height="900" alt="05-security-group-inbound-rules" src="https://github.com/user-attachments/assets/47d90099-727d-4cbf-8822-66748890417f" />
<img width="1598" height="900" alt="07-parameter-store-secure-string" src="https://github.com/user-attachments/assets/0182f7d0-cf11-487d-9a91-fc802f18755d" />
<img width="1600" height="900" alt="08-ec2-iam-least-privilege" src="https://github.com/user-attachments/assets/485933a8-f27f-4683-bcdd-a41c99de355a" />
<img width="1597" height="900" alt="09-github-actions-iam-least-privilege" src="https://github.com/user-attachments/assets/612a6afd-0973-4824-bc66-f222440fc72d" />

Security was considered throughout the Hav-A-Seat AWS architecture.

The security implementation included:

* IAM roles for AWS services and EC2 instances
* No long-lived AWS access keys stored in application code
* GitHub Actions OIDC authentication
* Security groups controlling traffic between the ALB, EC2 application servers, and RDS
* PostgreSQL RDS deployed separately from the public-facing application layer
* RDS encryption enabled
* AWS Systems Manager used instead of publicly exposing SSH access for CI/CD deployment
* Least-privilege access principles applied to IAM permissions
* Sensitive database and deployment configuration kept outside the source code

The EC2 application servers were deployed in private subnets, while the Application Load Balancer provided the public entry point. This reduced direct exposure of the application servers to the internet.

### 🔑 Secrets and Configuration

Sensitive configuration such as database credentials and deployment-related secrets was kept outside the application source code.

AWS services and GitHub Actions were configured to use appropriate IAM-based authentication mechanisms rather than embedding long-lived AWS credentials in the project.

### 🧪 Week 4 Validation

The Week 4 implementation was validated through AWS console checks and infrastructure testing.

Validation included:

* Confirming the Auto Scaling Group and scaling configuration
* Checking CloudWatch CPU utilisation and alarm states
* Verifying scaling-related configuration
* Reviewing security group rules
* Confirming RDS encryption configuration
* Confirming IAM and SSM-based access configuration
* Verifying that application servers were not exposed through unnecessary public SSH access

---

## 📊 Deployment Architecture Diagram and Automation

The current deployment follows this general flow:

<img width="1162" height="1101" alt="final architecture drawio" src="https://github.com/user-attachments/assets/dfe91207-820c-4108-8d92-f3c6d2f9a1cc" />


Deployment automation follows:


GitHub
   │
   ▼
GitHub Actions
   │
   ├── Test
   │
   ├── Build Docker Image
   │
   ├── Push to Docker Hub
   │
   ├── Authenticate with AWS using OIDC
   │
   └── Deploy using AWS SSM
             │
             ▼
        EC2 Instances


---

## 📁 Project Structure

The main project structure includes:

Hav-A-Seat/
│
├── app/
│   ├── admin.py
│   ├── database.py
│   ├── routes.py
│   ├── templates/
│   │   ├── base.html
│   │   ├── events.html
│   │   ├── reservation_form.html
│   │   ├── confirmation.html
│   │   ├── base_admin.html
│   │   ├── dashboard.html
│   │   ├── event_form.html
│   │   ├── delete_confirm.html
│   │   └── login.html
│   └── ...
│
├── database/
│   └── init/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── app.py
├── .env
└── README.md


Sensitive configuration such as database credentials and deployment secrets should not be committed to the repository.

---

## 🛠️ Technologies Used

| Technology                | Purpose                          |
| ------------------------- | -------------------------------- |
| Python                    | Application programming language |
| Flask                     | Web application framework        |
| PostgreSQL                | Relational database              |
| Psycopg                   | PostgreSQL database connection   |
| Bootstrap                 | User interface styling           |
| Bootstrap Icons           | Application icons                |
| Gunicorn                  | Production WSGI server           |
| Docker                    | Application containerisation     |
| Docker Hub                | Container image registry         |
| Terraform                 | Infrastructure as Code           |
| Amazon EC2                | Application compute              |
| Amazon RDS                | Managed PostgreSQL database      |
| Application Load Balancer | Traffic distribution             |
| Auto Scaling Group        | Application scalability          |
| AWS SSM                   | Remote deployment                |
| IAM                       | AWS access control               |
| GitHub Actions            | CI/CD automation                 |
| GitHub OIDC               | Secure AWS authentication        |
| AWS CloudWatch            | Monitoring, metrics and alarms   |
| Security Groups           | Network traffic control          |
---

## 🚀 Running the Application Locally

Create and activate a Python virtual environment:

'python -m venv venv'

Activate it on Windows:

'.\venv\Scripts\Activate.ps1'

Install dependencies:

'pip install -r requirements.txt'


The application can be run locally using Flask or through the project's Docker Compose configuration.


For the Docker-based environment:

'docker compose up -d'


The application can then be accessed locally through the configured application port.

---

## 🌍 Cloud Deployment

The deployed application is accessed through the AWS Application Load Balancer.

The current public application endpoint is:

http://nm-hav-a-seat-alb-1086347342.af-south-1.elb.amazonaws.com/

The Events page is available at:

http://nm-hav-a-seat-alb-1086347342.af-south-1.elb.amazonaws.com/events

---


### ✅ Week 1 — Application Development

Completed:

* Flask application created
* GitHub repository created
* Application routes and templates implemented
* Event and reservation functionality created
* PostgreSQL database designed
* Local database integration completed
* Docker configuration created
* Application containerised

### ✅ Week 2 — Cloud Infrastructure

Completed:

* AWS networking infrastructure
* Public and private subnets
* EC2 application instances
* Auto Scaling configuration
* Application Load Balancer
* RDS PostgreSQL
* Security groups
* IAM configuration
* Terraform infrastructure management
* Application deployment to AWS
* Application and database connectivity testing

### ✅ Week 3 — CI/CD

Completed:

* GitHub Actions workflow
* Automated application testing
* Automated Docker image builds
* Docker Hub image publishing
* GitHub OIDC authentication with AWS
* AWS IAM trust configuration
* AWS identity verification
* Automated EC2 discovery
* SSM-based application deployment
* Deployment verification
* Successful end-to-end CI/CD deployment

A final CI/CD deployment test was also performed by making a visible change to the Events page, committing it to GitHub, triggering the pipeline, and verifying that the updated version appeared on the live AWS application.

### ✅ Week 4 Monitoring, Scaling & Security

Completed:

* Automated EC2 scaling based on CPU utilisation
* CloudWatch monitoring and alarms
* Centralised application logging
* IAM-based access control
* Secure GitHub Actions authentication using OIDC
* Private-subnet application deployment
* Restricted security-group communication
* Encrypted RDS storage
* Secure SSM-based deployment
---



## 🎯 Project Outcome

Hav-A-Seat has progressed from a locally developed Flask application into a cloud-hosted, containerised application with automated infrastructure and deployment.

The completed solution demonstrates:

* Full-stack web application development
* Relational database integration
* Containerisation
* Infrastructure as Code
* AWS cloud architecture
* High availability across Availability Zones
* Load balancing
* Auto Scaling
* Secure IAM configuration
* OIDC-based CI/CD authentication
* Automated Docker image publishing
* Automated AWS deployment
* Production-style application deployment using Gunicorn and SSM

The project provides a foundation for further improvements such as enhanced monitoring, automated application tests, HTTPS configuration, improved observability, and additional deployment safeguards.

