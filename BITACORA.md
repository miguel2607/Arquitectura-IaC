# Bitácora · Taller IaC con Terraform · Grupo 3

**Curso:** Arquitectura de Software II · 2026-2 · Tema VII: Infraestructura como Código

**Integrantes**

- Sofía Giraldo González
- Carlos Augusto Aranzazu
- Miguel Ángel Rodríguez

## Rotación de roles

Con 3 integrantes, Navegante y Bitácora los asume la misma persona.

| Fase | Operador/a | Navegante | Revisor/a del plan | Bitácora |
|---|---|---|---|---|
| 0 y 1 | Miguel Ángel Rodríguez | Sofía Giraldo González | Carlos Augusto Aranzazu | Sofía Giraldo González |
| 2 | Sofía Giraldo González | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Carlos Augusto Aranzazu |
| 3 | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Sofía Giraldo González | Miguel Ángel Rodríguez |
| 4 | Miguel Ángel Rodríguez | Sofía Giraldo González | Carlos Augusto Aranzazu | Sofía Giraldo González |
| 5 | Sofía Giraldo González | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Carlos Augusto Aranzazu |
| 6 | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Sofía Giraldo González | Miguel Ángel Rodríguez |
| 7 | Miguel Ángel Rodríguez | Sofía Giraldo González | Carlos Augusto Aranzazu | Sofía Giraldo González |
| 8 | Sofía Giraldo González | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Carlos Augusto Aranzazu |
| 9 | Carlos Augusto Aranzazu | Miguel Ángel Rodríguez | Sofía Giraldo González | Miguel Ángel Rodríguez |

---

## Fase 0 · Preparación del entorno

### Evidencias

```text
$ terraform -version
Terraform v1.17.1
on windows_amd64
```

```text
$ docker version
Client:
 Version:           28.1.1
 API version:       1.49
 Go version:        go1.23.8
 Git commit:        4eba377
 Built:             Fri Apr 18 09:53:24 2025
 OS/Arch:           windows/amd64
 Context:           desktop-linux

Server: Docker Desktop 4.41.2 (191736)
 Engine:
  Version:          28.1.1
  API version:      1.49 (minimum version 1.24)
  Go version:       go1.23.8
```

```text
$ git --version
git version 2.49.0.windows.1

$ docker pull nginx:1.27-alpine && docker pull nginx:1.28-alpine && docker pull postgres:17-alpine
docker.io/library/nginx:1.27-alpine
docker.io/library/nginx:1.28-alpine
docker.io/library/postgres:17-alpine
```

### Respuestas

Esta fase no tiene preguntas. Se creó el repositorio con `.gitignore`, la carpeta `infra/` y esta bitácora.

---

## Fase 1 · Arranque: hacerlo a mano

### Evidencias

```text
$ docker run -d --name clickops-g3 -p 8090:80 nginx:1.27-alpine
2aebb55738153df04a142868d565a7277ac33ebe7d906c0497695f25678a0e8f

$ curl -s http://localhost:8090 | grep -o '<title>.*</title>'
<title>Welcome to nginx!</title>
```

Repetir exactamente el mismo comando:

```text
$ docker run -d --name clickops-g3 -p 8090:80 nginx:1.27-alpine
docker: Error response from daemon: Conflict. The container name "/clickops-g3" is already in use by container "2aebb55738153df04a142868d565a7277ac33ebe7d906c0497695f25678a0e8f". You have to remove (or rename) that container to be able to reuse that name.
```

Otro nombre, mismo puerto:

```text
$ docker run -d --name clickops-g3-2 -p 8090:80 nginx:1.27-alpine
4fa3a8b558c791bfc229c1c8cb4d0e33b3f39229988af6cab94a360f9a2906b8
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint clickops-g3-2 (...): Bind for 0.0.0.0:8090 failed: port is already allocated
```

Docker alcanzó a crear el contenedor `clickops-g3-2` (imprimió su ID), pero no pudo arrancarlo: quedó creado y detenido.

```text
$ docker rm -f clickops-g3 clickops-g3-2
clickops-g3
clickops-g3-2

$ docker ps -a --filter name=clickops
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**El mismo objetivo de dos formas**

Imperativo (pasos en orden):

1. Descargar la imagen `nginx:1.27-alpine`.
2. Crear un contenedor llamado `clickops-g3` con esa imagen.
3. Publicar el puerto 80 del contenedor en el 8090 del equipo.
4. Arrancar el contenedor en segundo plano.

Declarativo (resultado deseado):

> «Quiero un contenedor `clickops-g3` con nginx 1.27 respondiendo en el puerto 8090.»

### Respuestas

1. **Error del segundo `docker run`.** `Conflict. The container name "/clickops-g3" is already in use`. Un comando imperativo no es idempotente: ejecuta la acción cada vez sin mirar si el resultado ya existe, así que repetirlo no da «lo mismo» sino un error (o, con otro nombre, un contenedor a medias que choca por el puerto). Hay que revisar a mano el estado antes de cada paso.
2. **Servidor idéntico para otro grupo.** Tendríamos que contarles el comando exacto, la imagen y la versión, el nombre, el puerto y que el 8090 debe estar libre. Eso no quedó registrado en ningún lado: solo en la historia de la terminal de quien lo tecleó y en nuestra memoria.
3. **Puntos de «Por qué duele» que vivimos.** Los cuatro: fue *propenso a errores* (el conflicto de nombre y el de puerto); *imposible de reproducir igual* (el segundo intento dejó un contenedor creado pero sin arrancar); *sin historial* (nada indica quién creó qué); y *el conocimiento se va con la persona* (solo el operador sabe qué comando usó).

---

## Fase 2 · Primer despliegue

### Evidencias

```text
$ terraform init
Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "~> 4.6"...
- Installing kreuzwerker/docker v4.6.0...
- Installed kreuzwerker/docker v4.6.0 (self-signed, key ID 0DCE698927DAF8EC)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above.
Terraform has been successfully initialized!

$ ls -a
.  ..  .terraform  .terraform.lock.hcl  main.tf

$ terraform fmt
$ terraform validate
Success! The configuration is valid.
```

```text
$ terraform plan
  # docker_container.web will be created
  + resource "docker_container" "web" {
      + name  = "web-g3"
      + ports {
          + external = 8080
          + internal = 80
        }
      ...
    }

  # docker_image.nginx will be created
  + resource "docker_image" "nginx" {
      + keep_locally = true
      + name         = "nginx:1.27-alpine"
      ...
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

Revisor del plan: **«Aprobado: 2 a crear, 0 a cambiar, 0 a destruir».**

```text
$ terraform apply
docker_image.nginx: Creating...
docker_image.nginx: Creation complete after 0s [id=sha256:6769dc3a703c...nginx:1.27-alpine]
docker_container.web: Creating...
docker_container.web: Creation complete after 1s [id=63092cf48625...]
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

$ curl -s http://localhost:8080 | grep -o '<title>.*</title>'
<title>Welcome to nginx!</title>

$ terraform output
url = "http://localhost:8080"

$ docker ps --filter name=web-g3
NAMES     IMAGE          PORTS                  STATUS
web-g3    6769dc3a703c   0.0.0.0:8080->80/tcp   Up 2 seconds
```

### Respuestas

1. **¿Cuántos recursos creó el plan?** Dos: `docker_image.nginx` y `docker_container.web`. En Terraform la imagen también es un recurso gestionado: el contenedor necesita que la imagen exista (y conocer su ID) antes de poder crearse.
2. **Orden que impone `docker_image.nginx.image_id`.** La referencia crea una dependencia implícita: primero la imagen y después el contenedor, como se ve en la salida del `apply`. Es el paso 2 de «Qué ocurre cuando aplicas»: Terraform lee el código, arma el grafo de dependencias y calcula el plan; luego (paso 3) llama al provider en ese orden.
3. **¿Qué descargó `terraform init`?** El provider `kreuzwerker/docker` v4.6.0, guardado en la carpeta oculta `.terraform/`. `.terraform.lock.hcl` fija esa versión exacta y sus hashes, para que todo el equipo use el mismo provider; por eso se versiona y `.terraform/` no.
4. **Bloque que falta de «Cómo se escribe Terraform».** `variable`. Ya tenemos `provider`, `resource` y `output`.
5. **¿Dónde quedó registrado ahora?** En `infra/main.tf`, versionado en Git con el commit `fase-2`. Cualquier grupo puede clonar el repositorio y obtener el mismo servidor con `terraform apply`.

---

## Fase 3 · Idempotencia y estado

### Evidencias

Aplicar otra vez sin cambiar nada:

```text
$ terraform apply
Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

```text
$ terraform state list
docker_container.web
docker_image.nginx

$ terraform state show docker_container.web   (extracto)
resource "docker_container" "web" {
    hostname     = "63092cf48625"
    id           = "63092cf48625e80b3fd99ccdd0d1f1ccda4f5196ca3e2a294c9875184d1ee7dd"
    image        = "sha256:6769dc3a703c719c1d2756bda113659be28ae16cf0da58dd5fd823d6b9a050ea"
    ipc_mode     = "private"
    log_driver   = "json-file"
    must_run     = true
    name         = "web-g3"
    network_data = [{ gateway = "172.17.0.1", ip_address = "172.17.0.2", network_name = "bridge", ... }]
    runtime      = "runc"
    shm_size     = 64
    ...
}
```

Lectura de `terraform.tfstate` (solo lectura):

```text
"version": 4,
"terraform_version": "1.17.1",
"serial": 4,
"lineage": "22497c04-f843-f199-04fc-e4b617aaeeb6",
"resources": [ docker_container.web, docker_image.nginx ]
```

Cambio de `nginx:1.27-alpine` a `nginx:1.28-alpine`:

```text
$ terraform plan
  # docker_container.web must be replaced
-/+ resource "docker_container" "web" {
      ~ image = "sha256:6769dc3a703c..." -> (known after apply) # forces replacement
  # docker_image.nginx must be replaced
-/+ resource "docker_image" "nginx" {
      ~ name  = "nginx:1.27-alpine" -> "nginx:1.28-alpine" # forces replacement
Plan: 2 to add, 0 to change, 2 to destroy.
```

Revisor del plan: **«Aprobado: 2 a crear, 0 a cambiar, 2 a destruir; es un reemplazo (-/+) por cambio de imagen».**

```text
$ terraform apply
docker_container.web: Destroying... [id=63092cf48625...]
docker_container.web: Destruction complete after 1s
docker_image.nginx: Destroying... [id=sha256:6769dc3a703c...nginx:1.27-alpine]
docker_image.nginx: Destruction complete after 0s
docker_image.nginx: Creating...
docker_image.nginx: Creation complete after 0s [id=sha256:dc73b49f5124...nginx:1.28-alpine]
docker_container.web: Creating...
docker_container.web: Creation complete after 1s [id=b39051a49e64...]
Apply complete! Resources: 2 added, 0 changed, 2 destroyed.

$ terraform plan
No changes. Your infrastructure matches the configuration.
```

`serial` después del reemplazo: **9** (antes: 4).

### Respuestas

1. **Respuesta en el paso 1.** «No changes… Apply complete! Resources: 0 added, 0 changed, 0 destroyed». Terraform comparó código, state e infraestructura real y no hizo nada. El segundo `docker run` de la Fase 1, en cambio, intentó crear otra vez y falló por conflicto de nombre: Terraform es idempotente, el comando imperativo no.
2. **Datos del state que no escribimos.** El `id` real del contenedor, el `hostname`, la IP y la red (`network_data`), el `image` en formato sha256, el `runtime`, `shm_size`, `log_driver`, el `repo_digest` de la imagen, etc. Terraform los necesita para saber qué objeto real corresponde a cada recurso del código, detectar diferencias y poder modificar o destruir exactamente ese objeto.
3. **¿Por qué se reemplazó?** Porque la imagen de un contenedor no se puede cambiar en sitio: el atributo marca `# forces replacement`. Terraform destruye el contenedor viejo y crea uno nuevo (`-/+`). Es la infraestructura inmutable: no se «cura» el servidor, se reemplaza completo y queda idéntico a lo descrito en el código.
4. **Cambio de `serial`.** Pasó de 4 a 9. Es un contador que aumenta cada vez que Terraform escribe una nueva versión del state; junto con `lineage` (el identificador único de ese state) permite saber qué copia es la más reciente y evitar sobrescribir un state con uno viejo.
5. **Riesgo de subir el state a Git.** El state guarda en texto plano todos los atributos de los recursos, incluidas contraseñas, cadenas de conexión y llaves de una base de datos. Subirlo a Git las filtra a cualquiera con acceso al repositorio y quedan para siempre en el historial; además, dos personas con copias distintas del state pueden pisarse los cambios.

---

## Fase 4 · Drift

### Evidencias

**Experimento A · Apagar el servidor**

```text
$ docker stop web-g3
web-g3

$ terraform plan
  # docker_container.web must be replaced
      ~ must_run          = false -> true
      + ports { # forces replacement
          + external = 8080 # forces replacement
          + internal = 80 # forces replacement
        }
Plan: 1 to add, 0 to change, 1 to destroy.
```

Revisor: **«Aprobado: 1 a crear, 0 a cambiar, 1 a destruir (reemplazo del contenedor detenido)».**

```text
$ terraform apply
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
$ curl -s http://localhost:8080 | grep -o '<title>.*</title>'
<title>Welcome to nginx!</title>
```

**Experimento B · Borrar el servidor**

```text
$ docker rm -f web-g3
web-g3

$ terraform plan -refresh-only
Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # docker_container.web has been deleted
  - resource "docker_container" "web" { ... }

This is a refresh-only plan, so Terraform will not take any actions to undo
these.

$ terraform plan
  # docker_container.web will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

Revisor: **«Aprobado: 1 a crear, 0 a cambiar, 0 a destruir».**

```text
$ terraform apply
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
$ curl -s http://localhost:8080 | grep -o '<title>.*</title>'
<title>Welcome to nginx!</title>
```

**Experimento C · Cambiar el contenido por dentro**

```text
$ docker exec web-g3 sh -c "echo '<h1>Cambio manual</h1>' > /usr/share/nginx/html/index.html"
$ curl -s http://localhost:8080
<h1>Cambio manual</h1>

$ terraform plan
No changes. Your infrastructure matches the configuration.

$ terraform apply -replace=docker_container.web
  # docker_container.web will be replaced, as requested
-/+ destroy and then create replacement
Plan: 1 to add, 0 to change, 1 to destroy.
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

$ curl -s http://localhost:8080 | grep -o '<title>.*</title>'
<title>Welcome to nginx!</title>

$ terraform plan
No changes. Your infrastructure matches the configuration.
```

**Tabla de drift**

| Experimento | ¿El plan lo detectó? | ¿Qué propuso Terraform? | ¿Cómo quedó corregido? |
|---|---|---|---|
| A · Apagar | Sí (`must_run` false → true y puertos ausentes) | Reemplazar el contenedor (`-/+`): 1 a crear, 1 a destruir | `terraform apply`: contenedor nuevo y la página responde |
| B · Borrar | Sí (`-refresh-only` informa «has been deleted») | Crear de nuevo el contenedor (`+`): 1 a crear | `terraform apply`: contenedor recreado y la página responde |
| C · Cambiar por dentro | No («No changes») | Nada | `terraform apply -replace=docker_container.web`: contenedor nuevo con el contenido original |

### Respuestas

1. **¿Por qué no detectó el experimento C?** Terraform solo compara los atributos del recurso que guarda en el state (imagen, nombre, puertos, estado de ejecución…). El archivo `index.html` dentro del contenedor no es un atributo del recurso, así que para Terraform el contenedor sigue igual. Ese nivel, lo que hay *dentro* de la máquina, le corresponde a las herramientas de **gestión de configuración** (Ansible, Chef, Puppet) de la diapositiva «Aprovisionar ≠ configurar»; Terraform es de aprovisionamiento.
2. **¿Por qué `-replace` es coherente con la infraestructura inmutable?** Porque no se entra a «arreglar» el contenedor a mano (mutable), sino que se descarta y se crea uno nuevo desde la definición del código. El resultado es idéntico a lo descrito y no arrastra cambios ocultos.
3. **Detectar drift en un equipo real.** Programando un `terraform plan` (o `plan -refresh-only` con `-detailed-exitcode`) periódico en el pipeline CI/CD, por ejemplo cada noche, que avise al equipo cuando encuentre diferencias. Además, quitando permisos de cambio manual en producción para que todo pase por el código.

---

## Fase 5 · Flexibilidad

### Evidencias

Código separado en `main.tf`, `variables.tf`, `locals.tf`, `data.tf`, `outputs.tf` y `terraform.tfvars`. TODO resueltos:

- **TODO 1:** variable `mensaje` (string, sin default) en `variables.tf`.
- **TODO 2:** local `etiquetas` = `{ curso = "arquitectura-sw-2", grupo = tostring(var.grupo) }`.
- **TODO 3 (reto):** bloque `dynamic "labels"` que recorre `local.etiquetas`.
- **TODO 4 y 5:** outputs `contenedor` y `red_driver`.

```text
$ terraform plan
  # docker_container.web must be replaced
      + labels { # forces replacement
      + labels { # forces replacement
      + upload { # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

Revisor: **«Aprobado: 1 a crear, 0 a cambiar, 1 a destruir. El contenedor se reemplaza porque agregamos `upload` (el nuevo index.html) y `labels`, y esos atributos no se pueden cambiar en un contenedor que ya existe».**

```text
$ terraform apply
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

$ curl -s http://localhost:8080
<h1>Hola desde el grupo 3</h1>
<p>Desplegado con Terraform por el grupo 3</p>

$ terraform output
contenedor = "web-g3"
red_driver = "bridge"
url = "http://localhost:8080"
```

```text
$ terraform console
> local.nombre
"web-g3"
> upper(var.mensaje)
"HOLA DESDE EL GRUPO 3"
> format("web-g%02d", var.grupo)
"web-g03"
> local.etiquetas
{
  "curso" = "arquitectura-sw-2"
  "grupo" = "3"
}
> data.docker_network.bridge.driver
"bridge"
> exit
```

```text
$ terraform plan -var="puerto=9500"
Error: Invalid value for variable

  on variables.tf line 6:
   6: variable "puerto" {
    │ var.puerto is 9500

El puerto debe estar entre 8000 y 8999.

$ terraform plan -var="puerto=8085"
          ~ external = 8080 -> 8085 # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
  ~ url        = "http://localhost:8080" -> "http://localhost:8085"
```

(Solo se planeó; no se aplicó.)

### Respuestas

1. **¿Qué valor gana?** El de mayor precedencia: `-var` en la línea de comandos gana sobre `terraform.tfvars`, y este gana sobre el `default` de la variable. Con `-var="puerto=8085"` el plan usó 8085.
2. **¿Qué hizo `validation` con 9500?** Detuvo el plan antes de llamar a Docker, con nuestro mensaje de error. Es Policy as Code en pequeño: una regla escrita en código («puertos solo entre 8000 y 8999») que la máquina hace cumplir automáticamente antes de aplicar.
3. **¿Terraform creó la red `bridge`?** No. Es un *data source*: solo la lee (por eso aparece «Reading…» y no «Creating…»). Al ejecutar `destroy` no le pasa nada, porque no está entre los recursos que Terraform gestiona.
4. **¿Qué ganamos con `local.nombre`?** El nombre se define en un solo lugar y se calcula a partir de `var.grupo`. Si cambia el grupo o el formato del nombre, se cambia una vez y todos los usos quedan coherentes; además, el mismo código sirve para cualquier grupo.

---

## Fase 6 · Módulos

### Evidencias

Módulo en `infra/modules/sitio_web/` (`versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`). La validación del puerto se movió a `variables.tf` del módulo. TODO resueltos:

- **TODO 1:** módulos `blog` (8082) y `docs` (8083) en `infra/main.tf`.
- **TODO 2:** output `urls` con la url de los tres módulos.

Limpieza de la raíz: se eliminaron `local.nombre`, `local.html` (y con ellos `local.etiquetas`, que ya nadie usaba, por lo que `locals.tf` quedó vacío y se borró), las variables `puerto` y `mensaje` (también de `terraform.tfvars`) y los outputs `url` y `contenedor`, que apuntaban a `docker_container.web`.

```text
$ terraform plan
Error: Module not installed      (x3: se olvidó el init)

$ terraform init
Initializing modules...
- docs in modules\sitio_web
- tienda in modules\sitio_web
- blog in modules\sitio_web
Terraform has been successfully initialized!

$ terraform plan
  # docker_container.web will be destroyed
  # (because docker_container.web is not in configuration)
  # docker_image.nginx will be destroyed
  # (because docker_image.nginx is not in configuration)
  # module.blog.docker_container.this will be created
  # module.blog.docker_image.this will be created
  # module.docs.docker_container.this will be created
  # module.docs.docker_image.this will be created
  # module.tienda.docker_container.this will be created
  # module.tienda.docker_image.this will be created
Plan: 6 to add, 0 to change, 2 to destroy.
```

Revisor: **«Aprobado: 6 a crear, 0 a cambiar, 2 a destruir. Se destruyen la imagen y el contenedor `web-g3` de la raíz porque ya no están en el código, y se crean imagen + contenedor para cada uno de los tres módulos».**

```text
$ terraform apply
Apply complete! Resources: 6 added, 0 changed, 2 destroyed.

$ curl -s localhost:8081 | head -1   →  <h1>Tienda del grupo 3</h1>
$ curl -s localhost:8082 | head -1   →  <h1>Blog del grupo 3</h1>
$ curl -s localhost:8083 | head -1   →  <h1>Docs del grupo 3</h1>

$ terraform output urls
[
  "http://localhost:8081",
  "http://localhost:8082",
  "http://localhost:8083",
]
```

Prueba de la pregunta 2 (se quitó `versions.tf` del módulo un momento y se volvió a poner):

```text
$ terraform init
- Finding latest version of hashicorp/docker...
Error: Failed to query available provider packages
hashicorp/docker: provider registry registry.terraform.io does not have a
provider named registry.terraform.io/hashicorp/docker
Did you intend to use kreuzwerker/docker? If so, you must specify that source
address in each module which requires that provider.
```

### Respuestas

1. **Línea `Plan:` del paso 8.** `Plan: 6 to add, 0 to change, 2 to destroy.` Se destruyeron `docker_container.web` y `docker_image.nginx` porque se eliminaron del código raíz; se crearon 6 recursos (una imagen y un contenedor por cada uno de los módulos `tienda`, `blog` y `docs`), porque cada llamada al módulo tiene su propia dirección en el state (`module.<nombre>.docker_*.this`).
2. **Error sin `versions.tf`.** `Error: Failed to query available provider packages … does not have a provider named registry.terraform.io/hashicorp/docker`. Sin declarar el origen, Terraform asume `hashicorp/docker`, que no existe.
3. **Agregar una etiqueta a todos los sitios.** Con módulo: un solo archivo (`modules/sitio_web/main.tf`), un solo bloque. Copiando y pegando: tres bloques `docker_container` (uno por sitio), con el riesgo de que alguno se quede desincronizado.
4. **¿Qué necesitaría otro grupo para usar el módulo sin copiar la carpeta?** Que el módulo esté publicado en un lugar accesible y versionado: por ejemplo este repositorio de GitHub con una etiqueta de versión, usando `source = "git::https://github.com/miguel2607/Arquitectura-IaC.git//infra/modules/sitio_web?ref=v1.0.0"`, o un registro de módulos. Además, conocer sus variables de entrada y sus outputs.

---

## Fase 7 · State remoto y ambientes

### Evidencias

La contraseña del backend se reemplaza por `****` en toda esta bitácora: nunca se escribe en el repositorio.

**Parte A · State remoto con bloqueo**

```text
$ docker run -d --name tf-state-g3 -e POSTGRES_USER=terraform -e POSTGRES_PASSWORD=**** -e POSTGRES_DB=terraform_backend -p 5433:5432 postgres:17-alpine
b492a644feea9f37731ff50a0d649d1cd56a6b4fd6ee784ae9171c242550d55c

$ export PG_CONN_STR="postgres://terraform:****@localhost:5433/terraform_backend?sslmode=disable"
```

En `main.tf`, dentro del bloque `terraform`: `backend "pg" {}`.

```text
$ terraform init -migrate-state
  Do you want to copy existing state to the new backend? ... Enter "yes" to copy
  Enter a value: yes
Successfully configured the backend "pg"! Terraform will automatically
use this backend unless the backend configuration changes.
Terraform has been successfully initialized!

$ terraform state list
data.docker_network.bridge
module.blog.docker_container.this
module.blog.docker_image.this
module.docs.docker_container.this
module.docs.docker_image.this
module.tienda.docker_container.this
module.tienda.docker_image.this

$ docker exec tf-state-g3 psql -U terraform -d terraform_backend -c "SELECT id, name FROM terraform_remote_state.states;"
 id |  name
----+---------
  1 | default
(1 row)
```

Prueba de bloqueo. Terminal 1: `terraform apply` quedó esperando en «Do you want to perform these actions?» (sin responder). Terminal 2:

```text
$ terraform plan
Error: Error acquiring the state lock

Error message: Workspace is already locked: default
Lock Info:
  ID:        eeca77b8-f7b4-9bdf-569e-2d73f553d551
  Operation: OperationTypePlan
  Who:       LAPTOP-IDV8ALI0\MIGUEL@LAPTOP-IDV8ALI0
  Version:   1.17.1
  Created:   2026-11-08 19:43:34.3732938 +0000 UTC

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time.
```

Terminal 1, al responder `no`: `Apply cancelled.`

**Parte B · Un mismo código, tres ambientes**

```text
$ terraform destroy        (workspace default)
Plan: 0 to add, 0 to change, 6 to destroy.
Destroy complete! Resources: 6 destroyed.
```

Revisor: **«Aprobado: 0 a crear, 0 a cambiar, 6 a destruir; es el workspace default, que queda vacío».**

TODO resueltos:

- **TODO 1:** atributo `imagen` en cada ambiente de `locals.tf` (dev y staging `nginx:1.28-alpine`; prod `nginx:1.27-alpine`).
- **TODO 2:** `imagen = local.amb.imagen` en `module "sitio"`.
- **TODO 3:** output `urls` como map `nombre => url`: `{ for k, m in module.sitio : m.nombre => m.url }`.

Plan en el workspace `default` (falla a propósito):

```text
$ terraform plan
Error: Invalid index
  on locals.tf line 11, in locals:
  11:   amb = local.ambientes[local.entorno]
    │ local.ambientes is object with 3 attributes
    │ local.entorno is "default"
The given key does not identify an element in this collection value.
```

```text
$ terraform init
- sitio in modules\sitio_web

$ terraform workspace new dev
Created and switched to workspace "dev"!
$ terraform apply          Revisor: «Workspace dev, 1 sitio: 2 a crear»
Plan: 2 to add, 0 to change, 0 to destroy.
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
urls = {
  "tienda-g3-dev" = "http://localhost:8101"
}

$ terraform workspace new staging
$ terraform apply          Revisor: «Workspace staging, 3 sitios: 6 a crear»
Plan: 6 to add, 0 to change, 0 to destroy.
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
urls = {
  "blog-g3-staging" = "http://localhost:8202"
  "docs-g3-staging" = "http://localhost:8203"
  "tienda-g3-staging" = "http://localhost:8201"
}

$ terraform workspace new prod
$ terraform apply          Revisor: «Workspace prod, 3 sitios: 6 a crear»
Plan: 6 to add, 0 to change, 0 to destroy.
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
urls = {
  "blog-g3-prod" = "http://localhost:8302"
  "docs-g3-prod" = "http://localhost:8303"
  "tienda-g3-prod" = "http://localhost:8301"
}

$ terraform workspace list
  default
  dev
* prod
  staging
```

```text
$ curl -s localhost:8101 | head -1  →  <h1>Tienda - DEV - grupo 3</h1>
$ curl -s localhost:8201 | head -1  →  <h1>Tienda - STAGING - grupo 3</h1>
$ curl -s localhost:8301 | head -1  →  <h1>Tienda - PROD - grupo 3</h1>

$ docker exec tf-state-g3 psql -U terraform -d terraform_backend -c "SELECT id, name FROM terraform_remote_state.states;"
 id |  name
----+---------
  1 | default
  4 | dev
  6 | staging
  8 | prod
(4 rows)

$ docker ps --filter name=-g3
NAMES               IMAGE                PORTS
blog-g3-prod        6769dc3a703c         0.0.0.0:8302->80/tcp
docs-g3-prod        6769dc3a703c         0.0.0.0:8303->80/tcp
tienda-g3-prod      6769dc3a703c         0.0.0.0:8301->80/tcp
docs-g3-staging     dc73b49f5124         0.0.0.0:8203->80/tcp
tienda-g3-staging   dc73b49f5124         0.0.0.0:8201->80/tcp
blog-g3-staging     dc73b49f5124         0.0.0.0:8202->80/tcp
tienda-g3-dev       dc73b49f5124         0.0.0.0:8101->80/tcp
tf-state-g3         postgres:17-alpine   0.0.0.0:5433->5432/tcp

$ git grep <contraseña-del-backend>
(sin resultados)
```

(`6769dc3a703c` es `nginx:1.27-alpine` y `dc73b49f5124` es `nginx:1.28-alpine`.)

### Respuestas

1. **Respuesta de la terminal 2.** `Error acquiring the state lock … Workspace is already locked: default`, con el ID del bloqueo, quién lo tiene y desde cuándo. Evita que dos personas apliquen cambios al mismo tiempo sobre el mismo state, lo que podría corromperlo o hacer que uno pise los cambios del otro.
2. **¿Dónde quedó la contraseña?** Solo en la variable de entorno `PG_CONN_STR` de la terminal (y en la configuración del contenedor del backend). No debe ir en `main.tf` porque ese archivo se versiona: quedaría en el historial de Git para siempre y la vería cualquiera con acceso al repositorio (anti-patrón «secretos en el código»).
3. **Filas de la tabla `states`.** `default`, `dev`, `staging` y `prod`: una fila por workspace. Cada workspace guarda su propio state independiente en el mismo backend.
4. **Error en `default`.** `Invalid index`: `local.ambientes` no tiene la clave `"default"`. Es útil porque impide desplegar por accidente en un ambiente sin nombre: obliga a elegir de forma explícita `dev`, `staging` o `prod`.
5. **dev con un sitio, staging igual a prod, imagen distinta.** Dev solo necesita lo mínimo para probar sin miedo y barato; staging es una réplica de producción para validar antes de lanzar, así que debe tener los mismos sitios. Prod se queda en `nginx:1.27-alpine` (la versión ya validada) hasta que staging confirme que la 1.28 funciona; así un cambio nuevo nunca llega primero a los clientes.
6. **Riesgo de compartir código y backend.** Un error de código o un `apply` hecho en el workspace equivocado afecta directamente a producción, porque nada separa físicamente los ambientes; también comparten permisos y credenciales del backend. Con carpetas separadas (cada una con su state y su configuración) el aislamiento es mayor y se pueden aplicar cambios y permisos distintos por ambiente, a costa de repetir algo de código.

---

## Fase 8 · Testing y calidad

### Evidencias

**1. Análisis estático** (desde `infra/`; no se usó tflint porque no está instalado)

```text
$ terraform fmt -check -recursive
$ echo $?
0
$ terraform validate
Success! The configuration is valid.
```

**2. Pruebas del módulo con `terraform test`**

TODO 1 resuelto: run `nombre_coincide_con_variable` (`command = plan`, `output.nombre == var.nombre`).

```text
$ cd modules/sitio_web
$ terraform init
Terraform has been successfully initialized!
$ terraform test
tests\sitio_web.tftest.hcl... in progress
  run "url_coherente_con_puerto"... pass
  run "rechaza_puerto_fuera_de_rango"... pass
  run "despliegue_real"... pass
  run "nombre_coincide_con_variable"... pass
tests\sitio_web.tftest.hcl... tearing down
tests\sitio_web.tftest.hcl... pass

Success! 4 passed, 0 failed.
```

Observador en otra terminal (`docker ps --filter name=prueba-g3` mientras corrían las pruebas):

```text
prueba-g3   Up Less than a second   0.0.0.0:8999->80/tcp
prueba-g3   Up 1 second             0.0.0.0:8999->80/tcp
```

Al terminar, `docker ps -a --filter name=prueba-g3` ya no muestra nada.

**3. Escaneo de seguridad** con checkov 3.4.3 sobre `seguridad/bucket.tf`

Primer escaneo (los cuatro valores en `false`):

```text
$ checkov -d seguridad --compact --quiet
Passed checks: 4, Failed checks: 11, Skipped checks: 0
Check: CKV_AWS_53: "Ensure S3 bucket has block public ACLS enabled"
Check: CKV_AWS_54: "Ensure S3 bucket has block public policy enabled"
Check: CKV_AWS_55: "Ensure S3 bucket has ignore public ACLs enabled"
Check: CKV_AWS_56: "Ensure S3 bucket has 'restrict_public_buckets' enabled"
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
```

Segundo escaneo (los cuatro valores corregidos a `true`):

```text
$ checkov -d seguridad --compact --quiet
Passed checks: 9, Failed checks: 6, Skipped checks: 0
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
```

**4. Mini pipeline `validar.sh`**

TODO 2: `terraform -chdir=infra/modules/sitio_web test`. TODO 3: `checkov -d seguridad --check CKV_AWS_53,CKV_AWS_54,CKV_AWS_55,CKV_AWS_56`.

```text
$ bash validar.sh
Success! The configuration is valid.
  run "url_coherente_con_puerto"... pass
  run "rechaza_puerto_fuera_de_rango"... pass
  run "despliegue_real"... pass
  run "nombre_coincide_con_variable"... pass
Success! 4 passed, 0 failed.
terraform scan results:
Passed checks: 4, Failed checks: 0, Skipped checks: 0
Check: CKV_AWS_53 ... PASSED
Check: CKV_AWS_54 ... PASSED
Check: CKV_AWS_55 ... PASSED
Check: CKV_AWS_56 ... PASSED
Validación completa: el cambio puede pasar a revisión
```

Prueba 1: se desordenó a propósito la indentación de `infra/outputs.tf`.

```text
$ bash validar.sh
outputs.tf
$ echo $?
3
```

Se detuvo en el **primer paso** (`fmt -check`), que lista el archivo mal formateado. Se restauró el archivo.

Prueba 2: se volvió a poner `block_public_acls = false`.

```text
$ bash validar.sh
Success! The configuration is valid.
Success! 4 passed, 0 failed.
Passed checks: 3, Failed checks: 1, Skipped checks: 0
	FAILED for resource: aws_s3_bucket_public_access_block.evidencias
$ echo $?
1
```

Se detuvo en el **último paso** (checkov, CKV_AWS_53) y no imprimió el mensaje final. Se devolvió el valor a `true`.

### Respuestas

1. **Qué encontró cada nivel.** El *estático* (`fmt`/`validate`) encontró problemas de forma y sintaxis sin ejecutar nada (la indentación desordenada). Las *pruebas* verificaron el comportamiento: que la URL corresponde al puerto, que se rechaza el 9500 y que el contenedor realmente se crea con el nombre esperado; eso no lo ve ni el formato ni el escáner. El *escaneo de seguridad* encontró configuraciones inseguras válidas en sintaxis (el bucket público), que ni `validate` ni las pruebas consideran errores.
2. **`docker ps` durante `despliegue_real`.** Apareció el contenedor `prueba-g3` en el puerto 8999 durante un par de segundos y luego desapareció solo. Vale la pena porque se prueba el despliegue de verdad sin tocar dev, staging ni prod, y el entorno se limpia automáticamente al terminar.
3. **Controles del bucket.** Fallaron 11: CKV_AWS_53, 54, 55, 56, CKV2_AWS_6, CKV2_AWS_61, CKV2_AWS_62, CKV_AWS_18, CKV_AWS_21, CKV_AWS_144 y CKV_AWS_145. Después de corregir quedaron 6 (eventos, replicación, ciclo de vida, logs de acceso, versionado y cifrado KMS). Los que corresponden a «sin buckets públicos» son CKV_AWS_53 a CKV_AWS_56 (bloquear ACL y políticas públicas, ignorar ACL públicas y restringir buckets públicos).
4. **Detectar antes del `apply`.** Corregir una línea de código es barato y no expone nada; en la nube el bucket ya estaría público y los datos podrían haberse filtrado antes de notarlo, además de costar dinero y trabajo revertirlo.
5. **Lugar en el pipeline.** `validar.sh` es el paso **2 · Validar** (después del commit). Luego viene el paso humano **3 · Revisar**: alguien lee y aprueba el plan propuesto antes de que se ejecute el `apply`.

---

## Fase 9 · Auditoría cruzada y cierre

### Evidencias

**Parte A · Auditoría**

Auditamos el repositorio del Grupo 1: https://github.com/ddeelena/iac-taller-gN. El resultado completo está en `AUDITORIA.md`.

```text
$ git log --all --name-only | grep tfstate
(sin resultados)

$ grep -rn --include='*.tf' docker_container infra/
infra/modules/sitio_web/main.tf:11:resource "docker_container" "this" {
infra/modules/sitio_web/outputs.tf:6:  value = docker_container.this.name

$ git log -p -S "<contraseña del backend>" --oneline
c31d20e fase-7: state remoto en postgres y tres ambientes   (aparece en BITACORA.md:269)

$ ls infra infra/modules/sitio_web
infra: data.tf  locals.tf  main.tf  modules  outputs.tf  terraform.tfvars  variables.tf
infra/modules/sitio_web: main.tf  outputs.tf  tests  variables.tf  versions.tf
```

Resultado: cumplen 4 de 6 (tocar a mano, state, copiar y pegar, archivo gigante); no cumplen «Secretos en el código» (parcial) ni «Aplicar sin leer el plan».

**Parte B · Cierre**

Plan de destrucción de cada ambiente (`terraform plan -destroy`), leído por el revisor antes de aprobar:

```text
$ terraform workspace select dev && terraform plan -destroy
  # module.sitio["tienda"].docker_container.this will be destroyed
  # module.sitio["tienda"].docker_image.this will be destroyed
Plan: 0 to add, 0 to change, 2 to destroy.

$ terraform workspace select staging && terraform plan -destroy
  # module.sitio["blog"].docker_container.this will be destroyed
  # module.sitio["blog"].docker_image.this will be destroyed
  # module.sitio["docs"].docker_container.this will be destroyed
  # module.sitio["docs"].docker_image.this will be destroyed
  # module.sitio["tienda"].docker_container.this will be destroyed
  # module.sitio["tienda"].docker_image.this will be destroyed
Plan: 0 to add, 0 to change, 6 to destroy.

$ terraform workspace select prod && terraform plan -destroy
  (los mismos 6 recursos de blog, docs y tienda)
Plan: 0 to add, 0 to change, 6 to destroy.
```

Revisor: **«Aprobado: 0 a crear, 0 a cambiar, 2 a destruir en dev; 6 a destruir en staging; 6 a destruir en prod. Solo se van los sitios del grupo; el backend no está en el state».**

Destrucción de cada ambiente, en orden `dev`, `staging`, `prod`:

```text
$ terraform workspace select dev && terraform destroy
Plan: 0 to add, 0 to change, 2 to destroy.
module.sitio["tienda"].docker_container.this: Destruction complete after 0s
module.sitio["tienda"].docker_image.this: Destruction complete after 0s
Destroy complete! Resources: 2 destroyed.

$ terraform workspace select staging && terraform destroy
Plan: 0 to add, 0 to change, 6 to destroy.
module.sitio["tienda"].docker_container.this: Destruction complete after 0s
module.sitio["tienda"].docker_image.this: Destruction complete after 0s
module.sitio["docs"].docker_container.this: Destruction complete after 0s
module.sitio["docs"].docker_image.this: Destruction complete after 0s
module.sitio["blog"].docker_container.this: Destruction complete after 0s
module.sitio["blog"].docker_image.this: Destruction complete after 0s
Destroy complete! Resources: 6 destroyed.

$ terraform workspace select prod && terraform destroy
Plan: 0 to add, 0 to change, 6 to destroy.
module.sitio["tienda"].docker_container.this: Destruction complete after 0s
module.sitio["tienda"].docker_image.this: Destruction complete after 0s
module.sitio["docs"].docker_container.this: Destruction complete after 0s
module.sitio["docs"].docker_image.this: Destruction complete after 0s
module.sitio["blog"].docker_container.this: Destruction complete after 0s
module.sitio["blog"].docker_image.this: Destruction complete after 0s
Destroy complete! Resources: 6 destroyed.
```

Solo queda el backend; se elimina al final:

```text
$ docker ps -a --filter "name=-g3"
NAMES         IMAGE                STATUS
tf-state-g3   postgres:17-alpine   Up 46 seconds

$ docker rm -f tf-state-g3
tf-state-g3

$ docker ps -a --filter "name=-g3"
NAMES     IMAGE     STATUS
```

### Respuestas

1. **Anti-patrones.** En el Grupo 1 encontramos dos: «Secretos en el código», porque el texto literal de la contraseña del backend quedó en su `BITACORA.md:269` (y por tanto en el historial, commit `c31d20e`), y «Aplicar sin leer el plan», porque solo la Fase 6 tiene escrita la aprobación del revisor con su línea `Plan:`. A nosotros el Grupo 1 nos dio «Cumple» en los seis anti-patrones, con una excepción en «Aplicar sin leer el plan»: el `terraform apply -replace` del Experimento C (Fase 4) no tiene escrita la aprobación del revisor. Además nos señalaron que todos los commits salieron de una sola cuenta de Git, por lo que el historial no refleja la rotación de roles (trabajamos desde un solo computador; la rotación quedó registrada en la tabla de esta bitácora); que la Fase 9 no tenía las salidas del `destroy` ni la eliminación del backend (agregadas arriba); que la variable `imagen` de `infra/variables.tf` quedó sin uso desde la Fase 7 (ya la eliminamos), y que en la prueba de bloqueo la información dice `OperationTypePlan` aunque la terminal 1 tenía un `apply`.
2. **Borrar el backend antes de los `destroy`.** El state de `dev`, `staging` y `prod` vive en la tabla `states` de PostgreSQL dentro de `tf-state-g3`. Si se elimina ese contenedor primero, Terraform pierde el registro de lo que creó: `init` y `destroy` ya no pueden conectarse al backend, y los siete contenedores quedarían huérfanos, existiendo en Docker sin que ningún código los administre. Habría que borrarlos a mano, que es justo el ClickOps que queremos evitar (y en la nube seguirían generando costo).
3. **Disciplina en `destroy`.** Un `destroy` también cambia la infraestructura real y no tiene vuelta atrás: lo que se borra (por ejemplo, una base de datos con sus datos) no vuelve con otro `apply`. Además, depende del workspace activo: en el workspace equivocado se destruye `prod` en vez de `dev`. Por eso el revisor lee el plan de destrucción, confirma el workspace y cuántos recursos se van, igual que antes de un `apply`.
