import os
from dotenv import load_dotenv
from huggingface_hub import HfApi

load_dotenv()

api = HfApi()
hf_token = os.getenv("HF_TOKEN")

if not hf_token:
    print("Error: HF_TOKEN not found in environment variables.")
    exit(1)

api.upload_file(
    path_or_fileobj="best_model.h5",
    path_in_repo="best_model.h5",
    repo_id="svr123777/plant-models",
    token=hf_token,
)
api.upload_file(
    path_or_fileobj="final_soil_model.h5",
    path_in_repo="final_soil_model.h5",
    repo_id="svr123777/plant-models",
    token=hf_token,
)
print("H5 Models Uploaded!")
