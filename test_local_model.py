
import sys
import os

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), ".")))

from trendradar.ai.client import AIClient
from unittest.mock import patch, MagicMock

def test_config_support():
    config = {
        "MODEL": "openai/qwen/qwen3.6-35b-a3b",
        "API_KEY": "EMPTY",
        "API_BASE": "http://localhost:1234/v1",
        "TEMPERATURE": 1.0,
        "MAX_TOKENS": 5000,
        "TIMEOUT": 120,
        "NUM_RETRIES": 2,
        "FALLBACK_MODELS": []
    }
    
    client = AIClient(config)
    
    # Check validation
    is_valid, error = client.validate_config()
    print(f"Config valid: {is_valid}")
    if error:
        print(f"Error: {error}")
        
    # Mock completion to see parameters
    with patch('trendradar.ai.client.completion') as mock_completion:
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "Test response"
        mock_completion.return_value = mock_response
        
        messages = [{"role": "user", "content": "Hello"}]
        client.chat(messages)
        
        # Verify call parameters
        args, kwargs = mock_completion.call_args
        print("\nLiteLLM call parameters:")
        for k, v in kwargs.items():
            print(f"  {k}: {v}")

if __name__ == "__main__":
    test_config_support()
