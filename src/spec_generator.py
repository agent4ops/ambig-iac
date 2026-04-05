"""
SpecGenerator: LLM-based generation of infrastructure specs and spec edits.

Owns its own LLM instance. Each method sets the system prompt (instructions)
then sends the task context as the user message.
Callers dump the conversation via ``llm.get_memory()``.
"""

import json
from typing import List, Optional

from src.utils.llm import LLM
from src.config import make_llm
from src.spec_types import Spec


_SPEC_SYSTEM_PROMPT = """
You are an infrastructure spec generator for AWS Terraform. Output a single JSON object with exactly these keys:

# Spec structure:
## 'resources': 
Maps short label strings to full Terraform addresses in the form 'aws_resource_type.instance_name'. IMPORTANT: use real AWS Terraform provider resource types (e.g. 'aws_vpc', 'aws_subnet', 'aws_instance', 'aws_s3_bucket', 'aws_cloudwatch_log_group', 'aws_route53_zone'). Never use shortened names like 'vpc.main' or 'ec2.instance'.

## 'topology': 
Maps src_label to list of dep_labels (dependency edges). Labels must match keys in 'resources'.

## 'attributes': 
Maps each resource label to a dict of key Terraform attributes for that resource (e.g. cidr_block, instance_type, engine, ami, etc.). Include the most important configuration attributes that would be needed to generate valid Terraform code.

# Guidelines:
- Strictly follow the given user request and clarification Q&A history to generate the spec.
- [Very Important] Never generate empty spec, if the request is very vague, take a random guess and generate a small spec to save infrastructure costs.
- [Very Important] Never hallucinate extra resources, topology, or attributes that are not explicitly mentioned in the user prompt or clarification Q&A. 
- [Very Important] Be more conservative, do not generate resources, and leave topology, or attributes empty if they are not clearly specified in the user prompt or clarification Q&A.
- [Important] Pay attention to the clarification Q&A history and infer the user's intent from it.
- [Important] Pay attention to the questions, when user reject a options means the exect given options are not what user wants. But some options might still be partially correct.

Example output:
{
  "resources": {
    "main": "aws_vpc.main",
    "sub1": "aws_subnet.sub1",
    "web": "aws_instance.web"
  },
  "topology": {
    "sub1": ["main"],
    "web": ["sub1"]
  },
  "attributes": {
    "main": {"cidr_block": "10.0.0.0/16"},
    "sub1": {"cidr_block": "10.0.1.0/24", "availability_zone": "us-east-1a"},
    "web": {"instance_type": "t2.micro", "ami": "ami-0c55b159cbfafe1f0"}
  }
}

Output ONLY the JSON object, no markdown, no explanations.
"""

_DIVERSE_SPEC_SYSTEM_PROMPT = """
You are an infrastructure spec generator for AWS Terraform. You are generating ONE POSSIBLE interpretation of an ambiguous infrastructure request. The request can be interpreted in multiple valid ways — your job is to pick a SPECIFIC interpretation that may differ from others.

Focus on STRUCTURAL diversity — vary your choices in:
- **Resources**: Consider different AWS services that could fulfill the same need (e.g., ALB vs NLB, RDS vs Aurora vs DynamoDB, CloudWatch vs S3 for logging, Lambda vs ECS vs EC2)
- **Topology**: Consider different dependency structures and how resources connect (e.g., direct vs through a gateway, single-tier vs multi-tier, which resources reference which)
- **Resource count**: Consider different numbers of resources (e.g., 2 replicas vs 3, single AZ vs multi-AZ)

Output a single JSON object with exactly these keys:

## 'resources':
Maps short label strings to full Terraform addresses in the form 'aws_resource_type.instance_name'. Use real AWS Terraform provider resource types.

## 'topology':
Maps src_label to list of dep_labels (dependency edges). Labels must match keys in 'resources'.

## 'attributes':
Maps each resource label to a dict of key Terraform attributes for that resource.

# Guidelines:
- Focus on structural choices (which resources exist, how they connect) rather than specific IDs or values.
- Do NOT invent specific IDs, ARNs, subnet IDs, AMI IDs, zone IDs, or account numbers.
- For attributes that reference other resources, use Terraform resource references (e.g., "${aws_db_instance.main.id}", "${aws_route53_zone.primary.zone_id}") instead of hardcoded IDs.
- For attributes, include structurally meaningful ones (e.g., engine type, instance_class, record type, source_db_instance_identifier) using resource references where appropriate.
- Include topology edges whenever resources logically depend on each other.
- Follow the user request and any clarification Q&A, but fill in ambiguous structural details with specific choices.

Output ONLY the JSON object, no markdown, no explanations.
"""

_EDIT_SYSTEM_PROMPT_TOPO = (
    "You are an infrastructure topology editor. "
    "Resources are fixed — do NOT add or remove resources. "
    "Only add or remove topology (dependency) edges.\n\n"
    "IMPORTANT: src_label and dep_label must be label keys that exist "
    "in the current spec's 'resources' dict (e.g. 'main', 'sub1').\n\n"
    "Output {{n}} separate option blocks. Each block starts with "
    "'### Option N ###' on its own line. Format:\n"
    "  add(topology, src_label{dep_label})\n"
    "  remove(topology, src_label{dep_label})\n\n"
    "Example:\n"
    "### Option 1 ###\n"
    "add(topology, subnet{vpc})\n"
    "### Option 2 ###\n"
    "add(topology, instance{subnet})\n"
    "remove(topology, instance{vpc})\n"
    "### Option 3 ###\n"
    "add(topology, subnet{vpc})\n"
    "add(topology, instance{subnet})\n\n"
    "Output ONLY the option blocks, no other text."
)

_EDIT_SYSTEM_PROMPT_FULL = (
    "You are an infrastructure spec editor. "
    "A spec 'resources' dict maps short labels to full Terraform addresses "
    "in the form 'aws_resource_type.instance_name' "
    "(e.g. 'main' -> 'aws_vpc.main', 'sub1' -> 'aws_subnet.sub1').\n\n"
    "IMPORTANT rules:\n"
    "- add(resource, ...) value MUST be 'aws_resource_type.instance_name' "
    "with a real AWS Terraform provider type (e.g. aws_vpc.main, "
    "aws_subnet.sub1, aws_instance.web). Never use short names like 'vpc.main'.\n"
    "- For data sources, use 'data.aws_resource_type.instance_name' "
    "(e.g. data.aws_iam_policy_document.policy1, data.aws_availability_zones.available).\n"
    "- topology labels must be keys from the 'resources' dict.\n\n"
    "Output {{n}} separate option blocks. Each block starts with "
    "'### Option N ###' on its own line. Format:\n"
    "  add(resource, aws_resource_type.instance_name)\n"
    "  remove(resource, aws_resource_type.instance_name)\n"
    "  add(topology, src_label{dep_label})\n"
    "  remove(topology, src_label{dep_label})\n"
    '  add(attribute, label, {"key": "value", ...})\n'
    "  remove(attribute, label)\n\n"
    "Example:\n"
    "### Option 1 ###\n"
    "add(resource, aws_vpc.main)\n"
    "add(topology, sub1{main})\n"
    'add(attribute, main, {"cidr_block": "10.0.0.0/16"})\n'
    "### Option 2 ###\n"
    "add(resource, aws_subnet.sub1)\n"
    "add(resource, aws_vpc.main)\n"
    'add(attribute, sub1, {"cidr_block": "10.0.1.0/24"})\n'
    "### Option 3 ###\n"
    "remove(resource, aws_s3_bucket.old)\n"
    "add(resource, aws_vpc.main)\n\n"
    "Output ONLY the option blocks, no other text."
)

# ---------------------------------------------------------------------------
# AWSCC provider variants
# The AWSCC provider wraps CloudFormation and uses the naming convention:
#   awscc_<service>_<resource>  (e.g. awscc_ec2_vpc, awscc_s3_bucket)
# Attribute names follow CloudFormation PascalCase conventions mapped to
# snake_case by the provider (e.g. cidr_block, image_id, instance_type).
# ---------------------------------------------------------------------------

_AWSCC_SPEC_SYSTEM_PROMPT = """
You are an infrastructure spec generator for the Terraform AWSCC provider. Output a single JSON object with exactly these keys:

# Spec structure:
## 'resources':
Maps short label strings to full Terraform addresses in the form 'awscc_<service>_<resource>.instance_name'. IMPORTANT: use real AWSCC Terraform provider resource types following the pattern awscc_<aws_service>_<resource_type> (e.g. 'awscc_ec2_vpc', 'awscc_ec2_subnet', 'awscc_ec2_instance', 'awscc_s3_bucket', 'awscc_logs_log_group', 'awscc_route53_hosted_zone', 'awscc_iam_role', 'awscc_lambda_function', 'awscc_dynamodb_table'). Never use the classic AWS provider types like 'aws_vpc' or 'aws_instance'.

## 'topology':
Maps src_label to list of dep_labels (dependency edges). Labels must match keys in 'resources'.

## 'attributes':
Maps each resource label to a dict of key Terraform attributes for that resource. AWSCC attributes use snake_case equivalents of CloudFormation properties (e.g. cidr_block, instance_type, image_id, engine_name, family_name, function_name). Include the most important configuration attributes that would be needed to generate valid Terraform code.

# Guidelines:
- Strictly follow the given user request and clarification Q&A history to generate the spec.
- [Very Important] Never hallucinate extra resources, topology, or attributes that are not explicitly mentioned in the user prompt or clarification Q&A.
- [Very Important] Be more conservative, do not generate resources, and leave topology, or attributes empty if they are not clearly specified in the user prompt or clarification Q&A.
- [Important] Pay attention to the clarification Q&A history and infer the user's intent from it.
- [Important] Pay attention to the questions, when user reject a options means the exect given options are not what user wants. But some options might still be partially correct.

Example output:
{
  "resources": {
    "main": "awscc_ec2_vpc.main",
    "sub1": "awscc_ec2_subnet.sub1",
    "web": "awscc_ec2_instance.web"
  },
  "topology": {
    "sub1": ["main"],
    "web": ["sub1"]
  },
  "attributes": {
    "main": {"cidr_block": "10.0.0.0/16"},
    "sub1": {"cidr_block": "10.0.1.0/24", "availability_zone": "us-east-1a"},
    "web": {"instance_type": "t2.micro", "image_id": "ami-0c55b159cbfafe1f0"}
  }
}

Output ONLY the JSON object, no markdown, no explanations.
"""

_AWSCC_EDIT_SYSTEM_PROMPT_TOPO = (
    "You are an infrastructure topology editor for the Terraform AWSCC provider. "
    "Resources are fixed — do NOT add or remove resources. "
    "Only add or remove topology (dependency) edges.\n\n"
    "IMPORTANT: src_label and dep_label must be label keys that exist "
    "in the current spec's 'resources' dict (e.g. 'main', 'sub1').\n\n"
    "Output {{n}} separate option blocks. Each block starts with "
    "'### Option N ###' on its own line. Format:\n"
    "  add(topology, src_label{dep_label})\n"
    "  remove(topology, src_label{dep_label})\n\n"
    "Example:\n"
    "### Option 1 ###\n"
    "add(topology, subnet{vpc})\n"
    "### Option 2 ###\n"
    "add(topology, instance{subnet})\n"
    "remove(topology, instance{vpc})\n"
    "### Option 3 ###\n"
    "add(topology, subnet{vpc})\n"
    "add(topology, instance{subnet})\n\n"
    "Output ONLY the option blocks, no other text."
)

_AWSCC_EDIT_SYSTEM_PROMPT_FULL = (
    "You are an infrastructure spec editor for the Terraform AWSCC provider. "
    "A spec 'resources' dict maps short labels to full Terraform addresses "
    "in the form 'awscc_<service>_<resource>.instance_name' "
    "(e.g. 'main' -> 'awscc_ec2_vpc.main', 'sub1' -> 'awscc_ec2_subnet.sub1').\n\n"
    "IMPORTANT rules:\n"
    "- add(resource, ...) value MUST be 'awscc_<service>_<resource>.instance_name' "
    "with a real AWSCC Terraform provider type "
    "(e.g. awscc_ec2_vpc.main, awscc_ec2_subnet.sub1, awscc_ec2_instance.web). "
    "Never use classic AWS provider types like 'aws_vpc.main'.\n"
    "- For data sources, use 'data.awscc_<service>_<resource>.instance_name' "
    "(e.g. data.awscc_ec2_vpc.existing, data.awscc_iam_role.existing).\n"
    "- topology labels must be keys from the 'resources' dict.\n\n"
    "Output {{n}} separate option blocks. Each block starts with "
    "'### Option N ###' on its own line. Format:\n"
    "  add(resource, awscc_service_resource.instance_name)\n"
    "  remove(resource, awscc_service_resource.instance_name)\n"
    "  add(topology, src_label{dep_label})\n"
    "  remove(topology, src_label{dep_label})\n"
    '  add(attribute, label, {"key": "value", ...})\n'
    "  remove(attribute, label)\n\n"
    "Example:\n"
    "### Option 1 ###\n"
    "add(resource, awscc_ec2_vpc.main)\n"
    "add(topology, sub1{main})\n"
    'add(attribute, main, {"cidr_block": "10.0.0.0/16"})\n'
    "### Option 2 ###\n"
    "add(resource, awscc_ec2_subnet.sub1)\n"
    "add(resource, awscc_ec2_vpc.main)\n"
    'add(attribute, sub1, {"cidr_block": "10.0.1.0/24"})\n'
    "### Option 3 ###\n"
    "remove(resource, awscc_s3_bucket.old)\n"
    "add(resource, awscc_ec2_vpc.main)\n\n"
    "Output ONLY the option blocks, no other text."
)

_INTERPRETATION_EDIT_SYSTEM_PROMPT = (
    "You are analyzing an ambiguous AWS Terraform request. "
    "You will be given the original user prompt, optional clarification Q&A, "
    "and one generated infrastructure spec.\n\n"
    "Generate edit actions that capture as many materially different plausible "
    "interpretations of the request as you can justify. There may be one "
    "interpretation or several.\n\n"
    "Rules:\n"
    "- Output ONLY edit actions, grouped into blocks starting with "
    "'### Interpretation N ###'.\n"
    "- Every action must use exactly one of these axis fields: resource, "
    "topology, attribute.\n"
    "- Each block may contain multiple edit actions that belong together as "
    "one candidate bundle.\n"
    "- Attribute-only interpretations should use one attribute edit per block.\n"
    "- Use the existing edit grammar only:\n"
    "  add(resource, aws_resource_type.instance_name)\n"
    "  remove(resource, aws_resource_type.instance_name)\n"
    "  add(topology, src_label{dep_label})\n"
    "  remove(topology, src_label{dep_label})\n"
    '  add(attribute, label, {"key": "value", ...})\n'
    "  remove(attribute, label)\n"
    "- Resource values must use real Terraform AWS resource types.\n"
    "- Topology labels must match keys in the current spec's resources dict.\n"
    "- Focus on edits that reflect distinct interpretations, not formatting "
    "variations.\n\n"
    "Examples:\n"
    "### Interpretation 1 ###\n"
    "add(resource, aws_vpc.main)\n"
    'add(attribute, main, {"cidr_block": "10.0.0.0/16"})\n'
    "### Interpretation 2 ###\n"
    "add(resource, aws_subnet.sub1)\n"
    "remove(resource, aws_s3_bucket.old)\n"
    "### Interpretation 3 ###\n"
    "add(resource, aws_vpc.main)\n"
    "add(resource, aws_subnet.sub1)\n"
    "### Interpretation 4 ###\n"
    "add(resource, aws_vpc.main)\n"
    "add(topology, sub1{main})\n"
    'add(attribute, sub1, {"cidr_block": "10.0.1.0/24"})\n'
    "### Interpretation 5 ###\n"
    "add(resource, aws_vpc.main)\n"
    "remove(resource, aws_s3_bucket.old)\n"
    "### Interpretation 6 ###\n"
    "add(topology, web{sub1})\n"
    "remove(topology, web{main})\n"
    "### Interpretation 7 ###\n"
    'add(attribute, web, {"instance_type": "t3.micro"})\n\n'
    "..."
    "### Interpretation N ###\n"
    "..."
    "Output ONLY the edit actions."
)


class SpecGenerator:
    """
    Generates and edits infrastructure specs via single-turn LLM calls.

    Each method sets the system prompt (instructions), then sends the task
    context as the user message.  Memory after each call contains the clean
    [system, user, assistant] triple.
    """

    def __init__(self, llm: LLM = None, config: dict = None, awscc: bool = False):
        self.llm = llm or make_llm(config or {}, "generator", stateful=True, temperature=0.0)
        self.call_count = 0
        self.awscc = awscc
        self.diverse_usage: dict[str, int] = {}

    def generate_spec(self, spec_or_prompt, feedback: str = "") -> str:
        """
        Ask the LLM to produce a complete new spec JSON.

        Args:
            spec_or_prompt: Either a dict (current spec) or a string (task prompt).
            feedback:       Mismatch or task description to guide generation.

        Returns:
            Raw LLM response string (expected to contain a JSON object).
        """
        if self.awscc:
            self.llm.set_system_prompt(_AWSCC_SPEC_SYSTEM_PROMPT)
        else:
            self.llm.set_system_prompt(_SPEC_SYSTEM_PROMPT)

        if isinstance(spec_or_prompt, dict):
            context = f"Current spec:\n{json.dumps(spec_or_prompt, indent=2)}"
        else:
            context = f"Task description: {spec_or_prompt}"

        parts = [context]
        if feedback:
            parts.append(f"Feedback / issue: {feedback}")

        self.call_count += 1
        return self.llm("\n\n".join(parts))

    def generate_diverse_specs(
        self,
        prompt: str,
        n: int,
        feedback: str = "",
        config: dict = None,
        max_workers: int = 10,
    ) -> list[str]:
        """
        Generate N diverse spec interpretations for an ambiguous prompt.

        The first spec uses the standard system prompt (deterministic, temp=0).
        Remaining specs use a diversity-encouraging prompt with temperature,
        generated concurrently using a thread pool.

        Token usage from all workers is aggregated into self.diverse_usage.

        Args:
            prompt: Task description.
            n: Number of specs to generate.
            feedback: Optional clarified intent or Q/A feedback.
            config: Config dict for creating diverse LLM instances.
            max_workers: Number of concurrent LLM calls for diverse specs.

        Returns:
            List of raw LLM response strings (each expected to be JSON).
        """
        from concurrent.futures import ThreadPoolExecutor, as_completed

        # First: deterministic spec (uses self.llm — usage tracked there)
        deterministic_result = self.generate_spec(prompt, feedback=feedback)

        if n <= 1:
            return [deterministic_result]

        # Build the user message for diverse specs
        def _call_diverse(i: int) -> tuple[str, dict]:
            diverse_llm = make_llm(
                config or {}, "generator", stateful=False, temperature=0.7,
            )
            diverse_llm.set_system_prompt(_DIVERSE_SPEC_SYSTEM_PROMPT)
            try:
                parts = [f"Task description: {prompt}"]
                if feedback:
                    parts.append(f"Feedback / issue: {feedback}")
                parts.append(
                    f"This is interpretation {i + 1} of {n}. "
                    f"Make specific, concrete choices that may differ from other interpretations."
                )
                result = diverse_llm("\n\n".join(parts))
                usage = diverse_llm.get_usage()
                return result, usage
            finally:
                diverse_llm.client.close()

        # Run diverse specs concurrently
        diverse_results: list[str | None] = [None] * (n - 1)
        workers = min(max_workers, n - 1)
        with ThreadPoolExecutor(max_workers=workers) as executor:
            future_to_idx = {
                executor.submit(_call_diverse, i): i - 1
                for i in range(1, n)
            }
            for future in as_completed(future_to_idx):
                idx = future_to_idx[future]
                try:
                    text, usage = future.result()
                    diverse_results[idx] = text
                    # Aggregate usage
                    for key in ("completion_tokens", "prompt_tokens", "total_tokens", "cached_tokens"):
                        self.diverse_usage[key] = self.diverse_usage.get(key, 0) + usage.get(key, 0)
                except Exception as e:
                    print(f"  [generate_diverse_specs] Worker {idx+1} failed: {e}")
                    diverse_results[idx] = "{}"

        self.call_count += n - 1
        return [deterministic_result] + [r or "{}" for r in diverse_results]

    def generate_edits(
        self,
        spec: dict,
        feedback: str,
        n: int = 3,
        freeze_resources: bool = False,
        implicit_intent: str = "",
    ) -> str:
        """
        Ask the LLM to produce N sets of spec edit actions.

        Each set is delimited by '### Option N ###'.  The raw response string is
        returned; callers split and parse with parse_edits / apply_edits.
        """
        if self.awscc:
            prompt = (_AWSCC_EDIT_SYSTEM_PROMPT_TOPO if freeze_resources
                      else _AWSCC_EDIT_SYSTEM_PROMPT_FULL)
        else:
            prompt = (_EDIT_SYSTEM_PROMPT_TOPO if freeze_resources
                  else _EDIT_SYSTEM_PROMPT_FULL)
        self.llm.set_system_prompt(prompt.replace("{{n}}", str(n)))

        parts = []
        if implicit_intent:
            parts.append(f"Clarified requirements:\n{implicit_intent}")
        parts.append(f"Current spec:\n{json.dumps(spec, indent=2)}")
        parts.append(f"Issue to fix: {feedback}")

        self.call_count += 1
        return self.llm("\n\n".join(parts))

    def generate_interpretation_edits(
        self,
        task_prompt: str,
        spec: Spec,
        clarified_intent: str = "",
    ) -> str:
        """
        Ask the LLM to emit edit actions for distinct prompt interpretations.

        Args:
            task_prompt: Original infrastructure request.
            spec: Generated base spec to reinterpret.
            clarified_intent: Optional Q/A-derived feedback context.

        Returns:
            Raw LLM response string containing edit actions.
        """
        self.llm.set_system_prompt(_INTERPRETATION_EDIT_SYSTEM_PROMPT)

        parts = [f"Infrastructure request: {task_prompt}"]

        if clarified_intent:
            parts.append(f"Additional feedback:\n{clarified_intent}")

        parts.append(f"Current spec:\n{json.dumps(spec, indent=2)}")
        parts.append(
            "Generate edit actions for every distinct plausible interpretation "
            "you see in this request."
        )

        self.call_count += 1

        return self.llm("\n\n".join(parts))

