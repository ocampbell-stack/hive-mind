#!/usr/bin/env python3
"""Record voice memos with automatic transcription and title generation.

Usage:
    python .aur2/scripts/record_memo.py [--max-duration SECONDS]

Records audio via sox, transcribes via OpenAI Whisper, generates a title,
and saves to .aur2/visions/queue/<title>/.

Requirements:
    - sox installed (brew install sox / apt install sox)
    - pip install -r .aur2/scripts/requirements.txt

Environment:
    OPENAI_API_KEY - Required. Your OpenAI API key.

Exit Codes:
    0 - Success (audio recorded, transcribed, titled, saved to queue/)
    1 - Recording failed (sox error, no audio)
    2 - Transcription failed (audio saved to failed/)
"""

import os
import sys
import signal
import shutil
import subprocess
import tempfile
import argparse
from datetime import datetime
from pathlib import Path


# Default maximum recording duration (10 minutes)
DEFAULT_MAX_DURATION = 600


def check_sox_installed() -> bool:
    """Check if sox is installed and available."""
    return shutil.which("sox") is not None


def get_visions_dir() -> Path:
    """Get the .aur2/visions directory path, creating it if needed."""
    # Try to find .aur2 directory by walking up from cwd
    cwd = Path.cwd()
    for parent in [cwd] + list(cwd.parents):
        aur2_dir = parent / ".aur2"
        if aur2_dir.exists():
            visions_dir = aur2_dir / "visions"
            return visions_dir

    # Fallback to cwd/.aur2/visions
    return cwd / ".aur2" / "visions"


def ensure_directories(visions_dir: Path) -> None:
    """Ensure queue/, processed/, and failed/ directories exist."""
    (visions_dir / "queue").mkdir(parents=True, exist_ok=True)
    (visions_dir / "processed").mkdir(parents=True, exist_ok=True)
    (visions_dir / "failed").mkdir(parents=True, exist_ok=True)


def record_audio(output_path: Path, max_duration: int = DEFAULT_MAX_DURATION) -> bool:
    """Record audio using sox.

    Args:
        output_path: Path to save the recorded audio
        max_duration: Maximum recording duration in seconds

    Returns:
        True if recording succeeded, False otherwise
    """
    print("Recording... Press Ctrl+C to stop.", file=sys.stderr)
    print(f"(Max duration: {max_duration} seconds)", file=sys.stderr)

    # sox rec command: record to wav format
    # -c 1: mono channel
    # -r 16000: 16kHz sample rate (good for speech)
    # trim 0 {max_duration}: limit recording length
    cmd = [
        "sox",
        "-d",  # Use default audio device
        "-c", "1",  # Mono
        "-r", "16000",  # 16kHz sample rate
        str(output_path),
        "trim", "0", str(max_duration)
    ]

    try:
        # Run sox and allow Ctrl+C to stop it
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        # Wait for process, but allow SIGINT to interrupt
        try:
            _, stderr = process.communicate()
        except KeyboardInterrupt:
            # User pressed Ctrl+C - send SIGINT to sox to stop recording
            process.send_signal(signal.SIGINT)
            process.wait()
            print("\nRecording stopped.", file=sys.stderr)

        # Check if we got any audio
        if output_path.exists() and output_path.stat().st_size > 0:
            return True
        else:
            print("Error: No audio recorded", file=sys.stderr)
            if stderr:
                print(f"Sox error: {stderr.decode()}", file=sys.stderr)
            return False

    except FileNotFoundError:
        print("Error: sox not found. Install it with: brew install sox (macOS) or apt install sox (Linux)", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Error during recording: {e}", file=sys.stderr)
        return False


def transcribe_audio(audio_path: Path) -> str | None:
    """Transcribe audio file using OpenAI Whisper.

    Args:
        audio_path: Path to the audio file

    Returns:
        Transcription text, or None if transcription failed
    """
    # Import transcription function from sibling script
    script_dir = Path(__file__).parent
    sys.path.insert(0, str(script_dir))

    try:
        from transcribe import transcribe_audio as _transcribe, split_audio_into_chunks, transcribe_chunks, get_audio_duration_ms, CHUNK_THRESHOLD_MS

        print("Transcribing...", file=sys.stderr)

        duration_ms = get_audio_duration_ms(str(audio_path))
        if duration_ms > CHUNK_THRESHOLD_MS:
            chunk_paths = split_audio_into_chunks(str(audio_path))
            transcript = transcribe_chunks(chunk_paths, str(audio_path))
        else:
            transcript = _transcribe(str(audio_path))

        return transcript

    except Exception as e:
        print(f"Transcription error: {e}", file=sys.stderr)
        return None
    finally:
        # Remove from sys.path
        if str(script_dir) in sys.path:
            sys.path.remove(str(script_dir))


def generate_title(transcript: str) -> str:
    """Generate a title from the transcript.

    Args:
        transcript: The transcription text

    Returns:
        Generated title in kebab-case format
    """
    script_dir = Path(__file__).parent
    sys.path.insert(0, str(script_dir))

    try:
        from generate_title import generate_title as _generate_title

        print("Generating title...", file=sys.stderr)
        return _generate_title(transcript)

    except Exception as e:
        print(f"Title generation error: {e}", file=sys.stderr)
        # Fallback title
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        return f"memo-{timestamp}"
    finally:
        if str(script_dir) in sys.path:
            sys.path.remove(str(script_dir))


def get_fallback_title() -> str:
    """Generate a fallback timestamp-based title."""
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return f"memo-{timestamp}"


def save_memo(audio_path: Path, transcript: str | None, visions_dir: Path) -> tuple[Path, bool]:
    """Save memo to appropriate directory.

    Args:
        audio_path: Path to the recorded audio file
        transcript: Transcription text, or None if transcription failed
        visions_dir: Base visions directory (.aur2/visions)

    Returns:
        Tuple of (final_dir, success) where success indicates if saved to queue/
    """
    if transcript:
        # Success path: generate title and save to queue/
        title = generate_title(transcript)
        target_dir = visions_dir / "queue" / title

        # Handle duplicate titles
        if target_dir.exists():
            timestamp = datetime.now().strftime("%H%M%S")
            title = f"{title}-{timestamp}"
            target_dir = visions_dir / "queue" / title
    else:
        # Failure path: save to failed/ with timestamp title
        title = get_fallback_title()
        target_dir = visions_dir / "failed" / title

    # Create directory and move/save files
    target_dir.mkdir(parents=True, exist_ok=True)

    # Move audio file
    target_audio = target_dir / "audio.wav"
    shutil.move(str(audio_path), str(target_audio))

    # Save transcript if available
    if transcript:
        target_transcript = target_dir / "transcript.txt"
        target_transcript.write_text(transcript, encoding="utf-8")
        return target_dir, True
    else:
        return target_dir, False


def main():
    """Main entry point for record_memo script."""
    parser = argparse.ArgumentParser(
        description="Record voice memos with automatic transcription and title generation",
        epilog="Examples:\n"
               "  python .aur2/scripts/record_memo.py\n"
               "  python .aur2/scripts/record_memo.py --max-duration 120\n",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--max-duration",
        type=int,
        default=DEFAULT_MAX_DURATION,
        help=f"Maximum recording duration in seconds (default: {DEFAULT_MAX_DURATION})"
    )

    args = parser.parse_args()

    # Load environment variables
    try:
        from dotenv import load_dotenv
        aur2_env = Path(".aur2/.env")
        if aur2_env.exists():
            load_dotenv(aur2_env)
        else:
            load_dotenv()
    except ImportError:
        pass

    # Check prerequisites
    if not check_sox_installed():
        print("Error: sox is not installed", file=sys.stderr)
        print("Install it with: brew install sox (macOS) or apt install sox (Linux)", file=sys.stderr)
        sys.exit(1)

    if not os.environ.get("OPENAI_API_KEY"):
        print("Error: OPENAI_API_KEY environment variable not set", file=sys.stderr)
        print("Set it in .aur2/.env or export it: export OPENAI_API_KEY=your-key", file=sys.stderr)
        sys.exit(1)

    # Get visions directory and ensure structure exists
    visions_dir = get_visions_dir()
    ensure_directories(visions_dir)

    # Create temp file for recording
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        temp_audio_path = Path(tmp.name)

    try:
        # Step 1: Record audio
        if not record_audio(temp_audio_path, args.max_duration):
            # Clean up temp file
            if temp_audio_path.exists():
                temp_audio_path.unlink()
            sys.exit(1)

        # Step 2: Transcribe audio
        transcript = transcribe_audio(temp_audio_path)

        # Step 3: Save memo (handles both success and failure cases)
        final_dir, success = save_memo(temp_audio_path, transcript, visions_dir)

        if success:
            print(f"\n✓ Memo saved to: {final_dir}", file=sys.stderr)
            print(f"  Run '/aur2.process_visions' to process it.", file=sys.stderr)
            sys.exit(0)
        else:
            print(f"\n⚠ Transcription failed. Audio saved to: {final_dir}", file=sys.stderr)
            print(f"  You can retry transcription manually or delete the memo.", file=sys.stderr)
            sys.exit(2)

    except KeyboardInterrupt:
        print("\nAborted.", file=sys.stderr)
        if temp_audio_path.exists():
            temp_audio_path.unlink()
        sys.exit(130)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        if temp_audio_path.exists():
            temp_audio_path.unlink()
        sys.exit(1)


if __name__ == "__main__":
    main()
