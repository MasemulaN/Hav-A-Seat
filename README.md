# Hav-A-Seat 🎟️

Hav-A-Seat is a Flask-based event booking and reservation system built as part of the Mid-Level Cloud Engineering Project.

The application allows users to browse events, view available sessions, make reservations, view their reservations, update reservations, and cancel reservations.

The Week 1 focus was on building the application, connecting it to PostgreSQL, containerizing the application with Docker, and preparing the project for future cloud deployment.

---

## ✨ Features

- Browse available events
- View event details and sessions
- View session availability
- Make event reservations
- View reservations using an email address
- Update reservations
- Cancel reservations
- Automatically calculate available seats
- Prevent users from booking more seats than are available
- PostgreSQL database for persistent data storage
- Dockerized Flask application
- Dockerized PostgreSQL database
- Nginx reverse proxy
- Docker Compose for running the application stack

---

## 🛠️ Technology Stack

- **Backend:** Python, Flask
- **Database:** PostgreSQL
- **Database Driver:** Psycopg
- **Web Server / Reverse Proxy:** Nginx
- **Containerization:** Docker
- **Container Orchestration:** Docker Compose
- **Version Control:** Git & GitHub
- **Frontend:** HTML, CSS, Jinja2 templates

---

## 🏗️ Application Architecture

The Week 1 application uses a three-container Docker architecture:

```text
                 Browser
                    |
                    | HTTP :80
                    v
              +-----------+
              |   Nginx   |
              |   :80     |
              +-----+-----+
                    |
                    | web:5000
                    v
              +-----------+
              |   Flask   |
              |   :5000   |
              +-----+-----+
                    |
                    | db:5432
                    v
              +-----------+

---

##🔄 Request Flow
A user accesses the application through http://localhost.
Nginx receives the request on port 80.
Nginx forwards the request to the Flask application.
Flask processes the request and communicates with PostgreSQL.
PostgreSQL stores and retrieves application data.
Flask returns the response through Nginx to the user's browser.

---

##🗄️ Database

The application uses PostgreSQL with three main tables.

📅 Events

Stores information about events including:

Event ID
Title
Description
Category
Location
Start date
End date
Cancellation status
🕐 Sessions

Stores individual sessions belonging to an event:

Session ID
Event ID
Session date
Start time
End time
Capacity

An event can contain multiple sessions. This allows a single event to run across multiple days or have multiple sessions on the same day.

🎫 Reservations

Stores user reservations and includes information such as:

Reservation ID
Session ID
Customer name
Email
Number of tickets
Reservation status
Created/updated timestamps

Available seats are calculated based on the session capacity and the number of active reservations.

---

## 🚀 Running the Application Locally
📋 Prerequisites

Install:

Docker Desktop
Git

Python is required for development outside Docker.

---

##📥 Clone the Repository
git clone https://github.com/MasemulaN/Hav-A-Seat.git
cd Hav-A-Seat

---

##🔐 Environment Variables

The application uses environment variables for database configuration.

Example:

DB_HOST=localhost
DB_PORT=5432
DB_NAME=hav_a_seat
DB_USER=postgres
DB_PASSWORD=your_password

⚠️ The actual .env file is not included in the GitHub repository for security reasons.

When running through Docker Compose, the Flask container communicates with PostgreSQL using the Docker service name:

DB_HOST=db
DB_PORT=5432

---
              | PostgreSQL|
              |   :5432   |
              +-----------+
