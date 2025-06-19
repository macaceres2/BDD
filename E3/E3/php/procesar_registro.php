<?php
// MODO DEPURACIÓN: Estas líneas nos mostrarán cualquier error en pantalla.
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

session_start();
require_once 'utils.php';

// Función para validar RUN simple
function validarRUN($run, $dv) {
    // Convertir a string para validación si viene como número
    $run_str = strval($run);
    
    // Validar que el RUN tenga 7 u 8 dígitos y no empiece por 0
    if (!is_numeric($run_str) || strlen($run_str) < 7 || strlen($run_str) > 8 || $run_str[0] == '0') {
        return false;
    }
    
    // Validar que el DV sea un dígito (0-9) o 'k'
    if (!preg_match('/^[0-9kK]$/', $dv)) {
        return false;
    }
    
    return true;
}

// Función para redirigir con mensaje
function redirigirConMensaje($tipo, $mensaje) {
    $_SESSION[$tipo . '_message'] = $mensaje;
    header("Location: registro.php");
    exit();
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    echo "Paso 1: Se ha recibido una petición POST.<br>";

    // Recibir todos los campos del formulario
    $nombre_completo = trim($_POST['nombre'] ?? '');
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    $password_confirm = $_POST['password_confirm'] ?? '';
    $correo = trim($_POST['correo'] ?? '');
    $telefono = trim($_POST['telefono'] ?? '');
    $run = trim($_POST['run'] ?? '');
    $dv = trim($_POST['dv'] ?? '');

    // Convertir RUN a entero para la base de datos
    $run_int = is_numeric($run) ? intval($run) : 0;

    echo "Paso 2: Datos recibidos del formulario:<br>";
    echo "Username: $username<br>Correo: $correo<br>Nombre: $nombre_completo<br>";
    echo "RUN: $run (convertido a int: $run_int)<br>DV: $dv<br><br>";

    // Validaciones básicas
    if (empty($nombre_completo) || empty($username) || empty($password) || 
        empty($correo) || empty($run) || empty($dv)) {
        die("Error de validación: Todos los campos obligatorios deben ser completados.");
    }

    if ($password !== $password_confirm) {
        die("Error de validación: Las contraseñas no coinciden.");
    }

    if (strlen($password) < 6) {
        die("Error de validación: La contraseña debe tener al menos 6 caracteres.");
    }

    if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) {
        die("Error de validación: El formato del correo electrónico no es válido.");
    }

    if (!validarRUN($run_int, $dv)) {
        die("Error de validación: El RUN y dígito verificador no son válidos.");
    }

    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    echo "Paso 3: Contraseña hasheada correctamente.<br>";

    $db = conectarBD();
    if (!$db) {
        die("Error fatal: No se pudo conectar a la base de datos. Revisa tus credenciales y el puerto en utils.php.");
    }
    echo "Paso 4: Conexión a la base de datos exitosa.<br><br>";

    try {
        echo "Paso 5: Iniciando bloque try...catch.<br>";

        // Verificar si el usuario, correo o RUN ya existen
        $stmt_check = $db->prepare("SELECT username, correo, run FROM persona WHERE username = :username OR correo = :correo OR run = :run");
        $stmt_check->bindParam(':username', $username);
        $stmt_check->bindParam(':correo', $correo);
        $stmt_check->bindParam(':run', $run_int, PDO::PARAM_INT);
        $stmt_check->execute();
        echo "Paso 6: Consulta de verificación de existencia ejecutada.<br>";
        
        $existing = $stmt_check->fetch(PDO::FETCH_ASSOC);
        if ($existing) {
            $conflicto = [];
            if ($existing['username'] == $username) $conflicto[] = 'nombre de usuario';
            if ($existing['correo'] == $correo) $conflicto[] = 'correo';
            if ($existing['run'] == $run_int) $conflicto[] = 'RUN';
            die("Error de lógica: El " . implode(', ', $conflicto) . " ya está en uso.");
        }
        echo "Paso 7: El usuario, correo y RUN están disponibles.<br>";

        // Iniciar transacción
        $db->beginTransaction();
        echo "Paso 8: Transacción iniciada.<br>";

        // Insertar en 'persona'
        $stmt_persona = $db->prepare(
            "INSERT INTO persona (nombre, username, contrasena, correo, telefono_contacto, run, dv) 
             VALUES (:nombre, :username, :contrasena, :correo, :telefono, :run, :dv)"
        );
        $stmt_persona->bindParam(':nombre', $nombre_completo);
        $stmt_persona->bindParam(':username', $username);
        $stmt_persona->bindParam(':contrasena', $hashed_password);
        $stmt_persona->bindParam(':correo', $correo);
        $stmt_persona->bindParam(':telefono', $telefono);
        $stmt_persona->bindParam(':run', $run_int, PDO::PARAM_INT);
        $stmt_persona->bindParam(':dv', $dv);
        
        if (!$stmt_persona->execute()) {
            throw new Exception("Error al insertar en tabla persona");
        }
        echo "Paso 9: Inserción en tabla 'persona' ejecutada exitosamente.<br>";

        // Insertar en 'usuario'
        $stmt_usuario = $db->prepare("INSERT INTO usuario (correo, puntos) VALUES (:correo, 0)");
        $stmt_usuario->bindParam(':correo', $correo);
        
        if (!$stmt_usuario->execute()) {
            throw new Exception("Error al insertar en tabla usuario");
        }
        echo "Paso 10: Inserción en tabla 'usuario' ejecutada exitosamente.<br>";

        // Si todo fue bien, confirmar transacción
        $db->commit();
        echo "Paso 11: Transacción confirmada (commit).<br>";

        // Registro exitoso - en modo depuración mostramos mensaje
        die("¡REGISTRO COMPLETADO CON ÉXITO! Puedes volver al inicio e iniciar sesión.");
        
        // Para producción, descomenta estas líneas y comenta el die() de arriba:
        // redirigirConMensaje('success', '¡Registro completado con éxito! Ya puedes iniciar sesión.');

    } catch (Exception $e) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        echo "Error capturado: " . $e->getMessage() . "<br>";
        echo "Archivo: " . $e->getFile() . "<br>";
        echo "Línea: " . $e->getLine() . "<br>";
        echo "Stack trace: <pre>" . $e->getTraceAsString() . "</pre>";
        die("¡ERROR FATAL CAPTURADO! Revisa los detalles arriba.");
    }

} else {
    die("Error: El script fue accedido sin usar el método POST.");
}
?>