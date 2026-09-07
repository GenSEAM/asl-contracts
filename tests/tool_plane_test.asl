(module asl-contracts/tool-plane-test
  :d "Unit tests for AgentScript Tool Control Plane Contract Specification."
  :x [test-tool-descriptor-creation
      test-tool-scope-filtering
      test-agent-role-authorization
      test-safety-tier-enforcement
      test-secret-masking-redaction
      test-tool-validation
      run-tests]
  :i [(tool_plane :a tp)])

(df test-tool-descriptor-creation [] -> Bool
  :d "Verifies initial tool descriptor construction and properties."
  (let [(sec (tp/make-secret-ref "API_KEY" "env" "GITHUB_TOKEN" "ghp_default"))
        (t0 (tp/make-tool-descriptor
              "tool-gh"
              "GitHub CLI"
              "Manage repositories and PRs"
              "Invoke when committing, pushing, or creating PRs"
              (list "asl" "asex")
              (list "implementer" "reviewer")
              (tp/safety-guarded)
              "gh"
              (list "pr" "list")
              (map-empty)
              (list sec)))]
    (and (= (.-id t0) "tool-gh")
         (and (= (.-name t0) "GitHub CLI")
              (and (not (.-redacted t0))
                   (= (list-len (.-secrets t0)) 1))))))

(df test-tool-scope-filtering [] -> Bool
  :d "Verifies multi-repo scope isolation and wildcard acceptance."
  (let [(scoped-tool (tp/make-tool-descriptor
                       "crawler-tool" "Crawler" "doc" "guidance"
                       (list "crawler" "spider")
                       (list "*")
                       (tp/safety-safe)
                       "crawl" (list) (map-empty) (list)))
        (global-tool (tp/make-tool-descriptor
                       "global-tool" "Global" "doc" "guidance"
                       (list "*")
                       (list "*")
                       (tp/safety-safe)
                       "global" (list) (map-empty) (list)))]
    (and (tp/is-tool-in-scope? scoped-tool "crawler")
         (and (not (tp/is-tool-in-scope? scoped-tool "asl"))
              (and (tp/is-tool-in-scope? global-tool "asl")
                   (tp/is-tool-in-scope? global-tool "editorial-matrix"))))))

(df test-agent-role-authorization [] -> Bool
  :d "Verifies agent role binding and permission enforcement."
  (let [(dev-tool (tp/make-tool-descriptor
                    "dev-tool" "Dev" "doc" "guidance"
                    (list "*")
                    (list "implementer" "architect")
                    (tp/safety-guarded)
                    "dev" (list) (map-empty) (list)))
        (open-tool (tp/make-tool-descriptor
                     "open-tool" "Open" "doc" "guidance"
                     (list "*")
                     (list "*")
                     (tp/safety-safe)
                     "open" (list) (map-empty) (list)))]
    (and (tp/is-agent-authorized? dev-tool "implementer")
         (and (not (tp/is-agent-authorized? dev-tool "reviewer"))
              (and (tp/is-agent-authorized? open-tool "planner")
                   (tp/is-agent-authorized? open-tool "reviewer"))))))

(df test-safety-tier-enforcement [] -> Bool
  :d "Verifies tool safety tier checks against execution ceilings."
  (let [(safe-tool (tp/make-tool-descriptor
                     "s" "Safe" "d" "g" (list "*") (list "*")
                     (tp/safety-safe) "s" (list) (map-empty) (list)))
        (guarded-tool (tp/make-tool-descriptor
                        "g" "Guarded" "d" "g" (list "*") (list "*")
                        (tp/safety-guarded) "g" (list) (map-empty) (list)))
        (danger-tool (tp/make-tool-descriptor
                       "d" "Danger" "d" "g" (list "*") (list "*")
                       (tp/safety-dangerous) "d" (list) (map-empty) (list)))]
    (and (tp/is-safety-permitted? safe-tool (tp/safety-safe))
         (and (not (tp/is-safety-permitted? guarded-tool (tp/safety-safe)))
              (and (tp/is-safety-permitted? guarded-tool (tp/safety-guarded))
                   (and (not (tp/is-safety-permitted? danger-tool (tp/safety-guarded)))
                        (tp/is-safety-permitted? danger-tool (tp/safety-dangerous))))))))

(df test-secret-masking-redaction [] -> Bool
  :d "Verifies that masking secrets strips raw secret refs and sets redacted flag."
  (let [(sec (tp/make-secret-ref "TOKEN" "env" "SECRET_TOKEN" "default_val"))
        (raw (tp/make-tool-descriptor
               "auth-tool" "Auth" "doc" "guidance"
               (list "*") (list "*") (tp/safety-safe)
               "auth" (list) (map-empty) (list sec)))
        (masked (tp/mask-tool-secrets raw))]
    (and (not (.-redacted raw))
         (and (.-redacted masked)
              (= (list-len (.-secrets masked)) 0)))))

(df test-tool-validation [] -> Bool
  :d "Verifies structural validity and mandatory field invariants."
  (let [(valid (tp/make-tool-descriptor
                 "valid-tool" "Valid" "doc" "guidance"
                 (list "asl") (list "implementer") (tp/safety-safe)
                 "echo" (list) (map-empty) (list)))
        (invalid (tp/make-tool-descriptor
                   "" "Invalid" "doc" "guidance"
                   (list "asl") (list "implementer") (tp/safety-safe)
                   "echo" (list) (map-empty) (list)))]
    (and (tp/validate-tool-descriptor valid)
         (not (tp/validate-tool-descriptor invalid)))))

(df run-tests [] -> Bool
  :d "Executes complete unit test suite for Tool Control Plane."
  (and (test-tool-descriptor-creation)
       (and (test-tool-scope-filtering)
            (and (test-agent-role-authorization)
                 (and (test-safety-tier-enforcement)
                      (and (test-secret-masking-redaction)
                           (test-tool-validation)))))))
