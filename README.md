# Mini Cloud Log Analyzer — Variante D
### Detectar tres errores HTTP consecutivos

**Materia:** Arquitectura de Computadoras  
**Lenguaje:** ARM64 Assembly (GNU Assembler)  
**Entorno:** AWS Ubuntu ARM64
## Nombre: Noyola Rivera Carlos Ernesto
## Numero de control: 22210327

---

## Descripción

Este programa analiza códigos de estado HTTP leídos desde `stdin` y detecta
si en algún punto del log aparecen **tres o más errores consecutivos**
(códigos 4xx o 5xx). Al detectarlos, imprime una alerta y continúa procesando.

### Uso

```bash
make
cat logs.txt | ./analyzer
```

---

## Diseño y lógica

### Flujo principal

```
inicio
  ↓
leer línea de stdin (read syscall)
  ↓ EOF?  → imprimir resumen final → exit
  ↓
parsear 3 dígitos ASCII → código HTTP (entero)
  ↓
¿código >= 400?
  ├─ SÍ → consecutivos++
  │         ¿consecutivos >= 3?
  │           ├─ SÍ + primera vez → imprimir ALERTA
  │           └─ NO → continuar
  └─ NO → ¿código 2xx?
            ├─ SÍ → consecutivos = 0
            └─ NO (3xx/1xx) → ignorar
  ↓
volver a leer siguiente línea
```

### Clasificación de códigos

| Rango | Categoría  | Efecto en contador         |
|-------|-----------|----------------------------|
| 2xx   | Éxito     | Resetea consecutivos a 0   |
| 3xx   | Redirección | Ignorado (no afecta)     |
| 4xx   | Error cliente | Incrementa consecutivos |
| 5xx   | Error servidor | Incrementa consecutivos |

### Registros ARM64 utilizados

| Registro | Uso                                              |
|----------|--------------------------------------------------|
| `x19`    | Contador de errores consecutivos                 |
| `x20`    | Bandera: 1 si ya se imprimió la alerta           |
| `x21`    | Bytes retornados por `read` syscall              |
| `x22`    | Puntero al buffer de lectura                     |
| `x23`    | Código HTTP parseado (valor entero)              |
| `x8`     | Número de syscall (convención Linux ARM64)       |
| `x0–x2`  | Argumentos de syscall                            |

### Syscalls Linux ARM64 utilizadas

| Syscall | Número | Uso                        |
|---------|--------|----------------------------|
| `read`  | 63     | Leer línea de stdin         |
| `write` | 64     | Imprimir mensajes a stdout  |
| `exit`  | 93     | Terminar el proceso         |

### Parsing del código HTTP

El buffer contiene caracteres ASCII. Se extraen los primeros 3 bytes y se
convierten a entero mediante:

```
código = (buf[0] - '0') × 100
       + (buf[1] - '0') × 10
       + (buf[2] - '0')
```

Usando instrucciones `ldrb` (load register byte) y operaciones aritméticas
ARM64 (`sub`, `mul`, `add`).

---

## Código de salida

| Código | Significado                              |
|--------|------------------------------------------|
| `0`    | No se detectaron 3 errores consecutivos  |
| `1`    | Se detectó la condición crítica          |

---

## Instrucciones ARM64 destacadas

- `ldrb` — carga un byte desde memoria (para leer dígito ASCII)
- `mul` — multiplicación para construir valor decimal
- `cmp` / `bge` / `blt` / `beq` — comparaciones y saltos condicionales
- `svc #0` — invocación de syscall Linux
- `adr` — dirección relativa al PC para referenciar datos
- `b` — salto incondicional (bucle principal)

---

## Evidencia de ejecución

```
$ make
as --warn --fatal-warnings -o analyzer.o analyzer.s
ld -o analyzer analyzer.o
>>> Compilación exitosa: ./analyzer

$ cat logs.txt | ./analyzer
>> Secuencia critica detectada en el log
ALERTA: Se detectaron 3 errores consecutivos

$ echo $?
1
```

### Test sin errores consecutivos:
```
$ printf "200\n404\n200\n503\n200\n" | ./analyzer
OK: No se detectaron 3 errores consecutivos

$ echo $?
0
```
- No usar C para la lógica
- No usar Python para la lógica
- No modificar la variante asignada (D)
- No omitir el uso de ARM64 Assembly
