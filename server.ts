import express from "express";
import { createServer as createViteServer } from "vite";
import Replicate from "replicate";
import dotenv from "dotenv";

dotenv.config();

const replicate = new Replicate({
  auth: process.env.REPLICATE_API_TOKEN,
});

async function startServer() {
  const app = express();
  const PORT = 3000;

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
      
      // Using the model specified by the user: stability-ai/stable-diffusion
      // Note: Replicate's API might return an array or a single string depending on the model version.
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

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    app.use(express.static("dist"));
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
