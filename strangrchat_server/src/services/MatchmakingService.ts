import { redis } from '../config/redis';

export interface MatchCriteria {
  userId: string;
  socketId: string;
  intent: string;
  gender: string;
  preferredGender: string; // From VIP status or random
  city?: string;
  countryCode?: string;
}

export class MatchmakingService {
  private static QUEUE_KEY = 'matchmaking:queue';
  private static USER_PREFIX = 'user:active:'; // user:active:userId -> socketId

  static async addToQueue(criteria: MatchCriteria): Promise<void> {
    const { userId, socketId, intent, gender, preferredGender } = criteria;
    
    // Map userId to socketId for quick lookup
    await redis.set(`${this.USER_PREFIX}${userId}`, socketId, 'EX', 3600);

    // Simplistic queueing: Categorize by intent and preferred gender
    // In a real high-scale app, we might use GEOADD for radius or more complex sets
    const queueName = `${this.QUEUE_KEY}:${intent}:${preferredGender}`;
    
    // We store the userId and his own gender in the queue
    // Format: userId:gender
    await redis.lpush(queueName, `${userId}:${gender}`);
  }

  static async findMatch(criteria: MatchCriteria): Promise<{ partnerId: string; partnerSocketId: string } | null> {
    const { userId, intent, gender, preferredGender } = criteria;
    
    // We are looking for someone whose preferred gender matches our gender
    // AND who is in the same intent queue
    // AND whose own gender matches our preferred gender
    const targetQueue = `${this.QUEUE_KEY}:${intent}:${gender}`;
    
    // Iteratively look through the queue
    // Note: LPOP is atomic. In a high concurrency environment, we might want to be careful.
    const queueLen = await redis.llen(targetQueue);
    
    for (let i = 0; i < queueLen; i++) {
      const partnerData = await redis.rpop(targetQueue);
      if (!partnerData) break;

      const [partnerId, partnerGender] = partnerData.split(':');

      // Check if partner's gender matches our preference
      // And avoid matching with self
      if (partnerId !== userId && (preferredGender === 'ANY' || partnerGender === preferredGender)) {
        const partnerSocketId = await redis.get(`${this.USER_PREFIX}${partnerId}`);
        
        if (partnerSocketId) {
          return { partnerId, partnerSocketId };
        }
      } else if (partnerId !== userId) {
        // Not a match, put them back at the start of the queue
        await redis.lpush(targetQueue, partnerData);
      }
    }

    return null;
  }

  static async removeFromQueue(userId: string, intent: string, preferredGender: string): Promise<void> {
    const queueName = `${this.QUEUE_KEY}:${intent}:${preferredGender}`;
    // This is O(N), acceptable for low N in queue
    // Better way: use a Set or just let it expire if the user disconnects
    const list = await redis.lrange(queueName, 0, -1);
    for (const item of list) {
      if (item.startsWith(`${userId}:`)) {
        await redis.lrem(queueName, 1, item);
        break;
      }
    }
    await redis.del(`${this.USER_PREFIX}${userId}`);
  }

  static async setPartner(userId: string, partnerId: string): Promise<void> {
    await redis.set(`chat:partner:${userId}`, partnerId, 'EX', 3600);
    await redis.set(`chat:partner:${partnerId}`, userId, 'EX', 3600);
  }

  static async getPartner(userId: string): Promise<string | null> {
    return await redis.get(`chat:partner:${userId}`);
  }

  static async endChat(userId: string): Promise<string | null> {
    const partnerId = await redis.get(`chat:partner:${userId}`);
    if (partnerId) {
      await redis.del(`chat:partner:${userId}`);
      await redis.del(`chat:partner:${partnerId}`);
    }
    return partnerId;
  }
}
