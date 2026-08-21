from functools import wraps

from flask import (
    Blueprint,
    flash,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from werkzeug.security import check_password_hash

from .database import get_db_connection


admin = Blueprint("admin", __name__, url_prefix="/admin")


# ---------------------------------------------------------------------------
# Authentication helper
# ---------------------------------------------------------------------------

def login_required(f):
    """Redirect to the admin login page if the admin is not signed in."""

    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get("admin_logged_in"):
            flash(
                "Please sign in to access the admin area.",
                "warning",
            )
            return redirect(url_for("admin.login"))

        return f(*args, **kwargs)

    return decorated


# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------

def validate_capacity(value):
    """
    Validate a session capacity value.

    Returns:
        int: The validated positive capacity.

    Raises:
        ValueError: If the capacity is empty, non-numeric, zero, or negative.
    """
    value = value.strip()

    if not value:
        raise ValueError("Capacity is required.")

    try:
        capacity = int(value)
    except (TypeError, ValueError):
        raise ValueError(
            "Capacity must be a valid whole number."
        )

    if capacity <= 0:
        raise ValueError(
            "Capacity must be greater than 0."
        )

    return capacity


# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

@admin.route("/login", methods=["GET", "POST"])
def login():
    """Display the admin login page and authenticate an admin."""

    if session.get("admin_logged_in"):
        return redirect(url_for("admin.dashboard"))

    if request.method == "POST":
        username = request.form["username"].strip()
        password = request.form["password"]

        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT admin_id, username, password_hash
            FROM admin_users
            WHERE username = %s
            """,
            (username,),
        )

        admin_user = cursor.fetchone()

        cursor.close()
        connection.close()

        if admin_user and check_password_hash(
            admin_user["password_hash"],
            password,
        ):
            session["admin_logged_in"] = True
            session["admin_id"] = admin_user["admin_id"]
            session["admin_username"] = admin_user["username"]

            flash(
                f"Welcome back, {admin_user['username']}!",
                "success",
            )

            return redirect(url_for("admin.dashboard"))

        flash(
            "Invalid username or password.",
            "danger",
        )

    return render_template("admin/login.html")


@admin.route("/logout", methods=["POST"])
def logout():
    """Sign the current admin out."""

    session.clear()

    flash(
        "You have been signed out.",
        "info",
    )

    return redirect(url_for("admin.login"))


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

@admin.route("/")
@login_required
def dashboard():
    """Display all events in the admin dashboard."""

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute(
        """
        SELECT
            e.event_id,
            e.title,
            e.category,
            e.location,
            e.start_date,
            e.end_date,
            e.cancelled,
            COUNT(s.session_id) AS session_count
        FROM events e
        LEFT JOIN sessions s
            ON e.event_id = s.event_id
        GROUP BY
            e.event_id,
            e.title,
            e.category,
            e.location,
            e.start_date,
            e.end_date,
            e.cancelled
        ORDER BY
            e.start_date DESC,
            e.title
        """
    )

    events = cursor.fetchall()

    cursor.close()
    connection.close()

    return render_template(
        "admin/dashboard.html",
        events=events,
    )


# ---------------------------------------------------------------------------
# Create event
# ---------------------------------------------------------------------------

@admin.route("/events/create", methods=["GET", "POST"])
@login_required
def create_event():
    """Create a new event and its sessions."""

    if request.method == "POST":
        title = request.form["title"].strip()
        description = request.form["description"].strip()
        category = request.form["category"].strip()
        location = request.form["location"].strip()
        start_date = request.form["start_date"]
        end_date = request.form["end_date"]

        # Basic event validation.
        if not title:
            flash(
                "Event title is required.",
                "danger",
            )

            return render_template(
                "admin/event_form.html",
                event=None,
                action="create",
            )

        if start_date and end_date and end_date < start_date:
            flash(
                "End date cannot be before start date.",
                "danger",
            )

            return render_template(
                "admin/event_form.html",
                event=request.form,
                action="create",
            )

        # Read submitted session data.
        session_dates = request.form.getlist(
            "session_date[]"
        )
        start_times = request.form.getlist(
            "start_time[]"
        )
        end_times = request.form.getlist(
            "end_time[]"
        )
        capacities = request.form.getlist(
            "capacity[]"
        )

        # Validate capacities before writing anything
        # to the database.
        validated_capacities = []

        for capacity in capacities:
            if not capacity.strip():
                # Ignore completely empty session rows.
                validated_capacities.append(None)
                continue

            try:
                validated_capacities.append(
                    validate_capacity(capacity)
                )
            except ValueError as error:
                flash(
                    str(error),
                    "danger",
                )

                return render_template(
                    "admin/event_form.html",
                    event=request.form,
                    action="create",
                )

        connection = get_db_connection()
        cursor = connection.cursor()

        try:
            cursor.execute(
                """
                INSERT INTO events (
                    title,
                    description,
                    category,
                    location,
                    start_date,
                    end_date
                )
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING event_id
                """,
                (
                    title,
                    description or None,
                    category or None,
                    location or None,
                    start_date or None,
                    end_date or None,
                ),
            )

            new_id = cursor.fetchone()["event_id"]

            # Add sessions belonging to the new event.
            for (
                session_date,
                start_time,
                end_time,
                capacity,
            ) in zip(
                session_dates,
                start_times,
                end_times,
                validated_capacities,
            ):
                if session_date and capacity is not None:
                    cursor.execute(
                        """
                        INSERT INTO sessions (
                            event_id,
                            session_date,
                            start_time,
                            end_time,
                            capacity
                        )
                        VALUES (%s, %s, %s, %s, %s)
                        """,
                        (
                            new_id,
                            session_date,
                            start_time or None,
                            end_time or None,
                            capacity,
                        ),
                    )

            connection.commit()

        except Exception:
            connection.rollback()
            raise

        finally:
            cursor.close()
            connection.close()

        flash(
            f'Event "{title}" created successfully.',
            "success",
        )

        return redirect(url_for("admin.dashboard"))

    return render_template(
        "admin/event_form.html",
        event=None,
        action="create",
    )


# ---------------------------------------------------------------------------
# Edit event
# ---------------------------------------------------------------------------

@admin.route(
    "/events/<int:event_id>/edit",
    methods=["GET", "POST"],
)
@login_required
def edit_event(event_id):
    """Edit an existing event and manage its sessions."""

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute(
        "SELECT * FROM events WHERE event_id = %s",
        (event_id,),
    )

    event = cursor.fetchone()

    if event is None:
        cursor.close()
        connection.close()

        flash(
            "Event not found.",
            "danger",
        )

        return redirect(url_for("admin.dashboard"))

    if request.method == "POST":
        title = request.form["title"].strip()
        description = request.form["description"].strip()
        category = request.form["category"].strip()
        location = request.form["location"].strip()
        start_date = request.form["start_date"]
        end_date = request.form["end_date"]
        cancelled = "cancelled" in request.form

        # Basic event validation.
        if not title:
            flash(
                "Event title is required.",
                "danger",
            )

            cursor.close()
            connection.close()

            return render_template(
                "admin/event_form.html",
                event=event,
                action="edit",
            )

        if start_date and end_date and end_date < start_date:
            flash(
                "End date cannot be before start date.",
                "danger",
            )

            cursor.close()
            connection.close()

            return render_template(
                "admin/event_form.html",
                event=event,
                action="edit",
            )

        # ---------------------------------------------------------------
        # Validate existing sessions.
        # ---------------------------------------------------------------

        existing_ids = request.form.getlist(
            "existing_session_id[]"
        )
        existing_dates = request.form.getlist(
            "existing_session_date[]"
        )
        existing_starts = request.form.getlist(
            "existing_start_time[]"
        )
        existing_ends = request.form.getlist(
            "existing_end_time[]"
        )
        existing_caps = request.form.getlist(
            "existing_capacity[]"
        )

        validated_existing_capacities = []

        for capacity in existing_caps:
            try:
                validated_existing_capacities.append(
                    validate_capacity(capacity)
                )
            except ValueError as error:
                flash(
                    str(error),
                    "danger",
                )

                cursor.close()
                connection.close()

                return render_template(
                    "admin/event_form.html",
                    event=event,
                    action="edit",
                )

        # ---------------------------------------------------------------
        # Validate new sessions.
        # ---------------------------------------------------------------

        new_dates = request.form.getlist(
            "session_date[]"
        )
        new_starts = request.form.getlist(
            "start_time[]"
        )
        new_ends = request.form.getlist(
            "end_time[]"
        )
        new_caps = request.form.getlist(
            "capacity[]"
        )

        validated_new_capacities = []

        for capacity in new_caps:
            if not capacity.strip():
                validated_new_capacities.append(None)
                continue

            try:
                validated_new_capacities.append(
                    validate_capacity(capacity)
                )
            except ValueError as error:
                flash(
                    str(error),
                    "danger",
                )

                cursor.close()
                connection.close()

                return render_template(
                    "admin/event_form.html",
                    event=event,
                    action="edit",
                )

        # ---------------------------------------------------------------
        # Update event and sessions.
        # ---------------------------------------------------------------

        try:
            cursor.execute(
                """
                UPDATE events
                SET
                    title = %s,
                    description = %s,
                    category = %s,
                    location = %s,
                    start_date = %s,
                    end_date = %s,
                    cancelled = %s
                WHERE event_id = %s
                """,
                (
                    title,
                    description or None,
                    category or None,
                    location or None,
                    start_date or None,
                    end_date or None,
                    cancelled,
                    event_id,
                ),
            )

            # Delete sessions marked for removal.
            removed_ids = request.form.getlist(
                "remove_session[]"
            )

            for session_id in removed_ids:
                cursor.execute(
                    """
                    DELETE FROM sessions
                    WHERE session_id = %s
                      AND event_id = %s
                    """,
                    (
                        int(session_id),
                        event_id,
                    ),
                )

            # Update existing sessions.
            for (
                session_id,
                session_date,
                start_time,
                end_time,
                capacity,
            ) in zip(
                existing_ids,
                existing_dates,
                existing_starts,
                existing_ends,
                validated_existing_capacities,
            ):
                cursor.execute(
                    """
                    UPDATE sessions
                    SET
                        session_date = %s,
                        start_time = %s,
                        end_time = %s,
                        capacity = %s
                    WHERE session_id = %s
                      AND event_id = %s
                    """,
                    (
                        session_date,
                        start_time or None,
                        end_time or None,
                        capacity,
                        int(session_id),
                        event_id,
                    ),
                )

            # Add new sessions.
            for (
                session_date,
                start_time,
                end_time,
                capacity,
            ) in zip(
                new_dates,
                new_starts,
                new_ends,
                validated_new_capacities,
            ):
                if session_date and capacity is not None:
                    cursor.execute(
                        """
                        INSERT INTO sessions (
                            event_id,
                            session_date,
                            start_time,
                            end_time,
                            capacity
                        )
                        VALUES (%s, %s, %s, %s, %s)
                        """,
                        (
                            event_id,
                            session_date,
                            start_time or None,
                            end_time or None,
                            capacity,
                        ),
                    )

            connection.commit()

        except Exception:
            connection.rollback()
            raise

        finally:
            cursor.close()
            connection.close()

        flash(
            f'Event "{title}" updated successfully.',
            "success",
        )

        return redirect(url_for("admin.dashboard"))

    # GET — load the event's sessions.
    cursor.execute(
        """
        SELECT
            session_id,
            session_date,
            start_time,
            end_time,
            capacity
        FROM sessions
        WHERE event_id = %s
        ORDER BY session_date, start_time
        """,
        (event_id,),
    )

    sessions = cursor.fetchall()

    cursor.close()
    connection.close()

    return render_template(
        "admin/event_form.html",
        event=event,
        sessions=sessions,
        action="edit",
    )


# ---------------------------------------------------------------------------
# Delete event
# ---------------------------------------------------------------------------

@admin.route(
    "/events/<int:event_id>/delete",
    methods=["GET", "POST"],
)
@login_required
def delete_event(event_id):
    """Delete an event and its sessions."""

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute(
        """
        SELECT event_id, title
        FROM events
        WHERE event_id = %s
        """,
        (event_id,),
    )

    event = cursor.fetchone()

    if event is None:
        cursor.close()
        connection.close()

        flash(
            "Event not found.",
            "danger",
        )

        return redirect(url_for("admin.dashboard"))

    if request.method == "POST":
        title = event["title"]

        cursor.execute(
            "DELETE FROM events WHERE event_id = %s",
            (event_id,),
        )

        connection.commit()

        cursor.close()
        connection.close()

        flash(
            f'Event "{title}" has been permanently deleted.',
            "success",
        )

        return redirect(url_for("admin.dashboard"))

    cursor.close()
    connection.close()

    return render_template(
        "admin/delete_confirm.html",
        event=event,
    )