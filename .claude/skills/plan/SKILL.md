---
name: plan
description: Generate a detailed implementation plan before applying code changes. Use when the user invokes `/plan <request>` to review and approve the approach before execution. The skill outputs a structured plan without making any changes, waits for approval ("aprobado"), handles feedback/revisions, and automatically executes once approved.
---

# Plan Skill

This skill implements a two-phase workflow: **Plan First, Execute Second**. When invoked with `/plan`, generate a detailed implementation plan for user review and approval before making any code changes.

## Workflow

### Phase 1: Planning (User invokes `/plan`)

When the user provides a request with `/plan`, respond with a **structured plan** that includes:

1. **Repositorio y Rama** - Specify which repository and branch the changes will go to
2. **Archivos a Modificar/Crear** - List all files that will be affected (modified or created)
3. **Cambios Específicos** - For each file, describe the specific changes that will be made
4. **Orden de Cambios** - Define the sequence in which changes will be applied
5. **Resumen** - Brief summary of what will be accomplished

**Important:** Do NOT apply any changes during this phase. Present only the plan.

**Format Example:**

```
## Plan de Implementación

**Repositorio:** sozu-admin
**Rama:** cambios_agente_alo

### Archivos a Modificar
1. `src/components/Button.tsx` - Update styling
2. `src/styles/globals.css` - Add new CSS variables
3. `.env.example` - Document new env vars

### Cambios Específicos

**src/components/Button.tsx:**
- Update button color prop handling
- Add new size variants (sm, lg)
- Improve accessibility attributes

**src/styles/globals.css:**
- Define new color variables
- Add responsive breakpoint utilities

**.env.example:**
- Add FEATURE_FLAG_NEW_BUTTON entry

### Orden de Cambios
1. Update globals.css (base styles)
2. Modify Button.tsx component
3. Update .env.example documentation

### Resumen
Implement new button variants with improved styling and accessibility. Changes are isolated to component layer with no breaking changes to existing API.

---

**¿Aprobado? (Responda "aprobado" para proceder o haga comentarios para ajustar)**
```

### Phase 2: Approval & Feedback

After presenting the plan, wait for user response:

- **If user says "aprobado"** → Execute all changes automatically in the exact sequence specified in the plan
- **If user provides feedback/comments** → Update the plan based on their input, re-present it, and wait for new approval or additional feedback. Repeat until approved.

### Phase 3: Execution (After approval "aprobado")

Once approved, automatically execute the plan:

1. Apply changes in the specified order
2. Use appropriate tools (Edit, Write, etc.) to modify files
3. Follow all existing code style and conventions
4. Make commits to the specified branch with clear messages

**After execution:** Confirm completion and summarize what was done.

## Rules

- **No changes without `/plan`**: If user requests changes without `/plan`, proceed directly with execution (existing behavior)
- **Plan-only mode**: `/plan` triggers review-before-action mode; no code changes during planning
- **Iterative refinement**: Support multiple rounds of feedback on the plan before approval
- **All repos**: This workflow applies to all repositories (sozu-admin, agente-alo, current project, etc.)
- **Branch awareness**: Always specify the target repository and branch in the plan

## Examples

**User invokes with `/plan`:**
```
/plan agregar un nuevo componente de dashboard en sozu-admin
```

**You respond with a plan** (not executing yet):
```
## Plan de Implementación
[structured plan as shown above]

¿Aprobado?
```

**User responds:**
```
aprobado
```

**You execute automatically** all changes and confirm completion.

---

**User requests without `/plan`:**
```
agregar un nuevo componente de dashboard en sozu-admin
```

**You proceed directly** with execution (existing behavior, no plan).
