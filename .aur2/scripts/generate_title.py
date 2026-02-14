#!/usr/bin/env python3
"""Generate memorable, human-readable titles for transcriptions using an LLM.

Usage:
    python .aur2/scripts/generate_title.py --text "transcription text"
    python .aur2/scripts/generate_title.py --file transcription.txt
    echo "transcription text" | python .aur2/scripts/generate_title.py

Requirements:
    pip install -r .aur2/scripts/requirements.txt

Environment:
    OPENAI_API_KEY - Required. Your OpenAI API key.
"""

import os
import sys
import re
import argparse
from datetime import datetime

MAX_TITLE_LENGTH = 50  # Characters before truncation


def sanitize_title(title: str) -> str:
    """Convert a title to filesystem-safe kebab-case format.

    Args:
        title: Raw title string to sanitize

    Returns:
        Sanitized kebab-case title suitable for directory names
    """
    if not title or not title.strip():
        return "untitled"

    # Lowercase the entire string
    title = title.lower()

    # Replace spaces and underscores with hyphens
    title = title.replace(" ", "-").replace("_", "-")

    # Remove all characters except alphanumeric and hyphens
    title = re.sub(r'[^a-z0-9-]+', '', title)

    # Replace multiple consecutive hyphens with a single hyphen
    title = re.sub(r'-+', '-', title)

    # Strip leading and trailing hyphens
    title = title.strip('-')

    # Truncate to MAX_TITLE_LENGTH characters if needed
    if len(title) > MAX_TITLE_LENGTH:
        title = title[:MAX_TITLE_LENGTH].rstrip('-')

    # Handle empty string edge case after sanitization
    if not title:
        return "untitled"

    return title


def generate_title(transcription: str, model: str = "gpt-4o-mini") -> str:
    """Generate a concise title for a transcription using an LLM.

    Args:
        transcription: The transcription text to generate a title for
        model: OpenAI model to use (default: gpt-4o-mini)

    Returns:
        Sanitized kebab-case title
    """
    # Load environment variables from .env file
    # Check .aur2/.env first (standard location), then .env in current dir
    try:
        from dotenv import load_dotenv
        from pathlib import Path
        aur2_env = Path(".aur2/.env")
        if aur2_env.exists():
            load_dotenv(aur2_env)
        else:
            load_dotenv()  # Falls back to .env in current directory
    except ImportError:
        pass  # dotenv not installed, rely on environment variables

    # Check for API key
    if not os.environ.get("OPENAI_API_KEY"):
        raise ValueError("OPENAI_API_KEY environment variable not set")

    # Handle empty or very short transcriptions
    if not transcription or len(transcription.strip()) < 10:
        return "short-memo"

    # Handle very long transcriptions - truncate to first 5,000 characters
    if len(transcription) > 10000:
        transcription = transcription[:5000]

    try:
        from openai import OpenAI

        client = OpenAI()

        # Construct focused prompt
        prompt = f"""Generate a short, memorable title (2-5 words) for this voice memo transcription.
The title should capture the main topic or purpose.
Return ONLY the title, no explanation or formatting.

Transcription:
{transcription}"""

        # Call OpenAI API
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=50
        )

        # Extract title from response
        title = response.choices[0].message.content.strip()

        # Sanitize and return
        return sanitize_title(title)

    except Exception as e:
        # Handle API errors - return fallback with timestamp
        print(f"Warning: API error ({e}), using fallback title", file=sys.stderr)
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        return f"transcription-{timestamp}"


def main():
    """CLI interface for title generation."""
    parser = argparse.ArgumentParser(
        description="Generate memorable titles for transcriptions using an LLM",
        epilog="Examples:\n"
               "  echo 'Meeting notes about API refactor' | python .aur2/scripts/generate_title.py\n"
               "  python .aur2/scripts/generate_title.py --file transcription.txt\n"
               "  python .aur2/scripts/generate_title.py --text 'Quick memo about the bug fix'\n",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    input_group = parser.add_mutually_exclusive_group()
    input_group.add_argument(
        "--file",
        type=str,
        help="Read transcription from file"
    )
    input_group.add_argument(
        "--text",
        type=str,
        help="Use provided text as transcription"
    )

    parser.add_argument(
        "--model",
        type=str,
        default="gpt-4o-mini",
        help="OpenAI model to use (default: gpt-4o-mini)"
    )

    args = parser.parse_args()

    # Load environment variables from .env file
    # Check .aur2/.env first (standard location), then .env in current dir
    try:
        from dotenv import load_dotenv
        from pathlib import Path
        aur2_env = Path(".aur2/.env")
        if aur2_env.exists():
            load_dotenv(aur2_env)
        else:
            load_dotenv()  # Falls back to .env in current directory
    except ImportError:
        pass

    # Check for API key
    if not os.environ.get("OPENAI_API_KEY"):
        print("Error: OPENAI_API_KEY environment variable not set", file=sys.stderr)
        print("Set it in .aur2/.env or export it: export OPENAI_API_KEY=your-key", file=sys.stderr)
        sys.exit(1)

    # Check for required dependencies
    try:
        from openai import OpenAI
    except ImportError:
        print("Error: openai not installed", file=sys.stderr)
        print("Install dependencies: pip install -r .aur2/scripts/requirements.txt", file=sys.stderr)
        sys.exit(1)

    # Get transcription text from appropriate source
    try:
        if args.file:
            # Read from file
            if not os.path.exists(args.file):
                print(f"Error: File not found: {args.file}", file=sys.stderr)
                sys.exit(1)
            with open(args.file, 'r', encoding='utf-8') as f:
                transcription = f.read()
        elif args.text:
            # Use provided text
            transcription = args.text
        else:
            # Read from stdin
            if sys.stdin.isatty():
                print("Error: No input provided. Use --file, --text, or pipe text via stdin.", file=sys.stderr)
                print("Run 'python .aur2/scripts/generate_title.py --help' for usage information.", file=sys.stderr)
                sys.exit(1)
            transcription = sys.stdin.read()

        # Handle empty input
        if not transcription or not transcription.strip():
            print("Error: Empty input provided", file=sys.stderr)
            sys.exit(1)

        # Generate and print title
        title = generate_title(transcription.strip(), model=args.model)
        print(title)

    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
