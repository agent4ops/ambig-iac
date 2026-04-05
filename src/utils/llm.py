"""
Simple LLM class for handling chat with memory and Azure OpenAI integration.
"""

import os
import openai
from typing import List, Dict, Any, Optional


class LLM:
    """
    A simple LLM class that handles credentials, setup, and chat memory.
    """
    
    # Class variables with default values
    DEFAULT_MODEL = "gpt-4o-mini"
    DEFAULT_MAX_TOKENS = 16384
    DEFAULT_TEMPERATURE = 0.0
    
    def __init__(self, system_prompt: str = "You are a helpful assistant", 
                 model: str = None, max_tokens: int = None, temperature: float = None, stateful: bool = False,
                 api_key: str = None, api_version: str = None, azure_endpoint: str = None):
        """
        Initialize the LLM with system prompt and Azure credentials.
        
        Args:
            system_prompt: The system prompt to set the assistant's behavior
            model: The model to use (defaults to DEFAULT_MODEL)
            max_tokens: Maximum tokens for response (defaults to DEFAULT_MAX_TOKENS)
            temperature: Temperature for response generation (defaults to DEFAULT_TEMPERATURE)
            stateful: Whether to use stateful memory (defaults to False)
            api_key: Azure OpenAI API key (defaults to environment variables)
            api_version: Azure OpenAI API version (defaults to environment variables)
            azure_endpoint: Azure OpenAI endpoint (defaults to environment variables)
        """
        self.stateful = stateful
        self.api_key = api_key or os.environ.get("AZURE_OPENAI_API_KEY") or os.environ.get("AZURE_API_KEY")
        self.api_version = api_version or os.environ.get("OPENAI_API_VERSION") or os.environ.get("AZURE_API_VERSION")
        self.azure_endpoint = azure_endpoint or os.environ.get("AZURE_OPENAI_ENDPOINT") or os.environ.get("AZURE_API_BASE")
        
        # Initialize OpenAI client with custom or environment credentials
        self.client = openai.AzureOpenAI(
            api_key=self.api_key,
            api_version=self.api_version,
            azure_endpoint=self.azure_endpoint,
        )
        
        # Set model parameters with defaults
        self.model = model if model is not None else self.DEFAULT_MODEL
        self.max_tokens = max_tokens if max_tokens is not None else self.DEFAULT_MAX_TOKENS
        self.temperature = temperature if temperature is not None else self.DEFAULT_TEMPERATURE

        self.print_setup()
        
        # Chat memory to track conversation history
        self.memory: List[Dict[str, str]] = []
        self.system_prompt = system_prompt
        self.usage_dict = {}

        # Add system prompt to memory
        if system_prompt:
            self.memory.append({"role": "system", "content": system_prompt})
    
    def print_setup(self):
        """
        Print the setup of the LLM.
        """
        print(f"LLM setup:")
        print(f"  Model: {self.model}")
        print(f"  Max tokens: {self.max_tokens}")
        print(f"  Temperature: {self.temperature}")
        print(f"  Stateful: {self.stateful}")

    def _update_usage(self, response):
        """
        Update the usage dictionary with the response usage.
        """
        response_usage = response.usage.to_dict()

        # Extract cache token counts from prompt_tokens_details if available
        cached_tokens = 0
        details = response_usage.get("prompt_tokens_details")
        if isinstance(details, dict):
            cached_tokens = details.get("cached_tokens", 0) or 0

        usage_update = {
            "completion_tokens": response_usage["completion_tokens"],
            "prompt_tokens": response_usage["prompt_tokens"],
            "total_tokens": response_usage["total_tokens"],
            "cached_tokens": cached_tokens,
        }

        if len(self.usage_dict) == 0:
            self.usage_dict = usage_update
        else:
            for key, value in usage_update.items():
                self.usage_dict[key] = self.usage_dict.get(key, 0) + value

    def clear_usage(self):
        """
        Clear the usage dictionary.
        """
        self.usage_dict = {}

    def get_usage(self) -> Dict[str, int]:
        """
        Get the usage dictionary.
        """
        return self.usage_dict

    def get_config(self) -> Dict[str, Any]:
        """
        Get the LLM config (model, max_tokens, temperature). No API keys.
        """
        return {
            "model": self.model,
            "max_tokens": self.max_tokens,
            "temperature": self.temperature,
        }

    def __call__(self, user_request: str) -> str:
        """
        Process a user request and return the LLM response.
        
        Args:
            user_request: The user's message/request
            
        Returns:
            The LLM's response as a string
        """
        # Add user message to memory
        self.memory.append({"role": "user", "content": user_request})
        
        try:
            # Make API call to Azure OpenAI
            if self.model == "gpt-5-mini":
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=self.memory,
                    max_completion_tokens=self.max_tokens
                )
                assistant_response = response.choices[0].message.content
            elif "gpt-4o" in self.model:
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=self.memory,
                    temperature=self.temperature,
                    max_tokens=self.max_tokens
                )
                assistant_response = response.choices[0].message.content
            elif "Llama-3.3-70B-Instruct" in self.model:
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=self.memory,
                    temperature=self.temperature,
                    max_tokens=self.max_tokens
                )
                assistant_response = response.choices[0].message.content
            elif self.model == "gpt-5.1-codex-mini":
                self.client = openai.AzureOpenAI(
                    api_key=self.api_key,
                    api_version="2025-03-01-preview",
                    azure_endpoint=self.azure_endpoint,
                )

                response = self.client.responses.create(
                    model=self.model,
                    input=self.memory,
                    # reasoning={"effort": "low"}
                )
                assistant_response = response.output_text
            elif self.model == "gpt-4.1-mini":
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=self.memory,
                    temperature=self.temperature,
                    max_completion_tokens=13107
                )
                assistant_response = response.choices[0].message.content
            elif "gpt-5" in self.model:
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=self.memory,
                    max_completion_tokens=16384,
                )
                assistant_response = response.choices[0].message.content
            else:
                raise ValueError(f"Model {self.model} not supported")
            
            self._update_usage(response)

            # Add assistant response to memory
            self.memory.append({"role": "assistant", "content": assistant_response})
            if not self.stateful:
                self.clear()
            
            return assistant_response
            
        except Exception as e:
            # Remove the user message from memory if API call failed
            self.memory.pop()
            raise Exception(f"Error calling LLM: {str(e)}")
    
    def clear(self):
        """
        Clear the chat memory, keeping only the system prompt.
        """
        # Keep only the system prompt if it exists
        self.memory = []
        if self.system_prompt:
            self.memory.append({"role": "system", "content": self.system_prompt})
    
    def get_memory(self) -> List[Dict[str, str]]:
        """
        Get the current chat memory.
        
        Returns:
            List of message dictionaries with 'role' and 'content' keys
        """
        return self.memory.copy()
    
    def set_system_prompt(self, system_prompt: str):
        """
        Update the system prompt and reset memory.

        Args:
            system_prompt: New system prompt
        """
        self.system_prompt = system_prompt
        self.clear()  # This will add the new system prompt

