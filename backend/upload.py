import os
from dotenv import load_dotenv
from huggingface_hub import HfApi

# Load environment variables from .env
load_dotenv()

HF_TOKEN = os.getenv("HF_TOKEN")

if not HF_TOKEN:
    print("⚠️  HF_TOKEN not found in environment variables. Please add it to your .env file.")
    exit(1)

api = HfApi()
api.upload_file(
    path_or_fileobj="best_model.h5",
    path_in_repo="best_model.h5",
    repo_id="svr123777/plant-models",
    token=HF_TOKEN,
)
api.upload_file(
    path_or_fileobj="final_soil_model.h5",
    path_in_repo="final_soil_model.h5",
    repo_id="svr123777/plant-models",
    token=HF_TOKEN,
)
print("H5 Models Uploaded!")
