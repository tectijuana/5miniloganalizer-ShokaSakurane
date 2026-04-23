# ============================================================
# Makefile — Mini Cloud Log Analyzer — Variante D
# Compilación ARM64 Assembly con GNU Assembler + Linker
# ============================================================
 
# Nombre del ejecutable final
TARGET = analyzer
 
# Archivo fuente en ensamblador
SRC = analyzer.s
 
# Herramientas GNU para ARM64
AS  = as
LD  = ld
 
# Flags del ensamblador
# --warn: mostrar advertencias
# --fatal-warnings: tratar advertencias como errores
ASFLAGS = --warn --fatal-warnings
 
# Flags del enlazador
LDFLAGS =
 
# Archivo objeto intermedio
OBJ = analyzer.o
 
# ============================================================
# Regla principal: compilar el ejecutable
# ============================================================
all: $(TARGET)
 
$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -o $(TARGET) $(OBJ)
	@echo ">>> Compilación exitosa: ./$(TARGET)"
 
$(OBJ): $(SRC)
	$(AS) $(ASFLAGS) -o $(OBJ) $(SRC)
 
# ============================================================
# Ejecutar con el archivo de logs de prueba
# ============================================================
run: $(TARGET)
	cat logs.txt | ./$(TARGET)
 
# ============================================================
# Pruebas adicionales
# ============================================================
test: $(TARGET)
	@echo "--- Test 1: sin errores consecutivos ---"
	@printf "200\n200\n404\n200\n500\n200\n" | ./$(TARGET)
	@echo ""
	@echo "--- Test 2: exactamente 3 errores seguidos ---"
	@printf "200\n404\n503\n500\n200\n" | ./$(TARGET)
	@echo ""
	@echo "--- Test 3: más de 3 errores seguidos ---"
	@printf "404\n500\n503\n404\n200\n" | ./$(TARGET)
	@echo ""
	@echo "--- Test 4: logs.txt completo ---"
	cat logs.txt | ./$(TARGET)
 
# ============================================================
# Limpiar archivos generados
# ============================================================
clean:
	rm -f $(OBJ) $(TARGET)
	@echo ">>> Limpieza completada"
 
.PHONY: all run test clean
