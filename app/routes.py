from flask import Blueprint, render_template, request, redirect, url_for
from .database import get_db_connection

main = Blueprint("main", __name__)


@main.route("/")
def home():
    return render_template("index.html")


@main.route("/events")
def events():
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            events.event_id,
            events.title,
            events.description,
            events.category,
            events.location,
            events.start_date,
            events.end_date,
            sessions.session_id,
            sessions.session_date,
            sessions.start_time,
            sessions.end_time,
            sessions.capacity
                - COALESCE(
                    SUM(
                        CASE
                            WHEN reservations.status = FALSE
                            THEN reservations.tickets
                            ELSE 0
                        END
                    ), 0
                ) AS available_seats
        FROM events
        LEFT JOIN sessions
            ON events.event_id = sessions.event_id
        LEFT JOIN reservations
            ON sessions.session_id = reservations.session_id
        GROUP BY
            events.event_id,
            events.title,
            events.description,
            events.category,
            events.location,
            events.start_date,
            events.end_date,
            sessions.session_id,
            sessions.session_date,
            sessions.start_time,
            sessions.end_time,
            sessions.capacity
        ORDER BY
            events.start_date,
            sessions.session_date,
            sessions.start_time;
    """)

    rows = cursor.fetchall()

    cursor.close()
    connection.close()

    events = {}

    for row in rows:
        event_id = row["event_id"]

        if event_id not in events:
            events[event_id] = {
                "event_id": event_id,
                "title": row["title"],
                "description": row["description"],
                "category": row["category"],
                "location": row["location"],
                "start_date": row["start_date"],
                "end_date": row["end_date"],
                "sessions": []
            }

        if row["session_id"] is not None:
            events[event_id]["sessions"].append({
                "session_id": row["session_id"],
                "session_date": row["session_date"],
                "start_time": row["start_time"],
                "end_time": row["end_time"],
                "available_seats": row["available_seats"]
            })


    return render_template(
        "events.html",
        events=list(events.values())
    )
    return render_template(
        "events.html",
        events=event_list
    )

    return render_template(
        "events.html",
        events=event_list
    )

    return render_template(
        "events.html",
        events=event_list
    )
    return render_template(
        "events.html",
        events=event_list
    )


@main.route("/reservations", methods=["GET", "POST"])
def reservations():
    reservations = []

    if request.method == "POST":
        email = request.form["email"]

        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("""
            SELECT
                reservations.reservation_id,
                reservations.full_name,
                reservations.email,
                reservations.tickets,
                reservations.status,
                reservations.created_at,
                events.title,
                sessions.session_date,
                sessions.start_time,
                sessions.end_time
            FROM reservations
            JOIN sessions
                ON reservations.session_id = sessions.session_id
            JOIN events
                ON sessions.event_id = events.event_id
            WHERE reservations.email = %s
            ORDER BY reservations.created_at DESC
        """, (email,))

        reservations = cursor.fetchall()

        cursor.close()
        connection.close()

    return render_template(
        "reservations.html",
        reservations=reservations
    )


@main.route("/reserve", methods=["GET", "POST"])
def reserve():
    session_id = request.args.get("session_id", type=int)

    if request.method == "POST":
        session_id = request.form["session_id"]
        full_name = request.form["full_name"]
        email = request.form["email"]
        tickets = int(request.form["tickets"])

        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("""
            SELECT
                sessions.capacity
                - COALESCE(SUM(reservations.tickets), 0)
                AS available_seats
            FROM sessions
            LEFT JOIN reservations
                ON reservations.session_id = sessions.session_id
            WHERE sessions.session_id = %s
            GROUP BY sessions.session_id, sessions.capacity
        """, (session_id,))

        session = cursor.fetchone()

        if session is None:
            cursor.close()
            connection.close()
            return "Session not found", 404

        if tickets > session["available_seats"]:
            cursor.close()
            connection.close()
            return "Not enough seats available", 400

        cursor.execute("""
            INSERT INTO reservations
                (session_id, full_name, email, tickets)
            VALUES
                (%s, %s, %s, %s)
        """, (session_id, full_name, email, tickets))

        connection.commit()

        cursor.close()
        connection.close()

        return render_template(
            "confirmation.html",
            full_name=full_name,
            email=email,
            tickets=tickets
        )

    return render_template(
        "reservation_form.html",
        session_id=session_id
    )

    return render_template("reservation_form.html")

@main.route("/cancel/<int:reservation_id>", methods=["POST"])
def cancel_reservation(reservation_id):
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("""
        UPDATE reservations
        SET status = TRUE,
            updated_at = CURRENT_TIMESTAMP
        WHERE reservation_id = %s
    """, (reservation_id,))

    connection.commit()

    cursor.close()
    connection.close()

    return redirect(url_for("main.reservations"))

@main.route("/update-reservation/<int:reservation_id>", methods=["GET", "POST"])
def update_reservation(reservation_id):
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            reservations.reservation_id,
            reservations.session_id,
            reservations.full_name,
            reservations.email,
            reservations.tickets,
            reservations.status,
            events.title,
            sessions.session_date,
            sessions.start_time,
            sessions.end_time
        FROM reservations
        JOIN sessions
            ON reservations.session_id = sessions.session_id
        JOIN events
            ON sessions.event_id = events.event_id
        WHERE reservations.reservation_id = %s
    """, (reservation_id,))

    reservation = cursor.fetchone()

    if reservation is None:
        cursor.close()
        connection.close()
        return "Reservation not found", 404

    if reservation["status"]:
        cursor.close()
        connection.close()
        return "Cancelled reservations cannot be updated", 400

    if request.method == "POST":
        new_tickets = int(request.form["tickets"])
        new_session_id = int(request.form["session_id"])

        if new_tickets < reservation["tickets"]:
            cursor.close()
            connection.close()
            return "You cannot reduce the number of tickets", 400

        cursor.execute("""
            SELECT
                sessions.capacity
                - COALESCE(
                    SUM(
                        CASE
                            WHEN reservations.reservation_id != %s
                            THEN reservations.tickets
                            ELSE 0
                        END
                    ), 0
                ) AS available_seats
            FROM sessions
            LEFT JOIN reservations
                ON reservations.session_id = sessions.session_id
                AND reservations.status = FALSE
            WHERE sessions.session_id = %s
            GROUP BY sessions.session_id, sessions.capacity
        """, (reservation_id, new_session_id))

        session = cursor.fetchone()

        if session is None:
            cursor.close()
            connection.close()
            return "Session not found", 404

        if new_tickets > session["available_seats"]:
            cursor.close()
            connection.close()
            return "Not enough seats available", 400

        cursor.execute("""
            UPDATE reservations
            SET session_id = %s,
                tickets = %s,
                updated_at = CURRENT_TIMESTAMP
            WHERE reservation_id = %s
        """, (new_session_id, new_tickets, reservation_id))

        connection.commit()

        cursor.close()
        connection.close()

        return redirect(url_for("main.reservations"))

    cursor.execute("""
        SELECT
            session_id,
            session_date,
            start_time,
            end_time,
            capacity
        FROM sessions
        WHERE event_id = (
            SELECT event_id
            FROM sessions
            WHERE session_id = %s
        )
        ORDER BY session_date, start_time
    """, (reservation["session_id"],))

    sessions = cursor.fetchall()

    cursor.close()
    connection.close()

    return render_template(
        "update_reservation.html",
        reservation=reservation,
        sessions=sessions
    )
