#!/usr/bin/env python3
"""
Anki Stats Exporter
-------------------
Exports Anki review statistics to JSON format for heatmap visualization.

Usage:
    python export_anki_stats.py [--db-path PATH] [--output PATH] [--deck-name NAME]

Requirements:
    pip install anki

This script should be run on the computer with Anki installed.
"""

import argparse
import json
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict
import sys


def find_anki_db():
    """Attempt to find the Anki database automatically."""
    possible_paths = [
        Path.home() / ".local/share/Anki2" / "User 1" / "collection.anki2",  # Linux
        Path.home() / "Library/Application Support/Anki2" / "User 1" / "collection.anki2",  # macOS
        Path.home() / "AppData/Roaming/Anki2" / "User 1" / "collection.anki2",  # Windows
    ]

    for path in possible_paths:
        if path.exists():
            return path

    return None


def calculate_streak(daily_reviews):
    """Calculate current and longest streak from daily reviews."""
    if not daily_reviews:
        return 0, 0

    # Sort dates
    sorted_dates = sorted(daily_reviews.keys(), reverse=True)

    # Calculate current streak
    current_streak = 0
    today = datetime.now().date()
    current_date = today

    for date_str in sorted_dates:
        date = datetime.strptime(date_str, '%Y-%m-%d').date()
        if date > today:
            continue

        if date == current_date and daily_reviews[date_str] > 0:
            current_streak += 1
            current_date -= timedelta(days=1)
        elif date < current_date:
            break

    # Calculate longest streak
    longest_streak = 0
    temp_streak = 0
    prev_date = None

    for date_str in sorted(daily_reviews.keys()):
        date = datetime.strptime(date_str, '%Y-%m-%d').date()

        if daily_reviews[date_str] > 0:
            if prev_date is None or (date - prev_date).days == 1:
                temp_streak += 1
                longest_streak = max(longest_streak, temp_streak)
            else:
                temp_streak = 1
            prev_date = date
        else:
            temp_streak = 0
            prev_date = None

    return current_streak, longest_streak


def export_anki_stats(db_path, output_path, deck_name=None, days=365):
    """
    Export Anki review statistics to JSON.

    Args:
        db_path: Path to Anki collection.anki2 database
        output_path: Path to output JSON file
        deck_name: Optional deck name to filter (None = all decks)
        days: Number of days of history to export (default: 365)
    """

    try:
        # Connect to Anki database
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Get deck ID if deck name is specified
        deck_id = None
        if deck_name:
            cursor.execute("SELECT id, name FROM decks")
            decks = cursor.fetchall()
            # Anki stores decks as JSON, need to parse
            for deck_data in decks:
                # This is a simplification; actual implementation may vary
                if deck_name.lower() in str(deck_data).lower():
                    deck_id = deck_data[0]
                    break

        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        start_timestamp = int(start_date.timestamp() * 1000)  # Anki uses milliseconds

        # Query reviews from the revlog table
        # Anki revlog schema: id, cid (card id), usn, ease, ivl, lastIvl, factor, time, type
        query = """
            SELECT id, cid, time, type
            FROM revlog
            WHERE id > ?
            ORDER BY id
        """

        cursor.execute(query, (start_timestamp,))
        reviews = cursor.fetchall()

        # Group reviews by date
        daily_reviews = defaultdict(int)
        total_reviews = 0

        for review in reviews:
            review_id = review[0]
            # Extract timestamp from review ID (first 13 digits)
            timestamp_ms = review_id
            timestamp_s = timestamp_ms / 1000
            review_date = datetime.fromtimestamp(timestamp_s).strftime('%Y-%m-%d')

            daily_reviews[review_date] += 1
            total_reviews += 1

        # Fill in missing dates with 0
        current_date = start_date.date()
        end = end_date.date()

        while current_date <= end:
            date_str = current_date.strftime('%Y-%m-%d')
            if date_str not in daily_reviews:
                daily_reviews[date_str] = 0
            current_date += timedelta(days=1)

        # Calculate streaks
        current_streak, longest_streak = calculate_streak(daily_reviews)

        # Prepare output data
        output_data = {
            "metadata": {
                "last_updated": datetime.now().isoformat() + "Z",
                "total_reviews": total_reviews,
                "current_streak": current_streak,
                "longest_streak": longest_streak,
                "deck_name": deck_name or "All Decks",
                "export_days": days
            },
            "daily_reviews": dict(sorted(daily_reviews.items()))
        }

        # Write to JSON file
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)

        conn.close()

        print(f"✓ Successfully exported {total_reviews} reviews")
        print(f"✓ Current streak: {current_streak} days")
        print(f"✓ Longest streak: {longest_streak} days")
        print(f"✓ Output saved to: {output_path}")

        return True

    except sqlite3.Error as e:
        print(f"✗ Database error: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Export Anki review statistics to JSON for heatmap visualization"
    )
    parser.add_argument(
        "--db-path",
        type=Path,
        help="Path to Anki collection.anki2 database (auto-detected if not specified)"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("anki-stats.json"),
        help="Output JSON file path (default: anki-stats.json)"
    )
    parser.add_argument(
        "--deck-name",
        type=str,
        help="Filter by specific deck name (optional)"
    )
    parser.add_argument(
        "--days",
        type=int,
        default=365,
        help="Number of days of history to export (default: 365)"
    )

    args = parser.parse_args()

    # Find database path
    db_path = args.db_path
    if not db_path:
        db_path = find_anki_db()
        if not db_path:
            print("✗ Could not find Anki database automatically.", file=sys.stderr)
            print("  Please specify path with --db-path", file=sys.stderr)
            sys.exit(1)
        print(f"Found Anki database: {db_path}")

    if not db_path.exists():
        print(f"✗ Database not found: {db_path}", file=sys.stderr)
        sys.exit(1)

    # Export stats
    success = export_anki_stats(db_path, args.output, args.deck_name, args.days)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
