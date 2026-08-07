from flask import Blueprint, render_template, request

main = Blueprint("main", __name__)


@main.route("/")
def home():
    return render_template("index.html")


@main.route("/events")
def events():

    event_list = [
        {
            "title": "AWS Cloud Bootcamp",
            "location": "Johannesburg",
            "date": "25 August 2026"
        },
        {
            "title": "Python for Beginners Workshop",
            "location": "Pretoria",
            "date": "2 September 2026"
        },
        {
            "title": "Fintech & E-Commerce Expo",
            "location": "Johannesburg",
            "date": "8-9 September 2026"
        },
        {
            "title": "Women in Tech Networking",
            "location": "Cape Town",
            "date": "10 September 2026"
        },
        {
            "title": "TECHSPO Johannesburg",
            "location": "Johannesburg",
            "date": "22-23 September 2026"
        }
    ]

    return render_template(
        "events.html",
        events=event_list
    )


@main.route("/reservations")
def reservations():
    return render_template("reservations.html")


@main.route("/reserve", methods=["GET", "POST"])
def reserve():

    if request.method == "POST":

        full_name = request.form["full_name"]
        email = request.form["email"]
        tickets = request.form["tickets"]

        return render_template(
            "confirmation.html",
            full_name=full_name,
            email=email,
            tickets=tickets
        )

    return render_template("reservation_form.html")