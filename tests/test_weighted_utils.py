from src.methods.weighted_utils import resolve_final_weights


def test_resolve_final_weights_applies_prior_by_default():
    runtime_weights = {"resource": 2, "topology": 3, "attribute": 4}

    final_weights = resolve_final_weights(
        "question",
        runtime_weights,
        prior=(3, 2, 1),
    )

    assert final_weights == {
        "resource": 6,
        "topology": 6,
        "attribute": 4,
    }


def test_resolve_final_weights_skips_prior_when_requested():
    runtime_weights = {"resource": 2, "topology": 3, "attribute": 4}

    final_weights = resolve_final_weights(
        "spec",
        runtime_weights,
        prior=(3, 2, 1),
        skip_prior_weighting=True,
    )

    assert final_weights == runtime_weights


def test_resolve_final_weights_keeps_fixed_weights_unchanged():
    runtime_weights = {"resource": 3, "topology": 2, "attribute": 1}

    final_weights = resolve_final_weights(
        "fixed",
        runtime_weights,
        prior=(9, 9, 9),
    )

    assert final_weights == runtime_weights
