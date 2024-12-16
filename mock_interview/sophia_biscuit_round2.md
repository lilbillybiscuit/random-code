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
# Token Bucket Extension

Building upon your basic rate limiter implementation, we now need to add burst handling capability to make our system more flexible for real-world usage patterns. This is particularly useful for handling traffic spikes and rewarding users who don't constantly max out their quota.

Extend your rate limiter to include a token bucket system that:
- Maintains the base rate limit of 50 requests per second per user
- Allows users to accumulate "burst tokens" during periods of inactivity
- Uses these tokens to temporarily exceed the base rate limit when needed

### Technical Specifications
1. Token Accumulation:
   - Users accumulate 1 token per second of inactivity
   - Maximum token accumulation of 100 tokens per user
   - Tokens should be calculated precisely based on elapsed time
   - Tokens are consumed only when the base rate limit is exceeded

Extend your `RateLimiter` class with this additional method:

```python
def get_burst_allowance(self, user_id: str) -> float:
    """
    Returns the number of burst tokens available for the user.
    
    Args:
        user_id (str): The identifier for the user
        
    Returns:
        float: Number of tokens available (0.0 to 100.0)
    """
    pass
```

Modify your existing `is_allowed` method to automatically use burst tokens when needed:
```python
def is_allowed(self, user_id: str) -> bool:
    """
    Returns True if the request is allowed, using burst tokens if necessary.
    
    Args:
        user_id (str): The identifier for the user making the request
        
    Returns:
        bool: True if the request is allowed, False otherwise
    """
    pass
```

### Test Script
```python
def test_token_bucket(rate_limiter):
    user_id = "test_user"
    
    # Test 1: Initial tokens
    initial_tokens = rate_limiter.get_burst_allowance(user_id)
    print(f"Initial tokens: {initial_tokens}")
    
    # Test 2: Token accumulation
    time.sleep(3)  # Wait 3 seconds
    tokens_after_wait = rate_limiter.get_burst_allowance(user_id)
    print(f"Tokens after 3s wait: {tokens_after_wait}")
    
    # Test 3: Burst capacity
    results = []
    for _ in range(70):  # Try 70 requests (20 over base limit)
        results.append(rate_limiter.is_allowed(user_id))
    
    print(f"Burst test: {sum(results)}/70 requests allowed")
    print(f"Remaining tokens: {rate_limiter.get_burst_allowance(user_id)}")

# Run the test:
# rate_limiter = RateLimiter()
# test_token_bucket(rate_limiter)
```

## Example Behavior
```python
rate_limiter = RateLimiter()
user = "user123"

# After 5 seconds of inactivity
print(rate_limiter.get_burst_allowance(user))  # Should be ~5.0

# Burst of 60 requests
for _ in range(60):
    rate_limiter.is_allowed(user)  # First 50 use base limit, next 10 use tokens
```

Good luck!
