# 🚀 PlantAI Deployment Guide

This guide will help you deploy the **PlantAI** application (Backend and Frontend) to production.

---

## 1. Backend Deployment (FastAPI)

The backend is built with FastAPI and requires a Python environment or Docker.

### Recommended Platforms
- **Render** (Easy, has a free tier)
- **Railway** (Great developer experience)
- **AWS App Runner** or **DigitalOcean App Platform**

### Deployment Steps (using Render/Railway)
1. **Push to GitHub**: Ensure your code is in a GitHub repository.
2. **Connect to Platform**: Create a new Web Service and link your repository.
3. **Configure Build Settings**:
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port 8000`
4. **Environment Variables**: Add the following variables in the dashboard:
   - `MONGODB_URL`: Your MongoDB Atlas connection string (see below).
   - `GEMINI_API_KEY`: Your Google Gemini API key.
   - `GROQ_API_KEY`: Your Groq API key.
   - `WEATHERSTACK_API_KEY`: Your Weatherstack API key.
   - `SECRET_KEY`: A long, random string for JWT authentication.

### MongoDB Atlas Setup
1. Create a free cluster on [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).
2. Create a database user and whitelist `0.0.0.0/0` (or the specific IP of your deployment platform).
3. Copy the connection string and use it as `MONGODB_URL`.

---

## 2. Frontend Deployment (Flutter)

### Step 1: Update API URL
Before building, update the production URL in `frontend/lib/services/api_service.dart`:
```dart
static const bool _isProduction = true;
static const String _prodUrl = 'https://your-backend-url.onrender.com';
```

### Step 2: Build for Production

#### Android (APK/App Bundle)
```bash
cd frontend
flutter build apk --release
# OR for Play Store
flutter build appbundle --release
```
The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

#### iOS
*Requires a Mac with Xcode.*
```bash
cd frontend
flutter build ios --release
```

#### Web
```bash
cd frontend
flutter build web --release
```
The web build will be in `build/web/`. You can deploy this folder to **Netlify**, **Vercel**, or **GitHub Pages**.

---

## 3. Important Considerations
- **ML Models**: The `.keras` files are large. Ensure your deployment platform has enough disk space or use **Git LFS**.
- **CORS**: The backend is currently configured to allow all origins (`allow_origins=["*"]`). For production, you should restrict this to your specific frontend domain.
- **SSL**: Most deployment platforms (Render, Railway) provide automatic SSL. Ensure your frontend calls the backend using `https`.
