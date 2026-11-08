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

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 7 · State remoto y ambientes

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 8 · Testing y calidad

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._

---

## Fase 9 · Auditoría cruzada y cierre

### Evidencias

_Pendiente._

### Respuestas

_Pendiente._
