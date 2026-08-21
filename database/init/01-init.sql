-- ============================================================
-- Events
-- ============================================================
CREATE TABLE public.events (
    event_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       varchar(255) NOT NULL,
    description varchar(255),
    category    varchar(255),
    location    varchar(255),
    start_date  date,
    end_date    date,
    cancelled   boolean NOT NULL DEFAULT false
);

-- ============================================================
-- Sessions
-- ============================================================
CREATE TABLE public.sessions (
    session_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id     integer NOT NULL,
    session_date date,
    start_time   time,
    end_time     time,
    capacity     integer NOT NULL CHECK (capacity > 0),
    CONSTRAINT sessions_event_id_fkey
        FOREIGN KEY (event_id) REFERENCES public.events(event_id)
        ON DELETE CASCADE
);

-- ============================================================
-- Reservations
-- ============================================================
CREATE TABLE public.reservations (
    reservation_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id     integer NOT NULL,
    full_name      varchar(255) NOT NULL,
    email          varchar(255) NOT NULL,
    tickets        integer NOT NULL CHECK (tickets > 0),
    status         boolean NOT NULL DEFAULT false,
    created_at     timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     timestamp,
    CONSTRAINT reservations_session_id_fkey
        FOREIGN KEY (session_id) REFERENCES public.sessions(session_id)
);

-- ============================================================
-- Admin users
-- ============================================================
CREATE TABLE public.admin_users (
    admin_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      varchar(100) NOT NULL UNIQUE,
    password_hash varchar(255) NOT NULL,
    created_at    timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Seed: events
-- ============================================================
INSERT INTO public.events
    (title, description, category, location, start_date, end_date, cancelled)
VALUES
(
    'AWS Cloud Bootcamp',
    'Hands-on introduction to AWS cloud computing and infrastructure.',
    'Technology',
    'Johannesburg',
    '2026-08-25',
    '2026-08-25',
    false
),
(
    'Python Workshop',
    'Practical Python development workshop for beginners and developers.',
    'Technology',
    'Johannesburg',
    '2026-09-02',
    '2026-09-02',
    false
),
(
    'AfroPiano',
    'A fusion of Amapiano and Afrobeats festival in Cape Town running over the weekend.',
    'Music',
    'Cape Town - Waterfront',
    '2026-09-05',
    '2026-09-06',
    false
),
(
    'Fintech & E-Commerce Expo',
    'Exploring innovations in financial technology and e-commerce.',
    'Business',
    'Johannesburg',
    '2026-09-08',
    '2026-09-09',
    false
),
(
    'Women in Tech Networking',
    'Networking event connecting women working and building careers in technology.',
    'Networking',
    'Johannesburg',
    '2026-09-10',
    '2026-09-10',
    false
),
(
    'TECHSPO Johannesburg',
    'Technology showcase featuring emerging technologies and digital innovation.',
    'Technology',
    'Johannesburg',
    '2026-09-22',
    '2026-09-23',
    false
);

-- ============================================================
-- Seed: sessions
-- ============================================================
INSERT INTO public.sessions
    (event_id, session_date, start_time, end_time, capacity)
VALUES
    (1, '2026-08-25', '09:00:00', '16:00:00', 100),
    (2, '2026-09-02', '09:00:00', '16:00:00', 100),
    (3, '2026-09-05', '18:00:00', '22:00:00', 100),
    (3, '2026-09-06', '18:00:00', '22:00:00', 100),
    (4, '2026-09-08', '09:00:00', '17:00:00', 150),
    (4, '2026-09-09', '09:00:00', '17:00:00', 150),
    (5, '2026-09-10', '18:00:00', '21:00:00',  80),
    (6, '2026-09-22', '09:00:00', '17:00:00', 200),
    (6, '2026-09-23', '09:00:00', '17:00:00', 200);

-- ============================================================
-- Seed: sample reservations
-- ============================================================
INSERT INTO public.reservations
    (session_id, full_name, email, tickets, status, created_at, updated_at)
VALUES
    (3, 'Demo User',     'demo@example.com', 2, true,  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (4, 'Test Customer', 'test@example.com', 3, false, CURRENT_TIMESTAMP, NULL);

-- ============================================================
-- Seed: default admin account
--   username : admin
--   password : admin123   (change immediately after first login)
-- ============================================================
INSERT INTO public.admin_users (username, password_hash)
VALUES (
    'admin',
    'scrypt:32768:8:1$ReVlQCvwpAvB4XGT$b9a8d3bfdee096f7b29de9af5b116ef6fd7059724018398f511c45ffc10436ad52c83a915d4b91f1b80fa04dc06cc4dd5654291ac9c894631a9e669da519a491'
);
