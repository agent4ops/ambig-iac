"""
User proxy for answering clarification questions (yes/no).
"""

from src.utils.llm import LLM


USER_PROXY_SYSTEM_PROMPT = """You are a expert in AWS cloud infrastructure and cloud configuration.
You will be given a cloud configuration and true/false questions about the configuration.
You will need to answer the questions strictly based on the configuration.

Guidelines:
- Only answer with yes or no.
- You must strictly follow the reference configuration to answer the question.

Example 1:
Task: Create an AWS resource to help me store images that I want to display on my website

Reference configuration:
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example-bucket" {
  bucket = "test-bucket"
}

Question 1: Do you need audit logging for access to the stored images?
Answer: No
Reason: The reference configuration does not contain any audit logging for access to the stored images.

Question 2: Do you want a S3 bucket for storing the images?
Answer: Yes
Reason: The reference configuration contains an S3 bucket for storing the images.

Question 3: Do you require any specific backup or recovery options for the stored images?
Answer: No
Reason: The reference configuration does not contain any specific backup or recovery options for the stored images.

End of example.

"""


class UserProxy:
    def __init__(self, llm: LLM, system_prompt: str = None, cfg: str = ""):
        self.llm = llm
        self.question_count = 0

        if cfg == "":
            raise ValueError("User proxy need to be initialized with a reference configuration")

        self.system_prompt = USER_PROXY_SYSTEM_PROMPT + f"\n\nReference configuration:\n{cfg}"
        self.llm.set_system_prompt(self.system_prompt)

    def __call__(self, request: str) -> list[bool | None]:
        self.question_count += 1
        questions = f"Question {request}\nPlease directly answer the question with yes or no. or list of yes or no answers, one answer per line."
        response = self.llm(questions)
        return self._parse_responses(response)

    def _parse_responses(self, llm_responses: str) -> list[bool | None]:
        responses = llm_responses.split("\n")
        responses_list: list[bool | None] = []
        for response in responses:
            if "yes" in response.lower():
                responses_list.append(True)
            elif "no" in response.lower():
                responses_list.append(False)
            else:
                responses_list.append(None)
        return responses_list
