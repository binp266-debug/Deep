type EventCallback<T = any> = (data: T) => Promise<void> | void;

interface Task<T = any> {
  event: string;
  payload: T;
  priority: number;
}

export class CoreEventDispatcher {
  private listeners: Map<string, Set<EventCallback>> = new Map();
  private queue: Task[] = [];
  private activeWorkers = 0;
  private readonly maxConcurrency: number;
  private isProcessing = false;

  constructor(maxConcurrency: number = navigator.hardwareConcurrency || 4) {
    this.maxConcurrency = maxConcurrency;
  }

  public on<T>(event: string, callback: EventCallback<T>): () => void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);

    // Return cleanup hook
    return () => {
      const targets = this.listeners.get(event);
      if (targets) {
        targets.delete(callback);
        if (targets.size === 0) {
          this.listeners.delete(event);
        }
      }
    };
  }

  public emit<T>(event: string, payload: T, priority: number = 0): void {
    // Binary insert for priority ordering (higher priority first)
    const task: Task<T> = { event, payload, priority };
    this.enqueue(task);
    this.flush();
  }

  private enqueue(task: Task): void {
    let low = 0;
    let high = this.queue.length;

    while (low < high) {
      const mid = (low + high) >>> 1;
      if (this.queue[mid].priority < task.priority) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    this.queue.splice(low, 0, task);
  }

  private async flush(): Promise<void> {
    if (this.isProcessing) return;
    this.isProcessing = true;

    while (this.queue.length > 0 && this.activeWorkers < this.maxConcurrency) {
      const task = this.queue.shift();
      if (!task) break;

      this.activeWorkers++;
      this.processTask(task).finally(() => {
        this.activeWorkers--;
        this.flush();
      });
    }

    this.isProcessing = false;
  }

  private async processTask(task: Task): Promise<void> {
    const callbacks = this.listeners.get(task.event);
    if (!callbacks || callbacks.size === 0) return;

    const executions = Array.from(callbacks).map(async (cb) => {
      try {
        await cb(task.payload);
      } catch (err) {
        // Fast error isolation to keep worker execution alive
        console.error(`Execution fault on event [${task.event}]:`, err);
      }
    });

    await Promise.allSettled(executions);
  }
}