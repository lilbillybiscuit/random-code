# Rate Limiter Implementation Challenge

## Background
You're working on a high-traffic API service that processes millions of requests daily. To ensure fair usage and protect the service from abuse, you need to implement a rate limiting solution.

## Requirements

### Core Functionality
Implement a rate limiter that:
- Limits each user to a maximum of 50 requests per second. You should choose the best way to handle this
- Must return a decision (allow/deny) for each request in under 2ms
- Should be able to handle many users concurrently
- Must handle cleanup of stale data automatically


## Implementation
Please implement a `RateLimiter` class with the following method:
```python
def is_allowed(self, user_id: str) -> bool:
    """
    Returns True if the request is allowed, False if it should be rate limited.
    
    Args:
        user_id (str): The identifier for the user making the request
        
    Returns:
        bool: True if the request is allowed, False otherwise
    """
    pass
```

### Test Script
Use this script to validate your implementation:

```python
import threading
import time
from concurrent.futures import ThreadPoolExecutor
import random

def stress_test(rate_limiter, duration_seconds=10):
    start_time = time.time()
    request_counts = {
        'allowed': 0,
        'denied': 0
    }
    
    def make_requests():
        user_id = f"user_{random.randint(1, 100)}"
        while time.time() - start_time < duration_seconds:
            result = rate_limiter.is_allowed(user_id)
            if result:
                request_counts['allowed'] += 1
            else:
                request_counts['denied'] += 1
    
    # Create 200 threads to simulate heavy concurrent load
    with ThreadPoolExecutor(max_workers=200) as executor:
        futures = [executor.submit(make_requests) for _ in range(200)]
    
    # Wait for all threads to complete
    for future in futures:
        future.result()
    
    total_time = time.time() - start_time
    total_requests = request_counts['allowed'] + request_counts['denied']
    
    print(f"Test Duration: {total_time:.2f} seconds")
    print(f"Total Requests: {total_requests:,}")
    print(f"Requests/Second: {total_requests/total_time:,.2f}")
    print(f"Allowed Requests: {request_counts['allowed']:,}")
    print(f"Denied Requests: {request_counts['denied']:,}")

# Example usage:
# rate_limiter = RateLimiter()
# stress_test(rate_limiter)
```

Good luck!
