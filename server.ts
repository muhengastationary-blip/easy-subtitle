import express from "express";
import Replicate from "replicate";
import dotenv from "dotenv";
import { GoogleGenAI } from "@google/genai";

dotenv.config();

const app = express();
app.use(express.json());

// Helper to get genAI instance with current key
const getGenAI = () => {
  const apiKey = process.env.GEMINI_API_KEY || process.env.API_KEY;
  if (!apiKey) {
    console.error("CRITICAL: GEMINI_API_KEY is missing from process.env");
    console.log("Available env keys:", Object.keys(process.env).filter(k => !k.includes('SECRET') && !k.includes('TOKEN') && !k.includes('KEY')));
    throw new Error("GEMINI_API_KEY is not set in environment variables. Please check your Netlify settings and redeploy.");
  }
  return new GoogleGenAI({ apiKey });
};

const getReplicate = () => {
  const auth = process.env.REPLICATE_API_TOKEN;
  if (!auth) {
    console.error("CRITICAL: REPLICATE_API_TOKEN is missing from process.env");
    throw new Error("REPLICATE_API_TOKEN is not set in environment variables. Please check your Netlify settings and redeploy.");
  }
  return new Replicate({ auth });
};

// Create a router for API routes
const apiRouter = express.Router();

// API route for image generation
apiRouter.post("/generate", async (req, res) => {
  const { prompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: "Prompt is required" });
  }

  try {
    const replicate = getReplicate();
    console.log("Generating image for prompt:", prompt);
    
    const output = await replicate.run(
      "stability-ai/stable-diffusion:ac732d83d0c1d7e7208199701ca2da4c0f551e20b93f1d4eba83e1a267e7d848",
      {
        input: {
          prompt: prompt,
        },
      }
    );

    console.log("Replicate output success");
    res.json({ output });
  } catch (error: any) {
    console.error("Error generating image:", error);
    res.status(500).json({ error: error.message || "Failed to generate image" });
  }
});

// API route for Gemini Chat
apiRouter.post("/chat", async (req, res) => {
  console.log("Received chat request:", req.body);
  const { message, history, systemInstruction } = req.body;

  if (!message) {
    return res.status(400).json({ error: "Message is required" });
  }

  try {
    const genAI = getGenAI();
    
    // Simple non-streaming implementation for stability in serverless
    const chat = genAI.chats.create({
      model: "gemini-3-flash-preview",
      config: {
        systemInstruction: systemInstruction,
      },
      history: history || [],
    });

    const result = await chat.sendMessage({ message });
    console.log("Gemini response success");
    res.json({ text: result.text });
  } catch (error: any) {
    console.error("Error in Gemini Chat:", error);
    res.status(500).json({ error: error.message || "Failed to get response from AI" });
  }
});

// API route for Gemini Multimodal (Image Analysis)
apiRouter.post("/multimodal", async (req, res) => {
  const { message, image, systemInstruction } = req.body;

  if (!image) {
    return res.status(400).json({ error: "Image is required" });
  }

  try {
    const genAI = getGenAI();

    const imagePart = {
      inlineData: {
        mimeType: image.split(';')[0].split(':')[1],
        data: image.split(',')[1],
      },
    };
    const textPart = { text: message || "Explain this image." };
    
    const response = await genAI.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: { parts: [imagePart, textPart] },
      config: { systemInstruction: systemInstruction }
    });
    
    res.json({ text: response.text });
  } catch (error: any) {
    console.error("Error in Gemini Multimodal:", error);
    res.status(500).json({ error: error.message || "Failed to analyze image" });
  }
});

// API route for Gemini TTS
apiRouter.post("/tts", async (req, res) => {
  const { text } = req.body;
  console.log("Received TTS request for text length:", text?.length);

  if (!text) {
    return res.status(400).json({ error: "Text is required" });
  }

  try {
    const genAI = getGenAI();

    const response = await genAI.models.generateContent({
      model: "gemini-2.5-flash-preview-tts",
      contents: [{ parts: [{ text }] }],
      config: {
        responseModalities: ["AUDIO"],
        speechConfig: {
          voiceConfig: {
            prebuiltVoiceConfig: { voiceName: 'Kore' },
          },
        },
      },
    });

    const base64Audio = response.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
    console.log("Gemini TTS success");
    res.json({ audio: base64Audio });
  } catch (error: any) {
    console.error("Error in Gemini TTS:", error);
    res.status(500).json({ error: error.message || "Failed to generate speech" });
  }
});

// Health check endpoint
apiRouter.get("/health", (req, res) => {
  const hasGeminiKey = !!(process.env.GEMINI_API_KEY || process.env.API_KEY);
  const hasReplicateToken = !!process.env.REPLICATE_API_TOKEN;
  
  res.json({ 
    status: "ok", 
    message: "Muhenga AI Server is running",
    env: { 
      hasGeminiKey,
      hasReplicateToken,
      nodeEnv: process.env.NODE_ENV,
      availableKeys: Object.keys(process.env).filter(k => !k.includes('SECRET') && !k.includes('TOKEN') && !k.includes('KEY'))
    } 
  });
});

// Mount the API router
app.use("/api", apiRouter);

// For local dev in AI Studio
if (process.env.NODE_ENV !== "production") {
  async function setupVite() {
    const { createServer: createViteServer } = await import("vite");
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
    
    const PORT = 3000;
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  }
  setupVite();
} else {
  // Static serving for production (if not using Netlify Functions)
  app.use(express.static("dist"));
  
  // Only listen if not being imported as a module (e.g., for Netlify)
  // This is a bit tricky with ESM, but usually Netlify doesn't call listen()
}

export default app;
