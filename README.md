# Práctica 1
## Implementación de un Mini Cloud Log Analyzer en ARM64

**Modalidad:** Individual  
**Entorno de trabajo:** AWS Ubuntu ARM64 + GitHub Classroom  
**Lenguaje:** ARM64 Assembly (GNU Assembler) + Bash + GNU Make  
**Variante asignada:** D — Detectar tres errores consecutivos

---

## 📦 Entrega de la practica

🔽 Descarga el proyecto completo:  
👉 [MiniCloudAnalyzer.zip](https://github.com/user-attachments/files/26989903/MiniCloudAnalyzer.zip)


### Contenido del archivo:

- `analyzer.s` → Código fuente en ARM64 Assembly
- `Makefile` → Script de compilación
- `logs.txt` → Archivo de pruebas
- `README.md` → Documentación del proyecto

---

## Introducción

Los sistemas modernos de cómputo en la nube generan continuamente registros (logs) que permiten monitorear el estado de servicios, detectar fallas y activar alertas ante eventos críticos.

En esta práctica se desarrolla un módulo simplificado de análisis de logs, implementado en ARM64 Assembly, inspirado en tareas reales de monitoreo utilizadas en sistemas cloud, observabilidad y administración de infraestructura.

El programa procesa códigos de estado HTTP suministrados mediante entrada estándar:

```bash
cat logs.txt | ./analyzer
```

---

## 🎯 Objetivo general

Diseñar e implementar, en lenguaje ensamblador ARM64, una solución para procesar registros de eventos y detectar la condición de **tres errores consecutivos** definida en la variante D.

---

## ⚠️ Variante D — Detectar tres errores consecutivos

El programa debe leer los códigos HTTP línea por línea y determinar si en algún punto se reciben tres respuestas de error (4xx o 5xx) de forma consecutiva.

**Regla:**
- Error = códigos entre 400 y 599
- Se detectan 3 errores seguidos

**Lógica aplicada:**
contador = 0
por cada código leído:
si 400 <= código <= 599:
contador++
si no:
contador = 0
si contador == 3:
    mostrar mensaje y terminar

---

## 🧠 Objetivos específicos

- Programación en ARM64 bajo Linux
- Manejo de registros (`x19`, `x20`)
- Direccionamiento y acceso a memoria
- Instrucciones de comparación (`cmp`)
- Estructuras iterativas en ensamblador
- Saltos condicionales (`bne`, `beq`, `blt`, `bgt`)
- Uso de syscalls Linux (`read`, `write`, `exit`)
- Compilación con GNU Make
- Control de versiones con GitHub Classroom

---

## 📁 Estructura del proyecto
MiniCloudAnalyzer/
├── analyzer.s
├── Makefile
├── logs.txt
└── README.md

---

## ⚙️ Compilación

```bash
make
```

## ▶️ Ejecución

```bash
cat logs.txt | ./analyzer
```

## ✅ Resultado esperado
Tres errores consecutivos detectados

---

## 📸 Evidencia

Se debe incluir una captura de pantalla donde se observe:

```bash
make
make run
```

---

## 📌 Entregables

- Código ARM64 funcional (`analyzer.s`)
- Archivo comprimido `MiniCloudAnalyzer.zip`
- README documentado
- Evidencia de ejecución
- Historial de commits en GitHub Classroom

---

## 📊 Criterios de evaluación

| Criterio | Ponderación |
|---|---|
| Compilación correcta | 20% |
| Correctitud de la solución | 35% |
| Uso adecuado de ARM64 | 25% |
| Documentación y comentarios | 10% |
| Evidencia de pruebas | 10% |

---

## 🚫 Restricciones

- No usar C para la lógica
- No usar Python para la lógica
- No modificar la variante asignada (D)
- No omitir el uso de ARM64 Assembly
