from flask import Flask, jsonify, render_template
import os
import psycopg2
import time

app = Flask(__name__)
DATABASE_URL = os.environ.get("DATABASE_URL")

def init_db():
    retries = 5
    while retries > 0:
        try:
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        CREATE TABLE IF NOT EXISTS messages (
                            id SERIAL PRIMARY KEY,
                            text TEXT
                        );
                    """)
                    conn.commit()
            print("Database initialized")
            return
        except psycopg2.OperationalError as e:
            print(f"Database init failed: {e}")
            retries -= 1
            time.sleep(3)
    raise Exception("Could not connect to the database after several attempts.")

@app.route('/')
def home():
    # Render a simple Hello World HTML page
    return render_template('index.html')

@app.route('/messages')
def get_messages():
    try:
        with psycopg2.connect(DATABASE_URL) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM messages;")
                rows = cur.fetchall()
                return jsonify(rows)
    except Exception as e:
        return f"DB read failed: {e}"

@app.route('/add')
def add_message():
    try:
        with psycopg2.connect(DATABASE_URL) as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO messages (text) VALUES (%s);", ("Hello from Flask!",))
                conn.commit()
        return "Message added!"
    except Exception as e:
        return f"DB insert failed: {e}"

if __name__ == '__main__':
    init_db()
    app.run(host="0.0.0.0", port=5000)

