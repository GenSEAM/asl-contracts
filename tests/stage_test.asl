(module asl-contracts/stage-test
  :d "Unit tests for AgentScript Pipeline Stage Contract Specification."
  :x [test-stage-creation
      test-stage-transitions
      test-stage-output
      test-stage-error-handling
      test-stage-terminal-states
      test-stage-invariants
      run-tests]
  :i [(stage :a st)])

(df test-stage-creation [] -> Bool
  :d "Verifies initial stage contract creation and default values."
  (let [(c (st/make-stage-contract "stage-001" (st/stage-script)))]
    (assert (= (.-id c) "stage-001") "Stage id must match stage-001")
    (assert (string-empty? (.-error-msg c)) "Stage error-msg must be empty")
    (assert (mt (.-status c) ((st/status-pending) true) (_ false)) "Initial status must be pending")
    true))

(df test-stage-transitions [] -> Bool
  :d "Verifies state transitions from pending to running to completed."
  (let [(c0 (st/make-stage-contract "stage-002" (st/stage-audio)))
        (c1 (st/stage-transition c0 (st/status-running)))
        (c2 (st/stage-transition c1 (st/status-completed)))]
    (assert (mt (.-status c1) ((st/status-running) true) (_ false)) "Status must transition to running")
    (assert (mt (.-status c2) ((st/status-completed) true) (_ false)) "Status must transition to completed")
    (assert (st/is-stage-successful? c2) "c2 must be classified as successful")
    true))

(df test-stage-output [] -> Bool
  :d "Verifies setting output key-value artifacts on the stage contract."
  (let [(c0 (st/make-stage-contract "stage-003" (st/stage-visuals)))
        (c1 (st/stage-set-output c0 "asset_count" "12"))
        (c2 (st/stage-set-output c1 "resolution" "1080x1920"))]
    (assert (map-has? (.-outputs c2) "asset_count") "Outputs must contain asset_count")
    (assert (map-has? (.-outputs c2) "resolution") "Outputs must contain resolution")
    true))

(df test-stage-error-handling [] -> Bool
  :d "Verifies stage failure recording and error propagation."
  (let [(c0 (st/make-stage-contract "stage-004" (st/stage-render)))
        (c1 (st/stage-set-error c0 "Remotion bundle failed: out of memory"))]
    (assert (mt (.-status c1) ((st/status-failed) true) (_ false)) "Status must transition to failed")
    (assert (= (.-error-msg c1) "Remotion bundle failed: out of memory") "Error msg must match")
    (assert (not (st/is-stage-successful? c1)) "Failed stage must not be classified as successful")
    true))

(df test-stage-terminal-states [] -> Bool
  :d "Verifies terminal state predicate for lifecycle statuses."
  (do
    (assert (not (st/is-stage-terminal? (st/status-pending))) "Pending must not be terminal")
    (assert (not (st/is-stage-terminal? (st/status-running))) "Running must not be terminal")
    (assert (st/is-stage-terminal? (st/status-completed)) "Completed must be terminal")
    (assert (st/is-stage-terminal? (st/status-failed)) "Failed must be terminal")
    true))

(df test-stage-invariants [] -> Bool
  :d "Verifies contract validation guards across valid and invalid states."
  (let [(valid-pending (st/make-stage-contract "stage-005" (st/stage-publish)))
        (valid-failed (st/stage-set-error valid-pending "Failed to upload to S3"))
        (invalid-failed (st/stage-transition valid-pending (st/status-failed)))]
    (assert (st/validate-stage-contract valid-pending) "valid-pending contract must be valid")
    (assert (st/validate-stage-contract valid-failed) "valid-failed contract must be valid")
    (assert (not (st/validate-stage-contract invalid-failed)) "invalid-failed contract without error msg must be invalid")
    true))

(df run-tests [] -> Bool
  :d "Executes all stage contract specification test suites."
  (do
    (assert (test-stage-creation) "test-stage-creation must pass")
    (assert (test-stage-transitions) "test-stage-transitions must pass")
    (assert (test-stage-output) "test-stage-output must pass")
    (assert (test-stage-error-handling) "test-stage-error-handling must pass")
    (assert (test-stage-terminal-states) "test-stage-terminal-states must pass")
    (assert (test-stage-invariants) "test-stage-invariants must pass")
    true))
