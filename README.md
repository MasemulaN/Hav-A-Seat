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

```bash
git clone https://github.com/MasemulaN/Hav-A-Seat.git
cd Hav-A-Seat
