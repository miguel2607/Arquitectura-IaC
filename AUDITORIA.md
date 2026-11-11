# Auditoría cruzada · Grupo 3 audita al Grupo 1

**Auditores:** Grupo 3 (Sofía Giraldo González, Carlos Augusto Aranzazu, Miguel Ángel Rodríguez)
**Grupo auditado:** Grupo 1 (Manuel Rodríguez, Xiomara Ocampo, Derly Quejada, Luisa Londoño)
**Repositorio auditado:** https://github.com/ddeelena/iac-taller-gN (commit `08337c5`, fase-8)

## Resultado por anti-patrón

| Anti-patrón | Resultado | Evidencia |
|---|---|---|
| Tocar a mano | Cumple | `BITACORA.md` solo registra comandos de Docker en las fases 1 (ClickOps), 4 (drift) y 7 (backend). En la Fase 2 el puerto se cambió de 8080 a 8081 editando `main.tf`, no a mano. |
| State sin proteger | Cumple | `git log --all --name-only \| grep tfstate` no devuelve nada; `.gitignore` excluye `*.tfstate` y `*.tfstate.*`. |
| Copiar y pegar | Cumple | `grep -rn --include='*.tf' docker_container infra/` solo aparece en `infra/modules/sitio_web/main.tf:11` y `outputs.tf:6`. Los siete sitios salen de un solo `module "sitio"` con `for_each`. |
| Secretos en el código | No cumple (parcial) | El backend está vacío (`backend "pg" {}`) y la cadena de conexión no aparece en ningún archivo, pero el texto literal de la contraseña sí está en `BITACORA.md:269` (entró en el commit `c31d20e`). `git log -p -S` y `git grep` con la contraseña lo encuentran, justo en la frase que dice que `git grep` no encuentra nada. |
| Aplicar sin leer el plan | No cumple | La única aprobación del revisor escrita en la bitácora es la de la Fase 6 (`BITACORA.md:194`, «Aprobado: 6 a crear, 0 a cambiar, 2 a destruir»). Los `apply` de las fases 2, 3, 4, 5 y 7 no tienen su línea `Plan:` ni la aprobación en texto; las salidas quedaron solo como capturas en `Evidencias/`. |
| Un solo archivo gigante | Cumple | `ls infra` muestra `main.tf`, `variables.tf`, `locals.tf`, `data.tf`, `outputs.tf` y `terraform.tfvars`; el módulo tiene `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf` y `tests/`. |

## Hallazgos concretos

1. **La bitácora quedó con plantillas sin llenar.** `BITACORA.md:255` conserva `<pegar aquí la salida de terraform plan en la terminal 2>` en la prueba de bloqueo, y `BITACORA.md:338-341` deja la tabla del escaneo con `<n>` y `<lista de IDs…>`, aunque los IDs reales sí están más arriba (`BITACORA.md:309` y `313`). Además, la guía pide pegar las salidas como texto en bloques de código y la mayoría de las evidencias son capturas de pantalla.
2. **La `N` del grupo no se reemplazó en todo el código.** `infra/modules/sitio_web/tests/sitio_web.tftest.hcl:2` y `:24` siguen usando `prueba-gN`, aunque la bitácora (`BITACORA.md:326`) dice que en `docker ps` apareció `prueba-g1`; el repositorio también se llama `iac-taller-gN`. Relacionado: quedaron comentarios `# TODO` de tareas ya resueltas en `infra/locals.tf:14-16` y `infra/main.tf:19`, y la variable `imagen` de `infra/variables.tf:6-10` ya no la usa nadie desde la Fase 7.

## Recomendación

Quitar el texto literal de la contraseña de `BITACORA.md:269` (por ejemplo, escribir «`git grep` con la contraseña no encuentra nada») y, como ya está en el historial, cambiar la contraseña del backend si el contenedor se va a reutilizar. En la misma pasada, completar las plantillas pendientes de la bitácora pegando como texto las salidas de `terraform plan`/`apply` con la línea `Plan:` y la frase de aprobación del revisor en cada fase.
