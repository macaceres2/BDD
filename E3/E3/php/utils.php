<?php
function conectarBD() {
    $host = 'localhost';
    $port = '5432'; // Puerto por defecto de PostgreSQL
    $dbname = 'e3'; // Cambia por el nombre de tu BD
    $user = 'postgres';
    $password = 'hJkpukibu534';

    // DSN correcto para PostgreSQL (sin user y password en la cadena)
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname";

    try {
        // Pasar usuario y contraseña como parámetros separados
        $db = new PDO($dsn, $user, $password);
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        // Opcional: configurar codificación UTF-8
        $db->exec("SET NAMES 'UTF8'");
        
        return $db;
    } catch (PDOException $e) {
        // Mostrar error detallado para depuración
        echo "Error de conexión detallado:<br>";
        echo "DSN: $dsn<br>";
        echo "Usuario: $user<br>";
        echo "Error: " . $e->getMessage() . "<br>";
        
        error_log("Error de conexión a la base de datos: " . $e->getMessage());
        return false;
    }
}

// Función alias para mantener compatibilidad
function get_db_connection() {
    return conectarBD();
}
?>