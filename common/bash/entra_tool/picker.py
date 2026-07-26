import subprocess
import sys


def run_fzf(input_text: str, prompt: str, header: str, query: str = "") -> str | None:
    args = [
        "fzf",
        "--ansi",
        "--height=90%",
        "--layout=reverse",
        "--border=rounded",
        "--cycle",
        "--exact",
        "--header-lines=2",
        "--no-multi",
        "--pointer=>",
        "--marker=*",
        f"--prompt={prompt}",
        f"--header={header}",
        "--delimiter=\t",
        "--with-nth=1",
    ]
    if query:
        args.append(f"--query={query}")
    result = subprocess.run(
        args,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=None,
        check=False,
    )
    if result.returncode != 0:
        print("No selection.", file=sys.stderr)
        return None
    return result.stdout.rstrip("\n")


def selected_hidden_value(parts: list[str], index: int = 1) -> str | None:
    value = parts[index] if len(parts) > index else ""
    if value == "__id" or not value:
        print("No data row selected.", file=sys.stderr)
        return None
    return value
