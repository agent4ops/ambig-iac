from src.edit_actions import EditAction
from src.methods.dimension_aware_refinement import (
    RefinementCandidate,
    _apply_history_to_pool,
    _build_candidates_from_block,
    _build_dimension_schedule,
    _build_pool_budget,
    _candidate_key,
    _filter_already_asked_candidates,
    _available_candidates,
    _generate_question_from_candidate,
    _prune_candidates,
    _regeneration_reason,
)


def _resource_candidate(*values: str) -> RefinementCandidate:
    return RefinementCandidate(
        dimension="resource",
        actions=[
            EditAction(op="add", field="resource", value=value)
            for value in values
        ],
    )


def _topology_candidate(*values: str) -> RefinementCandidate:
    return RefinementCandidate(
        dimension="topology",
        actions=[
            EditAction(op="add", field="topology", value=value)
            for value in values
        ],
    )


def _attribute_candidate(
    op: str = "add",
    value: str = "web",
    json_value: dict | None = None,
) -> RefinementCandidate:
    return RefinementCandidate(
        dimension="attribute",
        actions=[
            EditAction(
                op=op,
                field="attribute",
                value=value,
                json_value=json_value,
            )
        ],
    )


def test_build_dimension_schedule_groups_by_dimension():
    budget = {
        "resource": 2,
        "topology": 1,
        "attribute": 2,
    }

    schedule = _build_dimension_schedule(budget)

    assert schedule == [
        "resource",
        "resource",
        "topology",
        "attribute",
        "attribute",
    ]


def test_build_pool_budget_counts_bundle_candidates_by_dimension():
    candidates = [
        _resource_candidate("aws_vpc.main"),
        _resource_candidate("aws_subnet.sub1", "aws_instance.web"),
        _topology_candidate("web{sub1}"),
        _attribute_candidate(json_value={"instance_type": "t3.micro"}),
    ]

    runtime_weights, final_weights, budget = _build_pool_budget(
        candidates,
        remaining_rounds=4,
        ratios=(3, 2, 1),
        skip_prior_weighting=False,
    )

    assert runtime_weights == {
        "resource": 2,
        "topology": 1,
        "attribute": 1,
    }
    assert final_weights == {
        "resource": 6,
        "topology": 2,
        "attribute": 1,
    }
    assert budget == {
        "resource": 3,
        "topology": 1,
        "attribute": 0,
    }


def test_build_candidates_from_mixed_block_keeps_bundle_intact():
    block = (
        "add(resource, aws_vpc.main)\n"
        "add(topology, web{sub1})\n"
        'add(attribute, web, {"instance_type": "t3.micro"})\n'
    )

    candidates = _build_candidates_from_block(block)

    assert len(candidates) == 1
    assert candidates[0].dimension == "resource"
    assert [action.field for action in candidates[0].actions] == [
        "resource",
        "topology",
        "attribute",
    ]


def test_prune_candidates_yes_keeps_resource_supersets():
    chosen = _resource_candidate("aws_vpc.main")
    superset = _resource_candidate("aws_vpc.main", "aws_subnet.sub1")
    other = _resource_candidate("aws_s3_bucket.logs")
    pool = [chosen, superset, other, _topology_candidate("web{sub1}")]

    pruned = _prune_candidates(pool, chosen, observed_answer=True)

    assert chosen in pruned
    assert superset in pruned
    assert other not in pruned
    assert not any(candidate.dimension == "topology" for candidate in pruned)


def test_prune_candidates_no_drops_resource_supersets_only():
    chosen = _resource_candidate("aws_vpc.main")
    superset = _resource_candidate("aws_vpc.main", "aws_subnet.sub1")
    other = _resource_candidate("aws_s3_bucket.logs")

    pruned = _prune_candidates([chosen, superset, other], chosen, observed_answer=False)

    assert chosen not in pruned
    assert superset not in pruned
    assert other in pruned


def test_prune_candidates_yes_on_bundle_drops_weaker_resource_alternatives():
    singleton_a = _resource_candidate("aws_vpc.main")
    singleton_b = _resource_candidate("aws_subnet.sub1")
    bundle = _resource_candidate("aws_vpc.main", "aws_subnet.sub1")

    pruned = _prune_candidates(
        [singleton_a, singleton_b, bundle],
        bundle,
        observed_answer=True,
    )

    assert pruned == [bundle]


def test_prune_candidates_yes_applies_across_non_attribute_dimensions():
    chosen = RefinementCandidate(
        dimension="resource",
        actions=[
            EditAction(op="add", field="resource", value="aws_vpc.main"),
            EditAction(op="add", field="topology", value="sub1{main}"),
        ],
    )
    topology_only = RefinementCandidate(
        dimension="topology",
        actions=[EditAction(op="add", field="topology", value="sub1{main}")],
    )
    superset = RefinementCandidate(
        dimension="resource",
        actions=[
            EditAction(op="add", field="resource", value="aws_vpc.main"),
            EditAction(op="add", field="topology", value="sub1{main}"),
            EditAction(op="add", field="attribute", value="sub1", json_value={"cidr_block": "10.0.1.0/24"}),
        ],
    )

    pruned = _prune_candidates(
        [chosen, topology_only, superset],
        chosen,
        observed_answer=True,
    )

    assert chosen in pruned
    assert topology_only not in pruned
    assert superset in pruned


def test_prune_candidates_only_drops_chosen_attribute_when_disconfirmed():
    chosen = _attribute_candidate(
        value="web",
        json_value={"instance_type": "t3.micro"},
    )
    other_attribute = _attribute_candidate(
        value="web",
        json_value={"ami": "ami-123"},
    )
    pool = [
        chosen,
        other_attribute,
        _resource_candidate("aws_instance.web"),
    ]

    pruned = _prune_candidates(pool, chosen, observed_answer=False)

    assert chosen not in pruned
    assert other_attribute in pruned
    assert any(candidate.dimension == "resource" for candidate in pruned)


def test_generate_question_from_bundle_candidate_is_deterministic():
    candidate = _resource_candidate("aws_vpc.main", "aws_subnet.sub1")

    question = _generate_question_from_candidate(candidate)

    assert question == (
        "Should it have resource aws_vpc.main and have resource aws_subnet.sub1?"
    )


def test_generate_question_from_mixed_bundle_uses_end_state_language():
    candidate = RefinementCandidate(
        dimension="resource",
        actions=[
            EditAction(op="add", field="resource", value="aws_vpc.main"),
            EditAction(op="remove", field="resource", value="aws_s3_bucket.logs"),
        ],
    )

    question = _generate_question_from_candidate(candidate)

    assert question == (
        "Should it have resource aws_vpc.main and not have resource aws_s3_bucket.logs?"
    )


def test_available_candidates_excludes_previously_asked_candidates():
    chosen_bundle = _resource_candidate("aws_vpc.main")
    other_bundle = _resource_candidate("aws_s3_bucket.logs")
    chosen_attribute = _attribute_candidate(json_value={"instance_type": "t3.micro"})
    other_attribute = _attribute_candidate(json_value={"ami": "ami-123"})

    resource_available = _available_candidates(
        [chosen_bundle, other_bundle],
        "resource",
        {_candidate_key(chosen_bundle)},
        set(),
    )
    attribute_available = _available_candidates(
        [chosen_attribute, other_attribute],
        "attribute",
        set(),
        {_candidate_key(chosen_attribute)},
    )

    assert resource_available == [other_bundle]
    assert attribute_available == [other_attribute]


def test_regenerated_pool_is_repruned_and_deduped_against_asked_bundles():
    chosen = _resource_candidate("aws_vpc.main")
    superset = _resource_candidate("aws_vpc.main", "aws_subnet.sub1")
    other = _resource_candidate("aws_s3_bucket.logs")
    regenerated_pool = [chosen, superset, other]

    repruned_pool = _apply_history_to_pool(regenerated_pool, [(chosen, True)])
    filtered_pool = _filter_already_asked_candidates(
        repruned_pool,
        {_candidate_key(chosen)},
        set(),
    )

    assert filtered_pool == [superset]


def test_regeneration_reason_triggers_on_empty_pool():
    assert (
        _regeneration_reason([], "resource", set(), set())
        == "empty_pool_with_budget_remaining"
    )


def test_regeneration_reason_triggers_on_missing_dimension_after_asked_filter():
    pool = [
        _resource_candidate("aws_vpc.main"),
        _attribute_candidate(json_value={"cidr_block": "10.0.0.0/16"}),
    ]

    assert (
        _regeneration_reason(
            pool,
            "resource",
            {_candidate_key(pool[0])},
            set(),
        )
        == "no_resource_actions_for_scheduled_round"
    )
