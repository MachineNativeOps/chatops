// services/gateway-ts/src/index.ts
// REST Gateway for chatops Multi-Agent AI Platform
import express, { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { EngineClient } from './clients/engine';
import { Logger } from './utils/logger';

const app = express();
const logger = new Logger('gateway');
const engineClient = new EngineClient();

// Middleware
app.use(express.json());
app.use((req: Request, res: Response, next: NextFunction) => {
  const traceId = req.headers['x-trace-id'] as string || `trace-${Date.now()}-${uuidv4().slice(0, 8)}`;
  req.headers['x-trace-id'] = traceId;
  res.setHeader('x-trace-id', traceId);
  logger.info(`${req.method} ${req.path}`, { traceId });
  next();
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    service: 'gateway-ts',
    timestamp: new Date().toISOString(),
  });
});

// Ready check (includes downstream health)
app.get('/ready', async (req: Request, res: Response) => {
  try {
    const engineHealth = await engineClient.healthCheck();
    res.json({
      status: 'ready',
      service: 'gateway-ts',
      dependencies: {
        engine: engineHealth ? 'healthy' : 'unhealthy',
      },
      timestamp: new Date().toISOString(),
    });
  } catch {
    res.status(503).json({
      status: 'not-ready',
      service: 'gateway-ts',
      dependencies: {
        engine: 'unreachable',
      },
      timestamp: new Date().toISOString(),
    });
  }
});

// Process endpoint - Routes to gRPC engine
app.post('/api/v1/process', async (req: Request, res: Response) => {
  const traceId = req.headers['x-trace-id'] as string;

  try {
    const { input, options } = req.body;

    if (!input) {
      res.status(400).json({
        error: 'Missing required field: input',
        traceId,
      });
      return;
    }

    logger.info('Processing request', { traceId, input: input.substring(0, 100) });

    const result = await engineClient.process({
      input,
      traceId,
      options: options || {},
    });

    res.json({
      success: true,
      result,
      traceId,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Processing failed', { traceId, error: String(error) });
    res.status(500).json({
      success: false,
      error: 'Processing failed',
      traceId,
      timestamp: new Date().toISOString(),
    });
  }
});

// Batch process endpoint
app.post('/api/v1/batch', async (req: Request, res: Response) => {
  const traceId = req.headers['x-trace-id'] as string;

  try {
    const { items } = req.body;

    if (!Array.isArray(items)) {
      res.status(400).json({
        error: 'Missing required field: items (array)',
        traceId,
      });
      return;
    }

    logger.info('Batch processing', { traceId, count: items.length });

    const results = await Promise.all(
      items.map((item: { input: string; options?: Record<string, unknown> }) =>
        engineClient.process({
          input: item.input,
          traceId,
          options: item.options || {},
        })
      )
    );

    res.json({
      success: true,
      results,
      count: results.length,
      traceId,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Batch processing failed', { traceId, error: String(error) });
    res.status(500).json({
      success: false,
      error: 'Batch processing failed',
      traceId,
      timestamp: new Date().toISOString(),
    });
  }
});

// Error handler
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  const traceId = req.headers['x-trace-id'] as string;
  logger.error('Unhandled error', { traceId, error: err.message });
  res.status(500).json({
    error: 'Internal server error',
    traceId,
    timestamp: new Date().toISOString(),
  });
});

// Start server
const PORT = process.env.GATEWAY_PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => {
    logger.info(`Gateway listening on port ${PORT}`);
  });
}

export { app };
