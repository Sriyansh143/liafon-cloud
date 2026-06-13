import PocketBase from 'pocketbase';
import logger from '../utils/logger.js';

class PocketBaseService {
  constructor() {
    this.pb = null;
    this.isConnected = false;
  }

  async connect() {
    try {
      const url = process.env.POCKETBASE_URL || 'http://localhost:8090';
      this.pb = new PocketBase(url);

      // Admin authentication
      const adminEmail = process.env.POCKETBASE_ADMIN_EMAIL || 'admin@liafon.cloud';
      const adminPassword = process.env.POCKETBASE_ADMIN_PASSWORD || 'admin';

      await this.pb.admins.authWithPassword(adminEmail, adminPassword);
      
      this.isConnected = true;
      logger.info('PocketBase connection established');
      
      return this.pb;
    } catch (error) {
      logger.error('PocketBase connection failed:', error.message);
      throw error;
    }
  }

  getDb() {
    if (!this.isConnected || !this.pb) {
      throw new Error('PocketBase not connected');
    }
    return this.pb;
  }

  // Health Metrics
  async saveHealthMetric(userId, metricData) {
    try {
      const record = await this.pb.collection('health_metrics').create({
        user: userId,
        ...metricData,
        created_at: new Date().toISOString()
      });
      return record;
    } catch (error) {
      logger.error('Error saving health metric:', error);
      throw error;
    }
  }

  async getHealthMetrics(userId, options = {}) {
    try {
      const filter = `user = "${userId}"`;
      const records = await this.pb.collection('health_metrics').getList(1, 50, {
        filter,
        sort: '-created'
      });
      return records.items;
    } catch (error) {
      logger.error('Error fetching health metrics:', error);
      throw error;
    }
  }

  // Sleep Records
  async saveSleepRecord(userId, sleepData) {
    try {
      const record = await this.pb.collection('sleep_records').create({
        user: userId,
        ...sleepData
      });
      return record;
    } catch (error) {
      logger.error('Error saving sleep record:', error);
      throw error;
    }
  }

  async getSleepRecords(userId, startDate, endDate) {
    try {
      const filter = `user = "${userId}" && date >= "${startDate}" && date <= "${endDate}"`;
      const records = await this.pb.collection('sleep_records').getList(1, 100, {
        filter,
        sort: '-date'
      });
      return records.items;
    } catch (error) {
      logger.error('Error fetching sleep records:', error);
      throw error;
    }
  }

  // Emergency Contacts
  async getEmergencyContacts(userId) {
    try {
      const filter = `user = "${userId}"`;
      const records = await this.pb.collection('emergency_contacts').getList(1, 5, {
        filter
      });
      return records.items;
    } catch (error) {
      logger.error('Error fetching emergency contacts:', error);
      throw error;
    }
  }

  // Marketplace Requirements
  async getRequirements(options = {}) {
    try {
      const { page = 1, perPage = 20, category, location } = options;
      let filter = 'status = "open"';
      
      if (category) {
        filter += ` && category = "${category}"`;
      }
      
      const records = await this.pb.collection('marketplace_requirements').getList(page, perPage, {
        filter,
        sort: '-created'
      });
      return records;
    } catch (error) {
      logger.error('Error fetching requirements:', error);
      throw error;
    }
  }

  async createRequirement(userId, requirementData) {
    try {
      const record = await this.pb.collection('marketplace_requirements').create({
        user: userId,
        ...requirementData,
        status: 'open'
      });
      return record;
    } catch (error) {
      logger.error('Error creating requirement:', error);
      throw error;
    }
  }

  // Points Transactions
  async addPoints(userId, points, reason, transactionType = 'earn') {
    try {
      const record = await this.pb.collection('points_transactions').create({
        user: userId,
        points,
        type: transactionType,
        reason,
        created_at: new Date().toISOString()
      });
      
      // Update user's total points
      const user = await this.pb.collection('users').getOne(userId);
      const currentPoints = user.points || 0;
      const newPoints = transactionType === 'earn' 
        ? currentPoints + points 
        : currentPoints - points;
      
      await this.pb.collection('users').update(userId, { points: newPoints });
      
      return record;
    } catch (error) {
      logger.error('Error adding points:', error);
      throw error;
    }
  }

  async getPointsBalance(userId) {
    try {
      const user = await this.pb.collection('users').getOne(userId);
      return user.points || 0;
    } catch (error) {
      logger.error('Error fetching points balance:', error);
      throw error;
    }
  }

  // Prescriptions
  async savePrescription(userId, prescriptionData) {
    try {
      const record = await this.pb.collection('prescriptions').create({
        user: userId,
        ...prescriptionData
      });
      return record;
    } catch (error) {
      logger.error('Error saving prescription:', error);
      throw error;
    }
  }

  async getPrescriptions(userId) {
    try {
      const filter = `user = "${userId}"`;
      const records = await this.pb.collection('prescriptions').getList(1, 50, {
        filter,
        sort: '-created'
      });
      return records.items;
    } catch (error) {
      logger.error('Error fetching prescriptions:', error);
      throw error;
    }
  }

  // Memories (Vector DB sync)
  async saveMemory(userId, memoryData) {
    try {
      const record = await this.pb.collection('memories').create({
        user: userId,
        ...memoryData
      });
      return record;
    } catch (error) {
      logger.error('Error saving memory:', error);
      throw error;
    }
  }

  async getMemories(userId, options = {}) {
    try {
      const filter = `user = "${userId}"`;
      const { category, limit = 20 } = options;
      
      let finalFilter = filter;
      if (category) {
        finalFilter += ` && category = "${category}"`;
      }
      
      const records = await this.pb.collection('memories').getList(1, limit, {
        filter: finalFilter,
        sort: '-confidence'
      });
      return records.items;
    } catch (error) {
      logger.error('Error fetching memories:', error);
      throw error;
    }
  }
}

export default new PocketBaseService();
