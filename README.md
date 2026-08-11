# Hav-A-Seat 🎟️

Hav-A-Seat is a Flask-based event booking and reservation system developed as part of the Mid-Level Cloud Engineering Project.

The application allows users to browse events, view available sessions, make reservations, view their reservations, update reservations, and cancel reservations.

Week 1 focused on building the application, connecting it to PostgreSQL, containerizing the application with Docker, and configuring Nginx as a reverse proxy.

---

## ✨ Features

- Browse available events
- View event details and available sessions
- View session availability
- Make event reservations
- View reservations using an email address
- Update reservations
- Cancel reservations
- Automatically calculate available seats
- Prevent bookings when there are insufficient seats
- Store application data in PostgreSQL
- Run the application using Docker
- Run PostgreSQL in a Docker container
- Use Docker Compose to manage the application stack
- Use Nginx as a reverse proxy

---

## 🛠️ Technology Stack

- **Backend:** Python, Flask
- **Frontend:** HTML, CSS, Jinja2 Templates
- **Database:** PostgreSQL
- **Database Driver:** Psycopg
- **Web Server / Reverse Proxy:** Nginx
- **Containerization:** Docker
- **Container Management:** Docker Compose
- **Version Control:** Git & GitHub

---

## 🗄️ Database

The application uses PostgreSQL to store events, sessions, and reservations.

### 📅 Events

The `events` table stores information about each event, including:

- Event ID
- Title
- Description
- Category
- Location
- Start date
- End date
- Cancellation status

Events are distributed across different locations and categories.

### 🕐 Sessions

The `sessions` table stores individual sessions belonging to an event.

Each session contains:

- Session ID
- Event ID
- Session date
- Start time
- End time
- Capacity

An event can have multiple sessions. This allows an event to run over multiple days or have multiple sessions on the same day.

### 🎫 Reservations

The `reservations` table stores user bookings.

Reservation information includes:

- Reservation ID
- Session ID
- Customer name
- Email address
- Number of tickets
- Reservation status
- Created and updated timestamps

The application uses session capacity and active reservations to determine the number of available seats.

---

## 🎯 Week 1 Objectives

The main focus of Week 1 was to establish the application and containerization foundation for the project.

The completed work includes:

- Building the Flask web application
- Connecting Flask to PostgreSQL
- Implementing event and session functionality
- Implementing reservation functionality
- Implementing reservation updates and cancellations
- Implementing available-seat calculations
- Creating a Dockerfile
- Containerizing the Flask application
- Containerizing the PostgreSQL database
- Creating a Docker Compose configuration
- Configuring Nginx as a reverse proxy
- Testing the application locally
- Preparing the GitHub repository

---

## 🚀 Running the Application

### 📋 Prerequisites

The following software is required:

- Docker Desktop
- Git

Python is also required when running the application directly outside Docker.

---

## 📥 Clone the Repository

Clone the repository using:

`git clone https://github.com/MasemulaN/Hav-A-Seat.git`

Then navigate into the project:

`cd Hav-A-Seat`

---

## 🔐 Environment Variables

The application uses environment variables for database configuration.

Example configuration:

`DB_HOST=localhost`

`DB_PORT=5432`

`DB_NAME=hav_a_seat`

`DB_USER=postgres`

`DB_PASSWORD=your_password`

The actual `.env` file is excluded from the GitHub repository using `.gitignore`.

When the application runs inside Docker Compose, the Flask container communicates with PostgreSQL using the Docker service name `db`.

The Docker database configuration uses:

`DB_HOST=db`

`DB_PORT=5432`

---

## 🐳 Running with Docker Compose

Build and start the application using:

`docker compose up -d --build`

Check the running containers using:

`docker compose ps`

The Docker Compose stack contains three services:

- `hav-a-seat-nginx`
- `hav-a-seat-web`
- `hav-a-seat-db`

---

## 🌐 Accessing the Application

The recommended way to access the application is through Nginx:

`http://localhost`

The Flask application is also exposed on:

`http://localhost:5000`

The Flask port is available for development and troubleshooting purposes, while Nginx provides the main entry point to the application.

---

## 🧰 Useful Docker Commands

### ▶️ Start the application

`docker compose up -d`

### 🔨 Rebuild the application

`docker compose up -d --build`

### 🛑 Stop the application

`docker compose down`

### 📊 Check container status

`docker compose ps`

### 📝 View Flask logs

`docker logs hav-a-seat-web`

### 🌐 View Nginx logs

`docker logs hav-a-seat-nginx`

### 🗄️ View PostgreSQL logs

`docker logs hav-a-seat-db`

---

## 📁 Project Structure

The main project structure is:

- `app/` — Flask application code
- `app/static/` — Static files
- `app/templates/` — HTML/Jinja2 templates
- `app/database.py` — Database connection and database-related functionality
- `app/routes.py` — Application routes
- `nginx/` — Nginx configuration
- `nginx/nginx.conf` — Nginx reverse-proxy configuration
- `screenshots/` — Project screenshots
- `app.py` — Application entry point
- `Dockerfile` — Flask application Docker image configuration
- `docker-compose.yml` — Docker services configuration
- `requirements.txt` — Python dependencies
- `.gitignore` — Files excluded from version control
- `README.md` — Project documentation

---

## 🔮 Future Development

The project will continue to be developed during the following project phases.

Planned areas include:

- AWS infrastructure using Terraform
- VPC networking
- Public and private subnets
- Internet Gateway
- NAT Gateway
- Amazon RDS PostgreSQL
- Application Load Balancer
- EC2 deployment
- Auto Scaling
- Docker deployment on AWS
- GitHub Actions CI/CD
- CloudWatch monitoring
- AWS security configuration
- Cost optimization

---

## 👤 Author

**Noluthando Masemula**

Cloud Engineering / Software Development

GitHub: https://github.com/MasemulaN

---

# 🏗️ Application Architecture

The Week 1 application runs using three Docker containers:

**Browser → Nginx → Flask → PostgreSQL**

### 🔄 Architecture Components

**1. Browser**

The user accesses the application through `http://localhost`.

**2. Nginx**

Nginx listens on port `80` and acts as the reverse proxy and main entry point for the application.

**3. Flask**

The Flask application runs on port `5000`. It handles application logic, routes, reservations, event information, and communication with the database.

**4. PostgreSQL**

PostgreSQL runs inside the `hav-a-seat-db` Docker container on port `5432` and provides persistent data storage.

---

## 🔄 Request Flow

1. The user accesses `http://localhost`.
2. Nginx receives the request on port `80`.
3. Nginx acts as a reverse proxy and forwards the request to the Flask application using the Docker service name `web` and port `5000`.
4. Flask processes the request and determines what data or operation is required.
5. Flask communicates with PostgreSQL using the Docker service name `db` and port `5432`.
6. PostgreSQL stores or retrieves the requested data.
7. Flask generates the response.
8. Nginx forwards the response back to the user's browser.

---

## 🔗 Container Communication

The three containers communicate through the Docker Compose network.

**Browser**

↓

**Nginx — Port 80**

↓

**Flask — `web:5000`**

↓

**PostgreSQL — `db:5432`**

Nginx provides the main entry point, Flask handles the application logic, and PostgreSQL provides persistent data storage.
