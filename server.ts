import express from "express";
import { createServer as createViteServer } from "vite";
import Replicate from "replicate";
import dotenv from "dotenv";

dotenv.config();

const replicate = new Replicate({
  auth: process.env.REPLICATE_API_TOKEN,
});

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
