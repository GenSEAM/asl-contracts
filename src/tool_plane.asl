(module asl-contracts/tool-plane
  :d "AgentScript Tool Control Plane Contract Specification: multi-repo scoping, dynamic secret resolution, agent role permissions, and operational runbooks."
  :x [ToolSafety ToolDescriptor SecretRef ToolRunbook ToolScopeContext
      safety-safe safety-guarded safety-dangerous
      make-secret-ref make-tool-descriptor make-runbook make-scope-context
      is-tool-in-scope? is-agent-authorized? is-safety-permitted?
      mask-tool-secrets validate-tool-descriptor]
  :i [])

(dfe ToolSafety
  (:c safety-safe [] "Auto-run tool with zero mutation risk or isolated read-only sandbox")
  (:c safety-guarded [] "Tool requires workspace sandbox boundary enforcement")
  (:c safety-dangerous [] "Destructive or privileged tool requiring operator confirmation"))

(dfs SecretRef
  (:f key Str "Target environment variable or parameter name")
  (:f source Str "Resolution source: env, file, keychain, or literal")
  (:f ref Str "Source reference (e.g. environment variable name or file path)")
  (:f fallback Str "Default fallback value if source is unresolved"))

(dfs ToolRunbook
  (:f id Str "Unique runbook identifier")
  (:f title Str "Human/Agent readable runbook title")
  (:f steps (List Str) "Ordered sequence of operational actions"))

(dfs ToolDescriptor
  (:f id Str "Canonical unique tool identifier")
  (:f name Str "Human/Agent readable display name")
  (:f doc Str "Summary description of tool purpose")
  (:f guidance Str "Operational instructions: when to invoke and why")
  (:f scope (List Str) "Allowed repository/project scopes, or [\"*\"] for all")
  (:f agents (List Str) "Authorized agent roles, or [\"*\"] for all")
  (:f safety ToolSafety "Tool safety classification tier")
  (:f cmd Str "Executable command binary or script name")
  (:f args (List Str) "Default CLI arguments passed to command")
  (:f env (Map Str Str) "Injected environment key-value pairs")
  (:f secrets (List SecretRef) "Dynamic secret bindings")
  (:f redacted Bool "True if secrets and sensitive tokens are masked in descriptor"))

(dfs ToolScopeContext
  (:f active-repo Str "Target repository or directory path")
  (:f agent-role Str "Active calling agent role (e.g. planner, implementer)")
  (:f safety-ceiling ToolSafety "Maximum allowable safety tier for current execution"))

(df make-secret-ref [(key Str) (source Str) (ref Str) (fallback Str)] -> SecretRef
  :d "Constructs a dynamic secret reference specification."
  (SecretRef
    :key key
    :source source
    :ref ref
    :fallback fallback))

(df make-runbook [(id Str) (title Str) (steps (List Str))] -> ToolRunbook
  :d "Constructs an operational guidance runbook."
  (ToolRunbook
    :id id
    :title title
    :steps steps))

(df make-tool-descriptor [(id Str)
                          (name Str)
                          (doc Str)
                          (guidance Str)
                          (scope (List Str))
                          (agents (List Str))
                          (safety ToolSafety)
                          (cmd Str)
                          (args (List Str))
                          (env (Map Str Str))
                          (secrets (List SecretRef))] -> ToolDescriptor
  :d "Constructs a verified tool descriptor with active unredacted secrets."
  (ToolDescriptor
    :id id
    :name name
    :doc doc
    :guidance guidance
    :scope scope
    :agents agents
    :safety safety
    :cmd cmd
    :args args
    :env env
    :secrets secrets
    :redacted false))

(df make-scope-context [(active-repo Str) (agent-role Str) (safety-ceiling ToolSafety)] -> ToolScopeContext
  :d "Constructs an execution context for resolving tools."
  (ToolScopeContext
    :active-repo active-repo
    :agent-role agent-role
    :safety-ceiling safety-ceiling))

(df is-tool-in-scope? [(tool ToolDescriptor) (repo Str)] -> Bool
  :d "Checks if tool is permitted within the specified repository scope."
  (let [(scopes (.-scope tool))]
    (or (list-contains? scopes "*")
        (or (list-contains? scopes "all")
            (or (= repo "")
                (list-contains? scopes repo))))))

(df is-agent-authorized? [(tool ToolDescriptor) (role Str)] -> Bool
  :d "Checks if specified agent role is permitted to invoke the tool."
  (let [(allowed (.-agents tool))]
    (or (list-contains? allowed "*")
        (or (= role "")
            (list-contains? allowed role)))))

(df is-safety-permitted? [(tool ToolDescriptor) (ceiling ToolSafety)] -> Bool
  :d "Checks if tool safety classification is within allowable ceiling."
  (mt (.-safety tool)
    ((safety-safe) true)
    ((safety-guarded)
     (mt ceiling
       ((safety-safe) false)
       (_ true)))
    ((safety-dangerous)
     (mt ceiling
       ((safety-dangerous) true)
       (_ false)))))

(df mask-tool-secrets [(tool ToolDescriptor)] -> ToolDescriptor
  :d "Returns tool descriptor with secrets and sensitive environment variables masked."
  (ToolDescriptor
    :id (.-id tool)
    :name (.-name tool)
    :doc (.-doc tool)
    :guidance (.-guidance tool)
    :scope (.-scope tool)
    :agents (.-agents tool)
    :safety (.-safety tool)
    :cmd (.-cmd tool)
    :args (.-args tool)
    :env (map-empty)
    :secrets (list)
    :redacted true))

(df validate-tool-descriptor [(tool ToolDescriptor)] -> Bool
  :d "Validates structural completeness and safety invariants of a tool descriptor."
  (and (not (= (.-id tool) ""))
       (and (not (= (.-cmd tool) ""))
            (not (list-contains? (.-scope tool) "")))))
