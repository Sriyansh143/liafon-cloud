import axios from 'axios';
import logger from '../utils/logger.js';

class OllamaService {
  constructor() {
    this.baseUrl = process.env.OLLAMA_BASE_URL || 'http://localhost:11434';
    this.model = process.env.OLLAMA_MODEL || 'llama3.1:8b';
    this.isConnected = false;
  }

  async testConnection() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/tags`);
      this.isConnected = true;
      logger.info('Ollama connection successful');
      return true;
    } catch (error) {
      logger.error('Ollama connection failed:', error.message);
      this.isConnected = false;
      throw error;
    }
  }

  // Chat with AI assistant
  async chat(messages, options = {}) {
    try {
      const { stream = false, temperature = 0.7, maxTokens = 2048 } = options;

      const response = await axios.post(
        `${this.baseUrl}/api/chat`,
        {
          model: this.model,
          messages,
          stream,
          options: {
            temperature,
            num_predict: maxTokens
          }
        },
        {
          timeout: 60000
        }
      );

      if (stream) {
        return this.parseStreamResponse(response.data);
      }

      return {
        role: 'assistant',
        content: response.data.message.content,
        done: response.data.done
      };
    } catch (error) {
      logger.error('Ollama chat error:', error.message);
      throw new Error(`AI chat failed: ${error.message}`);
    }
  }

  // Generate embeddings for vector search
  async generateEmbeddings(text) {
    try {
      const response = await axios.post(
        `${this.baseUrl}/api/embeddings`,
        {
          model: this.model,
          prompt: text
        }
      );

      return response.data.embedding;
    } catch (error) {
      logger.error('Ollama embeddings error:', error.message);
      throw new Error(`Embeddings generation failed: ${error.message}`);
    }
  }

  // Generate text completion
  async generate(prompt, options = {}) {
    try {
      const { temperature = 0.7, maxTokens = 1024 } = options;

      const response = await axios.post(
        `${this.baseUrl}/api/generate`,
        {
          model: this.model,
          prompt,
          stream: false,
          options: {
            temperature,
            num_predict: maxTokens
          }
        },
        {
          timeout: 60000
        }
      );

      return {
        text: response.data.response,
        done: response.data.done
      };
    } catch (error) {
      logger.error('Ollama generate error:', error.message);
      throw new Error(`Text generation failed: ${error.message}`);
    }
  }

  // Health insights generation
  async generateHealthInsights(healthData) {
    const prompt = `
Analyze this health data and provide actionable insights:

Heart Rate: ${healthData.heartRate} bpm
SpO2: ${healthData.spo2}%
Sleep Quality: ${healthData.sleepQuality}/100
Stress Level: ${healthData.stressLevel}
Steps: ${healthData.steps}
Calories: ${healthData.calories}

Provide:
1. Overall health assessment
2. 3 specific recommendations
3. Any warning signs to watch for

Keep it concise and encouraging.
`;

    try {
      const response = await this.generate(prompt, {
        temperature: 0.5,
        maxTokens: 512
      });

      return response.text;
    } catch (error) {
      logger.error('Health insights generation failed:', error);
      throw error;
    }
  }

  // AI matching for marketplace
  async matchRequirementToUsers(requirement, userProfiles) {
    const prompt = `
Match this requirement to the best users based on their profiles:

Requirement:
- Title: ${requirement.title}
- Category: ${requirement.category}
- Budget: ₹${requirement.budget}
- Location: ${requirement.location}
- Description: ${requirement.description}

User Profiles:
${userProfiles.map(u => `- ${u.name}: Skills: ${u.skills.join(', ')}, Location: ${u.location}, Rating: ${u.rating}`).join('\n')}

Return a JSON array of matches with scores (0-100):
[{"userId": "id", "score": 85, "reason": "brief reason"}]

Only include matches with score > 70.
`;

    try {
      const response = await this.generate(prompt, {
        temperature: 0.3,
        maxTokens: 1024
      });

      // Parse JSON from response
      const jsonMatch = response.text.match(/\[[\s\S]*\]/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      
      return [];
    } catch (error) {
      logger.error('Marketplace matching failed:', error);
      throw error;
    }
  }

  // Memory extraction from conversations
  async extractMemories(conversation) {
    const prompt = `
Extract important memories from this conversation:

${conversation}

Extract:
- User interests
- Preferences
- Health conditions
- Relationships
- Work information
- Hobbies
- Food preferences

Return as JSON:
{
  "memories": [
    {"category": "interests", "key": "yoga", "value": "practices daily", "confidence": 0.9}
  ]
}
`;

    try {
      const response = await this.generate(prompt, {
        temperature: 0.3,
        maxTokens: 1024
      });

      const jsonMatch = response.text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }

      return { memories: [] };
    } catch (error) {
      logger.error('Memory extraction failed:', error);
      throw error;
    }
  }

  // Prescription analysis
  async analyzePrescription(extractedText) {
    const prompt = `
Analyze this prescription text and extract structured data:

${extractedText}

Extract:
- Patient name
- Doctor name
- Date
- Diagnosis
- Medications (name, dosage, frequency, duration)
- Lab tests
- Instructions

Return as JSON:
{
  "patientName": "",
  "doctorName": "",
  "date": "",
  "diagnosis": "",
  "medications": [
    {"name": "", "dosage": "", "frequency": "", "duration": ""}
  ],
  "labTests": [],
  "instructions": ""
}
`;

    try {
      const response = await this.generate(prompt, {
        temperature: 0.2,
        maxTokens: 1024
      });

      const jsonMatch = response.text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }

      return {};
    } catch (error) {
      logger.error('Prescription analysis failed:', error);
      throw error;
    }
  }

  parseStreamResponse(streamData) {
    // Handle streaming responses
    return streamData;
  }
}

export default new OllamaService();
