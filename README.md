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

The application container exposes port `5000` internally.

In the AWS environment, the container is published on port `80` on the EC2 instances and forwards traffic to the Flask/Gunicorn application running on port `5000`.

The Docker image is published to Docker Hub as:

`masemulan/hav-a-seat`

The CI/CD pipeline publishes both:

- `latest`
- Git commit SHA tagged images

This allows the latest application version to be deployed while also retaining commit-specific image versions.

---

# 🏗️ AWS Architecture

<img width="1162" height="1101" alt="aws drawing" src="https://github.com/user-attachments/assets/d1396406-95ba-4709-96ae-8174ef9e56a3" />


---

## ☁️ AWS Infrastructure

The application is deployed to AWS in the `af-south-1` region.

The infrastructure was designed using multiple Availability Zones to improve availability.

### 🌐 Network Architecture

The VPC contains:

- 2 public subnets
- 2 private subnets
- Resources distributed across 2 Availability Zones
- Internet connectivity for public resources
- Private networking for application/database resources
- Security groups controlling communication between components

The infrastructure was provisioned and managed using Terraform.

### ⚖️ Application Load Balancer

An Application Load Balancer provides the public entry point for the application.

The ALB distributes incoming HTTP traffic between the running EC2 application instances.

The target group listens on port `80`.

The EC2 instances are registered as targets and are monitored using ALB health checks.

Both application instances have been verified as healthy.

### 🖥️ EC2 and Auto Scaling

The application runs on EC2 instances distributed across two Availability Zones.

The instances are managed using an Auto Scaling Group.

The application container runs on each instance using:

- Container name: `hav-a-seat`
- Docker image: `masemulan/hav-a-seat:latest`
- Host port: `80`
- Container port: `5000`

The Auto Scaling configuration supports multiple application instances and provides redundancy across Availability Zones.

### 🗃️ Amazon RDS

PostgreSQL is hosted using Amazon RDS for the cloud deployment.

The RDS database is separated from the application instances and is accessed using the appropriate network and security configuration.

### 📡 AWS Systems Manager

AWS Systems Manager (SSM) is used to remotely execute deployment commands on the EC2 instances.

This allows the CI/CD pipeline to deploy the application without requiring SSH access to the EC2 instances.

### 🔄 Why SSM Was Used Instead of SSH During Week 3

The Week 3 requirements in the project PDF specify that the CI/CD pipeline should:

1. Trigger when code is pushed to the `main` branch
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

This fits the existing Hav-A-Seat architecture because the EC2 instances already use an IAM role with the `AmazonSSMManagedInstanceCore` policy.

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

1. Push code to `main`
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

```bash
terraform plan
````

and applied using:

```bash
terraform apply
```

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

The GitHub Actions IAM role uses a trust policy that restricts access to the project's GitHub repository and the `main` branch.

The workflow uses:

```yaml
permissions:
  contents: read
  id-token: write
```

AWS credentials are configured using:

```yaml
aws-actions/configure-aws-credentials
```

The workflow then verifies the AWS identity before continuing with deployment.

---

## 🔄 CI/CD Pipeline

The project includes an automated GitHub Actions CI/CD pipeline.

The workflow is located at:

`.github/workflows/deploy.yml`

The pipeline is triggered when changes are pushed to the `main` branch or when manually started using GitHub Actions.

### 1️⃣ Test Application

The first stage:

* Checks out the repository
* Sets up Python
* Installs project dependencies
* Runs Python syntax checks using `compileall`

### 2️⃣ Build and Push Docker Image

After the tests pass, the Docker stage:

* Logs into Docker Hub
* Sets up Docker Buildx
* Builds the application image
* Pushes the image to Docker Hub
* Creates both `latest` and Git SHA image tags

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

The workflow performs a final verification using SSM to confirm:

* The `hav-a-seat` container is running
* The expected Docker image is being used
* The deployment completed successfully

---

## 🧪 Deployment Testing

The deployed application has been tested through the public Application Load Balancer.

The following endpoints have been verified:

### 🏠 Home Page

Returns:

`HTTP 200 OK`

### 🎭 Events Page

Returns:

`HTTP 200 OK`

### ⚖️ Load Balancer Health

Both EC2 instances registered with the target group have been verified as:

`healthy`

### 🐳 Container Verification

Both EC2 instances have been verified to run:

`masemulan/hav-a-seat:latest`

with the application container mapped as:

`80 -> 5000`

---

## 📊 Current Deployment Architecture

The current deployment follows this general flow:

```text
                    Internet
                       │
                       ▼
              ┌─────────────────┐
              │ Application      │
              │ Load Balancer    │
              └────────┬────────┘
                       │
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
      ┌─────────────┐     ┌─────────────┐
      │ EC2 / AZ-1  │     │ EC2 / AZ-2  │
      │             │     │             │
      │ Docker      │     │ Docker      │
      │ Hav-A-Seat  │     │ Hav-A-Seat  │
      └──────┬──────┘     └──────┬──────┘
             │                   │
             └─────────┬─────────┘
                       │
                       ▼
                ┌─────────────┐
                │ PostgreSQL  │
                │    RDS      │
                └─────────────┘
```

Deployment automation follows:

```text
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
```

---

## 📁 Project Structure

The main project structure includes:

```text
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
```

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

---

## 🚀 Running the Application Locally

Create and activate a Python virtual environment:

```bash
python -m venv venv
```

Activate it on Windows:

```powershell
.\venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

The application can be run locally using Flask or through the project's Docker Compose configuration.

For the Docker-based environment:

```bash
docker compose up -d
```

The application can then be accessed locally through the configured application port.

---

## 🌍 Cloud Deployment

The deployed application is accessed through the AWS Application Load Balancer.

The current public application endpoint is:

http://nm-hav-a-seat-alb-1086347342.af-south-1.elb.amazonaws.com/

The Events page is available at:

http://nm-hav-a-seat-alb-1086347342.af-south-1.elb.amazonaws.com/events

---

## 📚 Project Progress

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


