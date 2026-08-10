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

---
              | PostgreSQL|
              |   :5432   |
              +-----------+
