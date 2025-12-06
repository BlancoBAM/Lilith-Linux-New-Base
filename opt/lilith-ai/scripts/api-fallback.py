#!/usr/bin/env python3

"""
Lilith Linux AI API Fallback System
Provides cloud AI processing for complex tasks when local hardware is insufficient
"""

import os
import sys
import json
import requests
import argparse
from pathlib import Path
from typing import Optional, Dict, Any

class APIManager:
    """Manages external AI API connections for Lilith Linux"""

    def __init__(self):
        self.config_dir = "/opt/lilith-ai/config"
        self.apis = {
            "openai": {
                "url": "https://api.openai.com/v1/chat/completions",
                "model": "gpt-4-turbo-preview",
                "headers": lambda: {"Authorization": f"Bearer {os.getenv('OPENAI_API_KEY')}"},
                "max_tokens": 4096
            },
            "anthropic": {
                "url": "https://api.anthropic.com/v1/messages",
                "model": "claude-3-opus-20240229",
                "headers": lambda: {
                    "x-api-key": os.getenv('ANTHROPIC_API_KEY'),
                    "anthropic-version": "2023-06-01"
                },
                "max_tokens": 4096
            },
            "groq": {
                "url": "https://api.groq.com/openai/v1/chat/completions",
                "model": "mixtral-8x7b-32768",
                "headers": lambda: {"Authorization": f"Bearer {os.getenv('GROQ_API_KEY')}"},
                "max_tokens": 4096
            },
            "mistral": {
                "url": "https://api.mistral.ai/v1/chat/completions",
                "model": "mistral-large-latest",
                "headers": lambda: {"Authorization": f"Bearer {os.getenv('MISTRAL_API_KEY')}"},
                "max_tokens": 4096
            },
            "gemini": {
                "url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
                "model": "gemini-pro",
                "headers": lambda: {},
                "params": lambda: {"key": os.getenv('GOOGLE_API_KEY')},
                "max_tokens": 4096
            }
        }

    def check_availability(self) -> list:
        """Check which APIs have active keys configured"""
        available = []
        for provider in self.apis.keys():
            if self.test_api(provider):
                available.append(provider)
        return available

    def test_api(self, provider: str) -> bool:
        """Test if API key works for a provider"""
        if provider not in self.apis:
            return False

        config = self.apis[provider]
        api_key_env = f"{provider.upper()}_API_KEY"

        # Special case for Google Gemini
        if provider == "gemini":
            api_key_env = "GOOGLE_API_KEY"

        if not os.getenv(api_key_env):
            return False

        try:
            headers = config["headers"]() if callable(config["headers"]) else config["headers"]

            if provider == "openai" or provider == "groq" or provider == "mistral":
                payload = {
                    "model": config["model"],
                    "messages": [{"role": "user", "content": "test"}],
                    "max_tokens": 10
                }
            elif provider == "anthropic":
                payload = {
                    "model": config["model"],
                    "messages": [{"role": "user", "content": "test"}],
                    "max_tokens": 10
                }
            elif provider == "gemini":
                params = config["params"]() if callable(config["params"]) else {}
                payload = {
                    "contents": [{
                        "parts": [{"text": "test"}]
                    }],
                    "generationConfig": {
                        "maxOutputTokens": 10
                    }
                }
                # Add API key to URL for Gemini
                config["url"] = f"{config['url']}?key={params['key']}"

            # Make test request
            response = requests.post(
                config["url"],
                headers=headers,
                json=payload,
                timeout=10
            )

            return response.status_code in [200, 201]

        except Exception:
            return False

    def query_api(self, provider: str, prompt: str, system_prompt: str = "",
                  context_mb: int = 2048) -> str:
        """Query external API for complex tasks"""
        if provider not in self.apis:
            raise ValueError(f"Unknown provider: {provider}")

        config = self.apis[provider]
        headers = config["headers"]() if callable(config["headers"]) else config["headers"]

        try:
            if provider == "openai" or provider == "groq" or provider == "mistral":
                messages = []
                if system_prompt:
                    messages.append({"role": "system", "content": system_prompt})
                messages.append({"role": "user", "content": prompt})

                payload = {
                    "model": config["model"],
                    "messages": messages,
                    "max_tokens": min(config["max_tokens"], max(512, context_mb * 4)),
                    "temperature": 0.7
                }

                response = requests.post(config["url"], headers=headers, json=payload, timeout=60)
                response.raise_for_status()

                if provider == "groq" or provider == "mistral":
                    return response.json()["choices"][0]["message"]["content"]
                else:
                    return response.json()["choices"][0]["message"]["content"]

            elif provider == "anthropic":
                full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt
                payload = {
                    "model": config["model"],
                    "messages": [{"role": "user", "content": full_prompt}],
                    "max_tokens": min(config["max_tokens"], max(512, context_mb * 4)),
                    "temperature": 0.7
                }

                response = requests.post(config["url"], headers=headers, json=payload, timeout=60)
                response.raise_for_status()

                return response.json()["content"][0]["text"]

            elif provider == "gemini":
                params = config["params"]() if callable(config["params"]) else {}
                full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt

                payload = {
                    "contents": [{
                        "parts": [{"text": full_prompt}]
                    }],
                    "generationConfig": {
                        "maxOutputTokens": min(config["max_tokens"], max(512, context_mb * 4)),
                        "temperature": 0.7
                    }
                }

                url = f"{config['url']}?key={params['key']}"
                response = requests.post(url, headers=headers, json=payload, timeout=60)
                response.raise_for_status()

                return response.json()["candidates"][0]["content"]["parts"][0]["text"]

        except Exception as e:
            raise Exception(f"API Error for {provider}: {str(e)}")


def main():
    """Main CLI interface"""
    parser = argparse.ArgumentParser(description="Lilith Linux API Fallback System")
    parser.add_argument("--list", action="store_true", help="List available APIs")
    parser.add_argument("--provider", choices=["openai", "anthropic", "groq", "mistral", "gemini"],
                       required=False)
    parser.add_argument("--prompt", required=False)
    parser.add_argument("--system-prompt", default="")
    parser.add_argument("--context-mb", type=int, default=2048)
    parser.add_argument("--output", required=False)

    args = parser.parse_args()

    api_manager = APIManager()

    if args.list:
        # List available APIs
        available = api_manager.check_availability()
        print("\n".join(available) if available else "")
        return

    if not args.provider or not args.prompt or not args.output:
        print("Error: --provider, --prompt, and --output are required", file=sys.stderr)
        sys.exit(1)

    available_apis = api_manager.check_availability()

    if args.provider not in available_apis:
        print(f"Error: {args.provider} API not available. Available: {available_apis}",
              file=sys.stderr)
        sys.exit(1)

    try:
        result = api_manager.query_api(
            args.provider,
            args.prompt,
            args.system_prompt,
            args.context_mb
        )

        with open(args.output, 'w') as f:
            f.write(result)

        print(f"API query completed - saved to {args.output}")

    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
