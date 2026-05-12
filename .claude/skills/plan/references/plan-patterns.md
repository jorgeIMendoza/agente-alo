# Plan Patterns & Examples

## Plan Structure Template

Every plan should follow this structure:

```
## Plan de Implementación

**Repositorio:** [repository name]
**Rama:** [branch name, typically cambios_agente_alo or main]

### Archivos a Modificar/Crear
- List each file with a brief description of why it changes

### Cambios Específicos
For each file, describe:
- What changes are being made
- Why the changes are needed
- Any important details (order dependencies, breaking changes, etc.)

### Orden de Cambios
- Sequential list of what gets executed when
- Consider dependencies (e.g., create base styles before using them)

### Resumen
- High-level overview of what was accomplished
- Impact assessment (breaking changes? backwards compatible?)
- Any post-execution steps needed

---

¿Aprobado? (Responda "aprobado" para proceder o haga comentarios para ajustar)
```

## Common Scenarios

### Adding a Feature
Include: feature scope, components affected, database/config changes, testing considerations

### Bug Fix
Include: root cause, affected files, why the fix works, regression risks

### Refactoring
Include: what's being reorganized, why, backwards compatibility, migration path

### Configuration/Environment Changes
Include: which env vars are added/modified, impact on different environments, examples

## User Feedback Patterns

When user provides feedback:
- **"Agregar..."** → Add more detail or additional files
- **"Cambiar..."** → Modify the approach or sequence
- **"Quitar..."** → Remove items from the plan
- **"¿Qué pasa si...?"** → Clarify edge cases or dependencies

Incorporate feedback and re-present the updated plan, then wait for "aprobado" or more feedback.
