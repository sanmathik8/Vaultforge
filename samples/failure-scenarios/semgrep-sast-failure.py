# Sample failure asset for Semgrep SAST Gate
# Demonstrates SQL Injection vulnerability flagged by Semgrep rules

import sqlite3

def unsafe_query(user_input):
    conn = sqlite3.connect('db.sqlite3')
    cursor = conn.cursor()
    # Unsafe raw string formatting in SQL query
    query = f"SELECT * FROM users WHERE username = '{user_input}'"
    cursor.execute(query)
    return cursor.fetchall()
