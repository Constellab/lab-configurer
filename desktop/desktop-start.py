# LICENSE
# This software is the exclusive property of Gencovery SAS.
# The use and distribution of this software is prohibited without the prior consent of Gencovery SAS.
# About us: https://gencovery.com


# This file is use to make an executable file to start the lab on desktop
import os
import sys
import time
import traceback
import webbrowser
from json import load
from typing import TypedDict
import shutil
import requests

application_path: str = None
if getattr(sys, 'frozen', False):
    application_path = os.path.dirname(sys.executable)
elif __file__:
    application_path = os.path.dirname(__file__)

print('AppLication path ', application_path)

BIOTA_ZIP_NAME = os.path.join(application_path, "mariadb.zip")
BIOTA_FOLDER_NAME = os.path.join(application_path, "mariadb")
GLAB_API_URL = "http://localhost:3100"
FRONT_URL = "http://localhost:80"
CONFIG_FILE_PATH = os.path.join(application_path, "config.json")
DOCKER_COMPOSE_FILE_PATH = os.path.join(application_path, "docker-compose.yml")

class Config(TypedDict):
    biota_maria_db_url: str


def check_docker() -> bool:
    res = os.system("docker --version")

    if res != 0:
        print("Docker is not installed or not started. To install docker please follow the instructions at https://www.docker.com/. To start docker search for 'Docker Desktop' in your start menu and click on it.")
        return False
    return True


def download_biota(url: str, destination_path: str) -> str:
    """
    Download a file from a given url to a given file path

    :param url: The url to download the file from
    :type url: `str`
    :param file_path: The path to save the file to
    :type file_path: `str`
    :param headers: The headers to send with the request
    :type headers: `dict`
    """
    if os.path.isfile(destination_path):
        print(f"Biota already downloaded to {destination_path}, skipping download")
        return destination_path

    print(f"Downloading biota database from {url} to {destination_path}")
    started_at = time.time()

    with requests.get(url, stream=True) as request:
        request.raise_for_status()

        with open(destination_path, 'wb') as file:

            if request.headers.get('content-length') is None:
                file.write(request.content)
            else:
                # download the file in chunks with a progress bar
                total_size = int(request.headers.get('content-length'))
                last_progress_logged = 0.0

                # convert a to int and if it fails, use None
                for chunk in request.iter_content(chunk_size=max(int(total_size/1000), 1024*1024)):
                    file.write(chunk)

                    downloaded_size = file.tell()
                    progress = downloaded_size / total_size

                    # if the progress is less than 1% more than the previous log, do not display the progress
                    if progress - last_progress_logged > 0.01:
                        # calculate remaining time
                        remaining_time = (
                            time.time() - started_at) / (downloaded_size / total_size) - (time.time() - started_at)

                        print_progress(total_size, downloaded_size, remaining_time)
                        last_progress_logged = progress

    duration = get_duration_pretty_text(time.time() - started_at)
    print(f"Biota downloaded to {destination_path} in {duration}")

    return destination_path


def unzip_file(zip_file_path: str, unzip_path: str) -> str:
    """
    Unzip a file to a given path

    :param file_path: The path to the file to unzip
    :type file_path: `str`
    :param unzip_path: The path to unzip the file to
    :type unzip_path: `str`
    """

    print(f"Unzipping biota to {unzip_path}, this may take a while...")
    started_at = time.time()

    shutil.unpack_archive(zip_file_path, unzip_path)

    duration = get_duration_pretty_text(time.time() - started_at)
    print(f"Unzipped {zip_file_path} to {unzip_path} in {duration}")

    # delete zip file TODO do we want to do this?
    # os.remove(zip_file_path)

    return unzip_path

def start_lab() -> bool:

    print(f'Executing command : docker compose -f "{DOCKER_COMPOSE_FILE_PATH}" up -d')
    # execute docker compose up -d command
    os.system(f'docker compose -f "{DOCKER_COMPOSE_FILE_PATH}" up -d')

    i = 0

    while i < 30:
        try:
            response = requests.get(f"{GLAB_API_URL}/core-api/health-check")
            if response.status_code == 200:
                print("Lab started successfully")
                return True
        except:
            pass

        print("Lab not started yet, retrying in 10 seconds")
        i += 1
        time.sleep(10)

    print("Lab failed to start, please try again later")
    return False


def print_progress(total: int, downloaded: int, remaining_time: float) -> None:
    """
    Dispatch the progress of the download

    :param total: The total size of the file to download
    :type total: `int`
    :param downloaded: The amount of data downloaded so far
    :type downloaded: `int`
    """
    downloaded_str = get_file_size_pretty_text(downloaded)
    total_str = get_file_size_pretty_text(total)

    remaining_time_str = get_duration_pretty_text(remaining_time)
    print(f"Downloaded {downloaded_str}/{total_str} - {remaining_time_str} remaining")


def get_config() -> Config:
    print('Loading config file...')

    if not os.path.exists(CONFIG_FILE_PATH):
        print(f"Config file ('{CONFIG_FILE_PATH}') not found, please make sure it exists")
        raise FileNotFoundError("Config file not found, please make sure it exists")
    with open(CONFIG_FILE_PATH, 'r', encoding="utf-8") as file:
        try:
            return load(file)
        except Exception as err:
            print("Error loading config file, please make sure it is valid JSON")
            raise err


def get_file_size_pretty_text(size: float) -> str:
    """Get a human readable file size"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB', 'PB']:
        if size < 1024.0:
            return f'{size:.1f} {unit}'
        size /= 1024.0
    return f'{size:.1f} EB'


def get_duration_pretty_text(duration_in_seconds: float) -> str:
    """Return a string representing the duration in a human readable way.
    """
    duration_in_seconds = abs(duration_in_seconds)
    if duration_in_seconds < 60:
        return f'{duration_in_seconds:.0f} secs'

    duration_in_minutes = duration_in_seconds // 60
    if duration_in_minutes < 60:
        rest_in_seconds = duration_in_seconds % 60
        if rest_in_seconds > 0:
            return f'{duration_in_minutes:.0f} mins, {rest_in_seconds:.0f} secs'
        return f'{duration_in_minutes:.0f} mins'

    duration_in_hours = duration_in_minutes / 60
    if duration_in_hours < 24:
        rest_in_minutes = duration_in_minutes % 60
        if rest_in_minutes > 0:
            return f'{duration_in_hours:.0f} hours, {rest_in_minutes:.0f} mins'
        return f'{duration_in_hours:.0f} hours'

    duration_in_days = duration_in_hours / 24
    rest_in_hours = duration_in_hours % 24
    if rest_in_hours > 0:
        return f'{duration_in_days:.0f} days, {rest_in_hours:.0f} hours'
    return f'{duration_in_days:.0f} days'


def run() -> bool:
    try:
      if not check_docker():
          return False
    except Exception:
        return False

    config: Config = None
    try:
        config = get_config()
    except Exception:
        return False

    if "biota_maria_db_url" not in config or not config["biota_maria_db_url"]:
        print("Biota db url not found in config file, skipping installation.")
    elif os.path.exists(BIOTA_FOLDER_NAME):
        print("Biota already installed, skipping installation.")
    else:

        try:
            download_biota(config["biota_maria_db_url"], BIOTA_ZIP_NAME)
        except Exception as err:
            print(f"Error while downloading biota database: {err}")
            print(traceback.format_exc())
            return False

        try:
            unzip_file(BIOTA_ZIP_NAME, application_path)
        except Exception as err:
            print(f"Error while unzipping biota database: {err}")
            print(traceback.format_exc())
            return False

    lab_started: bool = None
    try:
        print("Starting lab")
        # execute docker compose up -d command
        lab_started = start_lab()
    except Exception as err:
        print(f"Error while starting lab: {err}")
        print(traceback.format_exc())

    if lab_started:
        print("Opening lab in browser")
        webbrowser.open(FRONT_URL)

    return lab_started


result = run()

text: str = None
if result:
    text = "The lab is ready to be used, you can press 'q' and enter to close this window ...\n"
else:
    text = "The lab failed to start, you can press 'q' and enter to close this window ...\n"

while True:
    print_result = input(text)
    if print_result in ['q', 'Q', 'quit', 'QUIT']:
        break
