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
    (and (= (.-id c) "stage-001")
         (and (string-empty? (.-error-msg c))
              (mt (.-status c)
                ((st/status-pending) true)
                (_ false))))))

(df test-stage-transitions [] -> Bool
  :d "Verifies state transitions from pending to running to completed."
  (let [(c0 (st/make-stage-contract "stage-002" (st/stage-audio)))
        (c1 (st/stage-transition c0 (st/status-running)))
        (c2 (st/stage-transition c1 (st/status-completed)))]
    (and (mt (.-status c1)
           ((st/status-running) true)
           (_ false))
         (and (mt (.-status c2)
                ((st/status-completed) true)
                (_ false))
              (st/is-stage-successful? c2)))))

(df test-stage-output [] -> Bool
  :d "Verifies setting output key-value artifacts on the stage contract."
  (let [(c0 (st/make-stage-contract "stage-003" (st/stage-visuals)))
        (c1 (st/stage-set-output c0 "asset_count" "12"))
        (c2 (st/stage-set-output c1 "resolution" "1080x1920"))]
    (and (map-has? (.-outputs c2) "asset_count")
         (map-has? (.-outputs c2) "resolution"))))

(df test-stage-error-handling [] -> Bool
  :d "Verifies stage failure recording and error propagation."
  (let [(c0 (st/make-stage-contract "stage-004" (st/stage-render)))
        (c1 (st/stage-set-error c0 "Remotion bundle failed: out of memory"))]
    (and (mt (.-status c1)
           ((st/status-failed) true)
           (_ false))
         (and (= (.-error-msg c1) "Remotion bundle failed: out of memory")
              (not (st/is-stage-successful? c1))))))

(df test-stage-terminal-states [] -> Bool
  :d "Verifies terminal state predicate for lifecycle statuses."
  (and (not (st/is-stage-terminal? (st/status-pending)))
       (and (not (st/is-stage-terminal? (st/status-running)))
            (and (st/is-stage-terminal? (st/status-completed))
                 (st/is-stage-terminal? (st/status-failed))))))

(df test-stage-invariants [] -> Bool
  :d "Verifies contract validation guards across valid and invalid states."
  (let [(valid-pending (st/make-stage-contract "stage-005" (st/stage-publish)))
        (valid-failed (st/stage-set-error valid-pending "Failed to upload to S3"))
        (invalid-failed (st/stage-transition valid-pending (st/status-failed)))]
    (and (st/validate-stage-contract valid-pending)
         (and (st/validate-stage-contract valid-failed)
              (not (st/validate-stage-contract invalid-failed))))))

(df run-tests [] -> Bool
  :d "Executes all stage contract specification test suites."
  (and (test-stage-creation)
       (and (test-stage-transitions)
            (and (test-stage-output)
                 (and (test-stage-error-handling)
                      (and (test-stage-terminal-states)
                           (test-stage-invariants)))))))
