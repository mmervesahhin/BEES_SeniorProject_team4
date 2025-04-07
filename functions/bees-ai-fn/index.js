const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
app.use(bodyParser.json());

const API_KEY = ""; // güvenlik nedeniyle githuba pushlamamak için şimdilik siliyorum, ihtiyacınız olursa benle (suna) iletişime geçin lütfen.

app.post('/', async (req, res) => {
  const prompt = req.body.prompt;

  if (!prompt) {
    return res.status(400).json({ error: 'Prompt is missing.' });
  }

  try {
    const response = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      {
        contents: [
          {
            parts: [{ text: prompt }],
          },
        ],
      },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        params: {
          key: API_KEY,
        },
      }
    );

    const text = response.data.candidates?.[0]?.content?.parts?.[0]?.text || '❌ No summary returned by AI.';
    if (!text) throw new Error('No response from Gemini');

    res.status(200).json({ summary: text });
  } catch (error) {
    console.error('Gemini API error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/', (req, res) => {
  res.send('✅ BEES Gemini API is alive!');
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`✅ Server listening on port ${PORT}`);
});
