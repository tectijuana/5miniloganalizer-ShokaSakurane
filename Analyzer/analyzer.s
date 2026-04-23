// ============================================================
// analyzer.s — Mini Cloud Log Analyzer — Variante D
// Detectar tres errores HTTP consecutivos (4xx o 5xx)
//
// Autor:   [Tu nombre]
// Materia: Arquitectura de Computadoras
// Fecha:   2026
//
// Descripción:
//   Lee códigos de estado HTTP desde stdin (uno por línea).
//   Mantiene un contador de errores consecutivos.
//   Si se detectan 3 o más errores seguidos, imprime alerta.
//   Un código 2xx reinicia el contador a cero.
//
// Uso:
//   cat logs.txt | ./analyzer
//
// Syscalls utilizadas (Linux ARM64):
//   read  = 63
//   write = 64
//   exit  = 93
// ============================================================

// --- Constantes de syscall Linux ARM64 ---
.equ SYS_READ,   63
.equ SYS_WRITE,  64
.equ SYS_EXIT,   93

// --- Descriptores de archivo ---
.equ STDIN,   0
.equ STDOUT,  1

// --- Parámetros del programa ---
.equ BUF_SIZE,         16    // tamaño del buffer de lectura por línea
.equ UMBRAL_ERRORES,    3    // cantidad de errores consecutivos para alerta

// ============================================================
// Sección de datos: cadenas de texto (terminadas en \n o \0)
// ============================================================
.section .data

// Mensaje cuando se detectan 3+ errores consecutivos
msg_alerta:
    .ascii "ALERTA: Se detectaron 3 errores consecutivos\n"
msg_alerta_len = . - msg_alerta

// Mensaje de resumen al finalizar — sin errores críticos
msg_ok:
    .ascii "OK: No se detectaron 3 errores consecutivos\n"
msg_ok_len = . - msg_ok

// Prefijo informativo al encontrar la secuencia
msg_detalle:
    .ascii ">> Secuencia critica detectada en el log\n"
msg_detalle_len = . - msg_detalle

// ============================================================
// Sección BSS: variables sin inicializar (en cero al inicio)
// ============================================================
.section .bss

buf:        .skip BUF_SIZE   // buffer para leer una línea de stdin

// ============================================================
// Sección de texto: código ejecutable
// ============================================================
.section .text
.global _start

// ------------------------------------------------------------
// _start: punto de entrada del programa
// Registros usados:
//   x19 = contador de errores consecutivos
//   x20 = bandera: 1 si ya se imprimió la alerta
//   x21 = número de bytes leídos (retorno de read)
//   x22 = puntero al buffer
//   x23 = código HTTP parseado (entero)
// ------------------------------------------------------------
_start:
    // Inicializar variables
    mov     x19, #0         // consecutivos = 0
    mov     x20, #0         // alerta_impresa = false

loop_leer:
    // ---------------------------------------------------------
    // Syscall read(STDIN, buf, BUF_SIZE)
    // Lee hasta BUF_SIZE bytes de stdin hacia buf
    // ---------------------------------------------------------
    mov     x8, #SYS_READ
    mov     x0, #STDIN
    adr     x1, buf
    mov     x2, #BUF_SIZE
    svc     #0
    mov     x21, x0         // x21 = bytes leídos

    // Si read retorna <= 0: fin de stdin (EOF o error)
    cmp     x21, #0
    ble     fin_lectura

    // ---------------------------------------------------------
    // Parsear el código HTTP: convertir primeros 3 dígitos ASCII
    // a entero. El buffer contiene algo como "200\n" o "503\n".
    //
    // Fórmula: código = (buf[0]-'0')*100 + (buf[1]-'0')*10 + (buf[2]-'0')
    // ---------------------------------------------------------
    adr     x22, buf

    // Verificar que tenemos al menos 3 bytes
    cmp     x21, #3
    blt     loop_leer       // línea muy corta, ignorar

    // Dígito de centenas
    ldrb    w23, [x22, #0]  // w23 = buf[0] (ASCII)
    sub     w23, w23, #'0'  // w23 = dígito centenas
    // Validar que es dígito (0-9)
    cmp     w23, #9
    bhi     loop_leer
    cmp     w23, #0
    blt     loop_leer

    // código = centenas * 100
    mov     w0, #100
    mul     w23, w23, w0

    // Dígito de decenas
    ldrb    w1, [x22, #1]
    sub     w1, w1, #'0'
    cmp     w1, #9
    bhi     loop_leer
    cmp     w1, #0
    blt     loop_leer
    // código += decenas * 10
    mov     w0, #10
    mul     w1, w1, w0
    add     w23, w23, w1

    // Dígito de unidades
    ldrb    w1, [x22, #2]
    sub     w1, w1, #'0'
    cmp     w1, #9
    bhi     loop_leer
    cmp     w1, #0
    blt     loop_leer
    // código += unidades
    add     w23, w23, w1

    // ---------------------------------------------------------
    // Clasificar el código HTTP
    //
    // Error = código >= 400 (cubre 4xx y 5xx)
    // Éxito = código >= 200 && código < 300  (2xx)
    // 3xx   = ignorado (no afecta al contador)
    // ---------------------------------------------------------
    cmp     w23, #400
    bge     es_error        // >= 400 → error

    // No es error: verificar si es 2xx para resetear contador
    cmp     w23, #200
    blt     loop_leer       // < 200: ignorar (1xx u otro)
    cmp     w23, #300
    bge     loop_leer       // >= 300 y < 400: 3xx, ignorar

    // Es 2xx → resetear contador de errores consecutivos
    mov     x19, #0
    b       loop_leer

es_error:
    // Incrementar contador de errores consecutivos
    add     x19, x19, #1

    // ¿Llegamos al umbral de 3 errores consecutivos?
    cmp     x19, #UMBRAL_ERRORES
    blt     loop_leer       // aún no: seguir leyendo

    // ---------------------------------------------------------
    // Se detectaron 3 errores consecutivos
    // Imprimir alerta solo la primera vez
    // ---------------------------------------------------------
    cmp     x20, #1
    beq     loop_leer       // ya fue impresa, seguir leyendo

    // Marcar que ya se imprimió
    mov     x20, #1

    // Imprimir mensaje de detalle
    mov     x8, #SYS_WRITE
    mov     x0, #STDOUT
    adr     x1, msg_detalle
    mov     x2, #msg_detalle_len
    svc     #0

    // Imprimir mensaje de alerta
    mov     x8, #SYS_WRITE
    mov     x0, #STDOUT
    adr     x1, msg_alerta
    mov     x2, #msg_alerta_len
    svc     #0

    b       loop_leer       // continuar procesando el resto del log

// ------------------------------------------------------------
// fin_lectura: se llegó al EOF de stdin
// Imprimir resumen final según si hubo alerta o no
// ------------------------------------------------------------
fin_lectura:
    cmp     x20, #1
    beq     salir_con_error

    // No hubo 3 errores consecutivos → estado OK
    mov     x8, #SYS_WRITE
    mov     x0, #STDOUT
    adr     x1, msg_ok
    mov     x2, #msg_ok_len
    svc     #0

    // exit(0) — éxito
    mov     x8, #SYS_EXIT
    mov     x0, #0
    svc     #0

salir_con_error:
    // exit(1) — se detectó condición crítica
    mov     x8, #SYS_EXIT
    mov     x0, #1
    svc     #0
