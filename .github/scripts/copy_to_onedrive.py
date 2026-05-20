import os
import sys
import requests
from datetime import datetime
from pathlib import Path
import pytz


def get_access_token(client_id: str, refresh_token: str) -> str:
    resp = requests.post(
        "https://login.microsoftonline.com/consumers/oauth2/v2.0/token",
        data={
            "client_id": client_id,
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "scope": "Files.ReadWrite offline_access",
        },
    )
    resp.raise_for_status()
    data = resp.json()
    if "error" in data:
        print(f"Token error: {data}", file=sys.stderr)
        sys.exit(1)
    return data["access_token"]


def list_child_names(access_token: str, parent_path: str) -> list:
    encoded = requests.utils.quote(parent_path, safe="/")
    url = f"https://graph.microsoft.com/v1.0/me/drive/root:/{encoded}:/children"
    headers = {"Authorization": f"Bearer {access_token}"}
    resp = requests.get(url, headers=headers)
    if resp.status_code == 404:
        return []
    resp.raise_for_status()
    return [item["name"] for item in resp.json().get("value", [])]


def unique_folder_name(access_token: str, parent_path: str, base_name: str) -> str:
    existing = set(list_child_names(access_token, parent_path))
    if base_name not in existing:
        return base_name
    suffix = 2
    while f"{base_name}-{suffix}" in existing:
        suffix += 1
    return f"{base_name}-{suffix}"


def upload_file(access_token: str, dest_path: str, local_path: str) -> None:
    file_size = os.path.getsize(local_path)
    encoded = requests.utils.quote(dest_path, safe="/")
    headers = {"Authorization": f"Bearer {access_token}"}

    if file_size <= 4 * 1024 * 1024:
        url = f"https://graph.microsoft.com/v1.0/me/drive/root:/{encoded}:/content"
        with open(local_path, "rb") as f:
            resp = requests.put(url, headers=headers, data=f)
        resp.raise_for_status()
    else:
        session_url = f"https://graph.microsoft.com/v1.0/me/drive/root:/{encoded}:/createUploadSession"
        session_resp = requests.post(session_url, headers=headers, json={})
        session_resp.raise_for_status()
        upload_url = session_resp.json()["uploadUrl"]
        chunk_size = 4 * 1024 * 1024
        with open(local_path, "rb") as f:
            start = 0
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                end = start + len(chunk) - 1
                chunk_headers = {
                    "Content-Length": str(len(chunk)),
                    "Content-Range": f"bytes {start}-{end}/{file_size}",
                }
                r = requests.put(upload_url, headers=chunk_headers, data=chunk)
                if r.status_code not in (200, 201, 202):
                    r.raise_for_status()
                start += len(chunk)


def upload_path(access_token: str, local_path: str, onedrive_dest: str) -> None:
    p = Path(local_path)
    if p.is_file():
        print(f"  Uploading file: {local_path} -> {onedrive_dest}")
        upload_file(access_token, onedrive_dest, local_path)
    elif p.is_dir():
        for item in sorted(p.rglob("*")):
            if item.is_file():
                relative = item.relative_to(p.parent)
                dest = f"{onedrive_dest.rstrip('/')}/{relative}"
                print(f"  Uploading: {item} -> {dest}")
                upload_file(access_token, dest, str(item))
    else:
        print(f"Error: '{local_path}' not found in repository", file=sys.stderr)
        sys.exit(1)


def main():
    client_id = os.environ["AZURE_CLIENT_ID"]
    refresh_token = os.environ["ONEDRIVE_REFRESH_TOKEN"]
    source_path = os.environ["SOURCE_PATH"].strip("/")
    onedrive_parent = os.environ["ONEDRIVE_PARENT"].strip("/")
    tool_name = os.environ["TOOL_NAME"]

    if not source_path or not onedrive_parent or not tool_name:
        print("Error: SOURCE_PATH, ONEDRIVE_PARENT, TOOL_NAME are required", file=sys.stderr)
        sys.exit(1)

    jst = pytz.timezone("Asia/Tokyo")
    date_str = datetime.now(jst).strftime("%Y%m%d")
    base_name = f"{tool_name}_{date_str}"

    print("Getting OneDrive access token...")
    access_token = get_access_token(client_id, refresh_token)

    print(f"Determining unique folder name under '{onedrive_parent}'...")
    folder_name = unique_folder_name(access_token, onedrive_parent, base_name)
    dest_root = f"{onedrive_parent}/{folder_name}"
    print(f"Destination: {dest_root}")

    print(f"Uploading '{source_path}'...")
    upload_path(access_token, source_path, dest_root)

    print(f"\nDone! Copied to OneDrive: {dest_root}")


if __name__ == "__main__":
    main()
