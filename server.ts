import express from "express";
import { createServer as createViteServer } from "vite";
import Replicate from "replicate";
import dotenv from "dotenv";
import { GoogleGenAI } from "@google/genai";

dotenv.config();

const replicate = new Replicate({
  auth: process.env.REPLICATE_API_TOKEN,
});

const genAI = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || "" });

const app = express();
app.use(express.json());

// API route for image generation
app.post("/api/generate", async (req, res) => {
  const { prompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: "Prompt is required" });
  }

  try {
    if (!process.env.REPLICATE_API_TOKEN) {
      throw new Error("REPLICATE_API_TOKEN is not set in environment variables.");
    }

    console.log("Generating image for prompt:", prompt);
    
    const output = await replicate.run(
      "stability-ai/stable-diffusion:ac732d83d0c1d7e7208199701ca2da4c0f551e20b93f1d4eba83e1a267e7d848",
      {
        input: {
          prompt: prompt,
        },
      }
    );

    console.log("Replicate output:", output);
    res.json({ output });
  } catch (error: any) {
    console.error("Error generating image:", error);
    res.status(500).json({ error: error.message || "Failed to generate image" });
  }
});

// API route for Gemini Chat
app.post("/api/chat", async (req, res) => {
  const { message, history, systemInstruction } = req.body;

  if (!message) {
    return res.status(400).json({ error: "Message is required" });
  }

  try {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not set in environment variables.");
    }

    const model = genAI.models.get({ model: "gemini-3-flash-preview" });
    
    // Simple non-streaming implementation for stability in serverless
    const chat = genAI.chats.create({
      model: "gemini-3-flash-preview",
      config: {
        systemInstruction: systemInstruction,
      },
      history: history || [],
    });

    const result = await chat.sendMessage({ message });
    res.json({ text: result.text });
  } catch (error: any) {
    console.error("Error in Gemini Chat:", error);
    res.status(500).json({ error: error.message || "Failed to get response from AI" });
  }
});

// API route for Gemini Multimodal (Image Analysis)
app.post("/api/multimodal", async (req, res) => {
  const { message, image, systemInstruction } = req.body;

  if (!image) {
    return res.status(400).json({ error: "Image is required" });
  }

  try {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not set in environment variables.");
    }

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
app.post("/api/tts", async (req, res) => {
  const { text } = req.body;

  if (!text) {
    return res.status(400).json({ error: "Text is required" });
  }

  try {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not set in environment variables.");
    }

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
    res.json({ audio: base64Audio });
  } catch (error: any) {
    console.error("Error in Gemini TTS:", error);
    res.status(500).json({ error: error.message || "Failed to generate speech" });
  }
});

// For local dev in AI Studio
if (process.env.NODE_ENV !== "production") {
  async function setupVite() {
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
  if (import.meta.url === `file://${process.argv[1]}`) {
      const PORT = 3000;
      app.listen(PORT, "0.0.0.0", () => {
        console.log(`Server running on http://localhost:${PORT}`);
      });
  }
}

export default app;
