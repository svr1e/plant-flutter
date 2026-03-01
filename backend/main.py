from fastapi import FastAPI, File, UploadFile, HTTPException, Depends, status, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime, timedelta, date
from typing import List, Optional
from pathlib import Path
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from contextlib import asynccontextmanager
import tensorflow as tf
import numpy as np
from PIL import Image
import io
import base64
import os
import json
import asyncio
from dotenv import load_dotenv
import google.generativeai as genai
import http.client
import urllib.parse
import urllib.request
from huggingface_hub import hf_hub_download
from plant_care_models import PlantCare, PlantCareResponse, PlantCareCreate, PlantCareUpdate, ActionRequest, TodayTasksResponse, PlantCareListResponse
from plant_care_service import PlantCareService
from community_models import CommunityPostResponse, CommunityPostCreate, CommunityCommentCreate, CommunityFeedResponse
from community_service import CommunityService

import logging

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("backend.log")
    ]
)
logger = logging.getLogger("plant-diagnosis-api")

# Load environment variables
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

# MongoDB Configuration
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
mongodb_client = None
db = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events"""
    global mongodb_client, db
    try:
        # Optimized MongoDB client with connection pooling
        mongodb_client = AsyncIOMotorClient(
            MONGODB_URL,
            maxPoolSize=50,
            minPoolSize=10,
            maxIdleTimeMS=60000,
            connectTimeoutMS=5000,
            serverSelectionTimeoutMS=5000
        )
        db = mongodb_client.plant_diagnosis
        # Test connection
        await mongodb_client.admin.command('ping')
        logger.info("✅ Connected to MongoDB successfully")
        
        # Ensure indexes exist for faster queries
        await db.users.create_index("username", unique=True)
        await db.users.create_index("email", unique=True)
        logger.info("✅ Database indexes verified")
    except Exception as e:
        logger.error(f"⚠️  MongoDB connection failed: {e}")
        logger.warning("History features will be disabled")
        db = None
    
    yield
    
    # Shutdown logic
    if mongodb_client:
        mongodb_client.close()
        logger.info("🛑 MongoDB connection closed")

app = FastAPI(title="Plant Disease Diagnosis API", lifespan=lifespan)

@app.get("/")
async def root():
    return {"status": "Backend Running"}

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Gemini / Groq API Configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel('gemini-2.5-flash')
else:
    gemini_model = None
    print("⚠️  Gemini API key not configured. AI insights will be disabled.")

GROQ_API_KEY = os.getenv("GROQ_API_KEY")

# Weatherstack API Configuration
WEATHERSTACK_API_KEY = os.getenv("WEATHERSTACK_API_KEY")

# Auth Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here") # Change this in production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30 * 24 * 60 # 30 days for mobile apps

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# User Models
class User(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None
    disabled: Optional[bool] = None

class UserInDB(User):
    hashed_password: str

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    full_name: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

# Helper Functions
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    
    user_dict = await db.users.find_one({"username": token_data.username})
    if user_dict is None:
        raise credentials_exception
    return User(**user_dict)

def generate_with_groq(system_prompt: str, user_prompt: str) -> Optional[str]:
    if not GROQ_API_KEY:
        return None
    try:
        conn = http.client.HTTPSConnection("api.groq.com")
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json",
        }
        body = json.dumps(
            {
                "model": "llama-3.3-70b-versatile",
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "temperature": 0.7,
            }
        )
        conn.request("POST", "/openai/v1/chat/completions", body, headers)
        res = conn.getresponse()
        data = res.read()
        if res.status != 200:
            logger.error(f"Groq API error: {res.status} {data.decode(errors='ignore')}")
            return None
        parsed = json.loads(data.decode())
        choices = parsed.get("choices") or []
        if not choices:
            return None
        message = choices[0].get("message") or {}
        content = message.get("content")
        if isinstance(content, list):
            parts = []
            for part in content:
                if isinstance(part, dict) and isinstance(part.get("text"), str):
                    parts.append(part["text"])
            content = "\n".join(parts)
        return content
    except Exception as e:
        logger.error(f"Groq API exception: {e}")
        return None

# ── Model download from Hugging Face ──────────────────────────────────────────
HF_MODEL_REPO       = os.getenv("HF_MODEL_REPO")          # e.g. "svr1e/plant-models"
HF_PLANT_MODEL_FILE = os.getenv("HF_PLANT_MODEL_FILE", "best_model.h5")
HF_SOIL_MODEL_FILE  = os.getenv("HF_SOIL_MODEL_FILE",  "final_soil_model.h5")

def download_model_if_needed(filename: str) -> Optional[str]:
    """Download a model file from Hugging Face if it doesn't exist locally."""
    local_path = BASE_DIR / filename
    if local_path.exists():
        logger.info(f"✅ Model already present: {filename}")
        return str(local_path)
    if not HF_MODEL_REPO:
        logger.warning(f"⚠️  HF_MODEL_REPO not set — cannot download {filename}")
        return None
    try:
        logger.info(f"⬇️  Downloading {filename} from Hugging Face repo '{HF_MODEL_REPO}'...")
        downloaded = hf_hub_download(
            repo_id=HF_MODEL_REPO,
            filename=filename,
            local_dir=str(BASE_DIR),
        )
        logger.info(f"✅ Downloaded {filename} → {downloaded}")
        return downloaded
    except Exception as e:
        logger.error(f"⚠️  Failed to download {filename}: {e}")
        return None

# Load TensorFlow models (downloads from HF if not present)
model = None
model_load_error = None
try:
    plant_model_path = download_model_if_needed(HF_PLANT_MODEL_FILE)
    if plant_model_path:
        model = tf.keras.models.load_model(plant_model_path)
        logger.info("✅ Loaded plant disease model")
    else:
        logger.warning("⚠️  Plant disease model unavailable — /predict will return 503")
except Exception as e:
    import traceback
    model_load_error = traceback.format_exc()
    logger.error(f"⚠️  Plant disease model load failed: {e}")
    model = None

soil_model_error = None
soil_model = None
try:
    soil_model_path = download_model_if_needed(HF_SOIL_MODEL_FILE)
    if soil_model_path:
        soil_model = tf.keras.models.load_model(soil_model_path)
        logger.info("✅ Loaded soil model")
    else:
        logger.warning("⚠️  Soil model unavailable — /soil/predict will return 503")
except Exception as e:
    import traceback
    soil_model_error = traceback.format_exc()
    logger.error(f"⚠️  Soil model load failed: {e}")
    soil_model = None

# Comprehensive class labels for plant diseases
CLASS_LABELS = {
    0: "Apple___Apple_scab",
    1: "Apple___Black_rot",
    2: "Apple___Cedar_apple_rust",
    3: "Apple___healthy",
    4: "Blueberry___healthy",
    5: "Cherry_(including_sour)___Powdery_mildew",
    6: "Cherry_(including_sour)___healthy",
    7: "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot",
    8: "Corn_(maize)___Common_rust_",
    9: "Corn_(maize)___Northern_Leaf_Blight",
    10: "Corn_(maize)___healthy",
    11: "Grape___Black_rot",
    12: "Grape___Esca_(Black_Measles)",
    13: "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)",
    14: "Grape___healthy",
    15: "Orange___Haunglongbing_(Citrus_greening)",
    16: "Peach___Bacterial_spot",
    17: "Peach___healthy",
    18: "Pepper,_bell___Bacterial_spot",
    19: "Pepper,_bell___healthy",
    20: "Potato___Early_blight",
    21: "Potato___Late_blight",
    22: "Potato___healthy",
    23: "Raspberry___healthy",
    24: "Soybean___healthy",
    25: "Squash___Powdery_mildew",
    26: "Strawberry___Leaf_scorch",
    27: "Strawberry___healthy",
    28: "Tomato___Bacterial_spot",
    29: "Tomato___Early_blight",
    30: "Tomato___Late_blight",
    31: "Tomato___Leaf_Mold",
    32: "Tomato___Septoria_leaf_spot",
    33: "Tomato___Spider_mites Two-spotted_spider_mite",
    34: "Tomato___Target_Spot",
    35: "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
    36: "Tomato___Tomato_mosaic_virus",
    37: "Tomato___healthy"
}

# Disease information database
DISEASE_INFO = {
    "healthy": {
        "symptoms": "No visible signs of disease. Plant appears vigorous and green.",
        "treatment": "Continue regular care and monitoring.",
        "prevention": "Maintain good cultural practices, proper watering, and fertilization."
    },
    "Apple_scab": {
        "symptoms": "Olive-green to brown spots on leaves and fruit, leaf distortion.",
        "treatment": "Remove infected leaves, apply fungicides like captan or myclobutanil.",
        "prevention": "Plant resistant varieties, ensure good air circulation, remove fallen leaves."
    },
    "Black_rot": {
        "symptoms": "Purple spots on leaves, brown rotted areas on fruit, cankers on branches.",
        "treatment": "Prune infected branches, apply fungicides during growing season.",
        "prevention": "Remove mummified fruit, prune for air circulation, apply preventive fungicides."
    },
    "Cedar_apple_rust": {
        "symptoms": "Yellow-orange spots on leaves, premature leaf drop.",
        "treatment": "Apply fungicides in spring, remove nearby cedar trees if possible.",
        "prevention": "Plant resistant varieties, remove cedar hosts within 2 miles."
    },
    "Powdery_mildew": {
        "symptoms": "White powdery coating on leaves, stunted growth.",
        "treatment": "Apply sulfur or potassium bicarbonate sprays, neem oil.",
        "prevention": "Ensure good air circulation, avoid overhead watering, plant in sunny locations."
    },
    "Cercospora_leaf_spot": {
        "symptoms": "Small circular spots with gray centers and dark borders.",
        "treatment": "Apply fungicides containing chlorothalonil or mancozeb.",
        "prevention": "Crop rotation, remove plant debris, use resistant varieties."
    },
    "Common_rust": {
        "symptoms": "Small, circular to elongate brown pustules on leaves.",
        "treatment": "Apply fungicides if severe, usually not economically damaging.",
        "prevention": "Plant resistant hybrids, ensure good field drainage."
    },
    "Northern_Leaf_Blight": {
        "symptoms": "Long, elliptical gray-green lesions on leaves.",
        "treatment": "Apply fungicides at first sign, remove infected plant debris.",
        "prevention": "Use resistant hybrids, crop rotation, tillage to bury debris."
    },
    "Esca": {
        "symptoms": "Tiger-stripe pattern on leaves, berry shrivel, wood decay.",
        "treatment": "No cure available, prune infected wood, trunk surgery in severe cases.",
        "prevention": "Avoid pruning wounds, use protective pruning paste, maintain vine vigor."
    },
    "Leaf_blight": {
        "symptoms": "Brown spots with yellow halos, premature defoliation.",
        "treatment": "Apply copper-based fungicides, remove infected leaves.",
        "prevention": "Improve air circulation, avoid overhead irrigation, sanitation."
    },
    "Haunglongbing": {
        "symptoms": "Yellow shoots, blotchy mottled leaves, lopsided bitter fruit.",
        "treatment": "No cure - remove infected trees to prevent spread.",
        "prevention": "Control psyllid vectors, use certified disease-free nursery stock."
    },
    "Bacterial_spot": {
        "symptoms": "Small dark spots on leaves and fruit, yellow halos.",
        "treatment": "Apply copper-based bactericides, remove severely infected plants.",
        "prevention": "Use disease-free seeds, crop rotation, avoid overhead watering."
    },
    "Early_blight": {
        "symptoms": "Dark concentric rings on older leaves, target-like pattern.",
        "treatment": "Apply fungicides containing chlorothalonil or mancozeb.",
        "prevention": "Crop rotation, mulching, remove infected plant debris, resistant varieties."
    },
    "Late_blight": {
        "symptoms": "Water-soaked spots on leaves, white mold on undersides, rapid plant death.",
        "treatment": "Apply fungicides immediately, remove infected plants.",
        "prevention": "Use resistant varieties, avoid overhead irrigation, ensure good drainage."
    },
    "Leaf_Mold": {
        "symptoms": "Yellow spots on upper leaf surface, olive-green mold underneath.",
        "treatment": "Improve ventilation, apply fungicides, remove infected leaves.",
        "prevention": "Reduce humidity, increase spacing, use resistant varieties."
    },
    "Septoria_leaf_spot": {
        "symptoms": "Small circular spots with gray centers and dark borders.",
        "treatment": "Apply fungicides, remove lower infected leaves.",
        "prevention": "Mulch around plants, avoid overhead watering, crop rotation."
    },
    "Spider_mites": {
        "symptoms": "Tiny yellow spots on leaves, fine webbing, leaf bronzing.",
        "treatment": "Apply miticides or insecticidal soap, spray with water.",
        "prevention": "Maintain plant health, avoid water stress, encourage natural predators."
    },
    "Target_Spot": {
        "symptoms": "Brown spots with concentric rings on leaves and fruit.",
        "treatment": "Apply fungicides, remove infected plant parts.",
        "prevention": "Crop rotation, avoid overhead irrigation, plant spacing."
    },
    "Yellow_Leaf_Curl_Virus": {
        "symptoms": "Upward leaf curling, yellowing, stunted growth.",
        "treatment": "No cure - remove infected plants, control whitefly vectors.",
        "prevention": "Use resistant varieties, control whiteflies, use reflective mulches."
    },
    "Tomato_mosaic_virus": {
        "symptoms": "Mottled light and dark green on leaves, distorted growth.",
        "treatment": "No cure - remove infected plants to prevent spread.",
        "prevention": "Use resistant varieties, sanitize tools, avoid tobacco use near plants."
    },
    "Leaf_scorch": {
        "symptoms": "Purple to brown spots on leaves, scorched appearance.",
        "treatment": "Remove infected leaves, apply fungicides.",
        "prevention": "Avoid overhead watering, ensure good air circulation, mulch."
    }
}


# Soil labels
def _load_soil_labels():
    labels_path = BASE_DIR / "soil_labels.json"
    print(f"DEBUG: Loading soil labels from {labels_path}")
    
    # 1. Try loading from file
    try:
        if labels_path.exists():
            with open(labels_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    res = {int(k): v for k, v in data.items()}
                    print(f"✅ Loaded {len(res)} soil labels from JSON dict")
                    return res
                if isinstance(data, list):
                    res = {i: v for i, v in enumerate(data)}
                    print(f"✅ Loaded {len(res)} soil labels from JSON list")
                    return res
    except Exception as e:
        print(f"⚠️  Failed to load soil labels: {e}")

    # 2. Predefined common soil names
    common_soil_names = [
        "Alluvial Soil", 
        "Black Soil", 
        "Clay Soil", 
        "Red Soil", 
        "Sandy Soil", 
        "Loamy Soil", 
        "Silty Soil",
        "Peaty Soil",
        "Chalky Soil"
    ]

    # 3. Infer number of classes from model and map to names
    try:
        if soil_model is not None:
            dummy = np.zeros((1, 224, 224, 3), dtype=np.float32)
            out = soil_model.predict(dummy, verbose=0)
            num_classes = int(out.shape[-1]) if hasattr(out, "shape") else 0
            
            if num_classes > 0:
                labels = {}
                for i in range(num_classes):
                    if i < len(common_soil_names):
                        labels[i] = common_soil_names[i]
                    else:
                        labels[i] = f"Soil_Type_{i}"
                print(f"✅ Inferred {num_classes} soil classes from model")
                return labels
    except Exception as e:
        print(f"⚠️  Failed to infer soil labels from model: {e}")

    # Final fallback
    res = {i: name for i, name in enumerate(common_soil_names[:6])}
    print(f"ℹ️  Using default fallback soil labels: {res}")
    return res

SOIL_CLASS_LABELS = _load_soil_labels()



def get_disease_info(class_name: str):
    """Extract disease information from class name"""
    parts = class_name.split("___")
    plant = parts[0].replace("_", " ")
    
    if len(parts) > 1:
        disease = parts[1].replace("_", " ")
    else:
        disease = "healthy"
    
    # Find matching disease info
    disease_key = None
    search_term = disease.lower().replace(" ", "_")
    for key in DISEASE_INFO.keys():
        if key.lower() in search_term:
            disease_key = key
            break
    
    if disease_key:
        info = DISEASE_INFO[disease_key]
    else:
        info = {
            "symptoms": "Information not available",
            "treatment": "Consult with a local agricultural extension service",
            "prevention": "Follow general plant health practices"
        }
    
    return {
        "plant": plant,
        "disease": disease,
        "is_healthy": "healthy" in disease.lower(),
        **info
    }


async def get_treatment_guide_from_ai(plant: str, disease: str):
    prompt = f"""
You are a plant pathology expert.
Create a JSON object describing management for {plant} affected by {disease}.
The JSON must have exactly these string fields:
- "symptoms"
- "chemical_treatment"
- "organic_remedy"
- "prevention_tips"
Each value should be 2-4 sentences. Respond with JSON only.
"""
    data = None
    if gemini_model:
        try:
            # Add timeout to Gemini call
            response = await asyncio.wait_for(
                gemini_model.generate_content_async(prompt),
                timeout=25.0
            )
            text = response.text.strip()
            # Handle potential markdown code blocks
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0].strip()
            elif "```" in text:
                text = text.split("```")[1].split("```")[0].strip()

            start = text.find("{")
            end = text.rfind("}")
            if start != -1 and end != -1 and end > start:
                text = text[start:end + 1]
            data = json.loads(text)
        except asyncio.TimeoutError:
            logger.warning(f"Gemini treatment guide timeout for {plant} {disease}")
            data = None
        except Exception as e:
            logger.error(f"Gemini treatment guide error: {e}")
            data = None
    
    if data is None:
        try:
            # For Groq, we wrap the sync call in a thread to use wait_for
            loop = asyncio.get_event_loop()
            groq_text = await asyncio.wait_for(
                loop.run_in_executor(
                    None, 
                    generate_with_groq, 
                    "You are a plant pathology expert that returns pure JSON.", 
                    prompt
                ),
                timeout=20.0
            )
            if groq_text:
                text = groq_text.strip()
                start = text.find("{")
                end = text.rfind("}")
                if start != -1 and end != -1 and end > start:
                    text = text[start:end + 1]
                try:
                    data = json.loads(text)
                except Exception as e:
                    print(f"Groq treatment guide JSON parse error: {e}")
                    data = None
        except asyncio.TimeoutError:
            print(f"Groq treatment guide timeout for {plant} {disease}")
            data = None
        except Exception as e:
            print(f"Groq treatment guide exception: {e}")
            data = None
            
    if not data or not isinstance(data, dict):
        return None
    return {
        "symptoms": data.get("symptoms"),
        "chemical_treatment": data.get("chemical_treatment"),
        "organic_remedy": data.get("organic_remedy"),
        "prevention_tips": data.get("prevention_tips"),
    }

async def get_ai_summary_report(plant: str, disease: str, confidence: float):
    confidence_pct = round(confidence * 100, 1)
    prompt = f"""
You are an agricultural assistant.

A plant disease has been detected:

Disease Name: {disease}
Confidence Score: {confidence_pct}%
Plant Type: {plant}

Generate a concise recovery report for a home gardener.

Keep explanations short (2–4 sentences per section).
Be practical and beginner-friendly.
Avoid technical language.
Do not mention AI models.
Keep total response under 500 words.

Return ONLY a single JSON object with this exact structure:

{{
  "diagnosis_summary": {{
    "text": "Short explanation of disease, cause, and spread."
  }},
  "risk_assessment": {{
    "severity_level": "Mild | Moderate | Severe",
    "estimated_crop_damage_percent": 0,
    "immediate_action_required": true,
    "details": "Brief risk explanation."
  }},
  "chemical_treatment": {{
    "summary": "Short treatment overview.",
    "pesticide_name": "Common product name.",
    "dosage_guidance": "General safe guidance.",
    "application_frequency": "How often to apply.",
    "safety_precautions": "Basic precautions."
  }},
  "organic_remedies": {{
    "summary": "Short organic approach overview.",
    "methods": ["Method 1", "Method 2"],
    "when_to_use_organic_vs_chemical": "When each approach is suitable."
  }},
  "prevention_plan": {{
    "watering": "Short guidance.",
    "sunlight": "Short guidance.",
    "soil_and_spacing": "Short guidance.",
    "crop_rotation": "Short guidance."
  }},
  "recovery_timeline": {{
    "timeline": "Estimated recovery time.",
    "signs_of_recovery": "What improvements to look for."
  }},
  "product_search_keywords": ["keyword 1", "keyword 2"],
  "full_report": "Compact formatted summary for display."
}}

Respond with JSON only.
No extra text.
"""
    data = None
    raw_text = None
    if gemini_model:
        try:
            # Add timeout to Gemini call
            response = await asyncio.wait_for(
                gemini_model.generate_content_async(prompt),
                timeout=25.0
            )
            text = response.text.strip()
            # Handle potential markdown code blocks
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0].strip()
            elif "```" in text:
                text = text.split("```")[1].split("```")[0].strip()

            raw_text = text
            start = text.find("{")
            end = text.rfind("}")
            if start != -1 and end != -1 and end > start:
                text = text[start:end + 1]
            try:
                parsed = json.loads(text)
                if isinstance(parsed, dict):
                    data = parsed
            except Exception:
                logger.error("Gemini AI summary JSON parse error, falling back to raw text")
        except asyncio.TimeoutError:
            logger.warning(f"Gemini AI summary timeout for {plant} {disease}")
            data = None
        except Exception as e:
            logger.error(f"Gemini AI summary error: {e}")
            data = None
            
    if data is None:
        try:
            loop = asyncio.get_event_loop()
            groq_text = await asyncio.wait_for(
                loop.run_in_executor(
                    None, 
                    generate_with_groq, 
                    "You are an expert agricultural AI assistant that returns structured JSON.", 
                    prompt
                ),
                timeout=20.0
            )
            if groq_text:
                text = groq_text.strip()
                raw_text = text
                start = text.find("{")
                end = text.rfind("}")
                if start != -1 and end != -1 and end > start:
                    text = text[start:end + 1]
                try:
                    parsed = json.loads(text)
                    if isinstance(parsed, dict):
                        data = parsed
                except Exception as e:
                    print(f"Groq AI summary JSON parse error: {e}")
                    data = None
        except asyncio.TimeoutError:
            print(f"Groq AI summary timeout for {plant} {disease}")
            data = None
        except Exception as e:
            print(f"Groq AI summary exception: {e}")
            data = None
            
    if data is None:
        if raw_text:
            return {"full_report": raw_text}
        return None
    if not data.get("full_report") and raw_text:
        data["full_report"] = raw_text
    return data

async def get_gemini_insights(plant: str, disease: str, is_healthy: bool, confidence: float):
    """Get enhanced insights from Gemini AI"""
    if not gemini_model:
        return None
    
    try:
        if is_healthy:
            prompt = f"""As a plant health expert, provide brief care tips for a healthy {plant} plant.
            Include:
            1. Optimal growing conditions
            2. Fertilization schedule
            3. Common preventive measures
            Keep it concise (3-4 sentences)."""
        else:
            prompt = f"""As a plant pathology expert, provide detailed advice for {plant} affected by {disease}.
            The diagnosis confidence is {confidence:.1%}.
            Include:
            1. Severity assessment
            2. Immediate action steps
            3. Long-term management strategy
            4. When to seek professional help
            Keep it practical and actionable (4-5 sentences)."""
        
        response = await asyncio.wait_for(
            gemini_model.generate_content_async(prompt),
            timeout=20.0
        )
        return response.text
    except asyncio.TimeoutError:
        logger.warning(f"Gemini insights timeout for {plant} {disease}")
        return None
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        return None

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "message": "Plant Disease Diagnosis API is running",
        "version": "2.0.0",
        "features": {
            "mongodb": db is not None,
            "gemini_ai": gemini_model is not None
        }
    }

@app.get("/debug-models")
async def debug_models():
    """Return errors describing why models failed to load"""
    return {
        "plant_model_is_loaded": model is not None,
        "plant_model_error": model_load_error,
        "soil_model_is_loaded": soil_model is not None,
        "soil_model_error": soil_model_error,
        "hf_model_repo": HF_MODEL_REPO
    }

# Authentication Routes
@app.post("/signup", response_model=User)
async def signup(user: UserCreate):
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        # Check if user already exists
        existing_user = await db.users.find_one({"$or": [{"username": user.username}, {"email": user.email}]})
        if existing_user:
            raise HTTPException(
                status_code=400,
                detail="Username or email already registered"
            )
        
        user_in_db = {
            "username": user.username,
            "email": str(user.email),
            "full_name": user.full_name,
            "hashed_password": get_password_hash(user.password),
            "disabled": False,
            "created_at": datetime.utcnow()
        }
        
        await db.users.insert_one(user_in_db)
        return User(**user_in_db)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Signup failed for {user.username}: {e}")
        raise HTTPException(status_code=500, detail="Registration failed")

@app.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    user_dict = await db.users.find_one({"username": form_data.username})
    if not user_dict or not verify_password(form_data.password, user_dict["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_dict["username"]}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=User)
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

@app.get("/classes")
async def get_classes():
    """Get all available disease classes"""
    return {
        "total_classes": len(CLASS_LABELS),
        "classes": CLASS_LABELS
    }


@app.get("/treatment-guide")
async def treatment_guide(disease: str, plant: Optional[str] = None):
    """Get detailed treatment guide for a disease"""
    try:
        if plant:
            class_name = f"{plant.replace(' ', '_')}___{disease.replace(' ', '_')}"
        else:
            class_name = disease
        
        base_info = get_disease_info(class_name)
        
        ai_data = await get_treatment_guide_from_ai(
            base_info["plant"],
            base_info["disease"],
        )
        
        if ai_data:
            symptoms = ai_data.get("symptoms") or base_info["symptoms"]
            chemical_treatment = ai_data.get("chemical_treatment") or base_info["treatment"]
            organic_remedy = ai_data.get("organic_remedy") or base_info["prevention"]
            prevention_tips = ai_data.get("prevention_tips") or base_info["prevention"]
        else:
            symptoms = base_info["symptoms"]
            chemical_treatment = base_info["treatment"]
            organic_remedy = base_info["prevention"]
            prevention_tips = base_info["prevention"]
        
        return {
            "success": True,
            "plant": base_info["plant"],
            "disease": base_info["disease"],
            "symptoms": symptoms,
            "chemical_treatment": chemical_treatment,
            "organic_remedy": organic_remedy,
            "prevention_tips": prevention_tips,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get treatment guide: {str(e)}")

@app.post("/predict")
async def predict(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    """
    Predict plant disease from uploaded image
    
    Args:
        file: Image file (JPG, PNG, etc.)
    
    Returns:
        Prediction results with disease information and AI insights
    """
    try:
        if model is None:
            # Fallback: Try to use Gemini for prediction if model is not loaded
            if gemini_model:
                logger.info("⚠️ Model missing. Falling back to Gemini for prediction...")
                try:
                    # Read image contents
                    contents = await file.read()
                    image = Image.open(io.BytesIO(contents))
                    
                    # Generate content with Gemini
                    response = await gemini_model.generate_content_async([
                        "Identify the plant and the disease in this image. Respond with a JSON object containing 'plant', 'disease', and 'confidence' (0.0 to 1.0).",
                        image
                    ])
                    
                    text = response.text.strip()
                    # Basic JSON extraction
                    start = text.find("{")
                    end = text.rfind("}")
                    if start != -1 and end != -1:
                        data = json.loads(text[start:end+1])
                        plant = data.get("plant", "Unknown")
                        disease = data.get("disease", "Unknown")
                        confidence = data.get("confidence", 0.9)
                        
                        return {
                            "plant": plant,
                            "disease": disease,
                            "confidence": confidence,
                            "is_healthy": "healthy" in disease.lower(),
                            "source": "AI_FALLBACK"
                        }
                except Exception as e:
                    logger.error(f"Gemini fallback failed: {e}")
            
            raise HTTPException(status_code=503, detail="Plant disease model not available on server")

        # Read image contents first to validate with PIL
        contents = await file.read()
        
        # Validate file type - be more robust
        # Check if content type is provided and valid
        is_image = False
        if file.content_type and file.content_type.startswith("image/"):
            is_image = True
        
        # Try opening with PIL as the ultimate test
        try:
            image = Image.open(io.BytesIO(contents))
            is_image = True # PIL successfully opened it
        except Exception:
            if not is_image:
                raise HTTPException(
                    status_code=400,
                    detail="File must be an image (JPEG, PNG, etc.)"
                )
        
        if not is_image:
            raise HTTPException(
                status_code=400,
                detail="File must be an image (JPEG, PNG, etc.)"
            )
        
        # Process image
        try:
            # Convert to RGB if necessary
            if image.mode != "RGB":
                image = image.convert("RGB")
            
            # Resize to model input size
            image_resized = image.resize((224, 224))
            
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid image file: {str(e)}"
            )
        
        # Prepare image for prediction
        img_array = np.array(image_resized)
        img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)
        img_array = np.expand_dims(img_array, axis=0)
        
        # Make prediction
        prediction = model.predict(img_array, verbose=0)
        predicted_class_idx = int(np.argmax(prediction))
        confidence = float(np.max(prediction))
        
        # Get class name
        class_name = CLASS_LABELS.get(predicted_class_idx, "Unknown")
        
        # Get disease information
        disease_info = get_disease_info(class_name)
        
        # Get top 3 predictions
        top_3_indices = np.argsort(prediction[0])[-3:][::-1]
        top_predictions = [
            {
                "class": CLASS_LABELS.get(int(idx), "Unknown"),
                "confidence": float(prediction[0][idx])
            }
            for idx in top_3_indices
        ]
        
        ai_summary = await get_ai_summary_report(
            disease_info["plant"],
            disease_info["disease"],
            confidence
        )
        
        if ai_summary and isinstance(ai_summary, dict):
            ai_insights = ai_summary.get("full_report")
        else:
            ai_insights = None
        
        # Convert image to base64 for storage
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        image_base64 = base64.b64encode(buffered.getvalue()).decode()
        
        result = {
            "success": True,
            "prediction": {
                "class_index": predicted_class_idx,
                "class_name": class_name,
                "confidence": confidence,
                "confidence_percentage": round(confidence * 100, 2)
            },
            "disease_info": disease_info,
            "top_predictions": top_predictions,
            "ai_insights": ai_insights,
            "ai_summary": ai_summary,
            "filename": file.filename,
            "image_data": image_base64,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prediction failed for {current_user.username}: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error during prediction"
        )

def _fetch_weather_summary(lat: float, lon: float):
    try:
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=90)
        params = {
            "latitude": lat,
            "longitude": lon,
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "daily": "temperature_2m_mean,precipitation_sum",
            "timezone": "auto",
        }
        url = "https://archive-api.open-meteo.com/v1/era5?" + urllib.parse.urlencode(params)
        with urllib.request.urlopen(url, timeout=10) as resp:
            data = json.loads(resp.read().decode())
        temps = data.get("daily", {}).get("temperature_2m_mean") or []
        precs = data.get("daily", {}).get("precipitation_sum") or []
        if not temps or not precs:
            return None
        avg_temp = float(np.mean(temps))
        total_prec = float(np.sum(precs))
        aridity = "dry" if total_prec < 100 else "moderate" if total_prec < 250 else "wet"
        return {
            "avg_temperature_c": round(avg_temp, 2),
            "total_precipitation_mm": round(total_prec, 2),
            "aridity": aridity,
            "period_days": 90,
        }
    except Exception as e:
        logger.error(f"⚠️  Weather fetch failed: {e}")
        return None

def _fallback_crop_recommendations(soil: str, weather: Optional[dict]):
    soil_key = soil.lower()
    base = []
    if "loam" in soil_key:
        base = ["Tomato", "Corn", "Wheat", "Beans", "Sunflower"]
    elif "clay" in soil_key:
        base = ["Rice", "Broccoli", "Cabbage", "Wheat"]
    elif "sand" in soil_key or "sandy" in soil_key:
        base = ["Peanuts", "Watermelon", "Carrot", "Sweet Potato"]
    elif "silt" in soil_key or "silty" in soil_key:
        base = ["Soybean", "Cucumber", "Onion", "Potato"]
    elif "peat" in soil_key or "peaty" in soil_key:
        base = ["Cranberry", "Blueberry", "Potato"]
    elif "chalk" in soil_key or "chalky" in soil_key:
        base = ["Barley", "Beetroot", "Cabbage"]
    else:
        base = ["Maize", "Sorghum", "Cassava"]
    if weather:
        t = weather.get("avg_temperature_c", 20)
        ar = weather.get("aridity", "moderate")
        if t < 15:
            base = [c for c in base if c not in ["Watermelon", "Tomato"]]
            base = base + ["Pea", "Spinach"]
        if ar == "dry":
            base = [c for c in base if c not in ["Rice", "Cucumber"]]
            base = base + ["Millet"]
        if ar == "wet":
            base = base + ["Rice"]
    seen = set()
    uniq = []
    for c in base:
        if c not in seen:
            uniq.append(c)
            seen.add(c)
    out = [{"crop": c, "reason": f"Suited for {soil} and recent conditions"} for c in uniq[:6]]
    return out

@app.get("/weather/alerts")
async def get_weather_alerts(lat: float, lon: float, current_user: User = Depends(get_current_user)):
    """
    Get weather alerts and recommendations based on current weather from Weatherstack
    """
    if not WEATHERSTACK_API_KEY:
        raise HTTPException(status_code=503, detail="Weather API not configured")
    
    try:
        # 1. Fetch current weather from Weatherstack
        query = f"{lat},{lon}"
        url = f"http://api.weatherstack.com/current?access_key={WEATHERSTACK_API_KEY}&query={urllib.parse.quote(query)}"
        
        with urllib.request.urlopen(url, timeout=10) as resp:
            data = json.loads(resp.read().decode())
        
        if not data or "current" not in data:
            error_msg = data.get("error", {}).get("info", "Unknown weather API error")
            logger.error(f"Weatherstack error: {error_msg}")
            return {"success": False, "message": "Could not fetch weather data"}

        current = data["current"]
        temp = current.get("temperature", 25)
        precip = current.get("precip", 0)
        weather_desc = current.get("weather_descriptions", ["Clear"])[0]
        humidity = current.get("humidity", 50)
        
        alerts = []
        recommendations = []
        
        # 2. Generate Alerts & Recommendations
        # Frost Warning
        if temp <= 2:
            alerts.append({
                "type": "frost",
                "title": "Frost Warning ❄️",
                "message": f"Temperature is {temp}°C. Protect sensitive plants from frost tonight.",
                "severity": "high"
            })
            recommendations.append("Cover sensitive plants with frost blankets or move them indoors.")
        
        # Heat Stress
        elif temp >= 35:
            alerts.append({
                "type": "heat",
                "title": "Heat Stress Alert ☀️",
                "message": f"High temperature of {temp}°C detected. Your plants may need extra care.",
                "severity": "high"
            })
            recommendations.append("Water your plants early in the morning or late in the evening.")
            recommendations.append("Consider providing temporary shade for young or sensitive plants.")
        
        # Rain Prediction/Current Rain
        if precip > 0:
            alerts.append({
                "type": "rain",
                "title": "Rain Alert 🌧",
                "message": f"Rain detected ({precip}mm). Natural watering in progress.",
                "severity": "info"
            })
            recommendations.append("You may skip manual watering today if soil is sufficiently moist.")
            recommendations.append("Check for proper drainage to prevent waterlogging.")
        
        # High Humidity (Fungal risk)
        if humidity > 85:
            alerts.append({
                "type": "humidity",
                "title": "High Humidity 🌫️",
                "message": f"Humidity is {humidity}%. Higher risk of fungal diseases.",
                "severity": "medium"
            })
            recommendations.append("Ensure good air circulation between plants.")
            recommendations.append("Avoid overhead watering to keep foliage dry.")

        # Default recommendation if no alerts
        if not recommendations:
            if temp > 25:
                recommendations.append("Regular watering is recommended during this warm weather.")
            else:
                recommendations.append("Conditions are favorable for plant growth. Continue regular monitoring.")

        return {
            "success": True,
            "weather": {
                "temp": temp,
                "description": weather_desc,
                "humidity": humidity,
                "precip": precip,
                "location": data.get("location", {}).get("name", "Unknown")
            },
            "alerts": alerts,
            "recommendations": recommendations,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Weather alert error: {e}")
        return {"success": False, "message": str(e)}

@app.post("/soil/predict")
async def soil_predict(
    file: UploadFile = File(...),
    lat: Optional[float] = Form(None),
    lon: Optional[float] = Form(None),
    current_user: User = Depends(get_current_user),
):
    """
    Predict soil type/properties from an uploaded image using the soil model.
    """
    if soil_model is None:
        raise HTTPException(status_code=503, detail="Soil model not available on server")
    try:
        contents = await file.read()
        is_image = False
        if file.content_type and file.content_type.startswith("image/"):
            is_image = True
        try:
            image = Image.open(io.BytesIO(contents))
            is_image = True
        except Exception:
            if not is_image:
                raise HTTPException(
                    status_code=400,
                    detail="File must be an image (JPEG, PNG, etc.)"
                )
        if not is_image:
            raise HTTPException(
                status_code=400,
                detail="File must be an image (JPEG, PNG, etc.)"
            )
        # Preprocess
        if image.mode != "RGB":
            image = image.convert("RGB")
        image_resized = image.resize((224, 224))
        img_array = np.array(image_resized).astype(np.float32)
        # Try MobileNet preprocessing; if model expects raw [0,1], this is generally safe
        try:
            img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)
        except Exception:
            img_array = img_array / 255.0
        img_array = np.expand_dims(img_array, axis=0)
        # Predict
        prediction = soil_model.predict(img_array, verbose=0)
        if isinstance(prediction, list):
            prediction = prediction[0]
        predicted_class_idx = int(np.argmax(prediction))
        confidence = float(np.max(prediction))
        class_name = SOIL_CLASS_LABELS.get(predicted_class_idx, f"Unknown_Soil_{predicted_class_idx}")
        # Top predictions
        probs = prediction[0] if prediction.ndim == 2 else prediction
        top_k = np.argsort(probs)[-3:][::-1]
        top_predictions = [
            {
                "class": SOIL_CLASS_LABELS.get(int(idx), f"Unknown_Soil_{int(idx)}"),
                "confidence": float(probs[int(idx)]),
            }
            for idx in top_k
        ]
        # image base64 for clients that display it
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        image_base64 = base64.b64encode(buffered.getvalue()).decode()
        weather_summary = None
        if lat is not None and lon is not None:
            weather_summary = _fetch_weather_summary(lat, lon)
        recommendations = None
        if weather_summary and gemini_model is None and not GROQ_API_KEY:
            recommendations = _fallback_crop_recommendations(class_name, weather_summary)
        elif weather_summary and GROQ_API_KEY:
            sys = "You are an agronomy assistant. Recommend 5 suitable crops for cultivation given soil type and recent weather."
            usr = f"Soil: {class_name}\nWeather: avg_temp_c={weather_summary.get('avg_temperature_c')}, total_precip_mm={weather_summary.get('total_precipitation_mm')}, aridity={weather_summary.get('aridity')}\nReturn JSON list with items {{crop, reason}}."
            out = generate_with_groq(sys, usr)
            try:
                parsed = json.loads(out) if out else None
                if isinstance(parsed, list):
                    recommendations = []
                    for item in parsed:
                        crop = item.get("crop") if isinstance(item, dict) else None
                        reason = item.get("reason") if isinstance(item, dict) else None
                        if crop:
                            recommendations.append({"crop": crop, "reason": reason or "Suitable based on soil and climate"})
            except Exception:
                recommendations = _fallback_crop_recommendations(class_name, weather_summary)
        elif weather_summary and gemini_model:
            try:
                prompt = f"Soil: {class_name}. Recent weather: avg_temp_c={weather_summary.get('avg_temperature_c')}, total_precip_mm={weather_summary.get('total_precipitation_mm')}, aridity={weather_summary.get('aridity')}. Recommend 5 crops with brief reasons in JSON list of objects with fields crop and reason."
                resp = gemini_model.generate_content(prompt) if gemini_model else None
                txt = resp.text if resp else None
                parsed = json.loads(txt) if txt else None
                if isinstance(parsed, list):
                    recommendations = []
                    for item in parsed:
                        if isinstance(item, dict) and item.get("crop"):
                            recommendations.append({"crop": item.get("crop"), "reason": item.get("reason") or "Suitable"})
            except Exception:
                recommendations = _fallback_crop_recommendations(class_name, weather_summary)
        else:
            recommendations = _fallback_crop_recommendations(class_name, None)
        return {
            "success": True,
            "prediction": {
                "class_index": predicted_class_idx,
                "class_name": class_name,
                "confidence": confidence,
                "confidence_percentage": round(confidence * 100, 2),
            },
            "m": class_name,
            "weather_summary": weather_summary,
            "recommendations": recommendations,
            "top_predictions": top_predictions,
            "filename": file.filename,
            "image_data": image_base64,
            "timestamp": datetime.utcnow().isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Soil prediction failed: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during soil prediction")

@app.post("/history")
async def save_history(data: dict, current_user: User = Depends(get_current_user)):
    """Save diagnosis to history"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        history_item = {
            **data,
            "username": current_user.username,
            "created_at": datetime.utcnow()
        }
        result = await db.history.insert_one(history_item)
        return {
            "success": True,
            "id": str(result.inserted_id)
        }
    except Exception as e:
        logger.error(f"Failed to save history for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to save diagnosis history")

@app.get("/history")
async def get_history(limit: int = 50, skip: int = 0, current_user: User = Depends(get_current_user)):
    """Get diagnosis history"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        cursor = db.history.find({"username": current_user.username}).sort("created_at", -1).skip(skip).limit(limit)
        history = []
        async for doc in cursor:
            doc["id"] = str(doc["_id"])
            del doc["_id"]
            history.append(doc)
        
        return {
            "success": True,
            "count": len(history),
            "history": history
        }
    except Exception as e:
        logger.error(f"Failed to get history for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve history")

@app.delete("/history/{id}")
async def delete_history(id: str, current_user: User = Depends(get_current_user)):
    """Delete a history item"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        from bson import ObjectId
        result = await db.history.delete_one({
            "_id": ObjectId(id),
            "username": current_user.username
        })
        if result.deleted_count == 1:
            return {"success": True, "message": "History item deleted"}
        else:
            raise HTTPException(status_code=404, detail="History item not found or unauthorized")
    except Exception as e:
        logger.error(f"Failed to delete history item {id} for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete history item")

@app.get("/dashboard/stats")
async def get_dashboard_stats(current_user: User = Depends(get_current_user)):
    """Get dashboard statistics"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        # Get total diagnoses
        total_diagnoses = await db.history.count_documents({"username": current_user.username})
        
        # Get disease distribution
        disease_distribution = []
        pipeline = [
            {"$match": {"username": current_user.username}},
            {"$group": {"_id": "$disease_info.disease", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}}
        ]
        
        async for doc in db.history.aggregate(pipeline):
            disease_distribution.append({
                "disease": doc["_id"],
                "count": doc["count"]
            })
        
        # Get recent activity (last 7 days)
        from datetime import timedelta
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        recent_count = await db.history.count_documents({
            "username": current_user.username,
            "created_at": {"$gte": seven_days_ago}
        })
        
        # Get healthy vs diseased ratio
        healthy_count = await db.history.count_documents({
            "username": current_user.username,
            "disease_info.is_healthy": True
        })
        diseased_count = total_diagnoses - healthy_count
        
        return {
            "success": True,
            "stats": {
                "total_diagnoses": total_diagnoses,
                "recent_diagnoses": recent_count,
                "healthy_plants": healthy_count,
                "diseased_plants": diseased_count,
                "disease_distribution": disease_distribution
            }
        }
    except Exception as e:
        logger.error(f"Failed to get dashboard stats for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve dashboard statistics")

# Plant Care Scheduler Endpoints
@app.post("/plant-care", response_model=PlantCareResponse)
async def create_plant_care(
    plant_care: PlantCareCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new plant care schedule"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        # Create plant care document
        plant_care_doc = plant_care.model_dump()
        plant_care_doc["username"] = current_user.username
        plant_care_doc["created_at"] = datetime.utcnow()
        plant_care_doc["updated_at"] = datetime.utcnow()
        
        result = await db.plant_care.insert_one(plant_care_doc)
        plant_care_doc["_id"] = result.inserted_id
        
        return PlantCareService.create_response(plant_care_doc)
    except Exception as e:
        logger.error(f"Failed to create plant care for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create plant care schedule")

@app.get("/plant-care", response_model=PlantCareListResponse)
async def get_plant_care_list(
    current_user: User = Depends(get_current_user)
):
    """Get all plant care schedules for the user"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        plant_cares = []
        async for doc in db.plant_care.find({"username": current_user.username}):
            response = PlantCareService.create_response(doc)
            plant_cares.append(response)
        
        return PlantCareListResponse(plants=plant_cares, total=len(plant_cares))
    except Exception as e:
        logger.error(f"Failed to get plant care list for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve plant care schedules")

@app.get("/plant-care/today", response_model=TodayTasksResponse)
async def get_today_tasks(
    current_user: User = Depends(get_current_user)
):
    """Get today's care tasks"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        plant_cares = []
        async for doc in db.plant_care.find({"username": current_user.username}):
            plant_cares.append(doc)
        
        today_tasks = PlantCareService.get_today_tasks(plant_cares)
        
        message = "✨ All plants are happy today!" if not today_tasks else f"💧 {len(today_tasks)} tasks due today"
        
        return TodayTasksResponse(
            tasks=today_tasks,
            total_due=len(today_tasks),
            message=message
        )
    except Exception as e:
        logger.error(f"Failed to get today's tasks for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve today's tasks")

@app.get("/plant-care/{plant_care_id}", response_model=PlantCareResponse)
async def get_plant_care(
    plant_care_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific plant care schedule"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        from bson import ObjectId
        doc = await db.plant_care.find_one({
            "_id": ObjectId(plant_care_id),
            "username": current_user.username
        })
        
        if not doc:
            raise HTTPException(status_code=404, detail="Plant care not found")
        
        return PlantCareService.create_response(doc)
    except Exception as e:
        logger.error(f"Failed to get plant care {plant_care_id} for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve plant care schedule")

@app.put("/plant-care/{plant_care_id}", response_model=PlantCareResponse)
async def update_plant_care(
    plant_care_id: str,
    plant_care_update: PlantCareUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a plant care schedule"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        from bson import ObjectId
        
        # Check if plant care exists
        existing = await db.plant_care.find_one({
            "_id": ObjectId(plant_care_id),
            "username": current_user.username
        })
        
        if not existing:
            raise HTTPException(status_code=404, detail="Plant care not found")
        
        # Update document
        update_data = plant_care_update.model_dump(exclude_unset=True)
        update_data["updated_at"] = datetime.utcnow()
        
        result = await db.plant_care.update_one(
            {"_id": ObjectId(plant_care_id)},
            {"$set": update_data}
        )
        
        # Get updated document
        updated_doc = await db.plant_care.find_one({"_id": ObjectId(plant_care_id)})
        
        return PlantCareService.create_response(updated_doc)
    except Exception as e:
        logger.error(f"Failed to update plant care {plant_care_id} for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to update plant care schedule")

@app.post("/plant-care/{plant_care_id}/mark-action", response_model=PlantCareResponse)
async def mark_care_action(
    plant_care_id: str,
    action_request: ActionRequest,
    current_user: User = Depends(get_current_user)
):
    """Mark a care action as completed"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        from bson import ObjectId
        
        # Get plant care
        plant_care = await db.plant_care.find_one({
            "_id": ObjectId(plant_care_id),
            "username": current_user.username
        })
        
        if not plant_care:
            raise HTTPException(status_code=404, detail="Plant care not found")
        
        # Mark action as completed
        updated_plant_care = PlantCareService.mark_action_completed(
            plant_care, 
            action_request.action_type,
            action_request.completed_date
        )
        
        # Update in database
        await db.plant_care.update_one(
            {"_id": ObjectId(plant_care_id)},
            {"$set": {
                f"last_{action_request.action_type}": action_request.completed_date,
                "updated_at": datetime.utcnow()
            }}
        )
        
        return updated_plant_care
    except Exception as e:
        logger.error(f"Failed to mark action for plant care {plant_care_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to mark care action")

@app.delete("/plant-care/{plant_care_id}")
async def delete_plant_care(
    plant_care_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a plant care schedule"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        from bson import ObjectId
        
        result = await db.plant_care.delete_one({
            "_id": ObjectId(plant_care_id),
            "username": current_user.username
        })
        
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Plant care not found")
        
        return {"success": True, "message": "Plant care deleted successfully"}
    except Exception as e:
        logger.error(f"Failed to delete plant care {plant_care_id} for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete plant care schedule")

# Community Endpoints
@app.post("/community/posts", response_model=CommunityPostResponse)
async def create_community_post(
    post: CommunityPostCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new community post"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        # Handle image if provided (in a real app, you'd save to cloud storage)
        image_url = None
        if post.image_base64:
            # For simplicity, we'll just store the base64 string or a placeholder URL
            # In production, use S3/Cloudinary and store the returned URL
            image_url = f"data:image/jpeg;base64,{post.image_base64[:100]}..." # truncated for DB efficiency
            
        post_doc = await CommunityService.create_post(db, current_user.username, post, image_url)
        return CommunityService.create_response(post_doc, current_user.username)
    except Exception as e:
        logger.error(f"Failed to create community post for {current_user.username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create community post")

@app.get("/community/posts", response_model=CommunityFeedResponse)
async def get_community_feed(
    limit: int = 20,
    skip: int = 0,
    current_user: User = Depends(get_current_user)
):
    """Get the community feed (paginated)"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        posts = []
        # Find all posts, sorted by newest first with pagination
        # Optimize query by using a projection if needed, but here we need all fields
        cursor = db.community_posts.find().sort("created_at", -1).skip(skip).limit(limit)
        async for doc in cursor:
            posts.append(CommunityService.create_response(doc, current_user.username))
        
        # count_documents is generally efficient, but for very large collections, 
        # consider estimated_document_count() if exact count isn't needed.
        total_posts = await db.community_posts.count_documents({})
        
        return CommunityFeedResponse(posts=posts, total=total_posts)
    except Exception as e:
        logger.error(f"Failed to get community feed: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve community feed")

@app.post("/community/posts/{post_id}/like")
async def toggle_post_like(
    post_id: str,
    current_user: User = Depends(get_current_user)
):
    """Toggle a like on a post"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        is_liked = await CommunityService.toggle_like(db, post_id, current_user.username)
        return {"liked": is_liked}
    except Exception as e:
        logger.error(f"Failed to toggle like on post {post_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to toggle like")

@app.post("/community/posts/{post_id}/comments")
async def add_post_comment(
    post_id: str,
    comment: CommunityCommentCreate,
    current_user: User = Depends(get_current_user)
):
    """Add a comment to a post"""
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        new_comment = await CommunityService.add_comment(db, post_id, current_user.username, comment.content)
        if not new_comment:
            raise HTTPException(status_code=404, detail="Post not found")
        return new_comment
    except Exception as e:
        logger.error(f"Failed to add comment to post {post_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to add comment")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
