// services/gateway-ts/src/clients/engine.ts
// gRPC Client for Engine Service
import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';
import path from 'path';
import { Logger } from '../utils/logger';

interface ProcessRequest {
  input: string;
  traceId: string;
  options: Record<string, unknown>;
}

interface ProcessResponse {
  output: string;
  metadata: Record<string, string>;
  processingTime: number;
}

export class EngineClient {
  private client: grpc.Client | null = null;
  private logger: Logger;
  private connected: boolean = false;

  constructor() {
    this.logger = new Logger('engine-client');
    this.initialize();
  }

  private async initialize(): Promise<void> {
    const protoPath = path.resolve(__dirname, '../../../../proto/engine.proto');

    try {
      const packageDefinition = protoLoader.loadSync(protoPath, {
        keepCase: true,
        longs: String,
        enums: String,
        defaults: true,
        oneofs: true,
      });

      const proto = grpc.loadPackageDefinition(packageDefinition) as unknown as {
        chatops: {
          engine: {
            EngineService: new (
              address: string,
              credentials: grpc.ChannelCredentials
            ) => grpc.Client;
          };
        };
      };

      const address = process.env.ENGINE_GRPC || 'localhost:50051';
      this.client = new proto.chatops.engine.EngineService(
        address,
        grpc.credentials.createInsecure()
      );
      this.connected = true;
      this.logger.info('Connected to engine service', { address });
    } catch (error) {
      this.logger.warn('Failed to connect to engine service', { error: String(error) });
      this.connected = false;
    }
  }

  async process(request: ProcessRequest): Promise<ProcessResponse> {
    if (!this.connected || !this.client) {
      // Return mock response when not connected
      this.logger.warn('Engine not connected, returning mock response');
      return {
        output: `Processed: ${request.input}`,
        metadata: {
          mock: 'true',
          traceId: request.traceId,
        },
        processingTime: 0,
      };
    }

    return new Promise((resolve, reject) => {
      const deadline = new Date();
      deadline.setSeconds(deadline.getSeconds() + 30);

      (this.client as grpc.Client & { Process: Function }).Process(
        {
          input: request.input,
          trace_id: request.traceId,
          options: JSON.stringify(request.options),
        },
        { deadline },
        (error: grpc.ServiceError | null, response: ProcessResponse) => {
          if (error) {
            this.logger.error('gRPC call failed', { error: error.message });
            reject(error);
          } else {
            resolve(response);
          }
        }
      );
    });
  }

  async healthCheck(): Promise<boolean> {
    if (!this.connected || !this.client) {
      return false;
    }

    return new Promise((resolve) => {
      const deadline = new Date();
      deadline.setSeconds(deadline.getSeconds() + 5);

      (this.client as grpc.Client & { HealthCheck: Function }).HealthCheck(
        {},
        { deadline },
        (error: grpc.ServiceError | null) => {
          resolve(!error);
        }
      );
    });
  }

  close(): void {
    if (this.client) {
      grpc.closeClient(this.client);
      this.connected = false;
      this.logger.info('Disconnected from engine service');
    }
  }
}
