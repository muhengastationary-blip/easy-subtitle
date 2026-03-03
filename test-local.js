const serverless = require("serverless-http");
const express = require("express");
const app = express();
app.all("*", (req, res) => res.json({ path: req.path, url: req.url }));
const handler = serverless(app);
handler({ path: "/.netlify/functions/api/api/chat", httpMethod: "GET", headers: {} }, {}).then(console.log);
